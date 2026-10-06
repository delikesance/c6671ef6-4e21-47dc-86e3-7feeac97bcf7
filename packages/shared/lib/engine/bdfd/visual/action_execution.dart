import 'package:nyxx/nyxx.dart';

import '../../../actions/execution_policy.dart';
import '../../../bot/bot_data_store.dart';
import '../../../services/bot_block_action_service.dart';
import '../../../services/bot_command_query_service.dart';
import '../../../services/bot_component_service.dart';
import '../../../services/bot_cooldown_service.dart';
import '../../../services/bot_message_service.dart';
import '../../../services/bot_moderation_service.dart';
import '../../../services/bot_music_service.dart';
import '../../../services/bot_timing_service.dart';
import '../../../services/http_service.dart';
import '../../../services/lavalink_service.dart';
import '../../../services/permission_checks.dart' show BotPermissionCache;
import '../../../services/runtime_temporary_variables.dart';
import '../../../types/action.dart';
import '../../../utils/runtime_variables.dart' show hydrateActionPlaceholders;
import '../../discord_entity_fetcher.dart';
import '../../execution_budget.dart';
import '../execution.dart';
import '../replay.dart';
import '../runtime.dart';
import 'action_environment.dart';
import 'action_results.dart';
import 'action_runner.dart';
import 'control_flow_state.dart';
import 'variable_logic.dart' show resolveScopeContextId;

/// What the workflow that owns the root action list needs from the runner
/// about the interaction acknowledgement (`executeVisualWorkflow`).
///
/// The runner acknowledges (defers) before the first action, unless the list
/// does it itself (`deferInteraction`), opens a modal (the modal must be the
/// first response) or [enabled] is false; the deferral is ephemeral when
/// [ephemeral] is set or a `respondWithMessage` of the list is (a deferral
/// cannot change the visibility afterwards). A failing acknowledgement is
/// reported to [onLog] and leaves [didDefer] false. Only the root list takes
/// part: nested lists never acknowledge.
class VisualAcknowledgement {
  VisualAcknowledgement({
    required this.acknowledge,
    this.enabled = true,
    this.ephemeral = false,
    this.onLog,
  });

  final Future<void> Function({required bool ephemeral}) acknowledge;

  /// `workflow['autoDeferIfActions'] != false`.
  final bool enabled;

  /// `workflow['visibility'] == 'ephemeral'`.
  final bool ephemeral;
  final void Function(String message)? onLog;

  /// Whether the runner acknowledged the interaction.
  bool didDefer = false;

  /// The decision and the acknowledgement, for the list [actions].
  Future<void> apply(List<Action> actions) async {
    final hasDefer = actions.any(
      (a) => a.type == BotCreatorActionType.deferInteraction,
    );
    final hasModal = actions.any(
      (a) => a.type == BotCreatorActionType.respondWithModal,
    );
    if (!enabled || hasDefer || hasModal || actions.isEmpty) return;
    final wantsEphemeral =
        ephemeral ||
        actions.any(
          (a) =>
              a.type == BotCreatorActionType.respondWithMessage &&
              a.payload['ephemeral'] == true,
        );
    onLog?.call('Attempting to defer interaction');
    try {
      await acknowledge(ephemeral: wantsEphemeral);
      didDefer = true;
      onLog?.call('Interaction acknowledged successfully');
    } catch (e) {
      // didDefer stays false: the response is sent normally.
      onLog?.call('Failed to acknowledge interaction: $e');
    }
  }
}

/// One execution of a whole action list on the native engine: everything the
/// historical `handleActions` did around its loop (services, hydration, nested
/// lists, replay capture, execution policy) with no loop of its own. Built by
/// [BdfdActionRunner.runList]; nested lists (blocks, workflows, scripts) start
/// a new execution of the same runner on the shared [BdfdContext].
class BdfdActionExecution {
  BdfdActionExecution({
    required this.runner,
    required this.client,
    required this.interaction,
    required this.store,
    required this.botId,
    required this.variables,
    required this.resolveTemplate,
    this.fallbackChannelId,
    this.fallbackGuildId,
    this.workflowStack,
    this.onLog,
    this.onReplayCaptured,
    this.nestedActionsPreprocessor,
    this.entityCache,
    this.lavalinkService,
    this.executionPolicy,
    this.bdfdContext,
    this.bdfdMessages,
    this.bdfdModeration,
    this.bdfdCommandQueries,
    this.bdfdComponents,
    this.bdfdTiming,
    this.bdfdDelays = const RuntimeBotDelayService(),
    this.bdfdHttp,
    this.throwOnError = false,
    this.executionBudget,
    this.acknowledgement,
    this.startProfileClock,
  });

