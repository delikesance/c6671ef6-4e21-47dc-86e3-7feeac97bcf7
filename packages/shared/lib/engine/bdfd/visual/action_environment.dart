import 'dart:async';

import 'package:nyxx/nyxx.dart' show Interaction, NyxxGateway, Snowflake;

import '../../../actions/execution_policy.dart';
import '../../../actions/handler_utils.dart' show resolvePayloadValues;
import '../../../bot/bot_data_store.dart';
import '../../../services/bot_automod_service.dart';
import '../../../services/bot_block_action_service.dart';
import '../../../services/bot_guild_admin_service.dart';
import '../../../services/bot_poll_service.dart';
import '../../../services/bot_voice_service.dart';
import '../../../services/bot_moderation_service.dart';
import '../../../services/permission_checks.dart' show BotPermissionCache;
import '../../../services/http_service.dart';
import '../../../services/lavalink_service.dart';
import '../../../types/action.dart';
import '../../execution_budget.dart';
import '../runtime.dart';
import 'action_results.dart';
import 'control_flow_state.dart';

/// Resolves `((...))` in [value] with the precedence of the historical handler
/// (`resolveValue` in actions/handler.dart): a placeholder naming a result of
/// the current action list wins (exact key, then without the `action.` prefix),
/// every other placeholder goes to [resolveTemplate].
String resolveActionValue(
  String value,
  Map<String, String> results,
  String Function(String input) resolveTemplate,
) {
  // Result placeholders FIRST: the template resolver replaces unknown
  // `((...))` with an empty string, leaving nothing to match afterwards.
  final result = value.replaceAllMapped(RegExp(r'\(\(([^)]+)\)\)'), (match) {
    final key = match.group(1)!;
    if (results.containsKey(key)) return results[key]!;
    if (key.startsWith('action.')) {
      final stripped = key.substring('action.'.length);
      if (results.containsKey(stripped)) return results[stripped]!;
    }
    return match.group(0)!; // Keep the original when it is not a result.
  });
  return resolveTemplate(result);
}

/// Called before each action runs natively, with the action's type, result key,
/// raw payload and the result keys of its enclosing blocks (empty for a
/// top-level action). The historical loop hydrates entity placeholders here.
typedef ActionPrepare =
    Future<void> Function(
      BotCreatorActionType type,
      String key,
      Map<String, dynamic> payload,
      List<String> path,
    );

/// Everything a `bc_*` function needs besides the evaluated arguments: the
/// services and shared state of the execution that owns the translated program.
class ActionRunEnvironment {
  ActionRunEnvironment({
    required this.variables,
    required this.sink,
    required this.resolveTemplate,
    required this.budget,
    this.moderation,
    this.guildId,
    this.throwOnError = false,
    this.prepare,
    this.getScopedVariableTtl,
    this.store,
    this.botId = '',
    this.interaction,
    this.guildSnowflake,
    this.fallbackChannelId,
    this.http,
    this.onLog,
    this.blockActions,
    this.permissionCache,
    this.client,
    this.lavalinkService,
    this.pollService,
    this.voiceService,
    this.autoModService,
    this.guildAdminService,
    this.policy,
    this.replayCapturing = false,
    this.startProfileClock,
  });

  final Map<String, String> variables;
  final ResultSink sink;
  final String Function(String input) resolveTemplate;
  final CommandExecutionBudget budget;
  final BotModerationService? moderation;
  final String? guildId;

  /// Protected (nested try/catch) executions: failures always propagate and the
  /// per-action error mode is ignored, as in `handleActions(throwOnError: true)`.
  final bool throwOnError;
  final ActionPrepare? prepare;
  final Future<int?> Function(String scope, String key)? getScopedVariableTtl;

  /// Persistence and context of the variable / HTTP actions (the same values
  /// the historical `executeVariablesAction` receives).
  final BotDataStore? store;
  final String botId;
  final Interaction? interaction;
  final Snowflake? guildSnowflake;
  final Snowflake? fallbackChannelId;

  /// Transport of `httpRequest`; null builds a plain [HttpService].
  final HttpService? http;
  final void Function(String message)? onLog;

