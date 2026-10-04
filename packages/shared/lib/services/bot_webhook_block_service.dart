import 'dart:convert';

import 'package:nyxx/nyxx.dart';

import '../actions/handler_utils.dart' show resolvePayloadValues;
import '../actions/send_webhook.dart' show sendWebhookAction;

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

  /// Message construction (embeds, components, avatar) stays in
  /// send_webhook.dart: `buildWebhookMessage` is shared with the sandbox.
  @override
  Future<Map<String, String>> send({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) => sendWebhookAction(client, payload: payload, resolve: resolve);

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
