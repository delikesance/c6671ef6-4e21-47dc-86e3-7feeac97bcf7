import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../utils/bdfd_duration_parser.dart';
import '../services/bot_channel_mutation_service.dart';

Future<Map<String, String>> slowmodeAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) async {
  final id = resolve(payload['channelId']?.toString() ?? '');
  final duration = parseBdfdDuration(
    resolve(payload['duration']?.toString() ?? '0s'),
  );
  final reason = resolve(payload['reason']?.toString() ?? '');
  if (duration == null ||
      duration.isNegative ||
      duration > const Duration(hours: 6)) {
    return {'error': 'Slowmode duration must be between 0 and 6 hours'};
  }
  try {
    final change = SlowmodeChange(
      channelId: id,
      seconds: duration.inSeconds,
      reason: reason.isEmpty ? null : reason,
    );
    await DiscordBotChannelMutationService(
      client,
    ).setSlowmode(change, budget: budget ?? CommandExecutionBudget());
    return {
      'channelId': '${int.parse(id.trim())}',
      'duration': '${change.seconds}',
    };
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to set slowmode: $error'};
  }
}