  /// Block-only Discord operations (threads, self user, guild commands...) and
  /// the per-execution bot permission cache the historical loop shares.
  final BotBlockActionService? blockActions;
  final BotPermissionCache? permissionCache;

  /// Gateway and music service of the execution, for the component and
  /// listener blocks (the same values the historical loop hands them).
  final NyxxGateway? client;
  final LavalinkService? lavalinkService;

  /// Poll / voice / AutoMod / guild-admin blocks; null builds the Discord
  /// adapter over [client] (see admin_actions.dart).
  final BotPollService? pollService;
  final BotVoiceService? voiceService;
  final BotAutoModService? autoModService;
  final BotGuildAdminService? guildAdminService;

  /// Optional execution boundary (the sandbox): checked before every action,
  /// given the chance to simulate one ([ActionExecutionPolicy.intercept], a
  /// transitional seam until policies supply simulated services) and handed a
  /// frame per executed action.
  final ActionExecutionPolicy? policy;

  /// The root list is captured for replay: the historical loop then also
  /// records the numeric "last message" of its switch-handled types.
  final bool replayCapturing;

  /// Starts the stopwatch of a `debugProfile` list (milliseconds elapsed since
  /// the call); null uses a real [Stopwatch]. Tests inject a deterministic one.
  final int Function() Function()? startProfileClock;

  /// Owned by the runner: the interpreter registered with these functions.
  BdfdRuntime? runtime;

  /// Control-flow bookkeeping (loops, try blocks, stop/skip/jump signals) and
  /// the adapters the control-flow actions need; see control_flow_state.dart.
  final VisualFlowState flow = VisualFlowState();

  /// `resolveValue` for an action living in the list at [path].
  String Function(String) resolverFor(List<String> path) =>
      (value) => resolveActionValue(value, sink.scope(path), resolveTemplate);
}

/// One `bc_<type>` invocation, handed to the per-type handler.
class ActionCall {
  ActionCall({
    required this.invocation,
    required this.env,
    required this.type,
    required this.key,
    required this.path,
    required this.payload,
    this.rawPath = const [],
    this.options = const {},
  });

  final BdfdInvocation invocation;
  final ActionRunEnvironment env;
  final BotCreatorActionType type;
  final String key;

  /// Result keys of the enclosing blocks; empty for a top-level action.
  final List<String> path;

  /// The payload exactly as stored in the editor JSON (placeholders intact).
  final Map<String, dynamic> payload;

  /// [path] before the loop-iteration markers were resolved.
  final List<String> rawPath;

  /// The call options written by the translator (`path`, `mode`, ...).
  final Map<String, dynamic> options;

  /// Flow requests a handler makes; applied by the wrapper after the result is
  /// recorded (see `bc_*` in action_functions.dart).
  bool stopRequested = false;
  int? restartRequested;
  int? skipRequested;
  int? jumpOrdinalRequested;
  String? jumpKeyRequested;
  void requestStop() => stopRequested = true;

  /// Continue the ROOT list from the 0-based action [index], a position that
  /// is not after this action (the runner restarts its program there).
  void requestRestart(int index) => restartRequested = index;
  void requestSkip(int count) => skipRequested = count;
  void requestJumpToOrdinal(int ordinal) => jumpOrdinalRequested = ordinal;
  void requestJumpToKey(String key) => jumpKeyRequested = key;

  BdfdContext get context => invocation.context;
  CommandExecutionBudget get budget => env.budget;
  ResultSink get sink => env.sink;

  /// `resolveValue` of this action's own result list.
  String resolve(String value) => env.resolverFor(path)(value);

  /// The payload with every string resolved (`resolvePayloadValues`).
  Map<String, dynamic> resolvedPayload() =>
      resolvePayloadValues(payload, resolve);
}

/// Per-type behaviour behind `bc_<type>`. Returns the value stored in
/// `results[key]`, or null when the handler wrote its results through [ActionCall.sink].
/// Throw to fail: the wrapper records the error and applies the error mode.
typedef ActionHandler = Future<String?> Function(ActionCall call);
