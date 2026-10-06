import 'dart:async';
import 'dart:convert';
import 'package:nyxx/nyxx.dart';
import '../utils/global.dart';
import '../services/bot_role_query_service.dart';
import '../services/bot_channel_query_service.dart';

/// Raised by local fixture gateways when an entity is genuinely absent.
class DiscordEntityNotFound implements Exception {
  const DiscordEntityNotFound();
}

class DiscordEntityFetcher {
  /// Deduplicates in-flight requests across all instances to prevent race conditions
  /// and redundant network calls for the same entity in the same batch.
  static final Map<String, Future<dynamic>> _inFlight = {};

  static Future<void> hydrateEntity(
    NyxxGateway gateway,
    String scope,
    String contextId,
    Map<String, String> variables, {
    Map<String, dynamic>? cache,
  }) async {
    if (scope == 'banLookup') {
      final parts = contextId.split(';');
      final userId = _parseSnowflake(parts.first);
      final guildId = parts.length > 1 && parts[1].isNotEmpty
          ? _parseSnowflake(parts[1])
          : _resolveGuildId(variables);
      if (userId == null || guildId == null) return;
      Ban? ban;
      try {
        ban = await gateway.guilds.fetchBan(guildId, userId);
      } on HttpResponseError catch (error) {
        if (error.statusCode != 404) rethrow;
      } on DiscordEntityNotFound {
        // An absent ban is a valid negative lookup.
      }
      final userKey = userId.toString();
      final guildKey = guildId.toString();
      variables['member[$userKey].isBanned'] = (ban != null).toString();
      variables['ban.reason[$userKey]'] = ban?.reason ?? '';
      variables['ban.reason[$userKey;$guildKey]'] = ban?.reason ?? '';
      return;
    }
    final id = _parseSnowflake(contextId);
    if (id == null &&
        scope != 'getMessage' &&
        scope != 'getmessage' &&
        scope != 'getReactions' &&
        scope != 'getreactions' &&
        scope != 'getEmbedData' &&
        scope != 'getembeddata' &&
        scope != 'emojiCount' &&
        scope != 'serverEmojis' &&
        scope != 'roleBoundary' &&
        scope != 'roleBoundaryWithPerms' &&
        scope != 'emoji' &&
        scope != 'role' &&
        scope != 'channel' &&
        scope != 'channelFind' &&
        scope != 'userFind' &&
        scope != 'roleMembers' &&
        scope != 'memberRoleAt' &&
        scope != 'channelSearch' &&
        scope != 'channelList' &&
        scope != 'randomGuild' &&
        scope != 'randomUser' &&
        scope != 'guildExists') {
      return;
    }

    final flightKey =
        '${identityHashCode(gateway)}:${_resolveGuildId(variables)}:${_resolveChannelId(variables)}:$scope:$contextId';

    // Check if we already have this entity in our session cache
    if (cache != null && cache.containsKey(flightKey)) {
      final cached = cache[flightKey];
      _populateEntityVariables(variables, scope, contextId, cached);
      return;
    }

    // Deduplicate in-flight requests
    if (_inFlight.containsKey(flightKey)) {
      final entity = await _inFlight[flightKey];
      _populateEntityVariables(variables, scope, contextId, entity);
      return;
    }

    final completer = Completer<dynamic>();
    _inFlight[flightKey] = completer.future;
    // The initiating caller receives errors directly; also consume the shared
    // future's error when no concurrent caller subscribed to it.
    unawaited(
      completer.future.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );

    try {
      dynamic fetchedEntity;

      switch (scope) {
        case 'memberRoleAt':
          final parts = contextId.split(';');
          if (parts.length != 3) break;
          final userId = _parseSnowflake(parts[0]);
          final index = int.tryParse(parts[1]);
          final guildId = parts[2].isEmpty
              ? _resolveGuildId(variables)
              : _parseSnowflake(parts[2]);
          final outputKey = _key('memberRoleAt', contextId, 'id');
          variables[outputKey] = '';
          if (userId == null || guildId == null || index == null || index < 1) {
            break;
          }
          try {
            final member = await gateway.guilds[guildId].members.fetch(userId);
            final roleIds = member.roleIds.toSet();
            final roles =
                (await gateway.guilds[guildId].roles.list())
                    .where((role) => roleIds.contains(role.id))
                    .toList()
                  ..sort((a, b) => b.position.compareTo(a.position));
            if (index <= roles.length) {
              variables[outputKey] = roles[index - 1].id.toString();
            }
          } on DiscordEntityNotFound {
            // A missing member has no roles.
          } on HttpResponseError catch (error) {
            if (error.statusCode != 404) rethrow;
          }
          break;
        case 'roleMembers':
          final parts = contextId.split(';');
          if (parts.length != 3) break;
          final roleId = _parseSnowflake(parts[0]);
          final guildId = parts[2].isEmpty
              ? _resolveGuildId(variables)
              : _parseSnowflake(parts[2]);
          final outputKey = _key('roleMembers', contextId, 'list');
          variables[outputKey] = '';
          if (roleId == null || guildId == null) break;
          final separator = parts[1] == '__default__' ? ', ' : parts[1];
          final matches = <String>[];
          Snowflake? after;
          while (true) {
            final page = await gateway.guilds[guildId].members.list(
              limit: 1000,
              after: after,
            );
            for (final member in page) {
              if (member.roleIds.contains(roleId)) {
                matches.add('<@${member.id}>');
              }
            }
            if (page.length < 1000 ||
                (after != null && page.last.id.value <= after.value)) {
              break;
            }
            after = page.last.id;
          }
          variables[outputKey] = matches.join(separator);
          break;
        case 'userFind':
          final parts = contextId.split(';');
          final query = parts.first.trim();
          final fallbackToAuthor = parts.length < 2 || parts[1] != 'no';
          final outputKey = _key('userFind', contextId, 'id');
          variables[outputKey] = fallbackToAuthor
              ? (variables['author.id'] ?? '')
              : '';
          final guildId = _resolveGuildId(variables);
          if (guildId == null || query.isEmpty) break;
          final mention = RegExp(r'^<@!?(\d+)>$').firstMatch(query);
          final targetId = _parseSnowflake(mention?.group(1) ?? query);
          if (targetId != null) {
            try {
              await gateway.guilds[guildId].members.fetch(targetId);
              variables[outputKey] = targetId.toString();
            } on DiscordEntityNotFound {
              // A missing guild member uses the requested fallback.
            } on HttpResponseError catch (error) {
              if (error.statusCode != 404) rethrow;
            }
          } else {
            final matches = await gateway.guilds[guildId].members.search(
              query,
              limit: 100,
            );
            if (matches.isNotEmpty) {
              final exact = matches.where(
                (member) =>
                    member.user?.username.toLowerCase() ==
                        query.toLowerCase() ||
                    member.nick?.toLowerCase() == query.toLowerCase(),
              );
              variables[outputKey] =
                  (exact.isNotEmpty ? exact.first : matches.first).id
                      .toString();
            }
          }
          break;
        case 'randomGuild':
          variables['random.guildIds'] = jsonEncode(
            gateway.guilds.cache.keys
                .map((guildId) => guildId.toString())
                .toList(),
          );
          break;

        case 'user':
          try {
            final user = await gateway.users.fetch(id!);
            fetchedEntity = user;
            _populateUserVariables(variables, contextId, user);
          } on DiscordEntityNotFound {
            variables[_key('user', contextId, 'exists')] = 'false';
            fetchedEntity = false;
          } on HttpResponseError catch (error) {
            if (error.statusCode != 404) rethrow;
            variables[_key('user', contextId, 'exists')] = 'false';
            fetchedEntity = false;
          }
          break;

        case 'member':
          final guildId = _resolveGuildId(variables);
          if (guildId == null) {
            final user = await gateway.users.fetch(id!);
            fetchedEntity = user;
            _populateUserVariables(variables, contextId, user);
            break;
          }

          variables[_key('member', contextId, 'roles')] = '';
          variables[_key('member', contextId, 'roleNamesJson')] = '[]';
          variables[_key('member', contextId, 'isAdmin')] = 'false';
          variables[_key('member', contextId, 'isTimedOut')] = 'false';
          variables[_key('member', contextId, 'permissions')] = '';
          try {
            final member = await gateway.guilds[guildId].members.fetch(id!);
            fetchedEntity = member;
            final guild = await gateway.guilds[guildId].get();
            _populateMemberVariables(
              variables,
              contextId,
              member,
              guild: guild,
            );
            if (member.user != null) {
              _populateUserVariables(variables, contextId, member.user!);
            }
          } catch (_) {
            // Missing members have no roles or permissions.
          }
          break;

        case 'channel':
          final guildId = _resolveGuildId(variables);
          variables[_key('channel', contextId, 'exists')] = 'false';
          Channel? channel;
          if (id != null) {
            try {
              final candidate = await gateway.channels.fetch(id);
              if (guildId == null ||
                  (candidate is GuildChannel && candidate.guildId == guildId)) {
                channel = candidate;
              }
            } catch (_) {
              // Missing IDs resolve to false/empty, like missing role IDs.
            }
          } else if (guildId != null) {
            final matches = (await readDiscordChannels(
              gateway,
              guildId,
            )).where((item) => item.name == contextId).toList();
            if (matches.isNotEmpty) channel = matches.first as Channel;
          }
          fetchedEntity = channel;
          if (channel != null) {
            _populateChannelVariables(variables, 'channel', contextId, channel);
          }
          break;

        case 'channelFind':
          final guildId = _resolveGuildId(variables);
          variables[_key(scope, contextId, 'id')] = '';
          if (guildId != null && contextId.isNotEmpty) {
            final matches = (await readDiscordChannels(gateway, guildId))
                .where(
                  (item) =>
                      item.name.toLowerCase().contains(contextId.toLowerCase()),
                )
                .toList();
            if (matches.isNotEmpty) {
              final channel = matches.first as Channel;
              fetchedEntity = channel;
              _populateChannelVariables(variables, scope, contextId, channel);
            }
          }
          break;

        case 'channelSearch':
          final parts = contextId.split(';');
          final guildId = parts.length == 2 && parts[0].isNotEmpty
              ? _parseSnowflake(parts[0])
              : _resolveGuildId(variables);
          final pattern = parts.length == 2 ? parts[1] : contextId;
          variables[_key(scope, contextId, 'exists')] = 'false';
          if (guildId != null && pattern.isNotEmpty) {
            final wildcard = RegExp(
              '^${RegExp.escape(pattern).replaceAll(r'\*', '.*')}\$',
            );
            final matches = (await readDiscordChannels(
              gateway,
              guildId,
            )).where((item) => wildcard.hasMatch(item.name));
            variables[_key(scope, contextId, 'exists')] = matches.isNotEmpty
                .toString();
          }
          break;

        case 'channelList':
          final parts = contextId.split(';');
          if (parts.length != 3) break;
          final categoryId = parts[0];
          final separator = parts[1] == '__default__' ? ', ' : parts[1];
          final guildId = parts[2].isEmpty
              ? _resolveGuildId(variables)
              : _parseSnowflake(parts[2]);
          if (guildId == null) break;
          final all = await readDiscordChannels(gateway, guildId);
          final categories = all.whereType<GuildCategory>().toList();
          final channels = all.where((item) => item is! GuildCategory).toList();
          final selected = categoryId == 'all'
              ? all
              : channels
                    .where((item) => item.parentId.toString() == categoryId)
                    .toList();
          variables[_key(scope, contextId, 'names')] = selected
              .map((item) => item.name)
              .join(separator);
          variables[_key(
            scope,
            contextId,
            'count',
          )] = (categoryId == 'all' ? channels.length : selected.length)
              .toString();
          variables[_key(scope, contextId, 'categoryCount')] = categories.length
              .toString();
          break;

        case 'randomChannel':
        case 'randomCategory':
          final guildId = _parseSnowflake(contextId);
          if (guildId == null) break;
          final channels = await readDiscordChannels(gateway, guildId);
          final Iterable<GuildChannel> candidates = scope == 'randomCategory'
              ? channels.whereType<GuildCategory>()
              : channels;
          for (final channel in candidates) {
            _populateChannelVariables(
              variables,
              'channel',
              channel.id.toString(),
              channel as Channel,
            );
          }
          variables[scope == 'randomCategory'
              ? 'random.categoryIds'
              : 'random.channelIds'] = jsonEncode(
            candidates.map((channel) => channel.id.toString()).toList(),
          );
          break;

        case 'randomRole':
          final guildId = _parseSnowflake(contextId);
          if (guildId == null) break;
          final roles = await gateway.guilds[guildId].roles.list();
          for (final role in roles) {
            _populateRoleVariables(variables, role.id.toString(), role);
          }
          variables['random.roleIds'] = jsonEncode(
            roles.map((role) => role.id.toString()).toList(),
          );
          break;

        case 'randomUser':
          final guildId = _parseSnowflake(contextId);
          if (guildId == null) break;
          final ids = <String>[];
          final names = <String, String>{};
          Snowflake? after;
          while (true) {
            final page = await gateway.guilds[guildId].members.list(
              limit: 1000,
              after: after,
            );
            for (final member in page) {
              final memberId = member.id.toString();
              ids.add(memberId);
              names[memberId] =
                  member.nick ??
                  member.user?.globalName ??
                  member.user?.username ??
                  memberId;
            }
            if (page.length < 1000 ||
                (after != null && page.last.id.value <= after.value)) {
              break;
            }
            after = page.last.id;
          }
          variables['random.userIds'] = jsonEncode(ids);
          variables['random.userNames'] = jsonEncode(names);
          break;

        case 'guild':
          final guild = await gateway.guilds.fetch(id!);
          fetchedEntity = guild;
          _populateGuildVariables(variables, contextId, guild);
          break;

        case 'guildExists':
          variables[_key('guild', contextId, 'exists')] = 'false';
          if (id == null) {
            fetchedEntity = false;
            break;
          }
          try {
            await gateway.guilds.fetch(id);
            fetchedEntity = true;
            variables[_key('guild', contextId, 'exists')] = 'true';
          } catch (_) {
            fetchedEntity = false;
          }
          break;

        case 'role':
          final guildId = _resolveGuildId(variables);
          if (guildId != null) {
            variables[_key('role', contextId, 'exists')] = 'false';
            final manager = gateway.guilds[guildId].roles;
            Role? role;
            if (id != null) {
              role = await manager.fetch(id);
            } else {
              final matches = (await readDiscordRoles(
                gateway,
                guildId,
              )).where((role) => role.name == contextId).toList();
              // A duplicate name is ambiguous; never grant an arbitrary role.
              if (matches.length == 1) role = matches.single;
            }
            fetchedEntity = role;
            if (role != null) {
              _populateRoleVariables(variables, contextId, role);
            }
          }
          break;

        case 'message':
          final channelId = _resolveChannelId(variables);
          variables[_key('message', contextId, 'content')] = '';
          variables[_key('message', contextId, 'authorId')] = '';
          variables[_key('message', contextId, 'attachments')] = '';
          if (channelId != null) {
            try {
              final message = await (gateway.channels[channelId] as dynamic)
                  .messages
                  .fetch(id!);
              fetchedEntity = message;
              _populateMessageVariables(variables, contextId, message);
            } catch (_) {
              // A deleted or inaccessible target has no author/content.
            }
          }
          break;

        case 'getMessage':
        case 'getmessage':
          final parts = contextId.split(';');
          if (parts.length == 2) {
            variables['getMessage[${parts[0]};${parts[1]}].content'] = '';
            final chanId = _parseSnowflake(parts[0]);
            final msgId = _parseSnowflake(parts[1]);
            if (chanId != null && msgId != null) {
              try {
                final message = await (gateway.channels[chanId] as dynamic)
                    .messages
                    .fetch(msgId);
                fetchedEntity = message;
                _populateGetMessageVariables(
                  variables,
                  parts[0],
                  parts[1],
                  message,
                );
              } catch (_) {
                // Deleted or inaccessible messages resolve to empty text.
              }
            }
          }
          break;

        case 'getReactions':
        case 'getreactions':
          final parts = contextId.split(';');
          if (parts.length == 3) {
            final key = 'getReactions[${parts[0]};${parts[1]};${parts[2]}]';
            variables[key] = '0';
            final chanId = _parseSnowflake(parts[0]);
            final msgId = _parseSnowflake(parts[1]);
            final emoji = parts[2];
            if (chanId != null && msgId != null) {
              try {
                final message = await (gateway.channels[chanId] as dynamic)
                    .messages
                    .fetch(msgId);
                fetchedEntity = message;
                _populateGetReactionsVariables(
                  variables,
                  parts[0],
                  parts[1],
                  emoji,
                  message,
                );
              } catch (_) {
                // Missing or inaccessible messages have no reactions.
              }
            }
          }
          break;

        case 'getEmbedData':
        case 'getembeddata':
          final parts = contextId.split(';');
          if (parts.length == 4) {
            final key = 'getEmbedData[$contextId]';
            variables[key] = '';
            final channelId = _parseSnowflake(parts[0]);
            final messageId = _parseSnowflake(parts[1]);
            final index = int.tryParse(parts[2]);
            if (channelId != null &&
                messageId != null &&
                index != null &&
                index > 0) {
              try {
                final message =
                    await (gateway.channels[channelId] as dynamic).messages
                            .fetch(messageId)
                        as Message;
                fetchedEntity = message;
                variables[key] = _embedProperty(message, index, parts[3]);
              } catch (_) {
                // A missing or inaccessible message has no embed data.
              }
            }
          }
          break;

        case 'emoji':
          final guildId = _resolveGuildId(variables);
          variables['emoji[$contextId]'] = '';
          variables['emoji[$contextId].exists'] = 'false';
          variables['emoji[$contextId].name'] = '';
          variables['emoji[$contextId].animated'] = 'false';
          Emoji? foundEmoji;
          if (guildId != null) {
            try {
              for (final emoji in await gateway.guilds[guildId].emojis.list()) {
                if (emoji.id.toString() == contextId ||
                    emoji.name == contextId) {
                  foundEmoji = emoji;
                  break;
                }
              }
            } catch (_) {}
          }
          if (foundEmoji == null) {
            for (final otherGuildId in gateway.guilds.cache.keys) {
              if (otherGuildId == guildId) continue;
              try {
                for (final emoji
                    in await gateway.guilds[otherGuildId].emojis.list()) {
                  if (emoji.id.toString() == contextId ||
                      emoji.name == contextId) {
                    foundEmoji = emoji;
                    break;
                  }
                }
              } catch (_) {}
              if (foundEmoji != null) break;
            }
          }
          if (foundEmoji != null) {
            fetchedEntity = foundEmoji;
            _populateEmojiVariables(variables, contextId, foundEmoji);
          }
          break;

        case 'emojiCount':
        case 'serverEmojis':
          final parts = contextId.split(';');
          final guildId = _parseSnowflake(parts.first);
          final key = '$scope[$contextId]';
          variables[key] = scope == 'emojiCount' ? '0' : '';
          if (guildId != null) {
            try {
              final emojis = await gateway.guilds[guildId].emojis.list();
              variables[key] = scope == 'emojiCount'
                  ? emojis.length.toString()
                  : emojis.map(_formatEmoji).join(parts.skip(1).join(';'));
            } catch (_) {
              // Unknown or inaccessible guild has no available emojis.
            }
          }
          break;

        case 'roleBoundary':
          final parts = contextId.split(';');
          variables['roleBoundary[$contextId]'] = '';
          if (parts.length == 2) {
            final guildId = _parseSnowflake(parts[0]);
            if (guildId != null) {
              try {
                final roles = orderedDiscordRoles(
                  await readDiscordRoles(gateway, guildId),
                  guildId,
                );
                if (roles.isNotEmpty) {
                  variables['roleBoundary[$contextId]'] =
                      (parts[1] == 'highest' ? roles.first : roles.last).id
                          .toString();
                }
              } catch (_) {
                // Unknown or inaccessible guild has no role boundary.
              }
            }
          }
          break;

        case 'roleBoundaryWithPerms':
          final parts = contextId.split(';');
          variables['roleBoundaryWithPerms[$contextId]'] = '';
          if (parts.length >= 3) {
            final guildId = _parseSnowflake(parts[0]);
            final required = bdfdPermissionFlags(parts.skip(2));
            if (guildId != null && required != null) {
              try {
                final roles = orderedDiscordRoles(
                  await readDiscordRoles(gateway, guildId),
                  guildId,
                );
                final matches = roles
                    .where(
                      (role) => hasAllRolePermissions(
                        role.permissions.value,
                        required.map((flag) => flag.value),
                      ),
                    )
                    .toList();
                if (matches.isNotEmpty) {
                  variables['roleBoundaryWithPerms[$contextId]'] =
                      (parts[1] == 'highest' ? matches.first : matches.last).id
                          .toString();
                }
              } catch (_) {
                // Unknown guild or permissions have no matching role.
              }
            }
          }
          break;

        default:
          break;
      }

      if (cache != null && fetchedEntity != null) {
        cache[flightKey] = fetchedEntity;
      }

      completer.complete(fetchedEntity);
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight.remove(flightKey);
    }
  }

