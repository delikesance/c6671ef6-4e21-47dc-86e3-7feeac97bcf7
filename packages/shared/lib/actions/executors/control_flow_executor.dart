import '../../engine/bdfd/visual/control_flow_logic.dart';
import '../../types/action.dart';
import '../execution_budget.dart';
import '../../services/action_condition.dart';
import '../../utils/bdfd_duration_parser.dart';

export '../../engine/bdfd/visual/control_flow_logic.dart'
    show
        ControlFlowExecutor,
        applyCStyleLoopUpdate,
        evaluateCStyleLoopCondition,
        parseCStyleLoopInit,
        resolveJsonForEachEntries;

// Historical (pre-native) control-flow executor. The logic that is not tied to
// the historical action loop lives in
// engine/bdfd/visual/control_flow_logic.dart; what stays here is the loop /
// if-block driver of the historical path, deleted with it.
List<Action> _decodeActionList(dynamic raw) => decodeActionList(raw);

Future<bool> executeControlFlowAction({
  required BotCreatorActionType type,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String botId,
  required String Function(String input) resolveValue,
  required void Function(String message)? onLog,
  required Set<String> activeWorkflowStack,
  required Future<Map<String, dynamic>?> Function(String workflowName)
  getWorkflowByName,
  required Future<Map<String, String>> Function(List<Action> actions)
  executeActions,
  void Function()? checkExecutionBudget,
  Future<Map<String, String>> Function(String source)? executeNativeBdfdScript,
  Future<Map<String, String>> Function(List<Action> actions)?
  executeProtectedActions,

  /// When provided, applied to compiled/resolved actions before they are
  /// passed to [executeActions] in [runBdfdScript] and [runWorkflow]. Used by
  /// Legacy command handlers to adapt actions for messageCreate context.
  List<Action> Function(List<Action>)? nestedActionsPreprocessor,

  /// Optional provider for variable TTLs, used for cooldown resolution.
  Future<int?> Function(String scope, String key)? getScopedVariableTtl,
}) async {
  final checkBudget = checkExecutionBudget ?? CommandExecutionBudget().check;
  switch (type) {
    case BotCreatorActionType.runBdfdScript:
      await runBdfdScriptBlock(
        payload: payload,
        resultKey: resultKey,
        results: results,
        executeNativeBdfdScript: executeNativeBdfdScript,
        checkBudget: checkBudget,
      );
      return true;

    case BotCreatorActionType.runWorkflow:
      await runWorkflowBlock(
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        resolveValue: resolveValue,
        activeWorkflowStack: activeWorkflowStack,
        getWorkflowByName: getWorkflowByName,
        executeActions: executeActions,
        executeNativeBdfdScript: executeNativeBdfdScript,
        checkBudget: checkBudget,
        nestedActionsPreprocessor: nestedActionsPreprocessor,
      );
      return true;

    case BotCreatorActionType.stopUnless:
      final conditionPassed = await evaluateActionCondition(
        payload: payload,
        variables: variables,
        resolveValue: resolveValue,
        getScopedVariableTtl: getScopedVariableTtl,
      );
      results[resultKey] = conditionPassed ? 'PASSED' : 'STOPPED';
      if (!conditionPassed) {
        results['__stopped__'] = 'true';
      }
      return true;

    case BotCreatorActionType.ifBlock:
      if (payload['tryCatch'] == true) {
        final previousError = {
          for (final entry in variables.entries)
            if (entry.key.startsWith('error.')) entry.key: entry.value,
        };
        variables.removeWhere((key, _) => key.startsWith('error.'));
        var handled = false;
        Map<String, String> nestedResults;
        try {
          try {
            nestedResults = await (executeProtectedActions ?? executeActions)(
              _decodeActionList(payload['thenActions']),
            );
            results[resultKey] = 'TRY_OK';
          } catch (_) {
            results[resultKey] = 'TRY_CAUGHT';
            nestedResults = await (executeProtectedActions ?? executeActions)(
              _decodeActionList(payload['elseActions']),
            );
          }
          for (final entry in nestedResults.entries) {
            results['$resultKey.${entry.key}'] = entry.value;
          }
          if (nestedResults.containsKey('__stopped__')) {
            results['__stopped__'] = 'true';
          }
          handled = true;
        } finally {
          if (handled) {
            variables.removeWhere((key, _) => key.startsWith('error.'));
            variables.addAll(previousError);
          }
        }
        return true;
      }
      final conditionPassed = await evaluateActionCondition(
        payload: payload,
        variables: variables,
        resolveValue: resolveValue,
        getScopedVariableTtl: getScopedVariableTtl,
      );

      final rawThen = payload['thenActions'];
      final rawElse = payload['elseActions'];
      dynamic branchRaw = rawThen;
      var branchResult = 'IF_TRUE';

      if (!conditionPassed) {
        branchRaw = rawElse;
        branchResult = 'IF_FALSE';

        final rawElseIfConditions = payload['elseIfConditions'];
        if (rawElseIfConditions is List) {
          for (var index = 0; index < rawElseIfConditions.length; index++) {
            final entry = rawElseIfConditions[index];
            if (entry is! Map) {
              continue;
            }

            final elseIf = Map<String, dynamic>.from(entry);
            final elseIfPassed = await evaluateActionCondition(
              payload: elseIf,
              variables: variables,
              resolveValue: resolveValue,
              getScopedVariableTtl: getScopedVariableTtl,
            );
            if (!elseIfPassed) {
              continue;
            }

            branchRaw = elseIf['actions'];
            branchResult = 'ELSE_IF_${index + 1}';
            break;
          }
        }
      }

      final branchActions = _decodeActionList(branchRaw);

      results[resultKey] = branchResult;
      if (branchActions.isEmpty) {
        return true;
      }

      final suppressErrors = parseActionBooleanFlag(payload['suppressErrors']);

      Map<String, String> branchResults;
      if (suppressErrors) {
        try {
          branchResults = await (executeProtectedActions ?? executeActions)(
            branchActions,
          );
        } catch (_) {
          // Error suppressed — clear error.message so nested try/catch
          // don't see a stale error from within this suppressErrors block.
          variables.removeWhere((key, _) => key.startsWith('error.'));

          // Send the custom error message/embed as the response.
          final suppressMessage = (payload['suppressErrorsMessage'] ?? '')
              .toString();
          final suppressEmbed =
              payload['suppressErrorsEmbed'] as Map<String, dynamic>?;
          if (suppressMessage.isNotEmpty || suppressEmbed != null) {
            await executeActions([
              Action(
                type: BotCreatorActionType.respondWithMessage,
                payload: <String, dynamic>{
                  if (suppressMessage.isNotEmpty) 'content': suppressMessage,
                  if (suppressEmbed != null) 'embeds': [suppressEmbed],
                },
              ),
            ]);
          }
          return true;
        }
      } else {
        branchResults = await executeActions(branchActions);
      }

      for (final entry in branchResults.entries) {
        results['$resultKey.${entry.key}'] = entry.value;
      }
      if (branchResults.containsKey('__stopped__')) {
        results['__stopped__'] = 'true';
      }
      return true;

    case BotCreatorActionType.forLoop:
      final mode = (payload['mode'] ?? 'simple').toString();

      if (mode == 'cstyle') {
        return _executeCStyleForLoop(
          payload: payload,
          resultKey: resultKey,
          results: results,
          variables: variables,
          resolveValue: resolveValue,
          executeActions: executeActions,
          checkBudget: checkBudget,
        );
      }

      if (mode == 'list') {
        return _executeListForLoop(
          payload: payload,
          resultKey: resultKey,
          results: results,
          variables: variables,
          resolveValue: resolveValue,
          executeActions: executeActions,
          checkBudget: checkBudget,
        );
      }

      // Simple runtime loop: iterations is a template string.
      final rawIterations = resolveValue(
        (payload['iterations'] ?? '0').toString(),
      ).trim();
      final iterations = int.tryParse(rawIterations) ?? 0;
      final capped = iterations;
      final bodyActionsRaw = payload['bodyActions'];
      final templateActions = _decodeActionList(bodyActionsRaw);

      if (capped <= 0 || templateActions.isEmpty) {
        results[resultKey] = 'LOOP_0';
        return true;
      }

      for (var i = 0; i < capped; i++) {
        checkBudget();
        if (i % 32 == 0) await Future<void>.delayed(Duration.zero);
        variables['_loop.index'] = i.toString();
        variables['_loop.count'] = (i + 1).toString();

        final iterResults = await executeActions(templateActions);
        for (final entry in iterResults.entries) {
          results['$resultKey.iter$i.${entry.key}'] = entry.value;
        }
        if (iterResults.containsKey('__stopped__')) {
          results['__stopped__'] = 'true';
          break;
        }
      }
      variables.remove('_loop.index');
      variables.remove('_loop.count');
      results[resultKey] = 'LOOP_$capped';
      return true;

    case BotCreatorActionType.jsonForEachLoop:
      final pathRaw = payload['path'];
      final pathSegments = (pathRaw is List)
          ? pathRaw.map((e) => resolveValue(e.toString())).toList()
          : const <String>[];
      final bodyActionsRaw = payload['bodyActions'];
      final templateActions = _decodeActionList(bodyActionsRaw);

      if (templateActions.isEmpty) {
        results[resultKey] = 'JSONFE_0';
        return true;
      }

      final entries = resolveJsonForEachEntries(
        payload: payload,
        pathSegments: pathSegments,
        variables: variables,
        results: results,
      );
      if (entries.isEmpty) {
        results[resultKey] = 'JSONFE_0';
        return true;
      }
      final capped2 = entries.length;
      for (var i = 0; i < capped2; i++) {
        checkBudget();
        if (i % 32 == 0) await Future<void>.delayed(Duration.zero);
        final key = entries[i].key;
        final value = entries[i].value;
        variables['_loop.var.jsonkey'] = key;
        variables['_loop.var.jsonvalue'] = value;
        variables['_loop.var.jsonindex'] = i.toString();
        variables['_loop.index'] = i.toString();
        variables['_loop.count'] = (i + 1).toString();

        final iterResults = await executeActions(templateActions);
        for (final entry in iterResults.entries) {
          results['$resultKey.iter$i.${entry.key}'] = entry.value;
        }
        if (iterResults.containsKey('__stopped__')) {
          results['__stopped__'] = 'true';
          break;
        }
      }
      variables.remove('_loop.var.jsonkey');
      variables.remove('_loop.var.jsonvalue');
      variables.remove('_loop.var.jsonindex');
      variables.remove('_loop.index');
      variables.remove('_loop.count');
      results[resultKey] = 'JSONFE_$capped2';
      return true;

    case BotCreatorActionType.cooldown:
      await cooldownBlock(
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        botId: botId,
        resolveValue: resolveValue,
        executeActions: executeActions,
      );
      return true;
    case BotCreatorActionType.wait:
      final durationStr = resolveValue(
        (payload['duration'] ?? '0s').toString(),
      ).trim();
      final duration = parseBdfdDuration(durationStr);
      if (duration == null) {
        throw FormatException('Invalid wait duration: $durationStr');
      }
      if (duration.inMilliseconds > 0) {
        await Future.delayed(duration);
      }
      results[resultKey] = 'WAITED';
      return true;
    case BotCreatorActionType.stop:
      results[resultKey] = 'STOPPED';
      results['__stopped__'] = 'true';
      return true;
    case BotCreatorActionType.skipActions:
      final rawCount = resolveValue((payload['count'] ?? '0').toString());
      final count = int.tryParse(rawCount.trim()) ?? 0;
      results[resultKey] = 'SKIPPED_$count';
      if (count > 0) {
        results['__skipCount__'] = count.toString();
      }
      return true;
    case BotCreatorActionType.jumpToAction:
      final targetKey = resolveValue((payload['targetKey'] ?? '').toString());
      results[resultKey] = 'JUMP_TO_$targetKey';
      if (targetKey.isNotEmpty) {
        results['__jumpToTargetKey__'] = targetKey;
      }
      return true;
    default:
      return false;
  }
}

