import 'dart:convert';

import '../../../services/json_document.dart';
import '../../../types/action.dart';
import '../../../utils/bdfd_duration_parser.dart';
import '../../../utils/math_parser.dart';
import '../../../utils/runtime_cooldowns.dart';
import '../../../utils/workflow_call.dart';
import '../execution.dart' show BdfdBackend;

/// The real logic of the control-flow actions that is not a native construct
/// (`runBdfdScript`, `runWorkflow`, `cooldown`) and the loop helpers shared by
/// the native runner and the historical executor. Pure functions over closures:
/// nothing here depends on the historical action loop (`handleActions`).

class ControlFlowExecutor {
  static final _runtimeCooldowns = RuntimeCooldowns.expirations;
  static String _getCooldownKey(
    String botId,
    String scope,
    String varKey,
    Map<String, String> variables,
  ) => RuntimeCooldowns.key(botId, scope, varKey, variables);

  static void setRuntimeCooldown(
    String botId,
    String scope,
    String varKey,
    Map<String, String> variables,
    String durationStr,
  ) {
    final duration = parseBdfdDuration(durationStr);
    if (duration == null) return;

    final key = _getCooldownKey(botId, scope, varKey, variables);
    _runtimeCooldowns[key] =
        DateTime.now().millisecondsSinceEpoch + duration.inMilliseconds;
  }

  static void removeRuntimeCooldown(
    String botId,
    String scope,
    String varKey,
    Map<String, String> variables,
  ) {
    final key = _getCooldownKey(botId, scope, varKey, variables);
    _runtimeCooldowns.remove(key);
  }
}

List<Action> decodeActionList(dynamic branchRaw) {
  final branchActions = <Action>[];
  if (branchRaw is! List) {
    return branchActions;
  }

  for (final item in branchRaw) {
    if (item is Map) {
      branchActions.add(Action.fromJson(Map<String, dynamic>.from(item)));
    }
  }

  return branchActions;
}

/// `runBdfdScript`: runs the payload's script through [executeNativeBdfdScript]
/// and mirrors its results as `<resultKey>.<name>`.
Future<void> runBdfdScriptBlock({
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Future<Map<String, String>> Function(String source)?
  executeNativeBdfdScript,
  required void Function() checkBudget,
}) async {
  BdfdBackend.parse(payload['bdfdBackend']);
  checkBudget();
  final source = (payload['scriptContent'] ?? '').toString();
  if (source.trim().isEmpty) {
    results[resultKey] = 'BDFD_EMPTY';
    return;
  }
  if (executeNativeBdfdScript == null) {
    throw StateError('Native BDFD execution is not available in this adapter.');
  }
  // Stored source is parsed before any data interpolation. Explicit eval
  // is handled inside the native interpreter, never by resolveValue.
  final nativeResults = await executeNativeBdfdScript(source);
  checkBudget();
  for (final entry in nativeResults.entries) {
    results['$resultKey.${entry.key}'] = entry.value;
  }
  if (nativeResults.containsKey('__stopped__')) {
    results['__stopped__'] = 'true';
  }
  results[resultKey] = 'BDFD_OK';
}

