import 'package:nyxx/nyxx.dart' show Flag, Permissions, Snowflake;

import '../../../services/bot_automod_service.dart';
import '../../../services/bot_guild_admin_service.dart';
import '../../../services/bot_poll_service.dart';
import '../../../services/bot_voice_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';
import 'message_actions.dart' show visualClient, visualResolvedFallbackChannel;

/// Poll, voice moderation, AutoMod, guild settings and onboarding blocks on the
/// native engine: createPoll, endPoll, moveToVoiceChannel, disconnectFromVoice,
/// serverMuteMember, serverDeafenMember, updateGuild, updateAutoMod,
/// createAutoModRule, deleteAutoModRule, listAutoModRules, getGuildOnboarding
/// and updateGuildOnboarding.
///
/// None has a BDFD function. The Discord logic lives in [BotPollService],
/// [BotVoiceService], [BotAutoModService] and [BotGuildAdminService] (shared
/// with the historical block functions); these handlers reproduce the branches
/// of the historical loop: the bot permission pre-checks of the poll blocks, the
/// field-by-field placeholder resolution (including the quirks: `updateAutoMod`
/// only resolves `ruleId`, `endPoll` resolves its ids twice), `results[key]`,
/// the `variables['<key>.*']` mirrors and the failure messages.
final Map<BotCreatorActionType, ActionHandler> adminActionHandlers = {
  BotCreatorActionType.createPoll: _createPoll,
  BotCreatorActionType.endPoll: _endPoll,
  BotCreatorActionType.moveToVoiceChannel: (call) => _voice(
    call,
    (s, guild) => s.moveToVoiceChannel(
      guildId: guild,
      payload: call.payload,
      resolve: call.resolve,
    ),
    'moved',
  ),
  BotCreatorActionType.disconnectFromVoice: (call) => _voice(
    call,
    (s, guild) => s.disconnectFromVoice(
      guildId: guild,
      payload: call.payload,
      resolve: call.resolve,
    ),
    'disconnected',
  ),
  BotCreatorActionType.serverMuteMember: (call) => _voice(
    call,
    (s, guild) => s.serverMuteMember(
      guildId: guild,
      payload: call.payload,
      resolve: call.resolve,
    ),
    'muted',
  ),
  BotCreatorActionType.serverDeafenMember: (call) => _voice(
    call,
    (s, guild) => s.serverDeafenMember(
      guildId: guild,
      payload: call.payload,
      resolve: call.resolve,
    ),
    'deafened',
  ),
  BotCreatorActionType.updateGuild: _updateGuild,
  BotCreatorActionType.updateAutoMod: _updateAutoMod,
  BotCreatorActionType.createAutoModRule: _createAutoModRule,
  BotCreatorActionType.deleteAutoModRule: _deleteAutoModRule,
  BotCreatorActionType.listAutoModRules: _listAutoModRules,
  BotCreatorActionType.getGuildOnboarding: _getOnboarding,
  BotCreatorActionType.updateGuildOnboarding: _updateOnboarding,
};

/// Types the historical loop handles in its `switch`: its trace (and the numeric
/// "last message" quirk) is recorded only while a `$debug` profile or replay
/// capture runs.
final Set<BotCreatorActionType> adminProfilingOnlyTraceTypes = Set.unmodifiable(
  adminActionHandlers.keys,
);

bool _always(Action action) => true;

/// Every payload of these types runs natively.
final Map<BotCreatorActionType, bool Function(Action)> adminLeafPredicates = {
  for (final type in adminActionHandlers.keys) type: _always,
};

BotPollService _poll(ActionCall call) =>
    call.env.pollService ?? DiscordBotPollService(visualClient(call));
BotVoiceService _voiceService(ActionCall call) =>
    call.env.voiceService ?? DiscordBotVoiceService(visualClient(call));
BotAutoModService _autoMod(ActionCall call) =>
    call.env.autoModService ?? DiscordBotAutoModService(visualClient(call));
BotGuildAdminService _guildAdmin(ActionCall call) =>
    call.env.guildAdminService ??
    DiscordBotGuildAdminService(visualClient(call));

/// Unwraps the `{'error': ...}` result of a service like the historical branch.
Map<String, String> _checked(Map<String, String> result) {
  if (result['error'] != null) throw Exception(result['error']);
  return result;
}

Future<void> _requirePollPermission(
  ActionCall call,
  Flag<Permissions> permission,
  String label,
) async {
  final guildId = call.env.guildSnowflake;
  if (guildId == null) return;
  final error = await _poll(call).guildPermissionError(
    guildId: guildId,
    permissions: [permission],
    actionLabel: label,
    cache: call.env.permissionCache,
  );
  if (error != null) throw Exception(error);
}

