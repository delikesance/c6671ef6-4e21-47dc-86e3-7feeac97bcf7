import '../../services/bot_component_service.dart';
import '../../services/bot_cooldown_service.dart';
import '../../services/bot_timing_service.dart';
import '../../services/bot_command_query_service.dart';
import 'package:nyxx/nyxx.dart';

import '../../bot/bot_data_store.dart';
import '../../services/bot_message_service.dart';
import '../../services/bot_moderation_service.dart';
import '../../services/bot_music_service.dart';
import '../../services/http_service.dart';
import '../execution_budget.dart';
import '../../utils/interaction_ack_state.dart';
import 'engine.dart';
import 'replay.dart';
import 'runtime.dart';
import 'workflow_functions.dart';
import 'validation/bdfd_backend.dart';

export 'validation/bdfd_backend.dart';

/// Common entry-point adapter during migration. Backend selection occurs once,
/// before preparation or effects. The legacy callback is never used as an
/// error fallback, and the native interpreter never sees visual actions.
class BdfdScriptExecution {
  BdfdScriptExecution({
    required BotDataStore store,
    required String botId,
    required Map<String, String> variables,
    BotMessageService? messages,
    BotModerationService? moderation,
    BotCommandQueryService? commandQueries,
    BotComponentService? components,
    BotTimingService? timing,
    BotDelayService delays = const RuntimeBotDelayService(),
    HttpService? http,
    BotMusicService? music,
    BdfdVisualWorkflowRunner? runVisualWorkflow,
    CommandExecutionBudget? budget,
    BdfdContext? context,
    this.interaction,
    this.onReplayCaptured,
    this.expandDynamicVariables = false,
  }) : engine = BdfdEngine(
         store: store,
         botId: botId,
         messages: messages,
         moderation: moderation,
         commandQueries: commandQueries,
         components: components,
         timing: timing,
         delays: delays,
         http: http,
         music: music,
         runVisualWorkflow: runVisualWorkflow,
         legacyUserVariables: variables['bdfd.userVariableSemantics'] == '1',
       ),
       context = context ?? BdfdContext(variables: variables, budget: budget);

  final BdfdEngine engine;
  final BdfdContext context;
  final Interaction? interaction;

  /// Substitutes `((name))` dynamic variables (opts.*, user.*...) in the
  /// script's literal text, as data. Off for scripts embedded in visual blocks.
  final bool expandDynamicVariables;
  final void Function(List<Map<String, dynamic>> frames, int totalMs)?
  onReplayCaptured;

  Future<String?> execute(
    String source, {
    Object? backend,
    Future<void> Function()? onNativePrepared,
  }) async {
    BdfdBackend.parse(backend);
    if (onReplayCaptured == null) {
      return _executeSelected(
        source,
        backend: backend,
        onNativePrepared: onNativePrepared,
      );
    }
    final capture = BdfdReplayCapture();
    final previous = context.onTrace;
    context.onTrace = (event) {
      capture.record(event);
      previous?.call(event);
    };
    Object? failure;
    String? output;
    try {
      output = await _executeSelected(
        source,
        backend: backend,
        onNativePrepared: onNativePrepared,
      );
      return output;
    } catch (error) {
      failure = error;
      rethrow;
    } finally {
      context.onTrace = previous;
      capture.finish(failure, output: output, includeProgram: true);
      try {
        onReplayCaptured!(capture.frames, capture.clock.elapsedMilliseconds);
      } catch (_) {
        // Replay delivery cannot change an already executed command.
      }
    }
  }

  Future<String?> _executeSelected(
    String source, {
    Object? backend,
    Future<void> Function()? onNativePrepared,
  }) async {
    BdfdBackend.parse(backend);
    final program = engine.prepare(source)
      ..expandDynamicVariables = expandDynamicVariables;
    context.budget.check();
    var deferredHere = false;
    try {
      // Modal responses must precede acknowledgement. Dynamic execution and
      // stored workflows may contain a modal even when it is absent here.
      final mayOpenModal = RegExp(
        r'\$(newModal|callWorkflow|eval|funcCall)\b',
        caseSensitive: false,
      ).hasMatch(source);
      if (interaction != null && !mayOpenModal) {
        await context.budget.run(() async {
          if (!isInteractionAcknowledged(interaction!)) {
            await (interaction as dynamic).acknowledge();
            markInteractionAcknowledged(interaction!);
            deferredHere = true;
            try {
              context.budget.check();
            } catch (_) {
              // An acknowledgement may finish after the deadline. Its own
              // continuation cleans up, even if execute has already timed out.
              await _deleteDeferredResponse();
              deferredHere = false;
              rethrow;
            }
          }
          context.response.acknowledged = true;
        });
      }
      if (onNativePrepared != null) {
        await context.budget.run(onNativePrepared);
      }
      context.budget.check();
      return await engine.executeProgram(program, context: context);
    } finally {
      // Channel sends and ephemeral followups do not complete a deferred
      // original response. Remove only the placeholder created by this call.
      if (deferredHere && !context.response.originalResponseCompleted) {
        await _deleteDeferredResponse();
      }
    }
  }

  Future<void> _deleteDeferredResponse() async {
    try {
      await ((interaction as dynamic).deleteOriginalResponse() as Future)
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      // Cleanup cannot replay a send or hide the original execution error.
    }
  }
}