  static void _populateEntityVariables(
    Map<String, String> variables,
    String scope,
    String contextId,
    dynamic entity,
  ) {
    if (scope == 'guildExists' && entity is bool) {
      variables[_key('guild', contextId, 'exists')] = entity.toString();
    } else if (scope == 'user' && entity == false) {
      variables[_key('user', contextId, 'exists')] = 'false';
    } else if (entity is User) {
      _populateUserVariables(variables, contextId, entity);
    } else if (entity is Member) {
      _populateMemberVariables(variables, contextId, entity);
      if (entity.user != null) {
        _populateUserVariables(variables, contextId, entity.user!);
      }
    } else if (entity is Channel) {
      _populateChannelVariables(variables, scope, contextId, entity);
    } else if (entity is Guild) {
      _populateGuildVariables(variables, contextId, entity);
    } else if (entity is Role) {
      _populateRoleVariables(variables, contextId, entity);
    } else if (entity is Message) {
      if (scope == 'getMessage' || scope == 'getmessage') {
        final parts = contextId.split(';');
        if (parts.length == 2) {
          _populateGetMessageVariables(variables, parts[0], parts[1], entity);
        }
      } else if (scope == 'getReactions' || scope == 'getreactions') {
        final parts = contextId.split(';');
        if (parts.length == 3) {
          _populateGetReactionsVariables(
            variables,
            parts[0],
            parts[1],
            parts[2],
            entity,
          );
        }
      } else if (scope == 'getEmbedData' || scope == 'getembeddata') {
        final parts = contextId.split(';');
        final index = parts.length == 4 ? int.tryParse(parts[2]) : null;
        if (index != null && index > 0) {
          variables['getEmbedData[$contextId]'] = _embedProperty(
            entity,
            index,
            parts[3],
          );
        }
      } else {
        _populateMessageVariables(variables, contextId, entity);
      }
    } else if (entity is Emoji) {
      _populateEmojiVariables(variables, contextId, entity);
    }

    if (scope == 'role' && entity == null) {
      variables[_key('role', contextId, 'exists')] = 'false';
    }
  }

