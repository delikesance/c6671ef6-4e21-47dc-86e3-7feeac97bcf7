import 'dart:convert';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_tool_result.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';
import 'package:bot_creator_shared/types/action.dart' as blocks;

/// Settings edits do not need to transmit scripts or compiled action trees.
/// Revisions must always be calculated from the original, complete command.
Map<String, dynamic> copilotCommandSettings(Map<String, dynamic> command) {
  final data = command['data'] as Map? ?? const {};
  return {
    for (final key in ['id', 'discordId', 'name', 'description', 'type'])
      if (command.containsKey(key)) key: command[key],
    'data': {
      for (final key in [
        'executionMode',
        'options',
        'defaultMemberPermissions',
        'contexts',
        'integrationTypes',
      ])
        if (data.containsKey(key)) key: data[key],
    },
  };
}

/// Checks an AI-supplied BDFD script with the lexer, the function registry and
/// the compiler diagnostics. Unknown functions never enter a saved command.
/// BDFD scripts execute natively (`native-v1`), so nothing is compiled to
/// actions; the checked diagnostics are returned.
BdfdCompileResult checkCopilotBdfd(
  String script, {
  bool legacyUserVariables = false,
}) {
  if (script.trim().isEmpty || script.length > 12000) {
    throw const FormatException('Invalid script length');
  }
  final lexical = BdfdLexer().tokenize(script);
  for (final token in lexical.tokens) {
    if (token.type == BdfdTokenType.function &&
        !allBdfdFunctions.contains(token.lexeme.substring(1).toLowerCase())) {
      throw CopilotArgumentError(
        'Unknown function ${token.lexeme}; use the local block registry',
      );
    }
  }
  // The lexer keeps unknown names as literal text (the runtime preserves them),
  // so Copilot, which must never save a hallucinated function, checks every
  // bracketed call itself.
  for (final match in RegExp(r'(?<!\\)\$([A-Za-z_]\w*)\[').allMatches(script)) {
    if (!allBdfdFunctions.contains(match.group(1)!.toLowerCase())) {
      throw CopilotArgumentError(
        'Unknown function \$${match.group(1)}; use the local block registry',
      );
    }
  }
  final result = BdfdCompiler(
    legacyUserVariables: legacyUserVariables,
  ).compile(script);
  if (result.hasErrors) {
    throw CopilotArgumentError(result.diagnostics.map((d) => d.message).join('\n'));
  }
  return result;
}

Map<String, dynamic> copilotExecutionData(String script) =>
    copilotExecutionDataForMode('bdfd_script', script: script);

/// Compile without saving or performing Discord operations. This is a syntax
/// and supported-function check, not evidence of successful runtime execution.
Map<String, dynamic> validateCopilotBdfd(
  String script, {
  bool legacyUserVariables = false,
}) {
  try {
    final result = checkCopilotBdfd(
      script,
      legacyUserVariables: legacyUserVariables,
    );
    return {
      'valid': true,
      'bdfdUserVariableSemantics': legacyUserVariables ? 1 : 2,
      'validation_kind': 'compilation',
      'runtime_tested': false,
      'script_revision': HashUtil.calculateHash(script),
      'bdfdBackend': 'native-v1',
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
      'bdfdUserVariableSemantics': legacyUserVariables ? 1 : 2,
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
  bool legacyUserVariables = false,
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
    checkCopilotBdfd(source, legacyUserVariables: legacyUserVariables);
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
    if (executionMode == 'bdfd_script') 'bdfdBackend': 'native-v1',
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
  bool legacyUserVariables = false,
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
        legacyUserVariables: legacyUserVariables,
      ),
    };
    data['subcommandWorkflows'] = workflows;
  } else {
    data.addAll(
      copilotExecutionDataForMode(
        executionMode,
        script: script,
        actionsJson: actionsJson,
        legacyUserVariables: legacyUserVariables,
      ),
    );
  }
  copy['data'] = data;
  return copy;
}
