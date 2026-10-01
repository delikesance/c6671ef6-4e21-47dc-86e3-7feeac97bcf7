import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';

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

Future<Map<String, String>> createWebhookAction(
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
