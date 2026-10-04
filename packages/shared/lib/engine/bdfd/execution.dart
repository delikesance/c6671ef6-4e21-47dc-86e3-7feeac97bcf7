import '../../services/bot_component_service.dart';
import '../../services/bot_cooldown_service.dart';
import '../../services/bot_timing_service.dart';
import '../../services/bot_command_query_service.dart';
import 'package:nyxx/nyxx.dart';

import '../../bot/bot_data_store.dart';
import '../../services/bot_message_service.dart';
import '../../services/bot_moderation_service.dart';
import '../../services/http_service.dart';
import '../execution_budget.dart';
import '../../utils/interaction_ack_state.dart';
import 'engine.dart';
import 'replay.dart';
import 'runtime.dart';
import 'workflow_functions.dart';

enum BdfdBackend {
  legacy('legacy-v1'),
  native(BdfdEngine.backendId);

  const BdfdBackend(this.id);
  final String id;

  static BdfdBackend parse(Object? value) {
    if (value == null || value == '') return legacy;
    for (final backend in values) {
      if (value == backend.id) return backend;
    }
    throw FormatException('Unknown BDFD backend: $value');
  }
}

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
    BdfdVisualWorkflowRunner? runVisualWorkflow,
    CommandExecutionBudget? budget,
    BdfdContext? context,
    this.interaction,
    this.onReplayCaptured,
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
         runVisualWorkflow: runVisualWorkflow,
         legacyUserVariables: variables['bdfd.userVariableSemantics'] == '1',
       ),
       context = context ?? BdfdContext(variables: variables, budget: budget);

  final BdfdEngine engine;
  final BdfdContext context;
  final Interaction? interaction;
  final void Function(List<Map<String, dynamic>> frames, int totalMs)?
  onReplayCaptured;

  Future<String?> execute(
    String source, {
    Object? backend,
    required Future<void> Function(String source) executeLegacy,
    Future<void> Function()? onNativePrepared,
  }) async {
    if (onReplayCaptured == null ||
        BdfdBackend.parse(backend) != BdfdBackend.native) {
      return _executeSelected(
        source,
        backend: backend,
        executeLegacy: executeLegacy,
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
        executeLegacy: executeLegacy,
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
    required Future<void> Function(String source) executeLegacy,
    Future<void> Function()? onNativePrepared,
  }) async {
    final selected = BdfdBackend.parse(backend);
    if (selected == BdfdBackend.legacy) {
      await executeLegacy(source);
      return null;
    }
    final program = engine.prepare(source);
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
