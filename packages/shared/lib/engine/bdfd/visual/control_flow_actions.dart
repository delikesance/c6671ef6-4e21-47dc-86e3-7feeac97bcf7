import 'dart:convert';

import '../../../actions/executors/control_flow_executor.dart'
    show
        applyCStyleLoopUpdate,
        evaluateCStyleLoopCondition,
        executeControlFlowAction,
        parseCStyleLoopInit,
        resolveJsonForEachEntries;
import '../../../services/action_condition.dart';
import '../../../types/action.dart';
import '../../../utils/bdfd_duration_parser.dart';
import '../../execution_budget.dart';
import '../program.dart' show BdfdNativeError;
import '../runtime.dart';
import 'action_environment.dart';
import 'control_flow_state.dart';
import 'message_actions.dart' show visualRespondWithMessage;

/// Control flow on the native engine, parity with `executeControlFlowAction`
/// (actions/executors/control_flow_executor.dart) and `log`
/// (variables_executor.dart): same results, same variables, same failures.
///
/// * Leaf actions (`stop`, `stopUnless`, `skipActions`, `jumpToAction`, `wait`,
///   `log`, `runWorkflow`, `runBdfdScript`) are ordinary `bc_<type>` handlers.
///   `runWorkflow` / `runBdfdScript` run the historical workflow / script code
///   through the closures of [VisualControlAdapter] (so `workflow.response.*`
///   and the `<key>.<sub>` results keep their contract).
/// * Blocks (`forLoop`, `jsonForEachLoop`, `ifBlock` try/catch and
///   suppressErrors) are translated to native `$while` loops and `$try`
///   statements whose conditions / lifecycle hooks are the hidden functions
///   below. They add no statement to any list, so `skipActions` / `jumpToAction`
///   ordinals inside bodies are exactly the ones of the editor's lists.
final Map<BotCreatorActionType, ActionHandler> controlActionHandlers = {
  BotCreatorActionType.stop: stopAction,
  BotCreatorActionType.stopUnless: stopUnlessAction,
  BotCreatorActionType.skipActions: skipActionsAction,
  BotCreatorActionType.jumpToAction: jumpToActionAction,
  BotCreatorActionType.wait: waitAction,
  BotCreatorActionType.log: logAction,
  BotCreatorActionType.runWorkflow: runWorkflowAction,
  BotCreatorActionType.runBdfdScript: runBdfdScriptAction,
};

final Map<BotCreatorActionType, bool Function(Action)> controlLeafPredicates = {
  for (final type in controlActionHandlers.keys) type: (_) => true,
};

/// Types that own nested action lists and are translated structurally.
const Set<BotCreatorActionType> visualBlockTypes = {
  BotCreatorActionType.ifBlock,
  BotCreatorActionType.forLoop,
  BotCreatorActionType.jsonForEachLoop,
};

const String bdfdVisualLoopFunction = 'bc_loopnext';
const String bdfdVisualTryEnterFunction = 'bc_tryenter';
const String bdfdVisualTryCatchFunction = 'bc_trycatch';
const String bdfdVisualTryExitFunction = 'bc_tryexit';
const String bdfdVisualSuppressFunction = 'bc_suppress';

const List<String> bdfdVisualControlFunctionNames = [
  bdfdVisualLoopFunction,
  bdfdVisualTryEnterFunction,
  bdfdVisualTryCatchFunction,
  bdfdVisualTryExitFunction,
  bdfdVisualSuppressFunction,
];

// ---------------------------------------------------------------------------
// Leaf actions
// ---------------------------------------------------------------------------

Future<String?> stopAction(ActionCall call) async {
  call.requestStop();
  return 'STOPPED';
}

Future<String?> stopUnlessAction(ActionCall call) async {
  final passed = await evaluateActionCondition(
    payload: call.payload,
    variables: call.env.variables,
    resolveValue: call.resolve,
    getScopedVariableTtl: call.env.getScopedVariableTtl,
  );
  if (!passed) call.requestStop();
  return passed ? 'PASSED' : 'STOPPED';
}