  // Helpers

  static Snowflake? _parseSnowflake(String idStr) {
    final parsed = int.tryParse(idStr);
    return parsed != null ? Snowflake(parsed) : null;
  }

  static Snowflake? _resolveGuildId(Map<String, String> variables) {
    final guildIdStr =
        variables['guild.id'] ??
        variables['interaction.guildId'] ??
        variables['guildId'];
    final parsed = int.tryParse(guildIdStr ?? '');
    return parsed != null ? Snowflake(parsed) : null;
  }

  static Snowflake? _resolveChannelId(Map<String, String> variables) {
    final channelIdStr =
        variables['channel.id'] ??
        variables['interaction.channelId'] ??
        variables['channelId'];
    final parsed = int.tryParse(channelIdStr ?? '');
    return parsed != null ? Snowflake(parsed) : null;
  }

  static String _key(String scope, String contextId, String field) =>
      '$scope[$contextId].$field';

  static void _populateUserVariables(
    Map<String, String> variables,
    String contextId,
    User user,
  ) {
    final keys = <String>[];
    void set(String field, String value) {
      final key = _key('user', contextId, field);
      variables[key] = value;
      keys.add(key);
    }

    set('username', user.username);
    set('exists', 'true');
    set('tag', user.discriminator);
    set(
      'avatar',
      _safeAvatarUrl(
        id: user.id.toString(),
        avatar: user.avatar,
        discriminator: user.discriminator,
      ),
    );
    set('globalName', user.globalName ?? user.username);
    set('displayName', user.globalName ?? user.username);
    set('createdAt', user.id.timestamp.toIso8601String());
    set('isBot', user.isBot.toString());
    set('banner', user.banner?.url.toString() ?? '');
    set(
      'bannerColor',
      user.accentColor != null
          ? '#${user.accentColor!.value.toRadixString(16).padLeft(6, '0')}'
          : '',
    );
    set('accentColor', user.accentColor?.value.toString() ?? '');
    set('flags', user.flags?.value.toString() ?? '');
    set('publicFlags', user.publicFlags?.value.toString() ?? '');
    set('avatarDecorationHash', user.avatarDecorationHash ?? '');
    set(
      'avatarDecorationData.skuId',
      user.avatarDecorationData != null
          ? user.avatarDecorationData!.skuId.toString()
          : '',
    );
    set('avatarDecorationData.asset', user.avatarDecorationData?.asset ?? '');
    set(
      'primaryGuild.identityGuildId',
      user.primaryGuild?.identityGuildId?.toString() ?? '',
    );
    set(
      'primaryGuild.identityEnabled',
      user.primaryGuild?.isIdentityEnabled?.toString() ?? 'false',
    );
    set('primaryGuild.tag', user.primaryGuild?.tag ?? '');
    set('primaryGuild.badge', (user.primaryGuild?.badge ?? '').toString());
    set(
      'verified',
      (user.flags?.has(UserFlags.verifiedBot) ?? false).toString(),
    );
  }

