part of '../event_contexts.dart';

Future<EventExecutionContext> buildGuildCreateEventContext(
  GuildCreateEvent event,
) async {
  final count = await getGuildMemberCount(
    event.guild,
    client: event.guild.manager.client,
    guildId: event.guild.id,
  );
  return _baseEventContext(
    eventName: 'guildCreate',
    guildId: event.guild.id,
    channelId: null,
    userId: null,
    extra: <String, String>{
      'guild.name': event.guild.name,
      'guild.memberCount': count.toString(),
    },
  );
}