  final BdfdActionRunner runner;
  final NyxxGateway client;
  final Interaction? interaction;
  final BotDataStore store;
  final String botId;
  final Map<String, String> variables;
  final String Function(String input) resolveTemplate;
  final Snowflake? fallbackChannelId;
  final Snowflake? fallbackGuildId;
  final Set<String>? workflowStack;
  final void Function(String message)? onLog;
  final void Function(List<Map<String, dynamic>> frames, int totalMs)?
  onReplayCaptured;
  final List<Action> Function(List<Action>)? nestedActionsPreprocessor;
  final Map<String, dynamic>? entityCache;
  final LavalinkService? lavalinkService;
  final ActionExecutionPolicy? executionPolicy;
  final BdfdContext? bdfdContext;
  final BotMessageService? bdfdMessages;
  final BotModerationService? bdfdModeration;
  final BotCommandQueryService? bdfdCommandQueries;
  final BotComponentService? bdfdComponents;
  final BotTimingService? bdfdTiming;
  final BotDelayService bdfdDelays;
  final HttpService? bdfdHttp;
  final bool throwOnError;
  final CommandExecutionBudget? executionBudget;
  final VisualAcknowledgement? acknowledgement;
  final int Function() Function()? startProfileClock;

  /// Run [actions] and return the list's results (`__stopped__` included when
  /// the list stopped). A failure is rethrown as the original exception once
  /// its results and `error.*` variables are recorded.
  Future<Map<String, String>> run(List<Action> actions) {
    final budget = executionBudget ?? CommandExecutionBudget();
    return budget.run(() => _run(actions, budget));
  }