  // Using dynamic to avoid type issues across different library versions
  static void _populateMemberVariables(
    Map<String, String> variables,
    String contextId,
    dynamic member, {
    dynamic guild,
  }) {
    final keys = <String>[];
    void set(String field, String value) {
      final key = _key('member', contextId, field);
      variables[key] = value;
      keys.add(key);
    }

    set('nick', member.nick ?? '');
    set(
      'avatar',
      _safeAvatarUrl(
        id: member.id.toString(),
        avatar: member.avatar ?? member.user?.avatar,
        discriminator: member.user?.discriminator,
      ),
    );
    set(
      'displayName',
      member.nick ?? member.user?.globalName ?? member.user?.username ?? '',
    );
    set('joinedAt', member.joinedAt?.toIso8601String() ?? '');
    final timeoutUntil = member.communicationDisabledUntil as DateTime?;
    set(
      'isTimedOut',
      (timeoutUntil != null && timeoutUntil.isAfter(DateTime.now().toUtc()))
          .toString(),
    );
    set('roles', (member.roleIds ?? []).map((rid) => rid.toString()).join(','));

    if (guild != null) {
      final details = extractMemberRuntimeDetails(
        member: member,
        guild: guild,
        guildId: guild.id.toString(),
      );
      for (final entry in details.entries) {
        if (entry.key.startsWith('member.')) {
          set(entry.key.substring('member.'.length), entry.value);
        }
      }
      variables['permissions.byId.$contextId'] =
          details['member.permissions'] ?? '';
    }

    // Compute highest/lowest role by position from guild role list
    if (guild != null) {
      try {
        final memberRoleIds = <String>{};
        final roleIdsRaw = member.roleIds;
        if (roleIdsRaw is Iterable) {
          for (final rid in roleIdsRaw) {
            memberRoleIds.add(rid.toString().trim());
          }
        }

        final roleListRaw = guild.roleList;
        if (roleListRaw is Iterable) {
          String? highestRoleId;
          int highestPos = -1;
          String? lowestRoleId;
          int lowestPos = 999999;

          for (final role in roleListRaw) {
            final roleId = role.id.toString().trim();
            if (!memberRoleIds.contains(roleId)) continue;
            final pos = (role.position as int?) ?? 0;

            // Skip @everyone role (position <= 0)
            if (pos <= 0) continue;

            if (pos > highestPos) {
              highestPos = pos;
              highestRoleId = roleId;
            }
            if (pos < lowestPos) {
              lowestPos = pos;
              lowestRoleId = roleId;
            }
          }

          if (highestRoleId != null) {
            set('highestRole', highestRoleId);
            set('highestRoleWithPerms', highestRoleId);
          }
          if (lowestRoleId != null) {
            set('lowestRole', lowestRoleId);
            set('lowestRoleWithPerms', lowestRoleId);
          }
        }
      } catch (_) {
        // Role position not available — skip silently
      }
      variables.putIfAbsent(
        _key('member', contextId, 'highestRole'),
        () => guild.id.toString(),
      );
      variables.putIfAbsent(
        _key('member', contextId, 'lowestRole'),
        () => guild.id.toString(),
      );
    }
  }