Future<String?> _createPoll(ActionCall call) async {
  await _requirePollPermission(call, Permissions.sendMessages, 'create polls');
  final result = _checked(
    await _poll(call).createPoll(
      payload: call.payload,
      fallbackChannelId: visualResolvedFallbackChannel(call.env),
      resolve: call.resolve,
    ),
  );
  final variables = call.env.variables;
  variables['${call.key}.messageId'] = result['messageId'] ?? '';
  variables['${call.key}.pollId'] = result['pollId'] ?? '';
  return result['messageId'] ?? '';
}

Future<String?> _endPoll(ActionCall call) async {
  await _requirePollPermission(call, Permissions.manageMessages, 'end polls');
  // The historical branch resolves both ids itself and the action resolves the
  // whole payload once more.
  final resolved = Map<String, dynamic>.from(call.payload);
  for (final field in const ['channelId', 'messageId']) {
    if (call.payload.containsKey(field)) {
      resolved[field] = call.resolve(call.payload[field].toString());
    }
  }
  final result = _checked(
    await _poll(call).endPoll(
      payload: resolved,
      fallbackChannelId: visualResolvedFallbackChannel(call.env),
      resolve: call.resolve,
    ),
  );
  return result['status'] ?? 'ended';
}

Future<String?> _voice(
  ActionCall call,
  Future<Map<String, String>> Function(BotVoiceService, Snowflake?) run,
  String defaultStatus,
) async {
  final result = _checked(
    await run(_voiceService(call), call.env.guildSnowflake),
  );
  return result['status'] ?? defaultStatus;
}

Future<String?> _updateGuild(ActionCall call) async {
  final result = _checked(
    await _guildAdmin(call).updateGuild(
      guildId: call.env.guildSnowflake,
      payload: call.payload,
      resolve: call.resolve,
    ),
  );
  return result['guildId'] ?? '';
}

Future<String?> _updateAutoMod(ActionCall call) async {
  // Only `ruleId` is resolved; every other field is used as stored.
  final resolved = Map<String, dynamic>.from(call.payload);
  if (call.payload.containsKey('ruleId')) {
    resolved['ruleId'] = call.resolve(call.payload['ruleId'].toString());
  }
  final result = _checked(
    await _autoMod(
      call,
    ).updateAutoMod(guildId: call.env.guildSnowflake, payload: resolved),
  );
  return result['status'] ?? 'OK';
}

Future<String?> _createAutoModRule(ActionCall call) async {
  final result = _checked(
    await _autoMod(call).createAutoModRule(
      guildId: call.env.guildSnowflake,
      payload: call.payload,
      resolve: call.resolve,
    ),
  );
  final variables = call.env.variables;
  variables['${call.key}.ruleId'] = result['ruleId'] ?? '';
  variables['${call.key}.name'] = result['name'] ?? '';
  return result['ruleId'] ?? '';
}

Future<String?> _deleteAutoModRule(ActionCall call) async {
  final result = _checked(
    await _autoMod(call).deleteAutoModRule(
      guildId: call.env.guildSnowflake,
      payload: call.payload,
      resolve: call.resolve,
    ),
  );
  return result['status'] ?? 'deleted';
}

Future<String?> _listAutoModRules(ActionCall call) async {
  final result = _checked(
    await _autoMod(call).listAutoModRules(guildId: call.env.guildSnowflake),
  );
  final variables = call.env.variables;
  variables['${call.key}.rulesJson'] = result['rulesJson'] ?? '[]';
  variables['${call.key}.count'] = result['count'] ?? '0';
  return result['rulesJson'] ?? '[]';
}

Future<String?> _getOnboarding(ActionCall call) async {
  final result = _checked(
    await _guildAdmin(
      call,
    ).getGuildOnboarding(guildId: call.env.guildSnowflake),
  );
  final variables = call.env.variables;
  variables['${call.key}.onboardingJson'] = result['onboardingJson'] ?? '{}';
  variables['${call.key}.enabled'] = result['enabled'] ?? 'false';
  return result['onboardingJson'] ?? '{}';
}

Future<String?> _updateOnboarding(ActionCall call) async {
  final result = _checked(
    await _guildAdmin(call).updateGuildOnboarding(
      guildId: call.env.guildSnowflake,
      payload: call.payload,
      resolve: call.resolve,
    ),
  );
  return result['status'] ?? 'updated';
}