/// `runWorkflow`: runs a stored workflow (visual actions or script) with its
/// arguments, publishes `workflow.response.*` and `<resultKey>.<name>`.
Future<void> runWorkflowBlock({
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required Set<String> activeWorkflowStack,
  required Future<Map<String, dynamic>?> Function(String workflowName)
  getWorkflowByName,
  required Future<Map<String, String>> Function(List<Action> actions)
  executeActions,
  required Future<Map<String, String>> Function(String source)?
  executeNativeBdfdScript,
  required void Function() checkBudget,
  List<Action> Function(List<Action>)? nestedActionsPreprocessor,
}) async {
  final workflowName = resolveValue(
    (payload['workflowName'] ?? '').toString(),
  ).trim();
  if (workflowName.isEmpty) {
    throw Exception('workflowName is required for runWorkflow');
  }

  final workflow = await getWorkflowByName(workflowName);
  if (workflow == null) {
    throw Exception('Workflow not found: $workflowName');
  }

  final requestedEntryPoint = resolveValue(
    (payload['entryPoint'] ?? '').toString(),
  ).trim();
  final workflowEntryPoint = normalizeWorkflowEntryPoint(
    requestedEntryPoint,
    fallback: normalizeWorkflowEntryPoint(workflow['entryPoint']),
  );
  final workflowArgDefinitions = parseWorkflowArgumentDefinitions(
    workflow['arguments'],
  );
  final workflowCallArguments = resolveWorkflowCallArguments(
    payload['arguments'],
    resolveValue,
  );

  final stackKey =
      '${workflowName.toLowerCase()}::${workflowEntryPoint.toLowerCase()}';
  if (activeWorkflowStack.contains(stackKey)) {
    throw Exception(
      'Workflow recursion detected for "$workflowName" (entry: $workflowEntryPoint)',
    );
  }

  applyWorkflowInvocationContext(
    variables: variables,
    workflowName: workflowName,
    entryPoint: workflowEntryPoint,
    definitions: workflowArgDefinitions,
    providedArguments: workflowCallArguments,
  );

  final workflowData = Map<String, dynamic>.from(
    (workflow['data'] as Map?) ?? workflow,
  );
  final source =
      (workflowData['bdfdScriptContent'] ??
              workflowData['scriptContent'] ??
              workflowData['bdfdScript'] ??
              '')
          .toString();
  final isScript =
      workflowData['executionMode'] == 'bdfd_script' ||
      source.trim().isNotEmpty;
  activeWorkflowStack.add(stackKey);
  late final Map<String, String> workflowResults;
  try {
    if (isScript) {
      workflowResults = {};
      await runBdfdScriptBlock(
        payload: {
          'scriptContent': source,
          'bdfdBackend': workflowData['bdfdBackend'],
        },
        resultKey: 'script',
        results: workflowResults,
        executeNativeBdfdScript: executeNativeBdfdScript,
        checkBudget: checkBudget,
      );
    } else {
      final workflowActions = decodeActionList(workflowData['actions']);
      workflowResults = await executeActions(
        nestedActionsPreprocessor?.call(workflowActions) ?? workflowActions,
      );
    }
  } finally {
    activeWorkflowStack.remove(stackKey);
  }
  if (workflowResults.containsKey('__stopped__')) {
    results['__stopped__'] = 'true';
  }

  for (final entry in workflowResults.entries) {
    results['$resultKey.${entry.key}'] = entry.value;
    variables['workflow.response.${entry.key}'] = entry.value;
  }
  variables['workflow.response'] = 'WORKFLOW_OK:$workflowEntryPoint';
  results[resultKey] = 'WORKFLOW_OK:$workflowEntryPoint';
}

/// `cooldown` (set / change a runtime cooldown). The error message of an
/// active cooldown is sent through [executeActions] (a one-action list).
/// Returns normally; the `__stopped__` signal is left in [results].
Future<void> cooldownBlock({
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String botId,
  required String Function(String input) resolveValue,
  required Future<Map<String, String>> Function(List<Action> actions)
  executeActions,
}) async {
  final change = payload['operation'] == 'change';
  final scope = RuntimeCooldowns.normalizeScope(
    resolveValue(
      (payload['scope'] ??
              (change ? variables['cooldown.type'] ?? 'user' : 'user'))
          .toString(),
    ).trim(),
  );
  final durationStr = resolveValue(
    (payload['duration'] ?? '0s').toString(),
  ).trim();
  final duration = parseBdfdDuration(durationStr);
  if (duration == null) {
    throw FormatException('Invalid cooldown duration: $durationStr');
  }
  final varKey = resolveValue(
    (payload['key'] ??
            (change
                ? variables['cooldown.key.$scope'] ??
                      RuntimeCooldowns.defaultVariable(scope)
                : 'default'))
        .toString(),
  ).trim();
  final key = ControlFlowExecutor._getCooldownKey(
    botId,
    scope,
    varKey,
    variables,
  );
  final now = DateTime.now().millisecondsSinceEpoch;
  RuntimeCooldowns.select(variables, scope, varKey, botId: botId);
  if (change) {
    if (RuntimeCooldowns.remainingMs(key) > 0) {
      if (duration == Duration.zero) {
        RuntimeCooldowns.expirations.remove(key);
      } else {
        RuntimeCooldowns.expirations[key] = now + duration.inMilliseconds;
      }
    }
    results[resultKey] = 'CHANGED';
    return;
  }
  final expiresAt = RuntimeCooldowns.expirations[key];
  if (expiresAt != null && expiresAt > now) {
    results[resultKey] = 'ACTIVE';
    results['__stopped__'] = 'true';
    final discordTimestamp = '<t:${expiresAt ~/ 1000}:R>';
    variables['cooldown.time'] = discordTimestamp;
    final errorMessage = resolveValue(
      (payload['errorMessage'] ?? '').toString(),
    ).replaceAll('%time%', discordTimestamp);
    if (errorMessage.isNotEmpty) {
      results['cooldown.error'] = errorMessage;
      await executeActions([
        Action(
          type: BotCreatorActionType.sendMessage,
          payload: {'content': errorMessage},
        ),
      ]);
    }
    return;
  }
  if (duration > Duration.zero) {
    RuntimeCooldowns.expirations[key] = now + duration.inMilliseconds;
  }
  results[resultKey] = 'SET';
}