  static void _populateGuildVariables(
    Map<String, String> variables,
    String contextId,
    Guild guild,
  ) {
    variables[_key('guild', contextId, 'name')] = guild.name;
    variables[_key('guild', contextId, 'id')] = guild.id.toString();
    variables[_key('guild', contextId, 'memberCount')] =
        guild.approximateMemberCount?.toString() ?? '0';
    variables[_key('guild', contextId, 'premiumSubscriptionCount')] =
        guild.premiumSubscriptionCount?.toString() ?? '0';
    variables[_key('guild', contextId, 'premiumTier')] = guild.premiumTier.value
        .toString();
    variables[_key('guild', contextId, 'emojiCount')] = guild
        .emojis
        .cache
        .length
        .toString();
    variables[_key('guild', contextId, 'stickerCount')] = guild
        .stickers
        .cache
        .length
        .toString();
    variables[_key('guild', contextId, 'exists')] = 'true';
    variables[_key('guild', contextId, 'description')] =
        guild.description ?? '';
    variables[_key('guild', contextId, 'ownerId')] = guild.ownerId.toString();
    variables[_key('guild', contextId, 'verificationLevel')] = guild
        .verificationLevel
        .value
        .toString();
    variables[_key('guild', contextId, 'features')] = guild.features.join(',');
    variables[_key('guild', contextId, 'vanityUrlCode')] =
        guild.vanityUrlCode ?? '';
    variables[_key('guild', contextId, 'banner')] =
        guild.banner?.toString() ?? '';
    variables[_key('guild', contextId, 'splash')] =
        guild.splash?.toString() ?? '';
    variables[_key('guild', contextId, 'afkTimeout')] = guild
        .afkTimeout
        .inSeconds
        .toString();
    variables[_key('guild', contextId, 'preferredLocale')] = guild
        .preferredLocale
        .toString();
  }