/// Executes a C-style runtime for loop.
Future<bool> _executeCStyleForLoop({
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required Future<Map<String, String>> Function(List<Action> actions)
  executeActions,
  required void Function() checkBudget,
}) async {
  final initRaw = resolveValue((payload['init'] ?? '').toString());
  final conditionTemplate = (payload['condition'] ?? '').toString();
  final updateTemplate = (payload['update'] ?? '').toString();
  final varNames = List<String>.from(payload['varNames'] ?? const <String>[]);
  final bodyActionsRaw = payload['bodyActions'];
  final templateActions = _decodeActionList(bodyActionsRaw);

  // Parse init: "i=0, j=10" where values may now be runtime-resolved.
  final loopVars = parseCStyleLoopInit(initRaw, resolveValue);

  if (templateActions.isEmpty) {
    results[resultKey] = 'LOOP_0';
    return true;
  }

  var iterationCount = 0;

  while (true) {
    checkBudget();
    if (iterationCount % 32 == 0) await Future<void>.delayed(Duration.zero);
    checkBudget();
    if (!evaluateCStyleLoopCondition(
      conditionTemplate,
      loopVars,
      resolveValue,
    )) {
      break;
    }

    for (final entry in loopVars.entries) {
      variables['_loop.var.${entry.key}'] = entry.value.toString();
    }
    variables['_loop.index'] = iterationCount.toString();
    variables['_loop.count'] = (iterationCount + 1).toString();

    final iterResults = await executeActions(templateActions);
    checkBudget();
    for (final entry in iterResults.entries) {
      results['$resultKey.iter$iterationCount.${entry.key}'] = entry.value;
    }
    if (iterResults.containsKey('__stopped__')) {
      results['__stopped__'] = 'true';
      break;
    }

    applyCStyleLoopUpdate(updateTemplate, loopVars, resolveValue);
    iterationCount++;
  }

  for (final name in varNames) {
    variables.remove('_loop.var.$name');
  }
  variables.remove('_loop.index');
  variables.remove('_loop.count');
  results[resultKey] = 'LOOP_$iterationCount';
  return true;
}