Future<String?> skipActionsAction(ActionCall call) async {
  final raw = call.resolve((call.payload['count'] ?? '0').toString());
  final count = int.tryParse(raw.trim()) ?? 0;
  if (count > 0) call.requestSkip(count);
  return 'SKIPPED_$count';
}

Future<String?> jumpToActionAction(ActionCall call) async {
  final target = call.resolve((call.payload['targetKey'] ?? '').toString());
  if (target.isNotEmpty) {
    if (call.env.flow.routed && call.path.isEmpty) {
      // The historical loop resolves the target among its own actions.
      call.requestJumpToKey(target);
    } else {
      final ordinal = _jumpOrdinal(call, target);
      if (ordinal != null) call.requestJumpToOrdinal(ordinal);
    }
  }
  return 'JUMP_TO_$target';
}

/// The ordinal (1-based position in the action's own list) to continue at, or
/// null when the target names nothing after the action (historical: no jump).
int? _jumpOrdinal(ActionCall call, String target) {
  final own = (call.options['own'] as num?)?.toInt() ?? 0;
  final count = (call.options['count'] as num?)?.toInt() ?? 0;
  final targets = call.options['targets'];
  if (targets is Map && targets.containsKey(target)) {
    final ordinal = (targets[target] as num).toInt();
    return ordinal > own ? ordinal : null;
  }
  final position = int.tryParse(target);
  if (position != null && position >= 1 && position <= count) {
    if (position > own) return position;
    // Historically a numeric target may point backwards; the interpreter (like
    // `$jumpToAction`) only continues forwards.
    throw Exception('jumpToAction can only jump to a later action: $target');
  }
  return null;
}

Future<String?> waitAction(ActionCall call) async {
  final durationStr = call
      .resolve((call.payload['duration'] ?? '0s').toString())
      .trim();
  final duration = parseBdfdDuration(durationStr);
  if (duration == null) {
    throw FormatException('Invalid wait duration: $durationStr');
  }
  if (duration.inMilliseconds > 0) {
    await (call.env.flow.delay ?? (d) => Future<void>.delayed(d))(duration);
  }
  return 'WAITED';
}

Future<String?> logAction(ActionCall call) async {
  final message = call.resolve((call.payload['message'] ?? '').toString());
  if (message.isNotEmpty) call.env.onLog?.call(message);
  return 'LOGGED';
}

Future<String?> runWorkflowAction(ActionCall call) => _historicalControl(call);
Future<String?> runBdfdScriptAction(ActionCall call) =>
    _historicalControl(call);

Future<String?> _historicalControl(ActionCall call) async {
  final adapter = call.env.flow.adapter;
  if (adapter == null) {
    throw StateError('${call.type.name} needs a workflow adapter.');
  }
  final results = call.sink.scope(call.path);
  await executeControlFlowAction(
    type: call.type,
    payload: call.payload,
    resultKey: call.key,
    results: results,
    variables: call.env.variables,
    botId: call.env.botId,
    resolveValue: call.resolve,
    onLog: call.env.onLog,
    activeWorkflowStack: adapter.activeWorkflowStack,
    getWorkflowByName: adapter.getWorkflowByName,
    executeActions: adapter.executeActions,
    executeProtectedActions: adapter.executeProtectedActions,
    executeNativeBdfdScript: adapter.executeNativeBdfdScript,
    nestedActionsPreprocessor: adapter.nestedActionsPreprocessor,
    checkExecutionBudget: call.budget.check,
    getScopedVariableTtl: call.env.getScopedVariableTtl,
  );
  if (results.containsKey('__stopped__')) call.requestStop();
  return null; // The shared code wrote the results itself.
}

// ---------------------------------------------------------------------------
// Flow requests (stop / skip / jump), applied by the `bc_*` wrapper
// ---------------------------------------------------------------------------