  static void _populateRoleVariables(
    Map<String, String> variables,
    String contextId,
    Role role,
  ) {
    variables[_key('role', contextId, 'info')] = jsonEncode({
      'id': role.id.toString(),
      'name': role.name,
      'color': role.colors.primary.value.toRadixString(16).padLeft(6, '0'),
      'position': role.position,
      'permissions': role.permissions.value.toString(),
      'mentionable': role.isMentionable,
      'hoist': role.isHoisted,
    });
    variables[_key('role', contextId, 'exists')] = 'true';
    variables[_key('role', contextId, 'name')] = role.name;
    variables[_key('role', contextId, 'id')] = role.id.toString();
    variables[_key('role', contextId, 'color')] = role.colors.primary.value
        .toRadixString(16)
        .padLeft(6, '0');
    variables[_key('role', contextId, 'position')] = role.position.toString();
    variables[_key('role', contextId, 'mentionable')] = role.isMentionable
        .toString();
    variables[_key('role', contextId, 'hoist')] = role.isHoisted.toString();
    variables[_key('role', contextId, 'permissions')] = role.permissions.value
        .toString();
  }

  static void _populateChannelVariables(
    Map<String, String> variables,
    String scope,
    String contextId,
    Channel channel,
  ) {
    final prefix = '$scope[$contextId]';
    variables['$prefix.id'] = channel.id.toString();
    variables['$prefix.name'] = _getChannelName(channel);
    variables['$prefix.exists'] = 'true';
    variables['$prefix.type'] = discordChannelTypeName(channel.type);
    variables['$prefix.typeValue'] = channel.type.value.toString();
    if (channel is GuildChannel) {
      variables['$prefix.position'] = channel.position.toString();
      variables['$prefix.parentId'] = channel.parentId?.toString() ?? '';
      variables['$prefix.nsfw'] = channel.isNsfw.toString();
    }
    if (channel is GuildTextChannel) {
      variables['$prefix.topic'] = channel.topic ?? '';
      variables['$prefix.rateLimitPerUser'] =
          (channel.rateLimitPerUser?.inSeconds ?? 0).toString();
      variables['$prefix.lastMessageId'] =
          channel.lastMessageId?.toString() ?? '';
      variables['$prefix.lastPinTimestamp'] =
          channel.lastPinTimestamp?.millisecondsSinceEpoch.toString() ?? '';
    }
    if (scope == 'channel' &&
        variables['channel.id'] == channel.id.toString()) {
      for (final field in [
        'name',
        'type',
        'typeValue',
        'position',
        'parentId',
        'nsfw',
        'topic',
        'lastMessageId',
        'lastPinTimestamp',
      ]) {
        final value = variables['$prefix.$field'];
        if (value != null) variables.putIfAbsent('channel.$field', () => value);
      }
      final slowmode = variables['$prefix.rateLimitPerUser'];
      if (slowmode != null) {
        variables.putIfAbsent('channel.slowmode', () => slowmode);
      }
    }
  }

