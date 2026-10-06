import 'dart:convert';

import '../types/action.dart';

/// Sandbox simulation of the Blocks actions that read or change Discord entities.
///
/// Everything runs on caller-provided fixtures (`entities.guilds.<guildId>.*`): nothing reaches
/// Discord. State is mutated in place so that a later action of the same run sees the effect, and
/// each change is recorded in [effects] with a `before`/`after` pair like the other simulations.
///
/// A missing fixture produces an error that names the exact key and shape to provide, so the
/// Copilot can fix its scenario in one step instead of guessing.

/// Fixture each simulated action needs, shown when the scenario does not provide it.
const Map<BotCreatorActionType, String> sandboxFixtureHints = {
  BotCreatorActionType.getMessage:
      'entities.guilds.<guildId>.messages.<channelId> = [{id, author_id, author_username?, content, timestamp?}]',
  BotCreatorActionType.createPoll:
      'entities.guilds.<guildId>.channels = [{id, type:"text"}] (the poll is added to messages.<channelId>)',
  BotCreatorActionType.endPoll:
      'entities.guilds.<guildId>.messages.<channelId> = [{id, poll:{question, answers:[...]}}]',
  BotCreatorActionType.getMember:
      'entities.guilds.<guildId>.members = {"<userId>": {username, nick?, roles?...}}',
  BotCreatorActionType.listMembers:
      'entities.guilds.<guildId>.members = {"<userId>": {username, nick?, roles?...}}',
  BotCreatorActionType.createInvite:
      'entities.guilds.<guildId>.channels = [{id, type:"text"}]',
  BotCreatorActionType.getInvite:
      'entities.guilds.<guildId>.invites = {"<code>": {channel_id, expires_at?}}',
  BotCreatorActionType.deleteInvite:
      'entities.guilds.<guildId>.invites = {"<code>": {channel_id}}',
  BotCreatorActionType.deleteChannelPermission:
      'entities.guilds.<guildId>.channels, roles and members containing the target',
  BotCreatorActionType.moveToVoiceChannel:
      'entities.guilds.<guildId>.members.<userId>.voice = {channel_id} and a voice channel in channels',
  BotCreatorActionType.disconnectFromVoice:
      'entities.guilds.<guildId>.members.<userId>.voice = {channel_id}',
  BotCreatorActionType.serverMuteMember:
      'entities.guilds.<guildId>.members.<userId>.voice = {channel_id}',
  BotCreatorActionType.serverDeafenMember:
      'entities.guilds.<guildId>.members.<userId>.voice = {channel_id}',
  BotCreatorActionType.updateEmoji:
      'entities.guilds.<guildId>.emojis = [{id, name}]',
  BotCreatorActionType.listWebhooks:
      'entities.guilds.<guildId>.webhooks = [{id, name, channel_id, token?}]',
  BotCreatorActionType.getWebhook:
      'entities.guilds.<guildId>.webhooks = [{id, name, channel_id, token?}]',
  BotCreatorActionType.editWebhook:
      'entities.guilds.<guildId>.webhooks = [{id, name, channel_id, token?}]',
  BotCreatorActionType.updateGuild: 'entities.guilds.<guildId> = {name, ...}',
  BotCreatorActionType.getGuildOnboarding:
      'entities.guilds.<guildId>.onboarding = {enabled, default_channel_ids, prompts}',
  BotCreatorActionType.listAutoModRules:
      'entities.guilds.<guildId>.automod_rules = [{id, name, enabled, trigger_type}] (may be empty)',
  BotCreatorActionType.createAutoModRule:
      'entities.guilds.<guildId> (any guild fixture; automod_rules is created)',
  BotCreatorActionType.deleteAutoModRule:
      'entities.guilds.<guildId>.automod_rules = [{id, name}]',
  BotCreatorActionType.updateAutoMod:
      'entities.guilds.<guildId> (any guild fixture; the two managed rules are created)',
  BotCreatorActionType.editComponentV2:
      'entities.guilds.<guildId>.messages.<channelId> = [{id, author_id}]',
  BotCreatorActionType.editInteractionMessage:
      'a previous respondWithMessage/respondWithComponentV2 in the same run',
  BotCreatorActionType.attachImage:
      'images = {"<imageSource>": "<base64 or data URL>"} (no network access)',
  BotCreatorActionType.canvasCreateBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"create"|"loadImage"|"drawText"|...})',
  BotCreatorActionType.canvasLoadImageBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"loadImage",...})',
  BotCreatorActionType.canvasDrawTextBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"drawText",...})',
  BotCreatorActionType.canvasDrawCircleBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"drawCircle",...})',
  BotCreatorActionType.canvasDrawRectBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"drawRect",...})',
  BotCreatorActionType.canvasDrawLineBlock:
      'canvas blocks only exist inside runtimeImageBlock.operations ({op:"drawLine",...})',
  BotCreatorActionType.playMusic:
      'music = {userVoiceChannels:{"<userId>":"<channelId>"}, tracks:{"<query>":{title,author,duration,uri}}}',
  BotCreatorActionType.joinVoice:
      'music = {userVoiceChannels:{"<userId>":"<channelId>"}}',
  BotCreatorActionType.pauseMusic:
      'music = {current:{title,author,duration}} (Lavalink fixture; no voice connection is opened)',
  BotCreatorActionType.resumeMusic:
      'music = {current:{title,author,duration}, isPaused:true}',
  BotCreatorActionType.skipMusic:
      'music = {current:{title,...}, queue:[{title,...}]}',
  BotCreatorActionType.stopMusic:
      'music = {current?:{title,...}, queue?:[...]}',
  BotCreatorActionType.setMusicVolume:
      'music = {volume?:100} (any music fixture)',
  BotCreatorActionType.setMusicLoop:
      'music = {loopMode?:"off"|"track"|"queue"}',
  BotCreatorActionType.seekMusic:
      'music = {current:{title,author,duration:<ms>}, position?}',
  BotCreatorActionType.leaveVoice: 'music = {channelId?:"<voiceChannelId>"}',
  BotCreatorActionType.getMusicInfo:
      'music = {current?:{title,author,duration}, queue?:[...], volume?, position?}',
};

