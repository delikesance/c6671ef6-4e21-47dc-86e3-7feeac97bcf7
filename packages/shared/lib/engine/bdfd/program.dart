import '../../utils/bdfd_ast.dart';
import '../../utils/bdfd_lexer.dart';
import '../../utils/bdfd_parser.dart';
import 'loop_syntax.dart';

/// A source location stays attached to native execution, including nested eval.
class BdfdLocation {
  BdfdLocation(this.source, this.offset, {this.functionName});
  final String source;
  final int offset;
  final String? functionName;
  int get line => '\n'.allMatches(source.substring(0, offset)).length + 1;
  int get column =>
      offset == 0 ? 1 : offset - source.lastIndexOf('\n', offset - 1);
}

class BdfdNativeError implements Exception {
  BdfdNativeError(
    this.message,
    this.location, {
    this.cause,
    this.callStack = const [],
  });
  final String message;
  final BdfdLocation location;
  final Object? cause;
  final List<BdfdLocation> callStack;
  @override
  String toString() =>
      'BDFD L${location.line}:${location.column}'
      '${location.functionName == null ? '' : ' ${location.functionName}'}: $message';
}

sealed class BdfdStatement {
  const BdfdStatement(this.node);
  final BdfdAstNode node;
}

class BdfdExpression extends BdfdStatement {
  const BdfdExpression(super.node);
}

class BdfdBranch {
  const BdfdBranch(this.condition, this.body);
  final List<BdfdAstNode>? condition;
  final List<BdfdStatement> body;
}

class BdfdConditional extends BdfdStatement {
  const BdfdConditional(super.node, this.branches);
  final List<BdfdBranch> branches;
}

class BdfdLoop extends BdfdStatement {
  const BdfdLoop(super.node, this.body, this.syntax);
  final List<BdfdStatement> body;
  final BdfdLoopSyntax syntax;
}

class BdfdJsonForEach extends BdfdStatement {
  const BdfdJsonForEach(super.node, this.body);
  final List<BdfdStatement> body;
}

class BdfdTry extends BdfdStatement {
  const BdfdTry(super.node, this.body, this.catchBody);
  final List<BdfdStatement> body;
  final List<BdfdStatement> catchBody;
}

class BdfdFunctionDefinition extends BdfdStatement {
  const BdfdFunctionDefinition(
    super.node,
    this.name,
    this.parameters,
    this.body,
  );
  final String name;
  final List<String> parameters;
  final List<BdfdStatement> body;
}

/// Native program: no Action model, block payload or transpiler dependency.
class BdfdProgram {
  static const structuralFunctionNames = <String>{
    'if',
    'elseif',
    'else',
    'endif',
    'for',
    'loop',
    'while',
    'endfor',
    'endloop',
    'endwhile',
    'jsonforeach',
    'endjsonforeach',
    'try',
    'catch',
    'endtry',
    'func',
    'funcend',
  };
  BdfdProgram._(this.source, this.statements);

  /// Builds a program from statements assembled by an adapter instead of
  /// parsed from BDFD text. [source] only backs diagnostics: every node's
  /// `start`/`end` must be an offset range inside it, because locations,
  /// error details and replay frames are derived from that text (it is never
  /// parsed or executed). A program parsed from text is unchanged.
  factory BdfdProgram.fromStatements(
    String source,
    List<BdfdStatement> statements,
  ) => BdfdProgram._(source, List.unmodifiable(statements));

  final String source;
  final List<BdfdStatement> statements;

  static BdfdProgram parse(String source) {
    final lexer = BdfdLexer().tokenize(source);
    if (lexer.diagnostics.isNotEmpty) {
      final d = lexer.diagnostics.first;
      throw BdfdNativeError(d.message, BdfdLocation(source, d.start));
    }
    final parsed = BdfdParser().parseTokens(lexer.tokens);
    if (parsed.diagnostics.isNotEmpty) {
      final d = parsed.diagnostics.first;
      throw BdfdNativeError(d.message, BdfdLocation(source, d.start));
    }
    final structure = _Structure(source, parsed.ast.nodes);
    return BdfdProgram._(source, List.unmodifiable(structure.read()));
  }
}

class _Structure {
  _Structure(this.source, this.nodes);
  final String source;
  final List<BdfdAstNode> nodes;
  int index = 0;
  static const delimiters = {
    'elseif',
    'else',
    'endif',
    'endfor',
    'endloop',
    'endwhile',
    'endjsonforeach',
    'catch',
    'endtry',
    'funcend',
  };

  BdfdNativeError error(BdfdAstNode node, String message) => BdfdNativeError(
    message,
    BdfdLocation(
      source,
      node.start ?? 0,
      functionName: node is BdfdFunctionCallAst ? node.name : null,
    ),
  );

