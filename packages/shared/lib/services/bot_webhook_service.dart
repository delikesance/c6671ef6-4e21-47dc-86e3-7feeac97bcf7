import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'bot_permission_query_service.dart';

class BotWebhookReference {
  const BotWebhookReference(this.id, this.token);
  final String id;
  final String token;
  String get url => 'https://discord.com/api/webhooks/$id/$token';
  static BotWebhookReference parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    final parts = uri?.pathSegments ?? const <String>[];
    final index = parts.indexOf('webhooks');
    if (uri == null ||
        uri.scheme != 'https' ||
        !{
          'discord.com',
          'discordapp.com',
          'canary.discord.com',
          'ptb.discord.com',
        }.contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        index < 0 ||
        index + 3 != parts.length ||
        index != 1 &&
            !(index == 2 && RegExp(r'^v[0-9]+$').hasMatch(parts[1])) ||
        parts.first != 'api' ||
        !RegExp(r'^[1-9][0-9]*$').hasMatch(parts[index + 1]) ||
        !RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(parts[index + 2])) {
      throw const FormatException('Invalid Discord webhook URL.');
    }
    return BotWebhookReference(parts[index + 1], parts[index + 2]);
  }
}

abstract interface class BotWebhookService {
  Future<String> create(
    String channelId,
    String name,
    String avatarUrl, {
    required CommandExecutionBudget budget,
  });
  Future<void> update(
    BotWebhookReference webhook, {
    String? name,
    String? avatarUrl,
    required CommandExecutionBudget budget,
  });
  Future<void> delete(
    BotWebhookReference webhook, {
    required CommandExecutionBudget budget,
  });
  Future<void> send(
    BotWebhookReference webhook,
    Map<String, dynamic> payload, {
    required CommandExecutionBudget budget,
  });
}

/// Values are fully evaluated before they reach this shared transport.
MessageBuilder buildBotWebhookMessage(Map<String, dynamic> payload) {
  final raw = payload['embed'];
  final embed = raw is Map
      ? Map<String, dynamic>.from(raw)
      : <String, dynamic>{};
  final builder = EmbedBuilder();
  if (embed['title'] != null) builder.title = embed['title'] as String;
  if (embed['description'] != null)
    builder.description = embed['description'] as String;
  if (embed['url'] != null && embed['title'] != null)
    builder.url = Uri.parse(embed['url'] as String);
  if (embed['color'] != null)
    builder.color = DiscordColor(embed['color'] as int);
  if (embed['author'] is Map) {
    final author = embed['author'] as Map;
    builder.author = EmbedAuthorBuilder(
      name: author['name'] as String,
      iconUrl: author['icon_url'] == null
          ? null
          : Uri.parse(author['icon_url'] as String),
    );
  }
  if (embed['footer'] is Map) {
    final footer = embed['footer'] as Map;
    builder.footer = EmbedFooterBuilder(
      text: footer['text'] as String,
      iconUrl: footer['icon_url'] == null
          ? null
          : Uri.parse(footer['icon_url'] as String),
    );
  }
  if (embed['thumbnail'] != null)
    builder.thumbnail = EmbedThumbnailBuilder(
      url: Uri.parse(embed['thumbnail'] as String),
    );
  if (embed['image'] != null)
    builder.image = EmbedImageBuilder(url: Uri.parse(embed['image'] as String));
  if (embed['timestamp'] != null)
    builder.timestamp = DateTime.parse(embed['timestamp'] as String);
  final content = payload['content'] as String? ?? '';
  return MessageBuilder(
    content: content.isEmpty ? null : content,
    embeds: builder.build().isEmpty ? null : [builder],
    allowedMentions: AllowedMentions(parse: []),
  );
}

void validateWebhookName(String name) {
  if (name.trim().length < 2 || name.length > 80)
    throw ArgumentError('Webhook name must contain 2–80 characters.');
}

Uri webhookImageUrl(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null ||
      !{'http', 'https'}.contains(uri.scheme) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    throw ArgumentError('An HTTP(S) image URL is required.');
  }
  return uri;
}

