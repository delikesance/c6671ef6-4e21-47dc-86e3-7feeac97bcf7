import 'package:nyxx/nyxx.dart';

import '../services/bot_webhook_block_service.dart';

/// `deleteWebhook` block. See [BotWebhookBlockService.delete].
Future<Map<String, String>> deleteWebhookAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) => DiscordBotWebhookBlockService(
  client,
).delete(payload: payload, resolve: resolve ?? (s) => s);