/// Message for an action the sandbox cannot run yet.
String sandboxMissingFixtureMessage(BotCreatorActionType type) {
  final hint = sandboxFixtureHints[type];
  return hint == null
      ? 'Sandbox action ${type.name} requires an explicit simulation fixture'
      : 'Sandbox action ${type.name} requires a simulation fixture: $hint';
}

/// Actions handled by [simulateAdditionalAction].
const Set<BotCreatorActionType> sandboxSimulatedAdditionalActions = {
  BotCreatorActionType.getMessage,
  BotCreatorActionType.createPoll,
  BotCreatorActionType.endPoll,
  BotCreatorActionType.getMember,
  BotCreatorActionType.listMembers,
  BotCreatorActionType.createInvite,
  BotCreatorActionType.getInvite,
  BotCreatorActionType.deleteInvite,
  BotCreatorActionType.deleteChannelPermission,
  BotCreatorActionType.moveToVoiceChannel,
  BotCreatorActionType.disconnectFromVoice,
  BotCreatorActionType.serverMuteMember,
  BotCreatorActionType.serverDeafenMember,
  BotCreatorActionType.updateEmoji,
  BotCreatorActionType.listWebhooks,
  BotCreatorActionType.getWebhook,
  BotCreatorActionType.editWebhook,
  BotCreatorActionType.updateGuild,
  BotCreatorActionType.getGuildOnboarding,
  BotCreatorActionType.updateGuildOnboarding,
  BotCreatorActionType.listAutoModRules,
  BotCreatorActionType.createAutoModRule,
  BotCreatorActionType.deleteAutoModRule,
  BotCreatorActionType.updateAutoMod,
  BotCreatorActionType.editComponentV2,
  BotCreatorActionType.editInteractionMessage,
};

