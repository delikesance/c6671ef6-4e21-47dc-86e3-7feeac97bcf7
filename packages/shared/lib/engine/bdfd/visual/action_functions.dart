import 'dart:convert';

import '../../../services/action_condition.dart';
import '../../../types/action.dart';
import '../../../utils/bdfd_ast.dart' show normalizeBdfdFunctionName;
import '../../execution_budget.dart';
import '../program.dart' show BdfdNativeError;
import '../runtime.dart';
import 'action_environment.dart';
import 'action_observer.dart';
import 'admin_actions.dart';
import 'channel_actions.dart';
import 'component_actions.dart';
import 'control_flow_actions.dart';
import 'debug_profile_actions.dart';
import 'emoji_actions.dart';
import 'guild_actions.dart';
import 'image_actions.dart';
import 'invite_actions.dart';
import 'listener_actions.dart';
import 'member_actions.dart';
import 'message_actions.dart';
import 'moderation_actions.dart';
import 'music_actions.dart';
import 'role_actions.dart';
import 'variable_actions.dart';
import 'webhook_actions.dart';

export 'action_environment.dart';

/// Hidden extension functions that run visual blocks on the native engine.
///
/// They are not BDFD functions: they are registered outside the catalogue (the
/// registry audit lists them under `registeredOutsideCatalogue`), never offered
/// by autocomplete and never present in the production script registry, so a
/// BDFD script cannot call them. Only [bdfdVisualFunctions] exposes them, to the
/// private interpreter of the visual runner.
///
/// Per-type behaviour: add a handler to [bdfdVisualActionHandlers] (and the
/// type to `ActionTranslator`); its function is named `bc_<type>`.
final Map<BotCreatorActionType, ActionHandler> bdfdVisualActionHandlers =
    Map.unmodifiable({
      BotCreatorActionType.addRole: addRoleAction,
      BotCreatorActionType.removeRole: removeRoleAction,
      ...variableActionHandlers,
      ...moderationActionHandlers,
      ...guildActionHandlers,
      ...channelActionHandlers,
      ...controlActionHandlers,
      ...debugProfileActionHandlers,
      ...messageActionHandlers,
      ...componentActionHandlers,
      ...listenerActionHandlers,
      ...adminActionHandlers,
      ...webhookActionHandlers,
      ...emojiActionHandlers,
      ...memberActionHandlers,
      ...inviteActionHandlers,
      ...musicActionHandlers,
      ...imageActionHandlers,
    });

/// Native types whose historical counterpart records its trace only while a
/// debug profile or replay capture runs (see `guildProfilingOnlyTraceTypes`):
/// no numeric "last message" bookkeeping for them otherwise.
final Set<BotCreatorActionType> bdfdVisualProfilingOnlyTraceTypes =
    Set.unmodifiable({
      ...guildProfilingOnlyTraceTypes,
      ...messageProfilingOnlyTraceTypes,
      ...adminProfilingOnlyTraceTypes,
      ...emojiProfilingOnlyTraceTypes,
      ...memberProfilingOnlyTraceTypes,
      ...inviteProfilingOnlyTraceTypes,
    });

const String bdfdVisualTemplateFunction = 'bc_tpl';
const String bdfdVisualConditionFunction = 'bc_cond';
const String bdfdVisualBlockErrorFunction = 'bc_blockerr';

String bdfdVisualFunctionFor(BotCreatorActionType type) => 'bc_${type.name}';

/// Normalized names of every hidden function (for the registry audit).
Set<String> bdfdVisualFunctionNames([Iterable<BotCreatorActionType>? types]) =>
    {
      for (final name in [
        bdfdVisualTemplateFunction,
        bdfdVisualConditionFunction,
        bdfdVisualBlockErrorFunction,
        ...bdfdVisualControlFunctionNames,
        bdfdVisualProfileEndFunction,
      ])
        normalizeBdfdFunctionName(name),
      for (final type in types ?? bdfdVisualActionHandlers.keys)
        normalizeBdfdFunctionName(bdfdVisualFunctionFor(type)),
    };

