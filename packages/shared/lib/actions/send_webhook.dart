import 'package:nyxx/nyxx.dart';
import '../types/component.dart';
import 'send_component_v2.dart';
import 'create_webhook.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

({Snowflake? id, String? token}) _extractWebhookRef(
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

Future<Map<String, String>> sendWebhookAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) async {
  resolve ??= (s) => s;
  if (payload['createWebhook'] == true) {
    return createWebhookAction(client, payload: payload, resolve: resolve);
  }
  try {
    final webhookUrl = resolve((payload['webhookUrl'] ?? '').toString()).trim();
    final webhookId = resolve((payload['webhookId'] ?? '').toString()).trim();
    final token = resolve((payload['token'] ?? '').toString()).trim();
    final ref = _extractWebhookRef(webhookUrl, webhookId, token);
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