/// Apply what a handler requested, once its result is recorded.
///
/// A single top-level action run for the historical loop hands the request
/// back through the signals of its results map (`__stopped__`, `__skipCount__`,
/// `__jumpToTargetKey__`), exactly what the historical executor leaves there.
/// Anything nested is applied natively: a stop unwinds the program, skip and
/// jump act on the statement list that contains the action.
void applyFlowRequests(ActionCall call) {
  final env = call.env;
  final topLevel = env.flow.routed && call.path.isEmpty;
  if (call.stopRequested) {
    _markStopped(env, call.path, call.rawPath);
    // Every enclosing loop ends the way the historical one does when its body
    // reports a stop: the loop result is still written, variables cleaned up.
    for (final element in call.rawPath.reversed) {
      if (!element.startsWith(visualIterationMarker)) continue;
      final state =
          env.flow.loops[element.substring(visualIterationMarker.length)];
      if (state != null) _finishLoop(env, state, stopped: true);
    }
    if (!topLevel) call.invocation.stop();
    return;
  }
  final skip = call.skipRequested;
  if (skip != null && skip > 0) {
    if (topLevel) {
      call.sink.set(const [], '__skipCount__', '$skip');
    } else {
      call.context.requestSkip(skip);
    }
  }
  final key = call.jumpKeyRequested;
  if (key != null) call.sink.set(const [], '__jumpToTargetKey__', key);
  final ordinal = call.jumpOrdinalRequested;
  if (ordinal != null) call.context.requestJump(ordinal);
}

/// `__stopped__` in the result list of the action and of every enclosing
/// block's list (what each historical level copies upwards). The namespace of
/// a loop itself (`<loopKey>`, between the loop's list and its iterations) is
/// not a list of the historical code and gets no marker.
void _markStopped(
  ActionRunEnvironment env,
  List<String> path,
  List<String> raw,
) {
  for (var k = path.length; k >= 0; k--) {
    if (k < raw.length && raw[k].startsWith(visualIterationMarker)) continue;
    env.sink.set(path.sublist(0, k), '__stopped__', 'true');
  }
}

// ---------------------------------------------------------------------------
// Loops
// ---------------------------------------------------------------------------

void _finishLoop(
  ActionRunEnvironment env,
  VisualLoopState state, {
  required bool stopped,
}) {
  if (state.finished) return;
  state.finished = true;
  env.flow.loops.remove(state.id);
  for (final name in state.cleanup) {
    env.variables.remove(name);
  }
  final String label;
  switch (state.kind) {
    case VisualLoopKind.simple:
    case VisualLoopKind.list:
      label = 'LOOP_${state.count}';
    case VisualLoopKind.cstyle:
      // The stopped iteration never reached its update: it is not counted.
      label = 'LOOP_${stopped ? state.entered - 1 : state.entered}';
    case VisualLoopKind.json:
      label = 'JSONFE_${state.count}';
  }
  env.sink.set(state.parentPath, state.key, label);
}

Future<String> _loopNext(
  ActionRunEnvironment env,
  BdfdInvocation call,
  BdfdNativeError Function(BdfdInvocation, Object) wrap,
) async {
  final id = await call.argument(0);
  try {
    var state = env.flow.loops[id];
    if (state == null || state.finished) {
      state = await _startLoop(env, call, id);
      if (state == null) return 'false'; // Empty: result already written.
    }
    final resolve = env.resolverFor(state.parentPath);
    final index = state.entered;
    if (state.kind == VisualLoopKind.cstyle) {
      if (index > 0) {
        applyCStyleLoopUpdate(state.updateTemplate, state.vars, resolve);
      }
      if (!evaluateCStyleLoopCondition(
        state.conditionTemplate,
        state.vars,
        resolve,
      )) {
        _finishLoop(env, state, stopped: false);
        return 'false';
      }
      for (final entry in state.vars.entries) {
        env.variables['_loop.var.${entry.key}'] = entry.value.toString();
      }
    } else {
      if (index >= state.count) {
        _finishLoop(env, state, stopped: false);
        return 'false';
      }
      switch (state.kind) {
        case VisualLoopKind.list:
          env.variables['_loop.var.${state.varName}'] = state.values[index];
        case VisualLoopKind.json:
          env.variables['_loop.var.jsonkey'] = state.entries[index].key;
          env.variables['_loop.var.jsonvalue'] = state.entries[index].value;
          env.variables['_loop.var.jsonindex'] = '$index';
        default:
          break;
      }
    }
    env.variables['_loop.index'] = '$index';
    env.variables['_loop.count'] = '${index + 1}';
    env.flow.iterations[id] = index;
    state.entered = index + 1;
    return 'true';
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    env.sink.lastError = error;
    throw wrap(call, error);
  }
}

