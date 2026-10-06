import 'package:nyxx/nyxx.dart';
import '../services/respond_with_message.dart';

// Compatibility entry point for visual blocks.
Future<Map<String, dynamic>> respondWithMessageAction(
  Interaction? interaction, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  required String botId,
  NyxxGateway? client,
  Snowflake? fallbackChannelId,
  Snowflake? fallbackMessageId,
  Map<String, String>? variables,
}) => respondWithMessage(
  interaction,
  payload: payload,
  resolve: resolve,
  botId: botId,
  client: client,
  fallbackChannelId: fallbackChannelId,
  fallbackMessageId: fallbackMessageId,
  variables: variables,
);