Map<String, dynamic> _object(String raw) {
  if (raw.trim().isEmpty) return <String, dynamic>{};
  final decoded = jsonDecode(raw);
  return decoded is Map
      ? Map<String, dynamic>.from(decoded)
      : <String, dynamic>{};
}

List<String> _pathOf(dynamic decoded) => decoded is List
    ? List.unmodifiable(decoded.map((e) => e.toString()))
    : const [];

List<String> _path(String raw) =>
    raw.trim().isEmpty ? const [] : _pathOf(jsonDecode(raw));

/// The `bc_*` functions bound to one execution. [handlers] is the registration
/// hook for per-type behaviour; it defaults to [bdfdVisualActionHandlers].
Map<String, BdfdNativeFunction> bdfdVisualFunctions(
  ActionRunEnvironment env, {
  Map<BotCreatorActionType, ActionHandler>? handlers,
}) {
  BdfdNativeError wrap(BdfdInvocation call, Object error) =>
      error is BdfdNativeError
      ? error
      : BdfdNativeError(error.toString(), call.location, cause: error);

  Future<String> run(
    BotCreatorActionType type,
    ActionHandler handler,
    BdfdInvocation call,
  ) async {
    final key = await call.argument(0);
    final rawPayload = _object(await call.argument(1));
    final options = _object(await call.argument(2));
    final rawPath = _pathOf(options['path']);
    final path = env.flow.resolvePath(rawPath);
    final routed = env.flow.routed;
    ActionCall? done;
    VisualActionObservation? observation;
    try {
      // The blocks that finished before this action are recorded first.
      flushBlocksBefore(env, path);
      // A historical loop owns the budget check and `execution.time` of the
      // root action it routed here; nothing else does.
      if (path.isNotEmpty || !routed) {
        env.budget.check();
        env.policy?.checkBudget();
        env.flow.refreshExecutionTime?.call();
      }
      await env.prepare?.call(type, key, rawPayload, path);
      final payload = !routed && path.isEmpty
          ? rootActionPayload(type, rawPayload, env.resolverFor(path))
          : rawPayload;
      observation = VisualActionObservation.begin(
        env,
        type,
        key,
        path,
        payload,
        withPolicy: !routed,
      );
      final policy = routed ? null : env.policy;
      if (policy != null &&
          await policy.intercept(
            action: Action(type: type, key: key, payload: payload),
            resultKey: key,
            results: env.sink.scope(path),
            variables: env.variables,
            resolveValue: env.resolverFor(path),
          )) {
        env.sink.noteNumeric(path, key);
        observation.finish(env.sink.scope(path)[key]);
        return '';
      }
      final action = ActionCall(
        invocation: call,
        env: env,
        type: type,
        key: key,
        path: path,
        payload: payload,
        rawPath: rawPath,
        options: options,
      );
      final result = await handler(action);
      if (result != null) env.sink.set(path, key, result);
      if (!bdfdVisualProfilingOnlyTraceTypes.contains(type) ||
          (!routed && observation.profiling)) {
        env.sink.noteNumeric(path, key);
      }
      observation.finish(env.sink.scope(path)[key]);
      done = action;
    } on CommandExecutionTimeout catch (error) {
      // Never an action error: it ends the whole execution, like today (the
      // historical handler still leaves the `error.*` variables).
      env.sink.recordError(type.name, key, path, error);
      rethrow;
    } catch (error) {
      env.sink.recordError(type.name, key, path, error);
      observation?.finish('Error: $error');
      if (env.throwOnError) throw wrap(call, error);
      switch (options['mode']) {
        case 'continue':
          return '';
        case 'jump':
          // The target is resolved to an ordinal at translation time and is
          // always a later action of the same list.
          call.context.requestJump((options['ordinal'] as num).toInt());
          return '';
        case 'skip':
          call.context.requestSkip((options['count'] as num).toInt());
          return '';
        default:
          throw wrap(call, error);
      }
    }
    // Outside the try: a stop is an interpreter control signal, not a failure.
    applyFlowRequests(done);
    return '';
  }

  return {
    // `bc_tpl[template;path?]`: the template of `resolveValue`.
    bdfdVisualTemplateFunction: BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final template = await call.argument(0);
        final path = call.argumentCount > 1
            ? env.flow.resolvePath(_path(await call.argument(1)))
            : const <String>[];
        try {
          return env.resolverFor(path)(template);
        } on CommandExecutionTimeout {
          rethrow;
        } catch (error) {
          throw wrap(call, error);
        }
      },
    ),
    // `bc_cond[key;index;conditionJson;path]`: "true"/"false" for the branch
    // `index` of the `ifBlock` `key` (0 = the `if`, n = the n-th `else if`), and
    // the branch label the block leaves in its results.
    bdfdVisualConditionFunction: BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) async {
        final key = await call.argument(0);
        final index = int.parse(await call.argument(1));
        final condition = _object(await call.argument(2));
        final path = env.flow.resolvePath(_path(await call.argument(3)));
        try {
          if (index == 0) {
            beginBlock(env, path, key, 'ifBlock', withPolicy: !env.flow.routed);
          }
          if (index == 0 && path.isNotEmpty) {
            env.flow.refreshExecutionTime?.call();
          }
          final passed = await evaluateActionCondition(
            payload: condition,
            variables: env.variables,
            resolveValue: env.resolverFor(path),
            getScopedVariableTtl: env.getScopedVariableTtl,
          );
          if (index == 0) {
            env.sink.set(path, key, passed ? 'IF_TRUE' : 'IF_FALSE');
          } else if (passed) {
            env.sink.set(path, key, 'ELSE_IF_$index');
          }
          return passed ? 'true' : 'false';
        } on CommandExecutionTimeout {
          rethrow;
        } catch (error) {
          env.sink.lastError = error;
          throw wrap(call, error);
        }
      },
    ),
    // `bc_blockerr[key;type;path;options?]`: catch body of a block that has its
    // own error mode (`continue`, `skip`, `jump`). The failing child already
    // recorded the error; the block records its own result, forgets the branch
    // results it never published (a loop keeps its finished iterations) and
    // applies the mode to the list that contains the block: the request is made
    // `outer`, so the interpreter hands it over once this catch body is done.
    bdfdVisualBlockErrorFunction: BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 4,
      handler: (call) async {
        final key = await call.argument(0);
        final type = await call.argument(1);
        final path = env.flow.resolvePath(_path(await call.argument(2)));
        final options = call.argumentCount > 3
            ? _object(await call.argument(3))
            : const <String, dynamic>{};
        final loopId = options['loop']?.toString();
        final loop = loopId == null ? null : env.flow.loops.remove(loopId);
        if (loop != null) {
          env.sink.discard([...path, key, 'iter${loop.entered - 1}']);
        } else {
          env.sink.discard([...path, key]);
        }
        env.flow.dropLoopsUnder([...path, key]);
        env.sink.recordError(
          type,
          key,
          path,
          env.sink.lastError ?? 'Unknown error',
        );
        failBlock(env, path, key, env.sink.lastError ?? 'Unknown error');
        switch (options['mode']) {
          case 'skip':
            call.context.requestSkip(
              (options['count'] as num).toInt(),
              outer: true,
            );
          case 'jump':
            call.context.requestJump(
              (options['ordinal'] as num).toInt(),
              outer: true,
            );
        }
        return '';
      },
    ),
    ...bdfdVisualControlFunctions(env),
    ...bdfdVisualProfileFunctions(env),
    for (final entry in (handlers ?? bdfdVisualActionHandlers).entries)
      bdfdVisualFunctionFor(entry.key): BdfdNativeFunction(
        minArguments: 3,
        maxArguments: 3,
        handler: (call) => run(entry.key, entry.value, call),
      ),
  };
}
