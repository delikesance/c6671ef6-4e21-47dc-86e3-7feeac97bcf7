import 'dart:convert';

import '../../../services/action_condition.dart';
import '../../../types/action.dart';
import '../../../utils/bdfd_ast.dart' show normalizeBdfdFunctionName;
import '../../execution_budget.dart';
import '../program.dart' show BdfdNativeError;
import '../runtime.dart';
import 'action_environment.dart';
import 'channel_actions.dart';
import 'guild_actions.dart';
import 'moderation_actions.dart';
import 'role_actions.dart';
import 'variable_actions.dart';

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
    });

/// Native types whose historical counterpart records its trace only while a
/// debug profile or replay capture runs (see `guildProfilingOnlyTraceTypes`):
/// no numeric "last message" bookkeeping for them otherwise.
final Set<BotCreatorActionType> bdfdVisualProfilingOnlyTraceTypes =
    Set.unmodifiable({...guildProfilingOnlyTraceTypes});

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
    final payload = _object(await call.argument(1));
    final options = _object(await call.argument(2));
    final path = _pathOf(options['path']);
    try {
      await env.prepare?.call(type, key, payload, path);
      final result = await handler(
        ActionCall(
          invocation: call,
          env: env,
          type: type,
          key: key,
          path: path,
          payload: payload,
        ),
      );
      if (result != null) env.sink.set(path, key, result);
      if (!bdfdVisualProfilingOnlyTraceTypes.contains(type)) {
        env.sink.noteNumeric(path, key);
      }
      return '';
    } on CommandExecutionTimeout {
      // Never an action error: it ends the whole execution, like today.
      rethrow;
    } catch (error) {
      env.sink.recordError(type.name, key, path, error);
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
  }

  return {
    // `bc_tpl[template;path?]`: the template of `resolveValue`.
    bdfdVisualTemplateFunction: BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final template = await call.argument(0);
        final path = call.argumentCount > 1
            ? _path(await call.argument(1))
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
        final path = _path(await call.argument(3));
        try {
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
          throw wrap(call, error);
        }
      },
    ),
    // `bc_blockerr[key;type;path]`: catch body of a block whose own error mode
    // is `continue`. The failing child already recorded the error; the block
    // records its own result and forgets the branch results it never published.
    bdfdVisualBlockErrorFunction: BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) async {
        final key = await call.argument(0);
        final type = await call.argument(1);
        final path = _path(await call.argument(2));
        env.sink.discard([...path, key]);
        env.sink.recordError(
          type,
          key,
          path,
          env.sink.lastError ?? 'Unknown error',
        );
        return '';
      },
    ),
    for (final entry in (handlers ?? bdfdVisualActionHandlers).entries)
      bdfdVisualFunctionFor(entry.key): BdfdNativeFunction(
        minArguments: 3,
        maxArguments: 3,
        handler: (call) => run(entry.key, entry.value, call),
      ),
  };
}
