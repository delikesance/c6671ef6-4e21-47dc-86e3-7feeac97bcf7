import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';

import '../actions/handler_utils.dart' show resolvePayloadValues;
import '../actions/send_component_v2.dart';
import '../types/component.dart';

/// Webhook operations of the visual blocks `sendWebhook`, `editWebhook`,
/// `deleteWebhook`, `listWebhooks` and `getWebhook`. Each returns the block's
/// own result map (`{'error': ...}` on failure), shared by the historical
/// executor and the hidden `bc_*` functions. Distinct from [BotWebhookService]
/// (bot_webhook_service.dart), which serves the narrower BDFD webhook functions.
///
/// [resolve] resolves `((...))` in each payload field, as the blocks always did.
abstract interface class BotWebhookBlockService {
  Future<Map<String, String>> send({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> edit({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> delete({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> list({
    required Map<String, dynamic> payload,
    required Snowflake? fallbackChannelId,
    required Snowflake? fallbackGuildId,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> get({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
}

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return Snowflake(parsed);
}

({Snowflake? id, String? token}) _extractWebhookRef(
  Map<String, dynamic> payload,
  String Function(String)? resolve,
) {
  final rawWebhookId = payload['webhookId']?.toString() ?? '';
  final webhookId = resolve != null ? resolve(rawWebhookId) : rawWebhookId;
  final directId = _toSnowflake(webhookId);
  final directToken = payload['token']?.toString().trim();

  final rawUrl = payload['webhookUrl']?.toString().trim() ?? '';
  final url = resolve != null ? resolve(rawUrl) : rawUrl;
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return (id: directId, token: directToken);
  }

  final segments = uri.pathSegments;
  final webhooksIndex = segments.indexOf('webhooks');
  if (webhooksIndex == -1 || webhooksIndex + 2 >= segments.length) {
    return (id: directId, token: directToken);
  }

  final parsedId = _toSnowflake(segments[webhooksIndex + 1]);
  final parsedToken = segments[webhooksIndex + 2].trim();

  return (
    id: parsedId ?? directId,
    token: parsedToken.isNotEmpty ? parsedToken : directToken,
  );
}

Map<String, dynamic> _simpleWebhook(Webhook webhook) => {
  'id': webhook.id.toString(),
  'name': webhook.name,
  'channelId': webhook.channelId?.toString(),
  'guildId': webhook.guildId?.toString(),
  'type': webhook.type.value,
  // `Webhook.url` is a `Uri`, which `jsonEncode` cannot serialize.
  'url': webhook.url?.toString(),
  'hasToken': webhook.token != null,
};

class DiscordBotWebhookBlockService implements BotWebhookBlockService {
  const DiscordBotWebhookBlockService(this.client);
  final NyxxGateway client;

  /// Message construction (embeds, components) is [buildWebhookMessage],
  /// shared with the sandbox preview.
  @override
  Future<Map<String, String>> send({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) => _sendWebhook(client, payload: payload, resolve: resolve);

  @override
  Future<Map<String, String>> edit({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    final resolvedPayload = resolvePayloadValues(payload, resolve);
    try {
      final ref = _extractWebhookRef(resolvedPayload, resolve);
      if (ref.id == null) {
        return {'error': 'Missing webhookId (or webhookUrl)', 'webhookId': ''};
      }

      final name = resolvedPayload['name']?.toString().trim();
      final channelId = _toSnowflake(resolvedPayload['channelId']);
      final auditLogReason = resolvedPayload['reason']?.toString().trim();

      final updated = await client.webhooks.update(
        ref.id!,
        WebhookUpdateBuilder(
          name: (name != null && name.isNotEmpty) ? name : null,
          channelId: channelId,
        ),
        token: (ref.token != null && ref.token!.isNotEmpty) ? ref.token : null,
        auditLogReason: (auditLogReason != null && auditLogReason.isNotEmpty)
            ? auditLogReason
            : null,
      );

      return {
        'webhookId': updated.id.toString(),
        'name': updated.name ?? '',
        'url': (updated.url ?? '').toString(),
      };
    } catch (error) {
      return {'error': 'Failed to edit webhook: $error', 'webhookId': ''};
    }
  }

  @override
  Future<Map<String, String>> delete({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    final resolvedPayload = resolvePayloadValues(payload, resolve);
    try {
      final ref = _extractWebhookRef(resolvedPayload, resolve);
      if (ref.id == null) {
        return {'error': 'Missing webhookId (or webhookUrl)', 'webhookId': ''};
      }

      final reason = resolvedPayload['reason']?.toString().trim();

      await client.webhooks.delete(
        ref.id!,
        token: (ref.token != null && ref.token!.isNotEmpty) ? ref.token : null,
        auditLogReason: (reason != null && reason.isNotEmpty) ? reason : null,
      );

      return {'webhookId': ref.id.toString(), 'status': 'deleted'};
    } catch (error) {
      return {'error': 'Failed to delete webhook: $error', 'webhookId': ''};
    }
  }

  @override
  Future<Map<String, String>> get({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    final resolvedPayload = resolvePayloadValues(payload, resolve);
    try {
      final ref = _extractWebhookRef(resolvedPayload, resolve);
      if (ref.id == null) {
        return {'error': 'Missing webhookId (or webhookUrl)', 'webhook': ''};
      }

      final webhook = await client.webhooks.fetch(
        ref.id!,
        token: (ref.token != null && ref.token!.isNotEmpty) ? ref.token : null,
      );

      return {
        'webhook': jsonEncode(_simpleWebhook(webhook)),
        'webhookId': webhook.id.toString(),
      };
    } catch (error) {
      return {'error': 'Failed to get webhook: $error', 'webhook': ''};
    }
  }

  @override
  Future<Map<String, String>> list({
    required Map<String, dynamic> payload,
    required Snowflake? fallbackChannelId,
    required Snowflake? fallbackGuildId,
    required String Function(String) resolve,
  }) async {
    final resolvedPayload = resolvePayloadValues(payload, resolve);
    try {
      final channelId =
          _toSnowflake(resolvedPayload['channelId']) ?? fallbackChannelId;
      final guildId =
          _toSnowflake(resolvedPayload['guildId']) ?? fallbackGuildId;

      List<Webhook> webhooks;
      if (channelId != null) {
        webhooks = await client.webhooks.fetchChannelWebhooks(channelId);
      } else if (guildId != null) {
        webhooks = await client.webhooks.fetchGuildWebhooks(guildId);
      } else {
        return {
          'error': 'Missing channelId/guildId',
          'webhooks': jsonEncode(<Map<String, dynamic>>[]),
        };
      }

      final encoded = jsonEncode(webhooks.map(_simpleWebhook).toList());
      return {'webhooks': encoded, 'count': webhooks.length.toString()};
    } catch (error) {
      return {
        'error': 'Failed to list webhooks: $error',
        'webhooks': jsonEncode(<Map<String, dynamic>>[]),
      };
    }
  }
}

({Snowflake? id, String? token}) _extractSendWebhookRef(
  String webhookUrl,
  String webhookId,
  String token,
) {
  final directId = _toSnowflake(webhookId);
  final directToken = token.trim();

  if (directId != null && directToken.isNotEmpty) {
    return (id: directId, token: directToken);
  }

  final uri = Uri.tryParse(webhookUrl.trim());
  if (uri == null) {
    return (id: directId, token: directToken);
  }

  final segments = uri.pathSegments;
  final webhooksIndex = segments.indexOf('webhooks');
  if (webhooksIndex == -1 || webhooksIndex + 2 >= segments.length) {
    return (id: directId, token: directToken);
  }

  final parsedId = _toSnowflake(segments[webhooksIndex + 1]);
  final parsedToken = segments[webhooksIndex + 2].trim();

  return (
    id: parsedId ?? directId,
    token: parsedToken.isNotEmpty ? parsedToken : directToken,
  );
}

Future<Map<String, String>> _sendWebhook(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) async {
  resolve ??= (s) => s;
  if (payload['createWebhook'] == true) {
    return _createWebhook(client, payload: payload, resolve: resolve);
  }
  try {
    final webhookUrl = resolve((payload['webhookUrl'] ?? '').toString()).trim();
    final webhookId = resolve((payload['webhookId'] ?? '').toString()).trim();
    final token = resolve((payload['token'] ?? '').toString()).trim();
    final ref = _extractSendWebhookRef(webhookUrl, webhookId, token);
    if (ref.id == null || ref.token == null || ref.token!.isEmpty) {
      return {
        'error': 'Missing webhookId/token (or webhookUrl)',
        'messageId': '',
      };
    }

    final username = resolve((payload['username'] ?? '').toString()).trim();
    final avatarUrl = resolve((payload['avatarUrl'] ?? '').toString()).trim();
    final waitRaw = resolve((payload['wait'] ?? '').toString());
    final wait = payload['wait'] is bool
        ? payload['wait'] as bool
        : waitRaw.toLowerCase() == 'true';
    final threadId = _toSnowflake(
      resolve((payload['threadId'] ?? '').toString()),
    );

    final builder = buildWebhookMessage(payload, resolve);

    final message = await client.webhooks.execute(
      ref.id!,
      builder,
      token: ref.token!,
      wait: wait,
      threadId: threadId,
      username: username.isNotEmpty ? username : null,
      avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
    );

    return {
      'messageId': message?.id.toString() ?? '',
      'webhookId': ref.id.toString(),
      'status': wait ? 'sent' : 'queued',
    };
  } catch (error) {
    return {'error': 'Failed to send webhook message: $error', 'messageId': ''};
  }
}

/// Builds the same Discord payload for production sends and sandbox previews.
MessageBuilder buildWebhookMessage(
  Map<String, dynamic> payload,
  String Function(String) resolve,
) {
  final content = resolve((payload['content'] ?? '').toString());
  final embeds = <EmbedBuilder>[];
  for (final raw in (payload['embeds'] as List? ?? const []).take(10)) {
    if (raw is! Map) continue;
    final json = Map<String, dynamic>.from(raw);
    final embed = EmbedBuilder();
    final title = resolve((json['title'] ?? '').toString());
    final description = resolve((json['description'] ?? '').toString());
    if (title.isNotEmpty) embed.title = title;
    if (description.isNotEmpty) embed.description = description;
    final colorRaw = resolve((json['color'] ?? '').toString()).trim();
    if (colorRaw.isNotEmpty) {
      final color = colorRaw.startsWith('#')
          ? int.tryParse(colorRaw.substring(1), radix: 16)
          : int.tryParse(colorRaw, radix: 16);
      if (color != null) {
        embed.color = DiscordColor.fromRgb(
          (color >> 16) & 0xff,
          (color >> 8) & 0xff,
          color & 0xff,
        );
      }
    }
    final footer = json['footer'];
    final footerText = footer is Map
        ? resolve((footer['text'] ?? '').toString())
        : resolve((footer ?? '').toString());
    if (footerText.isNotEmpty) {
      embed.footer = EmbedFooterBuilder(text: footerText);
    }
    if (embed.build().isNotEmpty) embeds.add(embed);
  }

  List<ComponentBuilder>? components;
  bool isRichV2 = false;
  final componentPayload = payload['componentV2'] ?? payload['components'];
  if (componentPayload is Map) {
    try {
      final def = ComponentV2Definition.fromJson(
        Map<String, dynamic>.from(componentPayload),
      );
      isRichV2 = def.isRichV2;
      components = buildComponentNodes(definition: def, resolve: resolve);
    } catch (_) {}
  }

  return MessageBuilder(
    content: content.isNotEmpty ? content : null,
    embeds: embeds.isEmpty ? null : embeds,
    components: components,
    flags: isRichV2 ? MessageFlags(32768) : null,
  );
}

const _maxAvatarBytes = 8 * 1024 * 1024;

Future<ImageBuilder?> _webhookAvatar(String source) async {
  if (source.isEmpty) return null;
  final uri = Uri.tryParse(source);
  if (uri == null) throw const FormatException('Invalid webhook avatar URL');

  List<int> bytes;
  String format;
  if (uri.scheme == 'data') {
    final comma = source.indexOf(',');
    if (comma < 0 || !source.substring(0, comma).contains(';base64')) {
      throw const FormatException('Webhook avatar must be base64 image data');
    }
    format = source.substring(5, comma).split(';').first.split('/').last;
    bytes = base64Decode(source.substring(comma + 1));
  } else if (uri.scheme == 'http' || uri.scheme == 'https') {
    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw StateError('Webhook avatar download failed');
      }
      format = (response.headers['content-type'] ?? '')
          .split(';')
          .first
          .split('/')
          .last;
      final buffer = BytesBuilder(copy: false);
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 10),
      )) {
        buffer.add(chunk);
        if (buffer.length > _maxAvatarBytes) {
          throw StateError('Webhook avatar exceeds 8 MB');
        }
      }
      bytes = buffer.takeBytes();
    } finally {
      client.close();
    }
  } else {
    throw const FormatException('Webhook avatar must use HTTPS or data URL');
  }
  if (bytes.isEmpty || bytes.length > _maxAvatarBytes) {
    throw StateError('Webhook avatar must be between 1 byte and 8 MB');
  }
  if (format == 'jpg') format = 'jpeg';
  if (!{'png', 'jpeg', 'gif', 'webp'}.contains(format)) {
    throw const FormatException('Unsupported webhook avatar format');
  }
  return ImageBuilder(data: bytes, format: format);
}

Future<Map<String, String>> _createWebhook(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    final channelId = int.tryParse(
      resolve((payload['channelId'] ?? '').toString()),
    );
    final name = resolve((payload['name'] ?? '').toString()).trim();
    if (channelId == null || name.length < 2 || name.length > 80) {
      return {'error': 'Webhook needs a channel ID and a 2–80 character name'};
    }
    final avatar = await _webhookAvatar(
      resolve((payload['avatarUrl'] ?? '').toString()).trim(),
    );
    final webhook = await client.webhooks.create(
      WebhookBuilder(
        name: name,
        channelId: Snowflake(channelId),
        avatar: avatar,
      ),
    );
    final url =
        webhook.url?.toString() ??
        (webhook.token == null
            ? ''
            : 'https://discord.com/api/webhooks/${webhook.id}/${webhook.token}');
    return {'webhookId': webhook.id.toString(), 'url': url};
  } catch (error) {
    return {'error': 'Failed to create webhook: $error'};
  }
}
