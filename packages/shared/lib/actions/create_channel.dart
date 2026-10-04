import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../services/bot_channel_mutation_service.dart';

bool? _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes' || text == 'y') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no' || text == 'n') {
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

ChannelType _channelTypeFromRaw(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'voice':
      return ChannelType.guildVoice;
    case 'announcement':
      return ChannelType.guildAnnouncement;
    case 'stage':
      return ChannelType.guildStageVoice;
    case 'forum':
      return ChannelType.guildForum;
    case 'category':
      return ChannelType.guildCategory;
    case 'text':
    default:
      return ChannelType.guildText;
  }
}

String _typeName(ChannelType type) => switch (type) {
  ChannelType.guildText => 'text',
  ChannelType.guildVoice => 'voice',
  ChannelType.guildStageVoice => 'stage',
  ChannelType.guildForum => 'forum',
  ChannelType.guildCategory => 'category',
  ChannelType.guildAnnouncement => 'announcement',
  _ => throw ArgumentError('Unsupported channel type.'),
};

Future<Map<String, String>> createChannel(
  NyxxGateway client,
  String name, {
  required Snowflake guildId,
  ChannelType type = ChannelType.guildText,
  CommandExecutionBudget? budget,
}) async {
  try {
    final id = await DiscordBotChannelMutationService(client).createChannel(
      ChannelCreation(guildId: '$guildId', name: name, type: _typeName(type)),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': id};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to create channel: $error', 'channelId': ''};
  }
}

Future<Map<String, String>> createChannelAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) => createChannelActionWith(
  DiscordBotChannelMutationService(client),
  guildId: '$guildId',
  payload: payload,
  resolve: resolve,
  budget: budget,
);

/// [createChannelAction] over any [BotChannelMutationService]: the historical
/// executor passes the Discord adapter, the native `bc_createChannel` the
/// execution's own service.
Future<Map<String, String>> createChannelActionWith(
  BotChannelMutationService service, {
  required String guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) async {
  final name = resolve((payload['name'] ?? '').toString()).trim();
  final type = _typeName(
    _channelTypeFromRaw(resolve((payload['type'] ?? 'text').toString())),
  );
  final category = resolve((payload['categoryId'] ?? '').toString()).trim();
  final topic = resolve((payload['topic'] ?? '').toString()).trim();
  final slowmode = _parseDuration(
    resolve((payload['slowmode'] ?? '').toString()),
  );
  final nsfw = _toBool(resolve((payload['nsfw'] ?? '').toString()));
  final reason = resolve((payload['reason'] ?? '').toString());
  try {
    final id = await service.createChannel(
      ChannelCreation(
        guildId: guildId,
        name: name,
        type: type,
        categoryId: category.isEmpty || type == 'category' ? null : category,
        topic:
            topic.isEmpty ||
                !const ['text', 'forum', 'announcement'].contains(type)
            ? null
            : topic,
        isNsfw: type == 'category' ? null : nsfw,
        slowmodeSeconds:
            const ['text', 'forum', 'voice', 'stage'].contains(type)
            ? slowmode?.inSeconds
            : null,
        reason: reason.isEmpty ? null : reason,
      ),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': id};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to create channel: $error', 'channelId': ''};
  }
}
