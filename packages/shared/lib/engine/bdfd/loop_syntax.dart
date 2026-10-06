import '../../utils/bdfd_ast.dart';

enum BdfdLoopKind { counted, cStyle, list, whileLoop }

class BdfdLoopAssignment {
  BdfdLoopAssignment(this.name, this.operator, List<BdfdAstNode> value)
    : value = List.unmodifiable(value);
  final String name;
  final String operator;
  final List<BdfdAstNode> value;
}

/// Parse the loop grammar from source nodes, before interpolating any values.
/// An evaluated value cannot introduce an assignment or a new loop binding.
class BdfdLoopSyntax {
  BdfdLoopSyntax._(
    this.kind, {
    this.iterator,
    this.initializers = const [],
    this.updates = const [],
  });
  final BdfdLoopKind kind;
  final String? iterator;
  final List<BdfdLoopAssignment> initializers;
  final List<BdfdLoopAssignment> updates;
  Set<String> get bindings => {
    ?iterator,
    for (final initializer in initializers) initializer.name,
  };

  static BdfdLoopSyntax parse(BdfdFunctionCallAst node) {
    final args = node.arguments;
    if (node.normalizedName == 'while') {
      if (args.length != 1) {
        throw const FormatException('Expected one while condition.');
      }
      return BdfdLoopSyntax._(BdfdLoopKind.whileLoop);
    }
    if (args.isEmpty) throw const FormatException('Expected a loop argument.');
    if (args.length == 1) return BdfdLoopSyntax._(BdfdLoopKind.counted);
    final initPrefix = args.first.firstOrNull;
    final cStyle =
        args.length == 3 &&
        ((initPrefix is BdfdTextAst &&
                RegExp(r'^\s*[a-zA-Z_]\w*\s*=').hasMatch(initPrefix.value)) ||
            args[1].whereType<BdfdTextAst>().any(
              (text) => RegExp(r'<=|>=|==|!=|<|>').hasMatch(text.value),
            ));
    if (cStyle) {
      final initializers = _assignments(args[0], initialize: true);
      final updates = _assignments(args[2], initialize: false);
      final names = initializers.map((item) => item.name).toSet();
      if (updates.any((item) => !names.contains(item.name))) {
        throw const FormatException(
          'Loop updates must refer to declared variables.',
        );
      }
      return BdfdLoopSyntax._(
        BdfdLoopKind.cStyle,
        initializers: List.unmodifiable(initializers),
        updates: List.unmodifiable(updates),
      );
    }
    if (args.first.any((node) => node is! BdfdTextAst)) {
      throw const FormatException(
        'The iterator name must be a literal identifier.',
      );
    }
    final iterator = args.first
        .cast<BdfdTextAst>()
        .map((node) => node.value)
        .join()
        .trim();
    if (!RegExp(r'^[a-zA-Z_]\w*$').hasMatch(iterator)) {
      throw const FormatException('Invalid iterator name.');
    }
    return BdfdLoopSyntax._(
      BdfdLoopKind.list,
      iterator: iterator.toLowerCase(),
    );
  }

  static List<BdfdLoopAssignment> _assignments(
    List<BdfdAstNode> nodes, {
    required bool initialize,
  }) {
    final parts = <List<BdfdAstNode>>[[]];
    for (final node in nodes) {
      if (node is! BdfdTextAst) {
        parts.last.add(node);
        continue;
      }
      var offset = node.start;
      final fragments = node.value.split(',');
      for (var i = 0; i < fragments.length; i++) {
        if (i > 0) parts.add([]);
        final text = fragments[i];
        if (text.isNotEmpty) {
          parts.last.add(
            BdfdTextAst(
              text,
              start: offset,
              end: offset == null ? null : offset + text.length,
            ),
          );
        }
        if (offset != null) offset += text.length + 1;
      }
    }
    final result = <BdfdLoopAssignment>[];
    for (final part in parts) {
      final first = part.firstOrNull;
      final header = first is BdfdTextAst
          ? RegExp(
              r'^\s*([a-zA-Z_]\w*)\s*(\+\+|--|\+=|-=|\*=|/=|=)\s*',
            ).firstMatch(first.value)
          : null;
      if (header == null || (initialize && header[2] != '=')) {
        throw FormatException(
          initialize ? 'Invalid loop initialization.' : 'Invalid loop update.',
        );
      }
      final text = first as BdfdTextAst;
      final rest = text.value.substring(header.end);
      final value = <BdfdAstNode>[
        if (rest.isNotEmpty)
          BdfdTextAst(
            rest,
            start: text.start == null ? null : text.start! + header.end,
            end: text.end,
          ),
        ...part.skip(1),
      ];
      if (['++', '--'].contains(header[2])) {
        if (value.isNotEmpty) {
          throw const FormatException('Unexpected text after loop increment.');
        }
      } else if (value.isEmpty) {
        throw const FormatException('Missing loop assignment value.');
      }
      result.add(
        BdfdLoopAssignment(header[1]!.toLowerCase(), header[2]!, value),
      );
    }
    return result;
  }
}