  Future<Map<String, String>> _run(
    List<Action> actions,
    CommandExecutionBudget budget,
  ) async {
    executionPolicy?.checkBudget();
    final resolvedFallbackChannelId =
        fallbackChannelId ??
        (interaction as dynamic)?.channel?.id as Snowflake?;
    final guildId =
        fallbackGuildId ?? (interaction as dynamic)?.guildId as Snowflake?;
    final activeWorkflowStack = workflowStack ?? <String>{};
    final activeEntityCache = entityCache ?? <String, dynamic>{};
    final nativeContext =
        bdfdContext ??
        BdfdContext(
          variables: variables,
          temporaryVariables: RuntimeTemporaryVariables(variables),
          budget: budget,
          activeWorkflows: activeWorkflowStack,
        );

    Future<Map<String, String>> executeNestedActions(
      List<Action> nestedActions, {
      bool protected = false,
    }) => runner.runList(
      client,
      interaction,
      actions: nestedActions,
      store: store,
      botId: botId,
      variables: variables,
      resolveTemplate: resolveTemplate,
      fallbackChannelId: resolvedFallbackChannelId,
      fallbackGuildId: guildId,
      workflowStack: activeWorkflowStack,
      onLog: onLog,
      nestedActionsPreprocessor: nestedActionsPreprocessor,
      entityCache: activeEntityCache,
      executionPolicy: executionPolicy,
      bdfdContext: nativeContext,
      bdfdMessages: bdfdMessages,
      bdfdModeration: bdfdModeration,
      bdfdCommandQueries: bdfdCommandQueries,
      bdfdComponents: bdfdComponents,
      bdfdTiming: bdfdTiming,
      bdfdDelays: bdfdDelays,
      bdfdHttp: bdfdHttp,
      throwOnError: protected || throwOnError,
      executionBudget: budget,
      lavalinkService: lavalinkService,
      startProfileClock: startProfileClock,
    );

    final discordFetcher = executionPolicy?.allowDiscordHydration == false
        ? null
        : (String scope, String contextId, Map<String, String> vars) async {
            await DiscordEntityFetcher.hydrateEntity(
              client,
              scope,
              contextId,
              vars,
              cache: activeEntityCache,
            );
          };

    Future<int?> scopedVariableTtl(String scope, String key) async =>
        await store.getScopedVariableTtl(
          botId,
          scope,
          resolveScopeContextId(
                scope: scope,
                variables: variables,
                interaction: interaction,
                guildId: guildId,
                channelId: resolvedFallbackChannelId,
              ) ??
              '',
          key,
        );

    // `runBdfdScript` on the native engine.
    Future<Map<String, String>> executeNativeScript(String source) async {
      // A script started from a native visual program is the outermost script
      // when no script is active around it.
      if (nativeContext.depth == (visualProgramDepth[nativeContext] ?? 0)) {
        nativeContext.startScript();
      }
      if (executionPolicy != null &&
          (bdfdMessages == null || bdfdHttp == null)) {
        throw StateError(
          'Native BDFD requires message and HTTP adapters for this execution policy.',
        );
      }
      final execution = BdfdScriptExecution(
        store: store,
        botId: botId,
        variables: variables,
        context: nativeContext,
        http: bdfdHttp,
        music: lavalinkService == null || guildId == null
            ? null
            : DiscordBotMusicService(
                client: client,
                guildId: guildId,
                lavalink: lavalinkService!,
              ),
        components:
            bdfdComponents ??
            (executionPolicy == null
                ? DiscordBotComponentService(
                    client: client,
                    channelId: resolvedFallbackChannelId,
                    interaction: interaction,
                  )
                : null),
        timing: bdfdTiming,
        delays: bdfdDelays,
        commandQueries:
            bdfdCommandQueries ??
            (executionPolicy == null
                ? DiscordBotCommandQueryService(
                    client: client,
                    store: store,
                    botId: botId,
                    guildId: guildId,
                  )
                : null),
        // Policies must explicitly provide effects adapters; a missing
        // moderation adapter leaves these calls unsupported at preflight.
        moderation:
            bdfdModeration ??
            (executionPolicy == null
                ? DiscordBotModerationService(
                    client: client,
                    guildId: guildId,
                    store: store,
                    botId: botId,
                  )
                : null),
        runVisualWorkflow: (workflow, context) => executeNestedActions(
          ((workflow['actions'] as List?) ?? [])
              .whereType<Map>()
              .map((json) => Action.fromJson(Map<String, dynamic>.from(json)))
              .toList(),
          protected: true,
        ),
        messages:
            bdfdMessages ??
            DiscordBotMessageService(
              botId: botId,
              client: client,
              interaction: interaction,
              channelId: resolvedFallbackChannelId,
              guildId: guildId?.toString(),
              messageId: int.tryParse(variables['message.id'] ?? '') == null
                  ? null
                  : Snowflake.parse(variables['message.id']!),
            ),
      );
      await execution.execute(source, backend: 'native-v1');
      return {
        ...nativeContext.results,
        if (nativeContext.stopped) '__stopped__': 'true',
      };
    }

    final results = <String, String>{};
    final sink = ResultSink(results: results, variables: variables);
    final executionStopwatch = Stopwatch()..start();

    final env = ActionRunEnvironment(
      variables: variables,
      sink: sink,
      resolveTemplate: resolveTemplate,
      budget: budget,
      moderation:
          bdfdModeration ??
          DiscordBotModerationService(
            client: client,
            guildId: guildId,
            store: store,
            botId: botId,
          ),
      guildId: guildId?.toString(),
      throwOnError: throwOnError,
      getScopedVariableTtl: scopedVariableTtl,
      store: store,
      botId: botId,
      interaction: interaction,
      guildSnowflake: guildId,
      fallbackChannelId: fallbackChannelId,
      http: bdfdHttp,
      onLog: onLog,
      blockActions: DiscordBotBlockActionService(
        client: client,
        store: store,
        botId: botId,
      ),
      permissionCache: BotPermissionCache(),
      client: client,
      lavalinkService: lavalinkService,
      policy: executionPolicy,
      replayCapturing: onReplayCaptured != null,
      startProfileClock: startProfileClock,
      // Every action hydrates the entities its placeholders name, root actions
      // included (a defer must acknowledge before any fetch can delay it).
      prepare: (type, key, payload, path) async {
        if (type == BotCreatorActionType.deferInteraction) return;
        await hydrateActionPlaceholders(
          store: store,
          botId: botId,
          actions: [Action(type: type, key: key, payload: payload)],
          variables: variables,
          discordFetcher: discordFetcher,
        );
      },
    );
    env.flow
      ..adapter = VisualControlAdapter(
        activeWorkflowStack: activeWorkflowStack,
        getWorkflowByName: (name) => store.getWorkflowByName(botId, name),
        executeActions: executeNestedActions,
        executeProtectedActions: (nested) =>
            executeNestedActions(nested, protected: true),
        executeNativeBdfdScript: executeNativeScript,
        nestedActionsPreprocessor: nestedActionsPreprocessor,
      )
      ..refreshExecutionTime = () {
        variables['execution.time'] =
            '${executionStopwatch.elapsedMilliseconds}ms';
      };

    // Replay capture (independent of the `$debug` embed): the native frames of
    // every `bc_*` call, nested lists included (they share the context).
    final replayCapture = onReplayCaptured == null
        ? null
        : BdfdReplayCapture(
            variables: variables,
            describe: (location) =>
                env.flow.replayRefs[location.source]?[location.line],
          );
    final previousObserver = nativeContext.onTrace;
    if (replayCapture != null) {
      nativeContext.onTrace = (event) {
        replayCapture.record(event);
        previousObserver?.call(event);
      };
    }
    final replayStopwatch = Stopwatch()..start();

    try {
      await acknowledgement?.apply(actions);
      return await runner.run(actions, env: env, context: nativeContext);
    } finally {
      if (replayCapture != null) {
        nativeContext.onTrace = previousObserver;
        replayCapture.finish(null);
        replayStopwatch.stop();
        onReplayCaptured!(
          List.of(replayCapture.frames),
          replayStopwatch.elapsedMilliseconds,
        );
      }
    }
  }
}
