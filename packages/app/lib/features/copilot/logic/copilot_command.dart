import 'dart:convert';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';

/// The editor compiler constructs all action types and payloads. Unknown
/// functions supplied by AI never enter a saved command.
List<Map<String, dynamic>> compileCopilotCommand(String script) {
  if (script.trim().isEmpty || script.length > 12000) {
    throw const FormatException('Invalid script length');
  }
  final lexical = BdfdLexer().tokenize(script);
  for (final token in lexical.tokens) {
    if (token.type == BdfdTokenType.function &&
        !allBdfdFunctions.contains(token.lexeme.substring(1).toLowerCase())) {
      throw FormatException(
        'Unknown function ${token.lexeme}; use the local block registry',
      );
    }
  }
  final result = BdfdCompiler().compile(script);
  if (result.hasErrors || result.actions.isEmpty) {
    throw FormatException(result.diagnostics.map((d) => d.message).join('\n'));
  }
  return result.actions.map((a) => a.toJson()).toList();
}

Map<String, dynamic> copilotExecutionData(String script) => {
  'executionMode': 'workflow',
  'editorMode': 'advanced',
  'bdfdScriptContent': '',
  'jsScriptContent': '',
  'actions': compileCopilotCommand(script),
  'response': {
    'mode': 'message',
    'text': '',
    'embeds': <Map<String, dynamic>>[],
  },
};

Map<String, dynamic> replaceCopilotExecution(
  Map<String, dynamic> command,
  String expectedRevision,
  String script, {
  String? route,
}) {
  if (command.isEmpty || HashUtil.calculateHash(command) != expectedRevision) {
    throw StateError(
      'Command changed; read its latest revision before editing',
    );
  }
  final copy = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(command)) as Map,
  );
  final data = Map<String, dynamic>.from(copy['data'] as Map? ?? {});
  final workflows = Map<String, dynamic>.from(
    data['subcommandWorkflows'] as Map? ?? {},
  );
  if (workflows.isNotEmpty && route == null) {
    throw StateError('Choose a subcommand route before editing its execution');
  }
  if (route != null) {
    if (workflows[route] is! Map) {
      throw StateError('Subcommand route not found');
    }
    workflows[route] = {
      ...Map<String, dynamic>.from(workflows[route] as Map),
      ...copilotExecutionData(script),
    };
    data['subcommandWorkflows'] = workflows;
  } else {
    data.addAll(copilotExecutionData(script));
  }
  copy['data'] = data;
  return copy;
}
