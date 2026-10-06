import 'package:nyxx/nyxx.dart';

/// Display stored flags without expanding Administrator.
/// CreateInvite and flag order match the official rolePerms example.
/// Other labels follow SDK names; the wiki has no exhaustive output table.
String formatRolePermissions(int permissions, {String separator = ','}) {
  final names = <String>[
    for (final entry in _displayFlags)
      if ((permissions & entry.key.value) != 0) entry.value,
  ];
  return names.isEmpty ? 'No Permissions' : names.join('$separator ');
}

final _displayFlags = <MapEntry<Flag<Permissions>, String>>[
  MapEntry(Permissions.createInstantInvite, 'CreateInvite'),
  MapEntry(Permissions.kickMembers, 'KickMembers'),
  MapEntry(Permissions.banMembers, 'BanMembers'),
  MapEntry(Permissions.administrator, 'Administrator'),
  MapEntry(Permissions.manageChannels, 'ManageChannels'),
  MapEntry(Permissions.manageGuild, 'ManageGuild'),
  MapEntry(Permissions.addReactions, 'AddReactions'),
  MapEntry(Permissions.viewAuditLog, 'ViewAuditLog'),
  MapEntry(Permissions.prioritySpeaker, 'PrioritySpeaker'),
  MapEntry(Permissions.stream, 'Stream'),
  MapEntry(Permissions.viewChannel, 'ViewChannel'),
  MapEntry(Permissions.sendMessages, 'SendMessages'),
  MapEntry(Permissions.sendTtsMessages, 'SendTtsMessages'),
  MapEntry(Permissions.manageMessages, 'ManageMessages'),
  MapEntry(Permissions.embedLinks, 'EmbedLinks'),
  MapEntry(Permissions.attachFiles, 'AttachFiles'),
  MapEntry(Permissions.readMessageHistory, 'ReadMessageHistory'),
  MapEntry(Permissions.mentionEveryone, 'MentionEveryone'),
  MapEntry(Permissions.useExternalEmojis, 'UseExternalEmojis'),
  MapEntry(Permissions.viewGuildInsights, 'ViewGuildInsights'),
  MapEntry(Permissions.connect, 'Connect'),
  MapEntry(Permissions.speak, 'Speak'),
  MapEntry(Permissions.muteMembers, 'MuteMembers'),
  MapEntry(Permissions.deafenMembers, 'DeafenMembers'),
  MapEntry(Permissions.moveMembers, 'MoveMembers'),
  MapEntry(Permissions.useVad, 'UseVoiceActivity'),
  MapEntry(Permissions.changeNickname, 'ChangeNickname'),
  MapEntry(Permissions.manageNicknames, 'ManageNicknames'),
  MapEntry(Permissions.manageRoles, 'ManageRoles'),
  MapEntry(Permissions.manageWebhooks, 'ManageWebhooks'),
  MapEntry(Permissions.manageGuildExpressions, 'ManageGuildExpressions'),
  MapEntry(Permissions.useApplicationCommands, 'UseApplicationCommands'),
  MapEntry(Permissions.requestToSpeak, 'RequestToSpeak'),
  MapEntry(Permissions.manageEvents, 'ManageEvents'),
  MapEntry(Permissions.manageThreads, 'ManageThreads'),
  MapEntry(Permissions.createPublicThreads, 'CreatePublicThreads'),
  MapEntry(Permissions.createPrivateThreads, 'CreatePrivateThreads'),
  MapEntry(Permissions.useExternalStickers, 'UseExternalStickers'),
  MapEntry(Permissions.sendMessagesInThreads, 'SendMessagesInThreads'),
  MapEntry(Permissions.useEmbeddedActivities, 'UseEmbeddedActivities'),
  MapEntry(Permissions.moderateMembers, 'ModerateMembers'),
  MapEntry(
    Permissions.viewCreatorMonetizationAnalytics,
    'ViewCreatorMonetizationAnalytics',
  ),
  MapEntry(Permissions.useSoundboard, 'UseSoundboard'),
  MapEntry(Permissions.createGuildExpressions, 'CreateGuildExpressions'),
  MapEntry(Permissions.createEvents, 'CreateEvents'),
  MapEntry(Permissions.useExternalSounds, 'UseExternalSounds'),
  MapEntry(Permissions.sendVoiceMessages, 'SendVoiceMessages'),
  MapEntry(Permissions.setVoiceChannelStatus, 'SetVoiceChannelStatus'),
  MapEntry(Permissions.sendPolls, 'SendPolls'),
  MapEntry(Permissions.useExternalApps, 'UseExternalApps'),
  MapEntry(Permissions.pinMessages, 'PinMessages'),
  MapEntry(Permissions.bypassSlowmode, 'BypassSlowmode'),
];