String _resolveLoopExpression(
  String template,
  Map<String, int> loopVars,
  String Function(String input) resolveValue, {
  bool replaceIdentifiers = false,
}) {
  var result = template;
  for (final entry in loopVars.entries) {
    result = result.replaceAll(
      '((_loop.var.${entry.key}))',
      entry.value.toString(),
    );
  }
  result = resolveValue(result);
  if (replaceIdentifiers) {
    for (final entry in loopVars.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
        entry.value.toString(),
      );
    }
  }
  return result;
}

bool _evaluateSimpleCondition(String resolved) {
  final pattern = RegExp(r'^(-?\d+)\s*(<=|>=|<|>|==|!=)\s*(-?\d+)$');
  final match = pattern.firstMatch(resolved.trim());
  if (match == null) return false;
  final left = int.tryParse(match.group(1)!) ?? 0;
  final op = match.group(2)!;
  final right = int.tryParse(match.group(3)!) ?? 0;
  switch (op) {
    case '<':
      return left < right;
    case '<=':
      return left <= right;
    case '>':
      return left > right;
    case '>=':
      return left >= right;
    case '==':
      return left == right;
    case '!=':
      return left != right;
    default:
      return false;
  }
}

void _applyRuntimeCStyleUpdate(
  String raw,
  Map<String, int> vars,
  String Function(String input) resolveValue,
) {
  for (final part in raw.split(',')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final resolved = _resolveLoopExpression(trimmed, vars, resolveValue);
    if (resolved.endsWith('++')) {
      final name = resolved
          .substring(0, resolved.length - 2)
          .trim()
          .toLowerCase();
      vars[name] = (vars[name] ?? 0) + 1;
    } else if (resolved.endsWith('--')) {
      final name = resolved
          .substring(0, resolved.length - 2)
          .trim()
          .toLowerCase();
      vars[name] = (vars[name] ?? 0) - 1;
    } else {
      final assignment = RegExp(
        r'^([a-zA-Z_]\w*)\s*(\+=|-=|\*=|/=|=)\s*(.+)$',
      ).firstMatch(resolved);
      if (assignment == null) {
        throw FormatException('Invalid loop update: $resolved');
      }
      final name = assignment.group(1)!.toLowerCase();
      final expression = _resolveLoopExpression(
        assignment.group(3)!,
        vars,
        resolveValue,
        replaceIdentifiers: true,
      );
      final value = MathExpressionParser(
        expression.replaceAll(RegExp(r'\s+'), ''),
      ).parse();
      if (value == null || !value.isFinite) {
        throw FormatException('Invalid loop update expression: $expression');
      }
      final current = vars[name] ?? 0;
      switch (assignment.group(2)) {
        case '=':
          vars[name] = value.toInt();
        case '+=':
          vars[name] = current + value.toInt();
        case '-=':
          vars[name] = current - value.toInt();
        case '*=':
          vars[name] = (current * value).toInt();
        case '/=':
          if (value == 0) {
            throw FormatException('Loop update cannot divide by zero');
          }
          vars[name] = (current / value).toInt();
      }
    }
  }
}

