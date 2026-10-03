import 'bdfd_ast.dart';
import 'bdfd_compiler.dart';
import 'bdfd_lexer.dart';
import 'bdfd_parser.dart';

/// Preserves legacy global-user storage while adopting official user functions.
/// Source spans retain escapes and text; only executable calls are rewritten.
({String source, int changes}) migrateLegacyUserVariableScript(String source) {
  final lexical = BdfdLexer().tokenize(source);
  final parsed = BdfdParser().parseTokens(lexical.tokens);
  if (lexical.hasErrors || parsed.hasErrors) {
    throw const FormatException(
      'Repair BDFD syntax before migrating variables',
    );
  }
  var changes = 0;
  late String Function(BdfdAstNode) render;
  String argument(List<BdfdAstNode> nodes) => nodes.map(render).join();
  render = (node) {
    final original = source.substring(node.start!, node.end!);
    if (node is! BdfdFunctionCallAst) return original;
    final name = node.normalizedName;
    if (name == 'c' || name == 'comment') return original;
    if (name == 'eval') {
      throw const FormatException(
        'Dynamic BDFD eval requires manual migration',
      );
    }
    final args = node.arguments.map(argument).toList();
    final isGet = name == 'getuservar';
    final isSet = name == 'setuservar';
    final isReset = name == 'resetuservar';
    if (isGet || isSet || isReset) {
      final userIndex = isSet ? 2 : 1;
      final guildIndex = userIndex + 1;
      if (args.isEmpty ||
          args.first.trim().isEmpty ||
          args.length > guildIndex + 1 ||
          (isSet && args.length < 2)) {
        throw FormatException('Invalid arguments for ${node.name}');
      }
      final user = args.length > userIndex && args[userIndex].trim().isNotEmpty
          ? args[userIndex]
          : r'$authorID';
      final guild = args.length > guildIndex ? args[guildIndex].trim() : '';
      if (guild.isEmpty) {
        changes++;
        if (isGet) return '\$getVar[${args[0]};$user]';
        if (isSet) return '\$setVar[${args[0]};${args[1]};$user]';
        return '\$resetGlobalUserVar[${args[0]};$user]';
      }
      if (isReset) {
        changes++;
        return '\$resetGuildMemberVar[${args[0]};$user;${args[guildIndex]}]';
      }
    }
    if (args.isEmpty) return original;
    return '${node.name}[${args.join(';')}]';
  };
  final migrated = parsed.ast.nodes.map(render).join();
  if (changes > 0 && BdfdCompiler().compile(migrated).hasErrors) {
    throw const FormatException('Migrated BDFD script does not compile');
  }
  return (source: changes == 0 ? source : migrated, changes: changes);
}

/// Transforms executable fields only. Storage, definitions, JS and metadata
/// remain untouched. The result is safe to run on either legacy or v2 runtimes.
({Map<String, dynamic> document, int changes})
migrateLegacyUserVariableDocument(Map<String, dynamic> document) {
  var changes = 0;
  String script(String source) {
    if (!source.contains(r'$')) return source;
    final result = migrateLegacyUserVariableScript(source);
    changes += result.changes;
    return result.source;
  }

  dynamic visit(dynamic value, {bool executable = false}) {
    if (value is String) return executable ? script(value) : value;
    if (value is List) {
      return value.map((item) => visit(item, executable: executable)).toList();
    }
    if (value is! Map) return value;
    final mode = value['executionMode'] ?? value['execution_mode'];
    if (mode == 'javascript') return Map<String, dynamic>.from(value);
    return <String, dynamic>{
      for (final entry in value.entries)
        entry.key.toString(): visit(
          entry.value,
          executable:
              executable ||
              const {
                'bdfdScriptContent',
                'bdfdScript',
                'scriptContent',
                'payload',
              }.contains(entry.key) ||
              (entry.key == 'script' && mode == 'bdfd_script'),
        ),
    };
  }

  return (document: visit(document) as Map<String, dynamic>, changes: changes);
}
