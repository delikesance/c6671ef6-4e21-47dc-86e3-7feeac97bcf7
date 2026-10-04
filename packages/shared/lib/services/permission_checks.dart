import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/utils/global.dart';
import '../engine/discord_entity_fetcher.dart';
import '../engine/execution_budget.dart';
import 'bot_role_query_service.dart' show orderedDiscordRoles;

// ── Permission cache ─────────────────────────────────────────────────────────

/// Caches guild and bot-member data for the lifetime of a single command
/// execution so that repeated permission checks don't make redundant HTTP
/// calls.
class BotPermissionCache {
  Guild? _guild;
  Snowflake? _cachedGuildId;
  Permissions? _botPermissions;
  Member? _botMember;

  Future<Guild> getGuild(NyxxGateway client, Snowflake guildId) async {
    if (_guild != null && _cachedGuildId == guildId) return _guild!;
    _cachedGuildId = guildId;
    _guild = await fetchGuildCached(client, guildId);
    _botPermissions = null;
    _botMember = null;
    return _guild!;
  }

  Future<Permissions> getBotPermissions(
    NyxxGateway client,
    Guild guild,
    Snowflake guildId,
  ) async {
    if (_botPermissions != null && _cachedGuildId == guildId) {
      return _botPermissions!;
    }
    final member = await _fetchBotMember(client, guild);
    _botPermissions = _permissionsFromRoles(guild, member.roleIds, guildId);
    return _botPermissions!;
  }

  Future<Member> _fetchBotMember(NyxxGateway client, Guild guild) async {
    if (_botMember != null && _cachedGuildId == guild.id) return _botMember!;
    _botMember = await guild.members.get(client.user.id);
    return _botMember!;
  }

  Future<Member> getBotMember(NyxxGateway client, Guild guild) =>
      _fetchBotMember(client, guild);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

/// Computes the combined permissions of the bot in [guild] by merging the
/// permissions of each of its roles (+ the @everyone role).
Future<Permissions> _computeBotPermissions(
  NyxxGateway client,
  Guild guild,
  Snowflake guildId,
) async {
  final botMember = await guild.members.get(client.user.id);
  return _permissionsFromRoles(guild, botMember.roleIds, guildId);
}

Permissions _permissionsFromRoles(
  Guild guild,
  List<Snowflake> roleIds,
  Snowflake guildId,
) {
  return Permissions(
    guild.roleList
        .where((r) => roleIds.contains(r.id) || r.id == guildId)
        .fold<int>(0, (acc, r) => acc | r.permissions.value),
  );
}

// ── Simple permission check (no role hierarchy) ─────────────────────────────

/// Discord's explicit overwrite order: everyone, combined roles, then member.
/// Administrator bypass and implicit channel restrictions belong to the caller.
Permissions applyChannelOverwrites({
  required Permissions base,
  required Snowflake guildId,
  required Snowflake memberId,
  required Iterable<Snowflake> roleIds,
  required Iterable<PermissionOverwrite> overwrites,
}) {
  var mask = base.value;
  final rows = overwrites.toList();
  void apply(Iterable<PermissionOverwrite> selected) {
    var allow = 0;
    var deny = 0;
    for (final row in selected) {
      allow |= row.allow.value;
      deny |= row.deny.value;
    }
    mask = (mask & ~deny) | allow;
  }

  apply(
    rows.where(
      (r) => r.type == PermissionOverwriteType.role && r.id == guildId,
    ),
  );
  final roles = roleIds.toSet()..remove(guildId);
  apply(
    rows.where(
      (r) => r.type == PermissionOverwriteType.role && roles.contains(r.id),
    ),
  );
  apply(
    rows.where(
      (r) => r.type == PermissionOverwriteType.member && r.id == memberId,
    ),
  );
  return Permissions(mask);
}

/// Effective permissions in the target channel, using parent overwrites for threads.
/// Categories do not implicitly supply overwrites to desynchronized children.
Future<String?> checkBotChannelPermission(
  NyxxGateway client, {
  required GuildChannel channel,
  required List<Flag<Permissions>> requiredPermissions,
  required String actionLabel,
  required CommandExecutionBudget budget,
}) => budget.run(() async {
  final guild = await fetchGuildCached(client, channel.guildId);
  budget.check();
  if (guild == null) return 'Guild not found';
  final botId = client.user.id;
  if (guild.ownerId == botId) return null;
  final member = await guild.members.get(botId);
  budget.check();
  final base = _permissionsFromRoles(guild, member.roleIds, channel.guildId);
  if (base.isAdministrator) return null;
  GuildChannel permissionChannel = channel;
  if (channel is Thread) {
    final parentId = channel.parentId;
    if (parentId == null) return 'Thread parent is missing.';
    final parent = await client.channels.fetch(parentId);
    budget.check();
    if (parent is! GuildChannel ||
        parent is Thread ||
        parent.guildId != channel.guildId) {
      return 'Thread parent is invalid.';
    }
    permissionChannel = parent;
  }
  final effective = applyChannelOverwrites(
    base: base,
    guildId: channel.guildId,
    memberId: botId,
    roleIds: member.roleIds,
    overwrites: permissionChannel.permissionOverwrites,
  );
  final missing = <String>[
    if (!effective.has(Permissions.viewChannel)) 'View Channel',
    for (final flag in requiredPermissions)
      if (flag != Permissions.viewChannel && !effective.has(flag))
        _permissionName(flag),
  ];
  return missing.isEmpty
      ? null
      : 'I do not have permission to $actionLabel. Missing: ${missing.join(', ')}.';
});

/// Checks that the bot has **all** of the given [requiredPermissions] in
/// the guild identified by [guildId].
///
/// Returns an error string if any permission is missing, or `null` if the
/// bot is authorised.
Future<String?> checkBotGuildPermission(
  NyxxGateway client, {
  required Snowflake guildId,
  required List<Flag<Permissions>> requiredPermissions,
  required String actionLabel,
  BotPermissionCache? cache,
  CommandExecutionBudget? budget,
}) async {
  budget?.check();
  final guild = cache != null
      ? await cache.getGuild(client, guildId)
      : await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) return 'Guild not found';
  if (guild.ownerId == client.user.id) return null;
  final perms = cache != null
      ? await cache.getBotPermissions(client, guild, guildId)
      : await _computeBotPermissions(client, guild, guildId);
  budget?.check();