  static void _populateMessageVariables(
    Map<String, String> variables,
    String contextId,
    Message message,
  ) {
    variables[_key('message', contextId, 'content')] = message.content;
    variables[_key('message', contextId, 'id')] = message.id.toString();
    variables[_key('message', contextId, 'authorId')] = message.author.id
        .toString();
    variables[_key('message', contextId, 'attachments')] = message.attachments
        .map((attachment) => attachment.url.toString())
        .join(', ');
    variables[_key('message', contextId, 'channelId')] = message.channelId
        .toString();
    variables[_key('message', contextId, 'createdAt')] = message.timestamp
        .toIso8601String();
  }

  // Avatar structure may vary across library versions; using dynamic for safety
  static String _safeAvatarUrl({
    required String id,
    dynamic avatar,
    String? discriminator,
  }) {
    if (avatar == null) {
      return makeAvatarUrl(id, avatarId: null, discriminator: discriminator);
    }
    final avatarHash = avatar.hash;
    final isAnimated = avatar.isAnimated ?? false;
    return makeAvatarUrl(
      id,
      avatarId: avatarHash,
      isAnimated: isAnimated,
      legacyFormat: 'webp',
      discriminator: discriminator,
    );
  }

  static String _getChannelName(Channel channel) {
    if (channel is GuildCategory) return channel.name;
    if (channel is GuildTextChannel ||
        channel is GuildVoiceChannel ||
        channel is ThreadsOnlyChannel ||
        channel is GuildStageChannel) {
      return (channel as dynamic).name ?? 'Unknown Channel';
    }
    if (channel is DmChannel) return 'DM';
    return 'Unknown Channel';
  }

