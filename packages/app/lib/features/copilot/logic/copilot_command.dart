import 'dart:convert';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';
import 'package:bot_creator_shared/types/action.dart' as blocks;

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

Map<String, dynamic> copilotExecutionData(String script) =>
    copilotExecutionDataForMode('bdfd_script', script: script);

/// Compile without saving or performing Discord operations. This is a syntax
/// and supported-function check, not evidence of successful runtime execution.
Map<String, dynamic> validateCopilotBdfd(String script) {
  try {
    final actions = compileCopilotCommand(script);
    final result = BdfdCompiler().compile(script);
    return {
      'valid': true,
      'validation_kind': 'compilation',
      'runtime_tested': false,
      'script_revision': HashUtil.calculateHash(script),
      'action_count': actions.length,
      'action_types': actions.map((a) => a['type']).toSet().toList(),
      'diagnostics': [
        for (final diagnostic in result.diagnostics)
          {
            'severity': diagnostic.severity.name,
            'message': diagnostic.message,
            if (diagnostic.line != null) 'line': diagnostic.line,
            if (diagnostic.column != null) 'column': diagnostic.column,
          },
      ],
      'message':
          'Compilation passed. Discord permissions, resource IDs and '
          'behavior still require runtime verification.',
    };
  } on FormatException catch (error) {
    return {
      'valid': false,
      'validation_kind': 'compilation',
      'runtime_tested': false,
      'script_revision': HashUtil.calculateHash(script),
      'diagnostics': [
        {'severity': 'error', 'message': error.message},
      ],
    };
  }
}

Map<String, dynamic> copilotExecutionDataForMode(
  String executionMode, {
  String? script,
  String? actionsJson,
}) {
  if (!const {
    'bdfd_script',
    'javascript',
    'workflow',
  }.contains(executionMode)) {
    throw const FormatException('Unsupported execution mode');
  }
  final source = script ?? '';
  var actions = <Map<String, dynamic>>[];
  if (executionMode == 'bdfd_script') {
    compileCopilotCommand(source);
  } else if (executionMode == 'javascript') {
    if (source.trim().isEmpty || source.length > 12000) {
      throw const FormatException('Invalid JavaScript length');
    }
  } else {
    if (actionsJson == null || actionsJson.length > 24000) {
      throw const FormatException('Visual blocks are required');
    }
    final decoded = jsonDecode(actionsJson);
    if (decoded is! List || decoded.isEmpty || decoded.length > 80) {
      throw const FormatException('Invalid visual blocks');
    }
    actions = decoded.map((item) {
      if (item is! Map || item['payload'] is! Map) {
        throw const FormatException('Invalid visual block');
      }
      return blocks.Action.fromJson(Map<String, dynamic>.from(item)).toJson();
    }).toList();
  }
  return {
    'executionMode': executionMode,
    'editorMode': 'advanced',
    'bdfdScriptContent': executionMode == 'bdfd_script' ? source : '',
    'jsScriptContent': executionMode == 'javascript' ? source : '',
    'actions': actions,
    'response': {
      'mode': 'message',
      'text': '',
      'embeds': <Map<String, dynamic>>[],
    },
  };
}

Map<String, dynamic> replaceCopilotExecution(
  Map<String, dynamic> command,
  String expectedRevision,
  String script, {
  String? route,
  String executionMode = 'bdfd_script',
  String? actionsJson,
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
      ...copilotExecutionDataForMode(
        executionMode,
        script: script,
        actionsJson: actionsJson,
      ),
    };
    data['subcommandWorkflows'] = workflows;
  } else {
    data.addAll(
      copilotExecutionDataForMode(
        executionMode,
        script: script,
        actionsJson: actionsJson,
      ),
    );
  }
  copy['data'] = data;
  return copy;
}
