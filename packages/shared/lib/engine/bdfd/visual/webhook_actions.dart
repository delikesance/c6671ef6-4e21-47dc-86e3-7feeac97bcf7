import 'package:nyxx/nyxx.dart' show Permissions;

import '../../../actions/permission_checks.dart' show checkBotGuildPermission;
import '../../../services/bot_webhook_block_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';
import 'message_actions.dart' show visualComponentFallbackChannel;

/// Webhook blocks on the native engine: sendWebhook, editWebhook,
/// deleteWebhook, listWebhooks and getWebhook. Parity with
/// `executeWebhooksAction`: the effect is [BotWebhookBlockService] (the same
/// code the historical executor runs), the payload keeps its `((...))` and is
/// resolved field by field by the service, the result is the same
/// (`url`/`webhookId`, the webhook list JSON, the webhook JSON) and a result
/// map carrying `error` fails the action with that exact text.
///
/// Hidden `bc_<type>` functions; no BDFD function covers these payloads.
final Map<BotCreatorActionType, ActionHandler> webhookActionHandlers = {
  BotCreatorActionType.sendWebhook: (call) => _mutation(
    call,
    (s) => s.send(payload: call.payload, resolve: call.resolve),
  ),
  BotCreatorActionType.editWebhook: (call) => _mutation(
    call,
    (s) => s.edit(payload: call.payload, resolve: call.resolve),
  ),
  BotCreatorActionType.deleteWebhook: (call) => _mutation(
    call,
    (s) => s.delete(payload: call.payload, resolve: call.resolve),
  ),
  BotCreatorActionType.listWebhooks: _list,
  BotCreatorActionType.getWebhook: _get,
};

bool _always(Action action) => true;

final Map<BotCreatorActionType, bool Function(Action)> webhookLeafPredicates = {
  for (final type in webhookActionHandlers.keys) type: _always,
};

BotWebhookBlockService _service(ActionCall call) {
  final client = call.env.client;
  if (client == null) {
    throw StateError('A Discord client is required for ${call.type.name}.');
  }
  return DiscordBotWebhookBlockService(client);
}

Future<String?> _mutation(
  ActionCall call,
  Future<Map<String, String>> Function(BotWebhookBlockService service) run,
) async {
  final result = await run(_service(call));
  if (result['error'] != null) throw Exception(result['error']);
  return result['url'] ?? result['webhookId'] ?? '';
}

Future<String?> _list(ActionCall call) async {
  final guild = call.env.guildSnowflake;
  if (guild != null) {
    final permError = await checkBotGuildPermission(
      call.env.client!,
      guildId: guild,
      requiredPermissions: [Permissions.manageWebhooks],
      actionLabel: 'list webhooks',
      cache: call.env.permissionCache,
    );
    if (permError != null) throw Exception(permError);
  }
  final result = await _service(call).list(
    payload: call.payload,
    fallbackChannelId: visualComponentFallbackChannel(call),
    fallbackGuildId: guild,
    resolve: call.resolve,
  );
  if (result['error'] != null) throw Exception(result['error']);
  return result['webhooks'] ?? '[]';
}

Future<String?> _get(ActionCall call) async {
  final result = await _service(
    call,
  ).get(payload: call.payload, resolve: call.resolve);
  if (result['error'] != null) throw Exception(result['error']);
  return result['webhook'] ?? '';
}