  if (perms.isAdministrator) return null;

  final missing = <String>[];
  for (final perm in requiredPermissions) {
    if (!perms.has(perm)) {
      missing.add(_permissionName(perm));
    }
  }

  if (missing.isEmpty) return null;
  return 'I do not have permission to $actionLabel. '
      'Missing: ${missing.join(', ')}.';
}

/// Guild-level permission of the command author, independent of bot privileges.
Future<String?> checkMemberGuildPermission(
  NyxxGateway client, {
  required Snowflake guildId,
  required Snowflake memberId,
  required Flag<Permissions> requiredPermission,
}) async {
  final guild = await fetchGuildCached(client, guildId);
  if (guild == null) return 'Guild not found';
  if (memberId == guild.ownerId) return null;
  final member = await guild.members.get(memberId);
  final permissions = _permissionsFromRoles(guild, member.roleIds, guildId);
  if (permissions.isAdministrator || permissions.has(requiredPermission)) {
    return null;
  }
  return 'The command author requires ${_permissionName(requiredPermission)} permission.';
}

// ── Moderation check (permissions + role hierarchy) ─────────────────────────

/// Checks whether the bot can moderate [targetUserId] in the given guild.
///
/// Returns an error string if the action should be blocked, or `null` if
/// the bot is authorised to proceed.
///
/// Checks performed:
/// 1. Bot has the required [requiredPermission] (e.g. ban/kick/moderate).
/// 2. Target is not the guild owner.
/// 3. Bot's highest role is above the target's highest role.
Future<String?> checkBotCanModerate(
  NyxxGateway client, {
  required Snowflake guildId,
  required Snowflake targetUserId,
  required Flag<Permissions> requiredPermission,
  required String actionLabel,
  BotPermissionCache? cache,
  bool allowNonMember = false,
  bool disallowAdministrator = false,
}) async {
  final guild = cache != null
      ? await cache.getGuild(client, guildId)
      : await fetchGuildCached(client, guildId);
  if (guild == null) return 'Guild not found';

  // ── 1. Check bot permissions ──
  final botMember = cache != null
      ? await cache.getBotMember(client, guild)
      : await guild.members.get(client.user.id);
  final botRoleIds = botMember.roleIds;
  final botPermissions = _permissionsFromRoles(guild, botRoleIds, guildId);

  if (!botPermissions.isAdministrator &&
      !botPermissions.has(requiredPermission)) {
    return 'I do not have permission to $actionLabel.';
  }

  // ── 2. Cannot target the guild owner ──
  if (targetUserId == guild.ownerId) {
    return 'I cannot $actionLabel the server owner.';
  }

  // ── 3. Role hierarchy: bot's highest role must be above target's ──
  final Member targetMember;
  try {
    targetMember = await guild.members.get(targetUserId);
  } on DiscordEntityNotFound {
    if (!allowNonMember) rethrow;
    return null;
  } on HttpResponseError catch (error) {
    // Only a definite unknown guild member allows banning an external user.
    // Permission/network failures must still block the mutation.
    if (!allowNonMember ||
        error.statusCode != 404 ||
        error.errorCode != 10007) {
      rethrow;
    }
    return null;
  }
  final targetRoleIds = targetMember.roleIds;
  if (disallowAdministrator &&
      _permissionsFromRoles(guild, targetRoleIds, guildId).isAdministrator) {
    return 'I cannot $actionLabel an administrator.';
  }

  final hierarchy = orderedDiscordRoles(guild.roleList, guildId);
  int highestRank(List<Snowflake> roleIds) => hierarchy.indexWhere(
    (role) => role.id == guildId || roleIds.contains(role.id),
  );
  final botHighest = highestRank(botRoleIds);
  final targetHighest = highestRank(targetRoleIds);
  if (botHighest < 0 || targetHighest < 0 || botHighest >= targetHighest) {
    return 'I cannot $actionLabel this user: their highest role is equal to or above mine.';
  }

  return null;
}