/// The immutable snapshot a `jsonForEachLoop` iterates: the JSON source is
/// looked up in the variables/results context (latest runtime JSON block), then
/// in the payload's compile-time `source`, and navigated by [pathSegments].
/// Shared by the historical executor and the native visual runner.
List<MapEntry<String, String>> resolveJsonForEachEntries({
  required Map<String, dynamic> payload,
  required List<String> pathSegments,
  required Map<String, String> variables,
  required Map<String, String> results,
}) {
  dynamic jsonCtx;
  final mergedContext = <String, String>{...variables, ...results};
  var jsonSource = _findLatestJsonContext(mergedContext);
  // Fall back to the compile-time source embedded in the payload.
  if (jsonSource.isEmpty) {
    jsonSource = (payload['source'] as String?) ?? '';
  }
  if (jsonSource.isNotEmpty) {
    try {
      jsonCtx = jsonDecode(jsonSource);
    } catch (_) {
      jsonCtx = null;
    }
  }

  // Navigate the path.
  if (jsonCtx != null && pathSegments.isNotEmpty) {
    for (final segment in pathSegments) {
      final index = int.tryParse(segment);
      if (index != null && jsonCtx is List) {
        if (index < 0 || index >= jsonCtx.length) {
          jsonCtx = null;
          break;
        }
        jsonCtx = jsonCtx[index];
      } else if (jsonCtx is Map) {
        if (!jsonCtx.containsKey(segment)) {
          jsonCtx = null;
          break;
        }
        jsonCtx = jsonCtx[segment];
      } else {
        jsonCtx = null;
        break;
      }
    }
  }

  // Project JSON foreach extension: use the same immutable iteration
  // snapshot as native BDFD. Body mutations cannot extend this traversal.
  return JsonDocument(jsonCtx).iterationSnapshot(const []);
}

/// C-style `forLoop` helpers, shared with the native visual runner.
///
/// Parses the resolved `init` ("i=0, j=10") into the loop variables.
Map<String, int> parseCStyleLoopInit(
  String initRaw,
  String Function(String input) resolveValue,
) {
  final loopVars = <String, int>{};
  for (final part in initRaw.split(',')) {
    final eqIndex = part.indexOf('=');
    if (eqIndex < 0) continue;
    final name = part.substring(0, eqIndex).trim().toLowerCase();
    final valueStr = resolveValue(part.substring(eqIndex + 1).trim());
    loopVars[name] = int.tryParse(valueStr) ?? 0;
  }
  return loopVars;
}

/// Whether the C-style [conditionTemplate] still holds for [loopVars].
bool evaluateCStyleLoopCondition(
  String conditionTemplate,
  Map<String, int> loopVars,
  String Function(String input) resolveValue,
) => _evaluateSimpleCondition(
  _resolveLoopExpression(
    conditionTemplate,
    loopVars,
    resolveValue,
    replaceIdentifiers: true,
  ),
);

/// Applies the C-style [updateTemplate] (`i++`, `i += 2`, ...) to [loopVars].
void applyCStyleLoopUpdate(
  String updateTemplate,
  Map<String, int> loopVars,
  String Function(String input) resolveValue,
) => _applyRuntimeCStyleUpdate(updateTemplate, loopVars, resolveValue);

/// Finds the latest runtime JSON context value from merged variables/results.
String _findLatestJsonContext(Map<String, String> mergedContext) {
  String? best;
  int bestIndex = -1;
  for (final entry in mergedContext.entries) {
    final key = entry.key.toLowerCase();
    if (entry.value.trim().isEmpty) continue;
    if (!key.startsWith('rtjson_') &&
        !RegExp(r'^action_\d+(\.json_\d+)?$').hasMatch(key)) {
      continue;
    }
    final idx = _feActionKeyIndex(key);
    if (idx > bestIndex && _looksLikeJson(entry.value)) {
      bestIndex = idx;
      best = entry.value;
    }
  }
  return best ?? '';
}

int _feActionKeyIndex(String key) {
  final match = RegExp(r'(\d+)').firstMatch(key);
  return match != null ? (int.tryParse(match.group(1)!) ?? 0) : 0;
}

bool _looksLikeJson(String value) {
  final trimmed = value.trim();
  return (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      (trimmed.startsWith('[') && trimmed.endsWith(']'));
}