/// Evaluate the loop's parameters (once, when it starts). Returns null when the
/// loop has nothing to run: its result is then written right away.
Future<VisualLoopState?> _startLoop(
  ActionRunEnvironment env,
  BdfdInvocation call,
  String id,
) async {
  final key = await call.argument(1);
  final payload = _object(await call.argument(2));
  final rawPath = _path(await call.argument(3));
  final path = env.flow.resolvePath(rawPath);
  if (path.isNotEmpty) env.flow.refreshExecutionTime?.call();
  final resolve = env.resolverFor(path);
  final empty = payload['empty'] == true;
  final mode = (payload['mode'] ?? 'simple').toString();
  final json = payload['loopType'] == 'json';

  VisualLoopState make(VisualLoopKind kind, List<String> cleanup) =>
      VisualLoopState(
        id: id,
        key: key,
        kind: kind,
        parentPath: path,
        cleanup: [...cleanup, '_loop.index', '_loop.count'],
      );
  VisualLoopState? nothing(String label) {
    env.sink.set(path, key, label);
    return null;
  }

  VisualLoopState? state;
  if (json) {
    final pathRaw = payload['path'];
    final segments = pathRaw is List
        ? pathRaw.map((e) => resolve(e.toString())).toList()
        : const <String>[];
    if (empty) return nothing('JSONFE_0');
    final entries = resolveJsonForEachEntries(
      payload: payload,
      pathSegments: segments,
      variables: env.variables,
      results: env.sink.scope(path),
    );
    if (entries.isEmpty) return nothing('JSONFE_0');
    state = make(VisualLoopKind.json, [
      '_loop.var.jsonkey',
      '_loop.var.jsonvalue',
      '_loop.var.jsonindex',
    ]);
    state.entries = entries;
    state.count = entries.length;
  } else if (mode == 'cstyle') {
    final initRaw = resolve((payload['init'] ?? '').toString());
    final names = List<String>.from(payload['varNames'] ?? const <String>[]);
    final vars = parseCStyleLoopInit(initRaw, resolve);
    if (empty) return nothing('LOOP_0');
    state = make(VisualLoopKind.cstyle, [
      for (final name in names) '_loop.var.$name',
    ]);
    state.vars = vars;
    state.conditionTemplate = (payload['condition'] ?? '').toString();
    state.updateTemplate = (payload['update'] ?? '').toString();
  } else if (mode == 'list') {
    if (empty) return nothing('LOOP_0');
    final varName = (payload['varName'] ?? 'item').toString().toLowerCase();
    final raw = payload['values'];
    state = make(VisualLoopKind.list, ['_loop.var.$varName']);
    state.varName = varName;
    state.values = [
      if (raw is List)
        for (final value in raw) resolve(value.toString()),
    ];
    state.count = state.values.length;
  } else {
    final iterations =
        int.tryParse(
          resolve((payload['iterations'] ?? '0').toString()).trim(),
        ) ??
        0;
    if (iterations <= 0 || empty) return nothing('LOOP_0');
    state = make(VisualLoopKind.simple, const []);
    state.count = iterations;
  }
  env.flow.loops[id] = state;
  return state;
}

// ---------------------------------------------------------------------------
// Hidden functions of the blocks
// ---------------------------------------------------------------------------

Map<String, dynamic> _object(String raw) {
  if (raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  return decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};
}

