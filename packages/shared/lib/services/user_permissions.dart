import 'package:nyxx/nyxx.dart';

/// Stored flags in Discord bit order, with labels matching the userPerms example.
/// Future flags without a known label are omitted. Administrator is not expanded.
String formatUserPermissions(
  int mask, {
  required int amount,
  required String separator,
}) {
  if (mask < 0 || amount < -1) {
    throw ArgumentError('Invalid permissions or amount.');
  }
  final names = [
    for (final flag in _flags)
      if ((mask & flag.key.value) != 0) flag.value,
  ];
  return (amount == -1 ? names : names.take(amount)).join(separator);
}

final _flags = <MapEntry<Flag<Permissions>, String>>[
  MapEntry(Permissions.createInstantInvite, 'CREATE_INSTANT_INVITE'),
  MapEntry(Permissions.kickMembers, 'KICK_MEMBERS'),
  MapEntry(Permissions.banMembers, 'BAN_MEMBERS'),
  MapEntry(Permissions.administrator, 'ADMINISTRATOR'),
  MapEntry(Permissions.manageChannels, 'MANAGE_CHANNELS'),
  MapEntry(Permissions.manageGuild, 'MANAGE_GUILD'),
  MapEntry(Permissions.addReactions, 'ADD_REACTIONS'),
  MapEntry(Permissions.viewAuditLog, 'VIEW_AUDIT_LOG'),
  MapEntry(Permissions.prioritySpeaker, 'PRIORITY_SPEAKER'),
  MapEntry(Permissions.stream, 'STREAM'),
  MapEntry(Permissions.viewChannel, 'VIEW_CHANNEL'),
  MapEntry(Permissions.sendMessages, 'SEND_MESSAGES'),
  MapEntry(Permissions.sendTtsMessages, 'SEND_TTS_MESSAGES'),
  MapEntry(Permissions.manageMessages, 'MANAGE_MESSAGES'),
  MapEntry(Permissions.embedLinks, 'EMBED_LINKS'),
  MapEntry(Permissions.attachFiles, 'ATTACH_FILES'),
  MapEntry(Permissions.readMessageHistory, 'READ_MESSAGE_HISTORY'),
  MapEntry(Permissions.mentionEveryone, 'MENTION_EVERYONE'),
  MapEntry(Permissions.useExternalEmojis, 'USE_EXTERNAL_EMOJIS'),
  MapEntry(Permissions.viewGuildInsights, 'VIEW_GUILD_INSIGHTS'),
  MapEntry(Permissions.connect, 'CONNECT'),
  MapEntry(Permissions.speak, 'SPEAK'),
  MapEntry(Permissions.muteMembers, 'MUTE_MEMBERS'),
  MapEntry(Permissions.deafenMembers, 'DEAFEN_MEMBERS'),
  MapEntry(Permissions.moveMembers, 'MOVE_MEMBERS'),
  MapEntry(Permissions.useVad, 'USE_VAD'),
  MapEntry(Permissions.changeNickname, 'CHANGE_NICKNAME'),
  MapEntry(Permissions.manageNicknames, 'MANAGE_NICKNAMES'),
  MapEntry(Permissions.manageRoles, 'MANAGE_ROLES'),
  MapEntry(Permissions.manageWebhooks, 'MANAGE_WEBHOOKS'),
  MapEntry(Permissions.manageGuildExpressions, 'MANAGE_GUILD_EXPRESSIONS'),
  MapEntry(Permissions.useApplicationCommands, 'USE_APPLICATION_COMMANDS'),
  MapEntry(Permissions.requestToSpeak, 'REQUEST_TO_SPEAK'),
  MapEntry(Permissions.manageEvents, 'MANAGE_EVENTS'),
  MapEntry(Permissions.manageThreads, 'MANAGE_THREADS'),
  MapEntry(Permissions.createPublicThreads, 'CREATE_PUBLIC_THREADS'),
  MapEntry(Permissions.createPrivateThreads, 'CREATE_PRIVATE_THREADS'),
  MapEntry(Permissions.useExternalStickers, 'USE_EXTERNAL_STICKERS'),
  MapEntry(Permissions.sendMessagesInThreads, 'SEND_MESSAGES_IN_THREADS'),
  MapEntry(Permissions.useEmbeddedActivities, 'USE_EMBEDDED_ACTIVITIES'),
  MapEntry(Permissions.moderateMembers, 'MODERATE_MEMBERS'),
  MapEntry(
    Permissions.viewCreatorMonetizationAnalytics,
    'VIEW_CREATOR_MONETIZATION_ANALYTICS',
  ),
  MapEntry(Permissions.useSoundboard, 'USE_SOUNDBOARD'),
  MapEntry(Permissions.createGuildExpressions, 'CREATE_GUILD_EXPRESSIONS'),
  MapEntry(Permissions.createEvents, 'CREATE_EVENTS'),
  MapEntry(Permissions.useExternalSounds, 'USE_EXTERNAL_SOUNDS'),
  MapEntry(Permissions.sendVoiceMessages, 'SEND_VOICE_MESSAGES'),
  MapEntry(Permissions.setVoiceChannelStatus, 'SET_VOICE_CHANNEL_STATUS'),
  MapEntry(Permissions.sendPolls, 'SEND_POLLS'),
  MapEntry(Permissions.useExternalApps, 'USE_EXTERNAL_APPS'),
  MapEntry(Permissions.pinMessages, 'PIN_MESSAGES'),
  MapEntry(Permissions.bypassSlowmode, 'BYPASS_SLOWMODE'),
];
