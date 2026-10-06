import 'dart:async';
import '../services/bot_message_service.dart';
import '../services/bot_moderation_service.dart';
import 'bdfd/runtime.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_execution.dart'
    show VisualAcknowledgement;
import 'package:bot_creator_shared/actions/interaction_response.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:bot_creator_shared/utils/runtime_variables.dart';
import 'package:bot_creator_shared/engine/bot_engine_callbacks.dart';
import 'package:bot_creator_shared/utils/interaction_ack_state.dart';

/// Helper to execute visual workflows or BDFD actions for both interactions and events.
class WorkflowExecutor {
  WorkflowExecutor({
    required this.store,
    required this.callbacks,
    this.bdfdMessages,
    this.bdfdModeration,
  });

  final BotMessageService? bdfdMessages;
  final BotModerationService? bdfdModeration;

  final BotDataStore store;
  final BotEngineCallbacks callbacks;

  /// Set by [BotSession] after Lavalink plugin is ready.
  LavalinkService? lavalinkService;

  /// Executes a list of actions for a given context.
  Future<Map<String, String>> executeActions({
    required List<Action> actions,
    required dynamic context, // Interaction or MessageCreateEvent, etc.
    required NyxxGateway gateway,
    required String botId,
    required Map<String, String> runtimeVariables,
    Snowflake? fallbackChannelId,
    Snowflake? fallbackGuildId,
    String? replayLabel,
    BdfdContext? bdfdContext,

    /// Acknowledgement of the interaction by the root list (the native runner
    /// decides, see `VisualAcknowledgement`).
    VisualAcknowledgement? acknowledgement,
  }) async {
    callbacks.onDebugLog?.call(
      'executeActions started with ${actions.length} actions',
      botId: botId,
    );

    if (actions.isEmpty) {
      callbacks.onDebugLog?.call(
        'No actions to execute, returning empty results',
        botId: botId,
      );
      return const {};
    }

    try {
      await _ensureVariableSemantics(botId, runtimeVariables);
      final isCapturing =
          callbacks.isDebugReplayCapturing?.call(botId) ?? false;

      _populateLavalinkVariables(runtimeVariables, context, fallbackGuildId);

      final results = await handleActions(
        gateway,
        context is Interaction ? context : null,
        actions: actions,
        store: store,
        botId: botId,
        variables: runtimeVariables,
        bdfdMessages: bdfdMessages,
        bdfdModeration: bdfdModeration,
        bdfdContext: bdfdContext,
        executionBudget: bdfdContext?.budget,
        workflowStack: bdfdContext?.activeWorkflows,
        throwOnError: bdfdContext != null,
        acknowledgement: acknowledgement,
        lavalinkService: lavalinkService,
        resolveTemplate: (input) {
          _populateLavalinkVariables(
            runtimeVariables,
            context,
            fallbackGuildId,
          );
          return resolveTemplatePlaceholders(input, runtimeVariables);
        },
        onLog: (msg) => callbacks.onLog?.call(msg, botId: botId),
        fallbackChannelId: fallbackChannelId,
        fallbackGuildId: fallbackGuildId,
        onReplayCaptured: isCapturing
            ? (frames, totalMs) {
                String label = replayLabel ?? '';
                if (label.isEmpty) {
                  // Fix 2: Restrict to ApplicationCommandInteraction to avoid NoSuchMethodError
                  if (context is ApplicationCommandInteraction) {
                    label = '/${context.data.name}';
                  } else if (runtimeVariables.containsKey('0')) {
                    label = '!${runtimeVariables['0']}';
                  } else {
                    label = 'Workflow';
                  }
                }
                callbacks.onReplayCaptured?.call(botId, label, frames, totalMs);
              }
            : null,
      );

      callbacks.onDebugLog?.call(
        'handleActions completed with ${results.length} results: $results',
        botId: botId,
      );

      return results;
    } catch (e, st) {
      callbacks.onDebugLog?.call(
        'Action execution failed: $e\n$st',
        botId: botId,
      );
      callbacks.onLog?.call('ERROR: Action execution failed: $e', botId: botId);
      rethrow;
    }
  }