  List<BdfdStatement> read([Set<String> until = const {}, int depth = 0]) {
    if (depth > 128) {
      throw BdfdNativeError(
        'Block nesting limit exceeded.',
        BdfdLocation(
          source,
          index < nodes.length ? nodes[index].start ?? 0 : source.length,
        ),
      );
    }
    final result = <BdfdStatement>[];
    while (index < nodes.length) {
      final node = nodes[index];
      if (node is BdfdFunctionCallAst) {
        final name = node.normalizedName;
        if (until.contains(name)) break;
        if (delimiters.contains(name)) {
          throw error(node, 'Unexpected ${node.name}.');
        }
        if (name == 'func') {
          if (node.arguments.isEmpty || node.arguments.length > 101) {
            throw error(
              node,
              'Expected a function name and up to 100 parameters.',
            );
          }
          final names = <String>[];
          for (final argument in node.arguments) {
            if (argument.any((part) => part is! BdfdTextAst)) {
              throw error(
                node,
                'Function names and parameters must be literal.',
              );
            }
            final value = argument
                .cast<BdfdTextAst>()
                .map((part) => part.value)
                .join()
                .trim()
                .toLowerCase();
            if (value.isEmpty) {
              throw error(
                node,
                'Function names and parameters cannot be empty.',
              );
            }
            names.add(value);
          }
          final parameters = names.skip(1).toList(growable: false);
          if (parameters.toSet().length != parameters.length) {
            throw error(node, 'Duplicate function parameter.');
          }
          index++;
          final body = read({'funcend'}, depth + 1);
          close(node, 'funcend');
          result.add(
            BdfdFunctionDefinition(
              node,
              names.first,
              List.unmodifiable(parameters),
              body,
            ),
          );
          continue;
        }
        if (name == 'if' && node.arguments.length == 1) {
          index++;
          final branches = <BdfdBranch>[
            BdfdBranch(
              node.arguments.single,
              read({'elseif', 'else', 'endif'}, depth + 1),
            ),
          ];
          while (index < nodes.length && _name == 'elseif') {
            final branch = nodes[index++] as BdfdFunctionCallAst;
            if (branch.arguments.length != 1) {
              throw error(branch, 'Expected one condition.');
            }
            branches.add(
              BdfdBranch(
                branch.arguments.single,
                read({'elseif', 'else', 'endif'}, depth + 1),
              ),
            );
          }
          if (index < nodes.length && _name == 'else') {
            _delimiter('else');
            branches.add(BdfdBranch(null, read({'endif'}, depth + 1)));
          }
          close(node, 'endif');
          result.add(BdfdConditional(node, List.unmodifiable(branches)));
          continue;
        }
        if (name == 'for' || name == 'loop' || name == 'while') {
          final BdfdLoopSyntax syntax;
          try {
            syntax = BdfdLoopSyntax.parse(node);
          } on FormatException catch (exception) {
            throw error(node, exception.message.toString());
          }
          index++;
          final body = read({'end$name'}, depth + 1);
          close(node, 'end$name');
          result.add(BdfdLoop(node, List.unmodifiable(body), syntax));
          continue;
        }
        if (name == 'jsonforeach') {
          if (node.arguments.length > 100) {
            throw error(node, 'Too many JSON path segments.');
          }
          index++;
          final body = read({'endjsonforeach'}, depth + 1);
          close(node, 'endjsonforeach');
          result.add(BdfdJsonForEach(node, List.unmodifiable(body)));
          continue;
        }
        if (name == 'try' && node.arguments.isEmpty) {
          index++;
          final body = read({'catch', 'endtry'}, depth + 1);
          var catchBody = <BdfdStatement>[];
          if (index < nodes.length && _name == 'catch') {
            _delimiter('catch');
            catchBody = read({'endtry'}, depth + 1);
          }
          close(node, 'endtry');
          result.add(
            BdfdTry(
              node,
              List.unmodifiable(body),
              List.unmodifiable(catchBody),
            ),
          );
          continue;
        }
      }
      result.add(BdfdExpression(node));
      index++;
    }
    return List.unmodifiable(result);
  }

  String? get _name => nodes[index] is BdfdFunctionCallAst
      ? (nodes[index] as BdfdFunctionCallAst).normalizedName
      : null;

  void _delimiter(String name) {
    final node = nodes[index++] as BdfdFunctionCallAst;
    if (node.arguments.isNotEmpty) {
      throw error(node, '\$$name does not accept arguments.');
    }
  }

  void close(BdfdAstNode opening, String name) {
    if (index >= nodes.length || _name != name) {
      throw error(opening, 'Missing \$$name.');
    }
    _delimiter(name);
  }
}