List<String> _path(String raw) {
  if (raw.trim().isEmpty) return const [];
  final decoded = jsonDecode(raw);
  return decoded is List
      ? List.unmodifiable(decoded.map((e) => e.toString()))
      : const [];
}

/// The hidden functions that drive loops, try/catch and suppressed errors.
Map<String, BdfdNativeFunction> bdfdVisualControlFunctions(
  ActionRunEnvironment env,
) {
  BdfdNativeError wrap(BdfdInvocation call, Object error) =>
      error is BdfdNativeError
      ? error
      : BdfdNativeError(error.toString(), call.location, cause: error);

  Future<R> guarded<R>(BdfdInvocation call, Future<R> Function() body) async {
    try {
      return await body();
    } on CommandExecutionTimeout {
      rethrow;
    } catch (error) {
      env.sink.lastError = error;
      throw wrap(call, error);
    }
  }

  return {
    // `bc_loopnext[id;key;payloadJson;path]`: the `$while` condition of a
    // forLoop / jsonForEachLoop. "true" enters the next iteration.
    bdfdVisualLoopFunction: BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) => _loopNext(env, call, wrap),
    ),
    // `bc_tryenter[id;key;path]`: a tryCatch starts. Its own `error.*` variables
    // are forgotten while it runs and restored when it ends.
    bdfdVisualTryEnterFunction: BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) => guarded(call, () async {
        final id = await call.argument(0);
        final key = await call.argument(1);
        final path = env.flow.resolvePath(_path(await call.argument(2)));
        if (path.isNotEmpty) env.flow.refreshExecutionTime?.call();
        env.flow.savedErrors[id] = {
          for (final entry in env.variables.entries)
            if (entry.key.startsWith('error.')) entry.key: entry.value,
        };
        env.variables.removeWhere((key, _) => key.startsWith('error.'));
        env.sink.set(path, key, 'TRY_OK');
        return '';
      }),
    ),
    // `bc_trycatch[key;path]`: the body failed. Its results are dropped (the
    // historical block only publishes the list that completed).
    bdfdVisualTryCatchFunction: BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) => guarded(call, () async {
        final key = await call.argument(0);
        final path = env.flow.resolvePath(_path(await call.argument(1)));
        env.sink.discard([...path, key]);
        env.flow.dropLoopsUnder([...path, key]);
        env.sink.set(path, key, 'TRY_CAUGHT');
        return '';
      }),
    ),
    // `bc_tryexit[id]`: the tryCatch completed; the outer `error.*` are back.
    bdfdVisualTryExitFunction: BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) => guarded(call, () async {
        final id = await call.argument(0);
        env.variables.removeWhere((key, _) => key.startsWith('error.'));
        env.variables.addAll(env.flow.savedErrors.remove(id) ?? const {});
        return '';
      }),
    ),
    // `bc_suppress[key;payloadJson;path]`: the selected branch of a
    // suppressErrors block failed. The error vanishes, the branch results are
    // dropped, and the configured message / embed (if any) is sent.
    bdfdVisualSuppressFunction: BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) => guarded(call, () async {
        final key = await call.argument(0);
        final payload = _object(await call.argument(1));
        final path = env.flow.resolvePath(_path(await call.argument(2)));
        env.sink.discard([...path, key]);
        env.flow.dropLoopsUnder([...path, key]);
        // Clear error.* so nested try/catch don't see a stale error.
        env.variables.removeWhere((key, _) => key.startsWith('error.'));
        final message = (payload['suppressErrorsMessage'] ?? '').toString();
        final embed = payload['suppressErrorsEmbed'];
        if (message.isNotEmpty || embed != null) {
          // Native, immediate and non-draft: the very body of a
          // `respondWithMessage` block (the historical path ran a nested
          // one-action list).
          await visualRespondWithMessage(
            env,
            call.context,
            path: [...path, key],
            payload: <String, dynamic>{
              if (message.isNotEmpty) 'content': message,
              if (embed != null) 'embeds': [embed],
            },
          );
        }
        return '';
      }),
    ),
  };
}