Map<String, dynamic> _copy(Map value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

bool _truthy(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  final text = value.toString().trim().toLowerCase();
  if (text.isEmpty) return fallback;
  return text == 'true' || text == '1' || text == 'yes';
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  final text = value?.toString() ?? '';
  if (text.trim().startsWith('[')) {
    try {
      return _stringList(jsonDecode(text));
    } catch (_) {}
  }
  return text
      .split(RegExp(r'[\n;,]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

class _Sim {
  _Sim({
    required this.type,
    required this.payload,
    required this.resultKey,
    required this.results,
    required this.variables,
    required this.effects,
    required this.responses,
    required this.guildId,
    required this.guild,
  });

  final BotCreatorActionType type;
  final Map<String, dynamic> payload;
  final String resultKey;
  final Map<String, String> results;
  final Map<String, String> variables;
  final List<Map<String, dynamic>> effects;
  final List<Map<String, dynamic>> responses;
  final String guildId;
  final Map? guild;

  StateError missing([String? detail]) {
    final base = sandboxMissingFixtureMessage(type);
    return StateError(detail == null ? base : '$detail ($base)');
  }

  Map requireGuild() {
    final g = guild;
    if (g == null) throw missing('No fixture for guild "$guildId"');
    return g;
  }

  String text(String key) => (payload[key] ?? '').toString().trim();

  String channelId() =>
      (payload['channelId'] ?? variables['channel.id'] ?? '').toString().trim();

  Map members() {
    final m = requireGuild()['members'];
    if (m is! Map) throw missing('Guild has no members fixture');
    return m;
  }

  List channels() {
    final c = requireGuild()['channels'];
    if (c is! List) throw missing('Guild has no channels fixture');
    return c;
  }

  Map channel(String id) {
    for (final raw in channels()) {
      if (raw is Map && raw['id'].toString() == id) return raw;
    }
    throw StateError('Channel "$id" is absent from the sandbox fixture');
  }

  Map member(String userId) {
    final raw = members()[userId];
    if (int.tryParse(userId) == null || raw is! Map) {
      throw StateError('Member "$userId" is absent from the sandbox fixture');
    }
    return raw;
  }

  List messageRows(String channel) {
    final byChannel = requireGuild()['messages'];
    final rows = byChannel is Map ? byChannel[channel] : null;
    if (rows is! List) {
      throw missing('No messages fixture for channel "$channel"');
    }
    return rows;
  }

  Map message(String channel, String id) {
    for (final raw in messageRows(channel)) {
      if (raw is Map && raw['id'].toString() == id) return raw;
    }
    throw StateError('Message "$id" is absent from the sandbox fixture');
  }

  int nextId() => 7000 + effects.length + 1;

  void done(String value, {Map<String, Object?> sub = const {}}) {
    results[resultKey] = value;
    for (final e in sub.entries) {
      results['$resultKey.${e.key}'] = e.value?.toString() ?? '';
    }
  }

  void effect(Map<String, dynamic> entry) =>
      effects.add({...entry, 'simulated': true});

  Map<String, dynamic> memberJson(String id, Map m) {
    final roles = m['roles'] ?? m['role_ids'] ?? const [];
    final nick = m['nick']?.toString();
    final username = (m['username'] ?? '').toString();
    final globalName = (m['global_name'] ?? m['globalName'] ?? '').toString();
    final voice = m['voice'];
    return {
      'id': id,
      'userId': id,
      'username': username,
      'globalName': globalName,
      'displayName': nick != null && nick.isNotEmpty
          ? nick
          : (globalName.isNotEmpty ? globalName : username),
      'nick': nick ?? '',
      'joinedAt': (m['joined_at'] ?? m['joinedAt'] ?? '').toString(),
      'isPending': m['pending'] == true,
      'isDeaf': voice is Map ? voice['deaf'] == true : m['deaf'] == true,
      'isMute': voice is Map ? voice['mute'] == true : m['mute'] == true,
      'roleIds': (roles as List).map((r) => r.toString()).toList(),
      'communicationDisabledUntil': (m['communication_disabled_until'] ?? '')
          .toString(),
    };
  }

  // --- reads ---------------------------------------------------------------------------------

  void getMessage() {
    final channel = channelId();
    final id = text('messageId');
    final row = message(channel, id);
    final authorId = (row['author_id'] ?? '').toString();
    final authorMember = members()[authorId];
    final author =
        (row['author_username'] ??
                (authorMember is Map ? authorMember['username'] : null) ??
                '')
            .toString();
    done(
      id,
      sub: {
        'messageId': id,
        'content': row['content'] ?? '',
        'authorId': authorId,
        'authorUsername': author,
        'timestamp': row['timestamp'] ?? '',
      },
    );
  }

  void getMember() {
    final id = (payload['userId'] ?? payload['memberId'] ?? '')
        .toString()
        .trim();
    done(jsonEncode(memberJson(id, member(id))));
  }

  void listMembers() {
    final query = text('query').toLowerCase();
    final after = int.tryParse(text('after')) ?? 0;
    final limit = (int.tryParse(text('limit')) ?? 100).clamp(1, 1000);
    final rows = <Map<String, dynamic>>[];
    final entries = members().entries.toList()
      ..sort(
        (a, b) => (int.tryParse('${a.key}') ?? 0).compareTo(
          int.tryParse('${b.key}') ?? 0,
        ),
      );
    for (final e in entries) {
      final id = e.key.toString();
      if (e.value is! Map || (int.tryParse(id) ?? 0) <= after) continue;
      final json = memberJson(id, e.value as Map);
      if (query.isNotEmpty &&
          !'${json['username']} ${json['nick']} ${json['globalName']}'
              .toLowerCase()
              .contains(query)) {
        continue;
      }
      rows.add(json);
      if (rows.length >= limit) break;
    }
    done(jsonEncode(rows));
  }

  void listWebhooks() {
    final webhooks = _webhooks();
    final channel = text('channelId');
    final rows = [
      for (final w in webhooks)
        if (w is Map &&
            (channel.isEmpty || w['channel_id'].toString() == channel))
          _webhookJson(w),
    ];
    done(jsonEncode(rows));
  }

  List _webhooks() {
    final w = requireGuild()['webhooks'];
    if (w is! List) throw missing('Guild has no webhooks fixture');
    return w;
  }

  Map<String, dynamic> _webhookJson(Map w) => {
    'id': w['id'].toString(),
    'name': (w['name'] ?? '').toString(),
    'channelId': (w['channel_id'] ?? '').toString(),
    'guildId': guildId,
    'type': (w['type'] ?? 'incoming').toString(),
    'url': w['token'] == null
        ? ''
        : 'https://discord.com/api/webhooks/${w['id']}/${w['token']}',
    'hasToken': w['token'] != null,
  };

  Map _findWebhook() {
    var id = text('webhookId');
    final uri = Uri.tryParse(text('webhookUrl'));
    final parts = uri?.pathSegments ?? const <String>[];
    final at = parts.indexOf('webhooks');
    if (at >= 0 && at + 1 < parts.length) id = parts[at + 1];
    for (final w in _webhooks()) {
      if (w is Map && w['id'].toString() == id) return w;
    }
    throw StateError('Webhook "$id" is absent from the sandbox fixture');
  }

  void getWebhook() => done(jsonEncode(_webhookJson(_findWebhook())));

  void editWebhook() {
    final w = _findWebhook();
    final before = _copy(w);
    final name = text('name');
    if (payload.containsKey('name') && (name.length < 2 || name.length > 80)) {
      throw StateError('Webhook name must be 2 to 80 characters');
    }
    if (payload.containsKey('name')) w['name'] = name;
    if (text('channelId').isNotEmpty) w['channel_id'] = text('channelId');
    effect({
      'type': 'editWebhook',
      'guild_id': guildId,
      'webhook_id': w['id'].toString(),
      'before': before,
      'after': _copy(w),
    });
    done(_webhookJson(w)['url'].toString());
  }

  // --- polls ---------------------------------------------------------------------------------

  void createPoll() {
    final channel = channelId();
    this.channel(channel);
    final question = text('question');
    final answers = _stringList(payload['answers']);
    if (question.isEmpty || question.length > 300) {
      throw StateError('Poll question must be 1 to 300 characters');
    }
    if (answers.length < 2 || answers.length > 10) {
      throw StateError('A poll needs 2 to 10 answers (got ${answers.length})');
    }
    final hours = int.tryParse(text('durationHours')) ?? 24;
    if (hours < 1 || hours > 768) {
      throw StateError('Poll duration must be between 1 and 768 hours');
    }
    final id = '${nextId()}';
    final row = <String, dynamic>{
      'id': id,
      'author_id': variables['bot.id'],
      'content': '',
      'pinned': false,
      'poll': {
        'question': question,
        'answers': answers,
        'duration_hours': hours,
        'allow_multiselect': _truthy(payload['allowMultiselect']),
        'ended': false,
      },
    };
    final byChannel = requireGuild()['messages'];
    if (byChannel is Map) {
      final rows = byChannel[channel];
      if (rows is List) rows.insert(0, row);
    }
    effect({
      'type': 'createPoll',
      'guild_id': guildId,
      'channel_id': channel,
      'message_id': id,
      'poll': _copy(row['poll'] as Map),
    });
    done(id, sub: {'messageId': id, 'pollId': id});
  }

  void endPoll() {
    final channel = channelId();
    final id = text('messageId');
    final row = message(channel, id);
    final poll = row['poll'];
    if (poll is! Map) throw StateError('Message "$id" has no poll');
    if (poll['ended'] == true) throw StateError('The poll has already ended');
    final before = _copy(poll);
    poll['ended'] = true;
    effect({
      'type': 'endPoll',
      'guild_id': guildId,
      'channel_id': channel,
      'message_id': id,
      'before': before,
      'after': _copy(poll),
    });
    done('ended');
  }

  // --- invites -------------------------------------------------------------------------------

  Map _invites({bool create = false}) {
    final g = requireGuild();
    if (g['invites'] is! Map) {
      if (!create) throw missing('Guild has no invites fixture');
      g['invites'] = <String, dynamic>{};
    }
    return g['invites'] as Map;
  }

  void createInvite() {
    final channel = channelId();
    this.channel(channel);
    final maxAge = int.tryParse(text('maxAge')) ?? 86400;
    final maxUses = int.tryParse(text('maxUses')) ?? 0;
    if (maxAge < 0 || maxAge > 604800) {
      throw StateError('Invite maxAge must be between 0 and 604800 seconds');
    }
    if (maxUses < 0 || maxUses > 100) {
      throw StateError('Invite maxUses must be between 0 and 100');
    }
    final code = 'sbx${nextId()}';
    final invite = <String, dynamic>{
      'code': code,
      'channel_id': channel,
      'max_age': maxAge,
      'max_uses': maxUses,
      'temporary': _truthy(payload['temporary']),
      'expires_at': maxAge == 0 ? '' : 'in ${maxAge}s',
    };
    _invites(create: true)[code] = invite;
    effect({
      'type': 'createInvite',
      'guild_id': guildId,
      'channel_id': channel,
      'invite': _copy(invite),
    });
    final url = 'https://discord.gg/$code';
    done(
      code,
      sub: {
        'inviteCode': code,
        'url': url,
        'invite_url': url,
        'channelId': channel,
        'guildId': guildId,
      },
    );
  }

  Map _invite() {
    final code = text('inviteCode');
    final invite = _invites()[code];
    if (invite is! Map) {
      throw StateError('Invite "$code" is absent from the sandbox fixture');
    }
    return invite;
  }

  void getInvite() {
    final invite = _invite();
    final code = invite['code']?.toString() ?? text('inviteCode');
    done(
      code,
      sub: {
        'inviteCode': code,
        'guildId': guildId,
        'channelId': invite['channel_id'] ?? '',
        'expiresAt': invite['expires_at'] ?? '',
      },
    );
  }

  void deleteInvite() {
    final invite = _invite();
    final code = text('inviteCode');
    _invites().remove(code);
    effect({
      'type': 'deleteInvite',
      'guild_id': guildId,
      'invite': _copy(invite),
    });
    done('deleted');
  }

  // --- channels, voice -----------------------------------------------------------------------

  void deleteChannelPermission() {
    final channel = channelId();
    final target = this.channel(channel);
    final targetId = text('targetId');
    final type = text('targetType');
    if (type != 'everyone' && int.tryParse(targetId) == null) {
      throw StateError('A permission target ID is required');
    }
    final overwrites = target['overwrites'];
    final before = overwrites is Map && overwrites[targetId] is Map
        ? _copy(overwrites[targetId] as Map)
        : null;
    if (overwrites is Map) overwrites.remove(targetId);
    effect({
      'type': 'deleteChannelPermission',
      'guild_id': guildId,
      'channel_id': channel,
      'target_id': targetId,
      'before': before,
    });
    done('deleted');
  }

  Map _voice(String userId, {bool required = true}) {
    final m = member(userId);
    final voice = m['voice'];
    if (voice is! Map || (voice['channel_id'] ?? '').toString().isEmpty) {
      if (required) {
        throw StateError(
          'Member "$userId" is not connected to a voice channel',
        );
      }
      m['voice'] = <String, dynamic>{};
    }
    return m['voice'] as Map;
  }

  void moveToVoiceChannel() {
    final userId = text('userId');
    final target = text('targetChannelId');
    final voice = _voice(userId);
    final channel = this.channel(target);
    if (!{'voice', 'stage'}.contains(channel['type'])) {
      throw StateError('Target channel "$target" is not a voice channel');
    }
    final before = _copy(voice);
    voice['channel_id'] = target;
    effect({
      'type': 'moveToVoiceChannel',
      'guild_id': guildId,
      'user_id': userId,
      'before': before,
      'after': _copy(voice),
    });
    done('moved');
  }

  void disconnectFromVoice() {
    final userId = text('userId');
    final voice = _voice(userId);
    final before = _copy(voice);
    voice['channel_id'] = '';
    effect({
      'type': 'disconnectFromVoice',
      'guild_id': guildId,
      'user_id': userId,
      'before': before,
      'after': _copy(voice),
    });
    done('disconnected');
  }

  void serverMuteOrDeafen({required bool mute}) {
    final userId = text('userId');
    final voice = _voice(userId);
    final key = mute ? 'mute' : 'deaf';
    final on = _truthy(payload[key], fallback: true);
    final before = _copy(voice);
    voice[key] = on;
    effect({
      'type': type.name,
      'guild_id': guildId,
      'user_id': userId,
      'before': before,
      'after': _copy(voice),
    });
    done(mute ? (on ? 'muted' : 'unmuted') : (on ? 'deafened' : 'undeafened'));
  }

  // --- guild-level ---------------------------------------------------------------------------

  void updateEmoji() {
    final emojis = requireGuild()['emojis'];
    if (emojis is! List) throw missing('Guild has no emojis fixture');
    final id = text('emojiId');
    final emoji = emojis.cast<dynamic>().firstWhere(
      (e) => e is Map && (e['id'].toString() == id || e['name'] == id),
      orElse: () => null,
    );
    if (emoji is! Map) throw StateError('Emoji "$id" not found');
    final before = _copy(emoji);
    if (payload.containsKey('name')) {
      final name = text('name');
      if (!RegExp(r'^[A-Za-z0-9_]{2,32}$').hasMatch(name)) {
        throw StateError(
          'Emoji name must be 2 to 32 letters, digits or underscores',
        );
      }
      emoji['name'] = name;
    }
    if (payload.containsKey('roles')) {
      emoji['roles'] = _stringList(payload['roles']);
    }
    effect({
      'type': 'updateEmoji',
      'guild_id': guildId,
      'before': before,
      'after': _copy(emoji),
    });
    done(
      jsonEncode({
        'emojiId': emoji['id'].toString(),
        'name': emoji['name'],
        'status': 'updated',
      }),
      sub: {'emojiId': emoji['id'], 'name': emoji['name'], 'status': 'updated'},
    );
  }

  void updateGuild() {
    final g = requireGuild();
    final before = _copy(g);
    final name = text('name');
    if (payload.containsKey('name') && (name.length < 2 || name.length > 100)) {
      throw StateError('Guild name must be 2 to 100 characters');
    }
    final description = payload['description']?.toString() ?? '';
    if (description.length > 300) {
      throw StateError('Guild description cannot exceed 300 characters');
    }
    const map = {
      'name': 'name',
      'description': 'description',
      'preferredLocale': 'preferred_locale',
      'afkChannelId': 'afk_channel_id',
      'systemChannelId': 'system_channel_id',
      'rulesChannelId': 'rules_channel_id',
      'publicUpdatesChannelId': 'public_updates_channel_id',
      'safetyAlertsChannelId': 'safety_alerts_channel_id',
      'afkTimeoutSeconds': 'afk_timeout',
      'verificationLevel': 'verification_level',
      'defaultMessageNotificationLevel': 'default_message_notifications',
      'explicitContentFilterLevel': 'explicit_content_filter',
      'premiumProgressBarEnabled': 'premium_progress_bar_enabled',
    };
    var changed = 0;
    for (final e in map.entries) {
      if (!payload.containsKey(e.key)) continue;
      g[e.value] = payload[e.key];
      changed++;
    }
    if (changed == 0) {
      throw StateError('updateGuild needs at least one field to change');
    }
    if (payload.containsKey('name')) {
      variables['guild.name'] = name;
      variables['server.name'] = name;
    }
    effect({
      'type': 'updateGuild',
      'guild_id': guildId,
      'before': before,
      'after': _copy(g),
    });
    done(guildId);
  }

  void getGuildOnboarding() {
    final onboarding = requireGuild()['onboarding'];
    if (onboarding is! Map) throw missing('Guild has no onboarding fixture');
    final json = jsonEncode({
      'guildId': guildId,
      'enabled': onboarding['enabled'] == true,
      'defaultChannelIds': onboarding['default_channel_ids'] ?? const [],
      'mode': onboarding['mode'] ?? 'default',
      'prompts': onboarding['prompts'] ?? const [],
    });
    done(
      json,
      sub: {'onboardingJson': json, 'enabled': onboarding['enabled'] == true},
    );
  }

  // --- auto moderation -----------------------------------------------------------------------

  List _rules({bool create = false}) {
    final g = requireGuild();
    if (g['automod_rules'] is! List) {
      if (!create) throw missing('Guild has no automod_rules fixture');
      g['automod_rules'] = <dynamic>[];
    }
    return g['automod_rules'] as List;
  }

  Map<String, dynamic> _ruleJson(Map r) => {
    'id': r['id'].toString(),
    'name': (r['name'] ?? '').toString(),
    'enabled': r['enabled'] != false,
    'triggerType': (r['trigger_type'] ?? 'keyword').toString(),
  };

  void listAutoModRules() {
    final rows = [
      for (final r in _rules())
        if (r is Map) _ruleJson(r),
    ];
    final json = jsonEncode(rows);
    done(json, sub: {'rulesJson': json, 'count': rows.length});
  }

  void createAutoModRule() {
    final name = text('name');
    if (name.isEmpty || name.length > 100) {
      throw StateError(
        'name is required for createAutoModRule (1 to 100 characters)',
      );
    }
    final trigger = text('triggerType').isEmpty
        ? 'keyword'
        : text('triggerType');
    const triggers = {'keyword', 'spam', 'keywordPreset', 'mentionSpam'};
    final normalized = trigger.replaceAll('_', '').toLowerCase();
    final match = triggers.firstWhere(
      (t) => t.toLowerCase() == normalized,
      orElse: () => '',
    );
    if (match.isEmpty) {
      throw StateError(
        'triggerType must be one of keyword, spam, keywordPreset, mentionSpam',
      );
    }
    final action = text('actionType').isEmpty
        ? 'block_message'
        : text('actionType');
    if (!{'block_message', 'send_alert_message', 'timeout'}.contains(
      action.toLowerCase().replaceAll('sendalertmessage', 'send_alert_message'),
    )) {
      throw StateError(
        'actionType must be block_message, send_alert_message or timeout',
      );
    }
    if (action == 'send_alert_message' && text('alertChannelId').isEmpty) {
      throw StateError(
        'alertChannelId is required for the send_alert_message action',
      );
    }
    if (match == 'mentionSpam') {
      final limit = int.tryParse(text('mentionTotalLimit')) ?? 5;
      if (limit < 1 || limit > 50) {
        throw StateError('mentionTotalLimit must be between 1 and 50');
      }
    }
    if (match == 'keyword' &&
        _stringList(payload['keywords']).isEmpty &&
        _stringList(payload['regexPatterns']).isEmpty) {
      throw StateError('A keyword rule needs keywords or regexPatterns');
    }
    final rules = _rules(create: true);
    if (rules.length >= 6 && match == 'keyword') {
      throw StateError('Discord allows at most 6 keyword rules per server');
    }
    final id = '${nextId()}';
    final rule = <String, dynamic>{
      'id': id,
      'name': name,
      'enabled': _truthy(payload['enabled'], fallback: true),
      'trigger_type': match,
      'action_type': action,
      'keywords': _stringList(payload['keywords']),
      'regex_patterns': _stringList(payload['regexPatterns']),
      'allowed_words': _stringList(payload['allowedWords']),
      'exempt_roles': _stringList(payload['exemptRoles']),
      'exempt_channels': _stringList(payload['exemptChannels']),
      'alert_channel_id': text('alertChannelId'),
      'timeout_seconds': int.tryParse(text('timeoutDuration')) ?? 60,
    };
    rules.add(rule);
    effect({
      'type': 'createAutoModRule',
      'guild_id': guildId,
      'rule': _copy(rule),
    });
    done(id, sub: {'ruleId': id, 'name': name});
  }

  void deleteAutoModRule() {
    final id = text('ruleId');
    if (id.isEmpty) {
      throw StateError('ruleId is required for deleteAutoModRule');
    }
    final rules = _rules();
    final index = rules.indexWhere((r) => r is Map && r['id'].toString() == id);
    if (index < 0) {
      throw StateError('AutoMod rule "$id" is absent from the sandbox fixture');
    }
    final removed = _copy(rules.removeAt(index) as Map);
    effect({'type': 'deleteAutoModRule', 'guild_id': guildId, 'rule': removed});
    done('deleted');
  }

  void updateAutoMod() {
    // The block only manages two rules it owns (keyword filter and mention limit).
    const keywordName = 'BotCreator - Keyword Filter';
    const mentionName = 'BotCreator - Mention Limit';
    final rules = _rules(create: true);
    final before = _copy({'rules': rules});
    final words = _stringList(payload['filterWords']);
    final maxMentions = (int.tryParse(text('maxMentions')) ?? 5).clamp(1, 50);
    final enabled = _truthy(payload['enabled'], fallback: true);
    Map? find(String name) =>
        rules.cast<dynamic>().firstWhere(
              (r) => r is Map && r['name'] == name,
              orElse: () => null,
            )
            as Map?;
    if (words.isNotEmpty) {
      final rule =
          find(keywordName) ??
          () {
            final created = <String, dynamic>{
              'id': '${nextId()}',
              'name': keywordName,
              'trigger_type': 'keyword',
            };
            rules.add(created);
            return created;
          }();
      rule['enabled'] = enabled;
      rule['keywords'] = words;
      rule['exempt_roles'] = _stringList(payload['allowedRoles']);
    } else {
      find(keywordName)?['enabled'] = false;
    }
    final mention =
        find(mentionName) ??
        () {
          final created = <String, dynamic>{
            'id': '${nextId()}',
            'name': mentionName,
            'trigger_type': 'mentionSpam',
          };
          rules.add(created);
          return created;
        }();
    mention['enabled'] = enabled;
    mention['mention_total_limit'] = maxMentions;
    effect({
      'type': 'updateAutoMod',
      'guild_id': guildId,
      'before': before,
      'after': _copy({'rules': rules}),
    });
    done('OK');
  }

  // --- interaction and component edits -------------------------------------------------------

  void editInteractionMessage() {
    Map<String, dynamic>? last;
    for (final r in responses.reversed) {
      if ({
        'respondWithMessage',
        'respondWithComponentV2',
        'deferInteraction',
      }.contains(r['type'])) {
        last = r;
        break;
      }
    }
    if (last == null) {
      throw missing('There is no interaction response to edit yet');
    }
    final before = _copy(last);
    final body = last['payload'] is Map
        ? Map<String, dynamic>.from(last['payload'] as Map)
        : <String, dynamic>{};
    if (payload.containsKey('content')) body['content'] = payload['content'];
    if (payload.containsKey('embeds')) body['embeds'] = payload['embeds'];
    if (_truthy(payload['clearEmbeds'])) body['embeds'] = <dynamic>[];
    if (_truthy(payload['clearComponents'])) body.remove('components');
    if (payload['components'] is Map) {
      body['components'] = payload['components'];
    }
    last['payload'] = body;
    effect({
      'type': 'editInteractionMessage',
      'response_id': last['id'],
      'before': before,
      'after': _copy(last),
    });
    done(last['id'].toString());
  }

  void editComponentV2() {
    final channel = channelId();
    final id = text('messageId');
    final row = message(channel, id);
    if (row['author_id']?.toString() != variables['bot.id']) {
      throw StateError('Only the bot’s message can be edited');
    }
    if (payload['components'] is! Map ||
        (payload['components'] as Map).isEmpty) {
      throw StateError('editComponentV2 requires a components definition');
    }
    final before = _copy(row);
    row['components'] = payload['components'];
    effect({
      'type': 'editComponentV2',
      'guild_id': guildId,
      'channel_id': channel,
      'message_id': id,
      'before': before,
      'after': _copy(row),
    });
    done(id);
  }
}

/// Runs [type] against the fixtures. Returns true when the action was simulated; throws a
/// [StateError] (surfaced as the action's error) when a fixture is missing or the request would
/// be refused by Discord.
bool simulateAdditionalAction({
  required BotCreatorActionType type,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required List<Map<String, dynamic>> effects,
  required List<Map<String, dynamic>> responses,
  required Map? guild,
}) {
  if (!sandboxSimulatedAdditionalActions.contains(type)) return false;
  final sim = _Sim(
    type: type,
    payload: payload,
    resultKey: resultKey,
    results: results,
    variables: variables,
    effects: effects,
    responses: responses,
    guildId: variables['guild.id'] ?? '',
    guild: guild,
  );
  switch (type) {
    case BotCreatorActionType.getMessage:
      sim.getMessage();
    case BotCreatorActionType.createPoll:
      sim.createPoll();
    case BotCreatorActionType.endPoll:
      sim.endPoll();
    case BotCreatorActionType.getMember:
      sim.getMember();
    case BotCreatorActionType.listMembers:
      sim.listMembers();
    case BotCreatorActionType.createInvite:
      sim.createInvite();
    case BotCreatorActionType.getInvite:
      sim.getInvite();
    case BotCreatorActionType.deleteInvite:
      sim.deleteInvite();
    case BotCreatorActionType.deleteChannelPermission:
      sim.deleteChannelPermission();
    case BotCreatorActionType.moveToVoiceChannel:
      sim.moveToVoiceChannel();
    case BotCreatorActionType.disconnectFromVoice:
      sim.disconnectFromVoice();
    case BotCreatorActionType.serverMuteMember:
      sim.serverMuteOrDeafen(mute: true);
    case BotCreatorActionType.serverDeafenMember:
      sim.serverMuteOrDeafen(mute: false);
    case BotCreatorActionType.updateEmoji:
      sim.updateEmoji();
    case BotCreatorActionType.listWebhooks:
      sim.listWebhooks();
    case BotCreatorActionType.getWebhook:
      sim.getWebhook();
    case BotCreatorActionType.editWebhook:
      sim.editWebhook();
    case BotCreatorActionType.updateGuild:
      sim.updateGuild();
    case BotCreatorActionType.getGuildOnboarding:
      sim.getGuildOnboarding();
    case BotCreatorActionType.updateGuildOnboarding:
      // Same refusal as the engine: the runtime cannot edit onboarding yet.
      throw StateError(
        'updateGuildOnboarding is not supported by the current nyxx runtime yet',
      );
    case BotCreatorActionType.listAutoModRules:
      sim.listAutoModRules();
    case BotCreatorActionType.createAutoModRule:
      sim.createAutoModRule();
    case BotCreatorActionType.deleteAutoModRule:
      sim.deleteAutoModRule();
    case BotCreatorActionType.updateAutoMod:
      sim.updateAutoMod();
    case BotCreatorActionType.editComponentV2:
      sim.editComponentV2();
    case BotCreatorActionType.editInteractionMessage:
      sim.editInteractionMessage();
    default:
      return false;
  }
  return true;
}