  /// Executes a full visual workflow (actions + response).
  Future<void> executeVisualWorkflow(
    Map<String, dynamic> workflowData, {
    required Interaction interaction,
    required NyxxGateway gateway,
    required String botId,
    required Map<String, String> runtimeVariables,
  }) async {
    callbacks.onDebugLog?.call('executeVisualWorkflow started', botId: botId);
    await _ensureVariableSemantics(botId, runtimeVariables);

    // Fix 1: Safe cast for response (avoid TypeError if not a Map)
    final rawResponse = workflowData["response"];
    final response = rawResponse is Map
        ? Map<String, dynamic>.from(rawResponse.cast<String, dynamic>())
        : <String, dynamic>{};
    callbacks.onDebugLog?.call(
      'Response data in executeVisualWorkflow: $response',
      botId: botId,
    );

    // Fix 1: Safe cast for workflow sub-map
    final rawWorkflow = response['workflow'];
    final workflow = rawWorkflow is Map
        ? Map<String, dynamic>.from(rawWorkflow.cast<String, dynamic>())
        : <String, dynamic>{};

    // Fix 1: Safe cast for actions list
    final rawActions = workflowData["actions"];
    var actionsJson = rawActions is List
        ? List<Map<String, dynamic>>.from(
            rawActions.whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
          )
        : const <Map<String, dynamic>>[];

    // Load saved workflow if needed
    final workflowName = (workflow['name'] ?? '').toString().trim();
    if (workflowName.isNotEmpty && actionsJson.isEmpty) {
      final savedWorkflow = await store.getWorkflowByName(botId, workflowName);
      if (savedWorkflow != null) {
        // Fix 1: Safe cast for saved workflow actions
        final savedRawActions = savedWorkflow['actions'];
        actionsJson = savedRawActions is List
            ? List<Map<String, dynamic>>.from(
                savedRawActions.whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ),
              )
            : const <Map<String, dynamic>>[];
      }
    }

    var actions = actionsJson.map(Action.fromJson).toList();
    callbacks.onDebugLog?.call(
      'Parsed ${actions.length} actions for visual workflow',
      botId: botId,
    );

    // Visibility of the response: the workflow's, or an ephemeral
    // respondWithMessage (Discord does not allow changing it after a defer).
    final isEphemeral =
        workflow['visibility']?.toString().toLowerCase() == 'ephemeral' ||
        actions.any(
          (a) =>
              a.type == BotCreatorActionType.respondWithMessage &&
              a.payload['ephemeral'] == true,
        );

    // The runner acknowledges (defers) before the first action unless the list
    // acknowledges itself (deferInteraction), opens a modal (it must be the
    // first response) or the workflow disables it; the deferral is ephemeral
    // when the workflow is or a respondWithMessage of the list is.
    final acknowledgement = VisualAcknowledgement(
      enabled: workflow['autoDeferIfActions'] != false,
      ephemeral:
          workflow['visibility']?.toString().toLowerCase() == 'ephemeral',
      onLog: (message) => callbacks.onDebugLog?.call(message, botId: botId),
      acknowledge: ({required bool ephemeral}) async {
        if (interaction is MessageResponse) {
          await interaction.acknowledge(isEphemeral: ephemeral);
        } else {
          await (interaction as dynamic).acknowledge(isEphemeral: ephemeral);
        }
        markInteractionAcknowledged(interaction);
      },
    );

    if (actions.isNotEmpty) {
      callbacks.onDebugLog?.call(
        'Executing ${actions.length} actions in visual workflow',
        botId: botId,
      );
      final results = await executeActions(
        actions: actions,
        context: interaction,
        gateway: gateway,
        botId: botId,
        runtimeVariables: runtimeVariables,
        acknowledgement: acknowledgement,
        replayLabel: workflowName.isNotEmpty
            ? workflowName
            : (interaction is ApplicationCommandInteraction
                  ? '/${interaction.data.name}'
                  : 'Slash Command'),
      );
      callbacks.onDebugLog?.call(
        'Action execution results: $results',
        botId: botId,
      );
      for (final entry in results.entries) {
        runtimeVariables['action.${entry.key}'] = entry.value;
      }
    }

    await sendWorkflowResponse(
      interaction: interaction,
      gateway: gateway,
      response: response,
      runtimeVariables: runtimeVariables,
      botId: botId,
      didDefer: acknowledgement.didDefer,
      isEphemeral: isEphemeral,
      onLog: (msg, {required botId}) async =>
          callbacks.onLog?.call(msg, botId: botId),
      onDebugLog: (msg, {required botId}) async =>
          callbacks.onDebugLog?.call(msg, botId: botId),
    );

