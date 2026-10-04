import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../services/bot_channel_mutation_service.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

bool? _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') {
    return true;
  }
  if (text == 'false') {
    return false;
  }
  return null;
}

Duration? _parseDuration(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return Duration(seconds: value.toInt());
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  final asInt = int.tryParse(text);
  if (asInt != null) {
    return Duration(seconds: asInt);
  }

  final match = RegExp(r'^(\d+)\s*([smhd])$').firstMatch(text.toLowerCase());
  if (match == null) {
    return null;
  }

  final amount = int.parse(match.group(1)!);
  final unit = match.group(2)!;
  switch (unit) {
    case 's':
      return Duration(seconds: amount);
    case 'm':
      return Duration(minutes: amount);
    case 'h':
      return Duration(hours: amount);
    case 'd':
      return Duration(days: amount);
    default:
      return null;
  }
}

int? _parseArchiveMinutes(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == '!unchanged') {
    return null;
  }
  final parsed = int.tryParse(text);
  if (parsed == null) {
    return null;
  }
  const allowed = <int>[60, 1440, 4320, 10080];
  return allowed.reduce(
    (prev, curr) => (curr - parsed).abs() < (prev - parsed).abs() ? curr : prev,
  );
}

Future<Map<String, String>> updateChannelAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => updateChannelActionWith(
  DiscordBotChannelMutationService(client),
  payload: payload,
  resolve: resolve,
  budget: budget,
);

/// [updateChannelAction] over any [BotChannelMutationService].
Future<Map<String, String>> updateChannelActionWith(
  BotChannelMutationService service, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) async {
  resolve ??= (s) => s;
  try {
    String value(String key) => resolve!((payload[key] ?? '').toString());
    final channelId = value('channelId').trim();
    final name = value('name').trim();
    final topic = value('topic');
    final nsfw = _toBool(value('nsfw'));
    final position = int.tryParse(value('position'));
    final category = _toSnowflake(value('categoryId'));
    final slowmode = _parseDuration(value('slowmode'));
    final archived = _toBool(value('archived'));
    final locked = _toBool(value('locked'));
    final archiveMinutes = _parseArchiveMinutes(value('autoArchiveDuration'));
    final reason = value('reason');
    await service.modifyChannel(
      ChannelModification(
        channelId: channelId,
        name: name.isEmpty || name == '!unchanged' ? null : name,
        topic: topic.isEmpty || topic == '!unchanged' ? null : topic,
        isNsfw: nsfw,
        position: position,
        categoryId: category?.toString(),
        slowmodeSeconds: slowmode?.inSeconds,
        isArchived: archived,
        isLocked: locked,
        autoArchiveMinutes: archiveMinutes,
        reason: reason.isEmpty ? null : reason,
      ),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': '${int.parse(channelId)}', 'status': 'updated'};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to update channel: $error', 'channelId': ''};
  }
}