  static void _populateGetMessageVariables(
    Map<String, String> variables,
    String channelId,
    String messageId,
    Message message,
  ) {
    final prefix = 'getMessage[$channelId;$messageId]';
    variables['$prefix.content'] = message.content;
    variables['$prefix.id'] = message.id.toString();
    variables['$prefix.authorId'] = message.author.id.toString();
    variables['$prefix.channelId'] = message.channelId.toString();
    variables['$prefix.createdAt'] = message.timestamp.toIso8601String();
    variables['$prefix.author'] = message.author.username;
  }

  static void _populateGetReactionsVariables(
    Map<String, String> variables,
    String channelId,
    String messageId,
    String emoji,
    Message message,
  ) {
    final key = 'getReactions[$channelId;$messageId;$emoji]';
    final rx = message.reactions;
    if (rx.isEmpty) {
      variables[key] = '0';
      return;
    }
    for (final r in rx) {
      final emojiObj = r.emoji;
      final name = emojiObj is Emoji ? (emojiObj.name ?? '') : '';
      final id = emojiObj.id.toString();
      if (name == emoji || id == emoji || '$name:$id' == emoji) {
        variables[key] = r.count.toString();
        return;
      }
    }
    variables[key] = '0';
  }

  static String _embedProperty(
    Message message,
    int oneBasedIndex,
    String property,
  ) {
    if (oneBasedIndex > message.embeds.length) return '';
    final embed = message.embeds[oneBasedIndex - 1];
    switch (property.toLowerCase()) {
      case 'title':
        return embed.title ?? '';
      case 'description':
        return embed.description ?? '';
      case 'footer':
        return embed.footer?.text ?? '';
      case 'color':
        return embed.color?.value.toRadixString(16).padLeft(6, '0') ?? '';
      case 'image':
        return embed.image?.url.toString() ?? '';
      case 'timestamp':
        return embed.timestamp?.toIso8601String() ?? '';
      default:
        return '';
    }
  }

  static void _populateEmojiVariables(
    Map<String, String> variables,
    String contextId,
    Emoji emoji,
  ) {
    final prefix = 'emoji[$contextId]';
    final isAnimated = (emoji as dynamic).isAnimated == true;
    final formatted = emoji.id == Snowflake.zero
        ? (emoji.name ?? '')
        : '<${isAnimated ? 'a' : ''}:${emoji.name}:${emoji.id}>';
    variables[prefix] = formatted;
    variables['$prefix.id'] = emoji.id.toString();
    variables['$prefix.name'] = emoji.name ?? '';
    variables['$prefix.isAnimated'] = isAnimated.toString();
    variables['$prefix.animated'] = isAnimated.toString();
    variables['$prefix.exists'] = (int.tryParse(contextId) != null).toString();
  }

  static String _formatEmoji(Emoji emoji) {
    final animated = emoji is GuildEmoji && emoji.isAnimated == true;
    return '<${animated ? 'a' : ''}:${emoji.name}:${emoji.id}>';
  }
}