// ── Human-readable permission names ─────────────────────────────────────────

String _permissionName(Flag<Permissions> flag) {
  final map = <int, String>{
    Permissions.addReactions.value: 'Add Reactions',
    Permissions.administrator.value: 'Administrator',
    Permissions.banMembers.value: 'Ban Members',
    Permissions.createInstantInvite.value: 'Create Instant Invite',
    Permissions.createPublicThreads.value: 'Create Public Threads',
    Permissions.createPrivateThreads.value: 'Create Private Threads',
    Permissions.kickMembers.value: 'Kick Members',
    Permissions.manageChannels.value: 'Manage Channels',
    Permissions.manageGuild.value: 'Manage Server',
    Permissions.manageMessages.value: 'Manage Messages',
    Permissions.manageRoles.value: 'Manage Roles',
    Permissions.manageWebhooks.value: 'Manage Webhooks',
    Permissions.moderateMembers.value: 'Moderate Members',
    Permissions.moveMembers.value: 'Move Members',
    Permissions.muteMembers.value: 'Mute Members',
    Permissions.deafenMembers.value: 'Deafen Members',
    Permissions.readMessageHistory.value: 'Read Message History',
    Permissions.sendMessages.value: 'Send Messages',
    Permissions.manageGuildExpressions.value: 'Manage Expressions',
  };
  return map[flag.value] ?? 'Permission(${flag.value})';
}

/// Role grants compare the role being changed, rather than the recipient's rank.
/// Nyxx exposes managed bot/integration/booster roles through their tags; Discord
/// remains authoritative for other managed roles not represented by this SDK.
Future<String?> checkBotCanManageRole(
  NyxxGateway client, {
  required Snowflake guildId,
  required Snowflake roleId,
  bool allowEveryone = false,
}) async {
  final guild = await fetchGuildCached(client, guildId);
  if (guild == null) return 'Guild not found';
  final bot = await guild.members.get(client.user.id);
  final permissions = _permissionsFromRoles(guild, bot.roleIds, guildId);
  if (!permissions.isAdministrator &&
      !permissions.has(Permissions.manageRoles)) {
    return 'I do not have permission to manage roles.';
  }
  final role = guild.roleList.where((r) => r.id == roleId).firstOrNull;
  if (role == null) return 'Role not found';
  if (role.id == guildId && !allowEveryone) {
    return 'The everyone role cannot be assigned or removed.';
  }
  final tags = role.tags;
  if (tags != null &&
      (tags.botId != null ||
          tags.integrationId != null ||
          tags.isPremiumSubscriber)) {
    return 'A managed role cannot be assigned or removed.';
  }
  final hierarchy = orderedDiscordRoles(guild.roleList, guildId);
  final botRank = hierarchy.indexWhere(
    (r) => r.id == guildId || bot.roleIds.contains(r.id),
  );
  final roleRank = hierarchy.indexWhere((r) => r.id == roleId);
  if (role.id != guildId &&
      (botRank < 0 || roleRank < 0 || roleRank <= botRank)) {
    return 'This role is equal to or above my highest role.';
  }
  return null;
}

/// Check every role that would be added or removed before issuing a replacement.
Future<String?> checkBotCanReplaceRoles(
  NyxxGateway client, {
  required Snowflake guildId,
  required Snowflake userId,
  required List<Snowflake> roleIds,
  CommandExecutionBudget? budget,
}) async {
  final permissionError = await checkBotGuildPermission(
    client,
    guildId: guildId,
    requiredPermissions: [Permissions.manageRoles],
    actionLabel: 'set roles',
  );
  budget?.check();
  if (permissionError != null) return permissionError;
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) return 'Guild not found';
  final member = await guild.members.get(userId);
  budget?.check();
  final desired = roleIds.toSet();
  final current = member.roleIds.toSet();
  final known = guild.roleList.map((r) => r.id).toSet();
  if (desired.contains(guildId)) {
    return 'The everyone role cannot be assigned or removed.';
  }
  if (desired.any((id) => !known.contains(id))) return 'Role not found';
  final changed = desired
      .difference(current)
      .union(current.difference(desired));
  for (final roleId in changed) {
    final error = await checkBotCanManageRole(
      client,
      guildId: guildId,
      roleId: roleId,
    );
    budget?.check();
    if (error != null) return error;
  }
  return null;
}