/// Executes a list-iteration runtime for loop ($for[varName;val1;val2;...]).
Future<bool> _executeListForLoop({
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required Future<Map<String, String>> Function(List<Action> actions)
  executeActions,
  required void Function() checkBudget,
}) async {
  final varName = (payload['varName'] ?? 'item').toString().toLowerCase();
  final rawValues = payload['values'];
  final bodyActionsRaw = payload['bodyActions'];
  final templateActions = _decodeActionList(bodyActionsRaw);

  if (templateActions.isEmpty) {
    results[resultKey] = 'LOOP_0';
    return true;
  }

  // Resolve each value at runtime.
  final values = <String>[];
  if (rawValues is List) {
    for (final v in rawValues) {
      values.add(resolveValue(v.toString()));
    }
  }

  final capped = values.length;

  for (var i = 0; i < capped; i++) {
    checkBudget();
    if (i % 32 == 0) await Future<void>.delayed(Duration.zero);
    variables['_loop.var.$varName'] = values[i];
    variables['_loop.index'] = i.toString();
    variables['_loop.count'] = (i + 1).toString();

    final iterResults = await executeActions(templateActions);
    for (final entry in iterResults.entries) {
      results['$resultKey.iter$i.${entry.key}'] = entry.value;
    }
    if (iterResults.containsKey('__stopped__')) {
      results['__stopped__'] = 'true';
      break;
    }
  }
  variables.remove('_loop.var.$varName');
  variables.remove('_loop.index');
  variables.remove('_loop.count');
  results[resultKey] = 'LOOP_$capped';
  return true;
}