    callbacks.onDebugLog?.call('executeVisualWorkflow completed', botId: botId);
  }

  Future<void> executeGeneralWorkflow({
    required Map<String, dynamic> workflowData,
    required NyxxGateway gateway,
    required String botId,
    required Map<String, String> runtimeVariables,
    String? replayLabel,
  }) async {
    callbacks.onDebugLog?.call('executeGeneralWorkflow started', botId: botId);
    await _ensureVariableSemantics(botId, runtimeVariables);

    // Fix 5: Safe cast for actions list
    final rawActions = workflowData["actions"];
    final actionsJson = rawActions is List
        ? List<Map<String, dynamic>>.from(
            rawActions.whereType<Map>().map(
              (e) => Map<String, dynamic>.from(e),
            ),
          )
        : const <Map<String, dynamic>>[];

    if (actionsJson.isEmpty) {
      callbacks.onDebugLog?.call(
        'No actions in general workflow, returning early',
        botId: botId,
      );
      return;
    }

    var actions = actionsJson.map(Action.fromJson).toList();

    callbacks.onDebugLog?.call(
      'Executing ${actions.length} actions in general workflow',
      botId: botId,
    );

    await executeActions(
      actions: actions,
      context: null,
      gateway: gateway,
      botId: botId,
      runtimeVariables: runtimeVariables,
      replayLabel: replayLabel ?? (workflowData['name'] ?? '').toString(),
    );

    callbacks.onDebugLog?.call(
      'executeGeneralWorkflow completed',
      botId: botId,
    );
  }

  Future<void> _ensureVariableSemantics(
    String botId,
    Map<String, String> runtimeVariables,
  ) async {
    if (!runtimeVariables.containsKey('bdfd.userVariableSemantics')) {
      await injectBdfdUserVariableSemantics(
        store: store,
        botId: botId,
        runtimeVariables: runtimeVariables,
      );
    }
  }

  void _populateLavalinkVariables(
    Map<String, String> variables,
    dynamic context,
    Snowflake? fallbackGuildId,
  ) {
    Snowflake? guildId = fallbackGuildId;
    if (guildId == null && context != null) {
      try {
        guildId = (context as dynamic).guildId as Snowflake?;
      } catch (_) {}
      if (guildId == null) {
        try {
          guildId = (context as dynamic).message?.guildId as Snowflake?;
        } catch (_) {}
      }
      if (guildId == null) {
        try {
          guildId = (context as dynamic).message?.guild?.id as Snowflake?;
        } catch (_) {}
      }
      if (guildId == null) {
        try {
          guildId = (context as dynamic).guild?.id as Snowflake?;
        } catch (_) {}
      }
    }

    final service = lavalinkService;
    if (guildId != null && service != null) {
      final session = service.session(guildId);
      if (session != null) {
        final current = session.currentTrack;
        variables['lavalink.title'] = current?.info.title ?? '';
        variables['lavalink.author'] = current?.info.author ?? '';

        final duration = current?.info.length ?? Duration.zero;
        variables['lavalink.duration'] = duration.inMilliseconds.toString();

        final position = session.position;
        variables['lavalink.position'] = position.inMilliseconds.toString();

        variables['lavalink.queueSize'] = session.queueSize.toString();
        variables['lavalink.volume'] = session.volume.toString();
        variables['lavalink.isPaused'] = session.isPaused.toString();
        variables['lavalink.isLooping'] = session.loop.toString();
        variables['lavalink.thumbnail'] = _getTrackThumbnail(current);
        return;
      }
    }

    variables['lavalink.title'] = '';
    variables['lavalink.author'] = '';
    variables['lavalink.duration'] = '0';
    variables['lavalink.position'] = '0';
    variables['lavalink.queueSize'] = '0';
    variables['lavalink.volume'] = '100';
    variables['lavalink.isPaused'] = 'false';
    variables['lavalink.isLooping'] = 'false';
    variables['lavalink.thumbnail'] = '';
  }

  String _getTrackThumbnail(Track? track) {
    if (track == null) return '';
    final info = track.info;

    // 1. Try artworkUrl if populated by Lavalink
    final artwork = info.artworkUrl?.toString() ?? '';
    if (artwork.isNotEmpty) {
      return artwork;
    }

    // 2. YouTube fallback using video identifier
    final source = info.sourceName.toLowerCase();
    final uriStr = info.uri?.toString() ?? '';
    final isYoutube =
        source == 'youtube' ||
        uriStr.contains('youtube.com') ||
        uriStr.contains('youtu.be');

    if (isYoutube && info.identifier.isNotEmpty) {
      return 'https://img.youtube.com/vi/${info.identifier}/hqdefault.jpg';
    }

    return '';
  }
}