class DiscordBotWebhookService implements BotWebhookService {
  const DiscordBotWebhookService({
    required this.client,
    this.httpClientFactory,
  });
  final NyxxGateway client;
  final http.Client Function()? httpClientFactory;

  Future<ImageBuilder> loadAvatar(
    String url,
    CommandExecutionBudget budget,
  ) async {
    final uri = webhookImageUrl(url);
    final transport = httpClientFactory?.call() ?? http.Client();
    try {
      return await budget.run(() async {
        final response = await transport.send(http.Request('GET', uri));
        budget.check();
        if (response.statusCode != 200 ||
            (response.contentLength ?? 0) > 8 * 1024 * 1024) {
          await response.stream.listen((_) {}).cancel();
          throw StateError('Webhook avatar download failed or exceeds 8 MiB.');
        }
        final buffer = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          budget.check();
          if (buffer.length + chunk.length > 8 * 1024 * 1024)
            throw StateError('Webhook avatar exceeds 8 MiB.');
          buffer.add(chunk);
        }
        final bytes = buffer.takeBytes();
        final type = (response.headers['content-type'] ?? '').split(';').first;
        final format = {
          'image/png': 'png',
          'image/jpeg': 'jpeg',
          'image/gif': 'gif',
          'image/webp': 'webp',
        }[type];
        if (bytes.isEmpty || format == null)
          throw StateError('Unsupported webhook avatar image.');
        return ImageBuilder(data: bytes, format: format);
      });
    } finally {
      transport.close();
    }
  }

  @override
  Future<String> create(
    String channelId,
    String name,
    String avatarUrl, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    validateWebhookName(name);
    final id = await prepareBotWebhookCreate(
      client,
      channelId,
      name,
      budget: budget,
    );
    final avatar = avatarUrl.isEmpty
        ? null
        : await loadAvatar(avatarUrl, budget);
    budget.check();
    final result = await client.webhooks.create(
      WebhookBuilder(name: name, channelId: id, avatar: avatar),
    );
    budget.check();
    if (result.token == null)
      throw StateError('Created webhook has no usable token.');
    return BotWebhookReference(result.id.toString(), result.token!).url;
  });

  @override
  Future<void> update(
    BotWebhookReference webhook, {
    String? name,
    String? avatarUrl,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    if (name != null) validateWebhookName(name);
    final avatar = avatarUrl == null
        ? null
        : await loadAvatar(avatarUrl, budget);
    budget.check();
    final builder = WebhookUpdateBuilder(name: name);
    if (avatarUrl != null) builder.avatar = avatar;
    await client.webhooks.update(
      Snowflake.parse(webhook.id),
      builder,
      token: webhook.token,
    );
    budget.check();
  });

  @override
  Future<void> delete(
    BotWebhookReference webhook, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    await client.webhooks.delete(
      Snowflake.parse(webhook.id),
      token: webhook.token,
    );
    budget.check();
  });

  @override
  Future<void> send(
    BotWebhookReference webhook,
    Map<String, dynamic> payload, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final snapshot = Map<String, dynamic>.from(
      jsonDecode(jsonEncode(payload)) as Map,
    );
    final builder = buildBotWebhookMessage(snapshot);
    budget.check();
    await client.webhooks.execute(
      Snowflake.parse(webhook.id),
      builder,
      token: webhook.token,
      wait: true,
    );
    budget.check();
  });
}

Future<Snowflake> prepareBotWebhookCreate(
  NyxxGateway client,
  String channelId,
  String name, {
  required CommandExecutionBudget budget,
}) => budget.run(() async {
  validateWebhookName(name);
  final id = Snowflake.parse(channelId);
  final channel = await client.channels.fetch(id);
  budget.check();
  if (channel is! GuildChannel || channel is Thread) {
    throw StateError('Webhook creation requires a guild channel.');
  }
  final permissions = await DiscordBotPermissionQueryService(
    client: client,
    guildId: channel.guildId,
  ).memberPermissions(channelId: channelId, budget: budget);
  budget.check();
  if (!permissions.hasAll([Permissions.manageWebhooks.value])) {
    throw StateError('Manage Webhooks permission is required.');
  }
  return id;
});
