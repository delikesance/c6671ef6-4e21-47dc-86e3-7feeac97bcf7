part of '../event_contexts.dart';

Future<EventExecutionContext> buildGuildUpdateEventContext(
  GuildUpdateEvent event,
) async {
  final count = await getGuildMemberCount(
    event.guild,
    client: event.guild.manager.client,
    guildId: event.guild.id,
  );

  final oldCount = await getGuildMemberCount(
    event.oldGuild,
    client: event.guild.manager.client,
    guildId: event.guild.id,
  );
  return _baseEventContext(
    eventName: 'guildUpdate',
    guildId: event.guild.id,
    channelId: null,
    userId: null,
    extra: <String, String>{
      'guild.name': event.guild.name,
      'guild.memberCount': count.toString(),
      'guild.systemChannelId':
          event.guild.systemChannelId?.toString() ?? 'unknown',
      'guild.oldSystemChannelId':
          event.oldGuild?.systemChannelId?.toString() ?? 'unknown',
      'guild.oldGuild.name': event.oldGuild?.name ?? 'unknown',
      'guild.oldGuild.memberCount': oldCount.toString(),
    },
  );
}
