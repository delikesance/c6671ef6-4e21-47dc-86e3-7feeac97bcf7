import 'package:nyxx/nyxx.dart';

import '../services/bot_webhook_block_service.dart';

/// `editWebhook` block. See [BotWebhookBlockService.edit].
Future<Map<String, String>> editWebhookAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) => DiscordBotWebhookBlockService(
  client,
).edit(payload: payload, resolve: resolve ?? (s) => s);
