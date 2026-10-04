import 'bot_webhook_service.dart';
import 'bot_emoji_service.dart';
import 'bot_member_query_service.dart';
import 'bot_message_query_service.dart';
import 'bot_reaction_service.dart';
import 'bot_channel_permission_service.dart';
import 'bot_permission_query_service.dart';
import 'bot_channel_mutation_service.dart';
import 'bot_channel_query_service.dart';
import 'package:nyxx/nyxx.dart';

import '../actions/delete_message.dart';
import 'bot_block_discord_actions.dart'
    show
        registerGuildCommandsAction,
        setNicknameAction,
        unregisterGuildCommandsAction;
import '../bot/bot_data_store.dart';

import '../engine/execution_budget.dart';
import '../utils/global.dart';
import 'permission_checks.dart';
import 'role_definition.dart';
import 'bot_role_query_service.dart';
import 'bot_user_query_service.dart';
import 'bot_guild_query_service.dart';
import 'bot_thread_service.dart';

enum BotModerationOperation {
  kick,
  ban,
  unban,
  timeout,
  untimeout,
  addRole,
  removeRole,
  createRole,
  updateRole,
  deleteRole,
  setUserRoles,
  clearMessages,
  setNickname,
  registerGuildCommands,
  unregisterGuildCommands,
  isBanned,
  banReason,
}

/// Evaluated moderation data. No script or block placeholders are interpreted.
class BotModerationRequest {
  const BotModerationRequest({
    required this.operation,
    required this.userId,
    this.reason = '',
    this.username = '',
    this.roleId = '',
    this.roleDefinition,
    this.roleReplacement,
    this.deleteMessageDays = 0,
    this.useDefaultReason = true,
    this.duration = const Duration(minutes: 10),
    this.until,
    this.clampTimeout = true,
    this.kickPermissionActorId,
    this.count = 0,
    this.onlyUserId = '',
    this.removePinned = true,
    this.nickname = '',
    this.targetGuildId = '',
    this.channelId = '',
  });

  final BotModerationOperation operation;
  // Message clearing: amount, optional author filter and pinned policy.
  final int count;
  final String onlyUserId;
  final bool removePinned;
  final String nickname;
  // Explicit guild override for bans lookups; empty means the current guild.
  final String targetGuildId;
  final String channelId;
  final String userId;
  final String reason;
  final String username;
  final String roleId;
  final RoleDefinition? roleDefinition;
  final RoleReplacement? roleReplacement;
  final Duration duration;
  final DateTime? until;
  final bool clampTimeout;
  // Set by kickMention; an empty actor ID fails instead of disabling the check.
  final String? kickPermissionActorId;
  final int deleteMessageDays;
  // Visual blocks retain their historical audit reason; BDFD can omit it.
  final bool useDefaultReason;

  DateTime timeoutDeadline(DateTime now) {
    final deadline = until?.toUtc() ?? now.add(duration);
    final maximum = now.add(const Duration(days: 28));
    if (!clampTimeout) {
      if (!deadline.isAfter(now) || deadline.isAfter(maximum)) {
        throw ArgumentError(
          'Timeout duration must be positive and at most 28 days.',
        );
      }
      return deadline;
    }
    if (deadline.isAfter(maximum)) return maximum;
    if (!deadline.isAfter(now)) return now.add(const Duration(seconds: 1));
    return deadline;
  }

  String? get auditLogReason {
    final value = reason.trim();
    if (value.isNotEmpty) return value;
    if (!useDefaultReason) return null;
    return switch (operation) {
      BotModerationOperation.setUserRoles => 'Set roles via BotCreator action',
      BotModerationOperation.createRole => 'Create role via BotCreator action',
      BotModerationOperation.updateRole => 'Update role via BotCreator action',
      BotModerationOperation.deleteRole => 'Delete role via BotCreator action',
      BotModerationOperation.addRole => 'Add role via BotCreator action',
      BotModerationOperation.removeRole => 'Remove role via BotCreator action',
      BotModerationOperation.kick => 'Kick via BotCreator action',
      BotModerationOperation.ban => 'Ban via BotCreator action',
      BotModerationOperation.unban => 'Unban via BotCreator action',
      BotModerationOperation.timeout => 'Timeout via BotCreator action',
      BotModerationOperation.untimeout =>
        'Remove timeout via BotCreator action',
      BotModerationOperation.clearMessages => null,
      BotModerationOperation.setNickname => null,
      BotModerationOperation.registerGuildCommands => null,
      BotModerationOperation.unregisterGuildCommands => null,
      BotModerationOperation.isBanned => null,
      BotModerationOperation.banReason => null,
    };
  }
}

abstract interface class BotModerationService {
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  });
}

/// Discord adapter shared with visual moderation blocks.
class DiscordBotModerationService
    implements
        BotModerationService,
        BotRoleQueryService,
        BotChannelQueryService,
        BotChannelMutationService,
        BotChannelPermissionService,
        BotPermissionQueryService,
        BotUserQueryService,
        BotGuildQueryService,
        BotThreadService,
        BotMessageQueryService,
        BotReactionService,
        BotMemberQueryService,
        BotEmojiService,
        BotWebhookService {
  const DiscordBotModerationService({
    required this.client,
    this.guildId,
    this.store,
    this.botId,
  });

  /// Needed only by guild command registration.
  final BotDataStore? store;
  final String? botId;

  DiscordBotWebhookService get _webhooks =>
      DiscordBotWebhookService(client: client);
  @override
  Future<String> create(
    String channelId,
    String name,
    String avatarUrl, {
    required CommandExecutionBudget budget,
  }) => _webhooks.create(channelId, name, avatarUrl, budget: budget);
  @override
  Future<void> update(
    BotWebhookReference webhook, {
    String? name,
    String? avatarUrl,
    required CommandExecutionBudget budget,
  }) => _webhooks.update(
    webhook,
    name: name,
    avatarUrl: avatarUrl,
    budget: budget,
  );
  @override
  Future<void> delete(
    BotWebhookReference webhook, {
    required CommandExecutionBudget budget,
  }) => _webhooks.delete(webhook, budget: budget);
  @override
  Future<void> send(
    BotWebhookReference webhook,
    Map<String, dynamic> payload, {
    required CommandExecutionBudget budget,
  }) => _webhooks.send(webhook, payload, budget: budget);
  final NyxxGateway client;
  final Snowflake? guildId;
  DiscordBotEmojiService get _emojiService =>
      DiscordBotEmojiService(client: client, guildId: guildId);
  @override
  Future<BotEmoji?> emoji(
    String id, {
    required CommandExecutionBudget budget,
  }) => _emojiService.emoji(id, budget: budget);
  @override
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  }) => _emojiService.emojiByName(name, budget: budget);
  @override
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => _emojiService.emojis(guildId: guildId, budget: budget);
  @override
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  }) => _emojiService.createEmoji(request, budget: budget);
  @override
  Future<void> deleteEmoji(
    String id, {
    required CommandExecutionBudget budget,
  }) => _emojiService.deleteEmoji(id, budget: budget);
  @override
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => DiscordBotMemberQueryService(
    client: client,
    guildId: this.guildId,
  ).guildMembers(guildId: guildId, budget: budget);
  @override
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  }) => DiscordBotMemberQueryService(
    client: client,
    guildId: this.guildId,
  ).guildMember(userId, guildId: guildId, budget: budget);
  @override
  Future<int> allGuildMembersCount({required CommandExecutionBudget budget}) =>
      DiscordBotMemberQueryService(
        client: client,
        guildId: guildId,
      ).allGuildMembersCount(budget: budget);
  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotMessageQueryService(
    client: client,
  ).messageChannel(channelId, budget: budget);
  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) => DiscordBotMessageQueryService(
    client: client,
  ).message(channelId: channelId, messageId: messageId, budget: budget);
  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotMessageQueryService(
    client: client,
  ).mutateMessage(change, budget: budget);
  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) => DiscordBotReactionService(
    client: client,
  ).addReactions(request, budget: budget);
  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) => DiscordBotReactionService(
    client: client,
  ).clearReactions(request, budget: budget);
  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) => DiscordBotReactionService(
    client: client,
  ).reactionUsers(query, budget: budget);
  DiscordBotThreadService get _threads =>
      DiscordBotThreadService(client: client, guildId: guildId);
  @override
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) => _threads.startThread(change, budget: budget);
  @override
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) => _threads.editThread(change, budget: budget);
  @override
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _threads.addThreadMember(change, budget: budget);
  @override
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _threads.removeThreadMember(change, budget: budget);
  @override
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  }) => _threads.threadInfo(threadId: threadId, budget: budget);
  @override
  Future<BotUser?> user(
    String userId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotUserQueryService(
    client: client,
    guildId: guildId,
  ).user(userId, budget: budget);
  @override
  Future<BotUserMember?> member(
    String userId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotUserQueryService(
    client: client,
    guildId: guildId,
  ).member(userId, budget: budget);
  @override
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => DiscordBotGuildQueryService(
    client: client,
    guildId: this.guildId,
  ).guild(guildId: guildId, budget: budget);
  @override
  Future<List<BotGuild>> guilds({required CommandExecutionBudget budget}) =>
      DiscordBotGuildQueryService(
        client: client,
        guildId: guildId,
      ).guilds(budget: budget);

  @override
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelQueryService(
    client: client,
    guildId: this.guildId,
  ).guildChannelSettings(guildId: guildId, budget: budget);

  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotPermissionQueryService(
    client: client,
    guildId: guildId,
  ).storedMemberPermissions(userId, budget: budget);

  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) => DiscordBotPermissionQueryService(
    client: client,
    guildId: guildId,
  ).memberPermissions(userId: userId, channelId: channelId, budget: budget);

  @override
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelPermissionService(
    client,
  ).editPermissions(change, budget: budget);
  @override
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelMutationService(
    client,
  ).createChannel(change, budget: budget);
  @override
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelMutationService(
    client,
  ).modifyChannel(change, budget: budget);
  @override
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelMutationService(
    client,
  ).deleteChannel(change, budget: budget);
  @override
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelMutationService(
    client,
  ).setSlowmode(change, budget: budget);
  @override
  Future<int> countChannels({required CommandExecutionBudget budget}) =>
      DiscordBotChannelQueryService(
        client: client,
        guildId: guildId,
      ).countChannels(budget: budget);
  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelQueryService(
    client: client,
    guildId: guildId,
  ).channel(id, budget: budget);
  @override
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  }) => DiscordBotChannelQueryService(client: client, guildId: this.guildId)
      .channels(
        guildId: guildId,
        includeActiveThreads: includeActiveThreads,
        budget: budget,
      );
  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => DiscordBotRoleQueryService(
    client: client,
    guildId: this.guildId,
  ).roles(guildId: guildId, budget: budget);
  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) => DiscordBotRoleQueryService(
    client: client,
    guildId: guildId,
  ).memberRoleIds(userId, budget: budget);

  @override
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final result = await executeDiscordModeration(
      client,
      guildId: guildId,
      request: request,
      budget: budget,
      store: store,
      botId: botId,
    );
    budget.check();
    if (result['value'] != null) return result['value']!;
    if (result['error'] != null) throw StateError(result['error']!);
    return result['userId'] ?? result['roleId']!;
  });
}

/// The transport retains the existing block result/error contract. The native
/// adapter supplies its shared budget, including a check immediately before
/// the destructive SDK call after asynchronous permission/hierarchy lookups.
Future<Map<String, String>> executeDiscordModeration(
  NyxxGateway client, {
  required Snowflake? guildId,
  required BotModerationRequest request,
  CommandExecutionBudget? budget,
  BotDataStore? store,
  String? botId,
}) async {
  final label = request.operation.name;
  try {
    budget?.check();
    if (guildId == null) return {'error': 'Missing guildId', 'userId': ''};
    switch (request.operation) {
      case BotModerationOperation.clearMessages:
        final channel = int.tryParse(request.channelId.trim());
        if (channel == null || channel <= 0) {
          return {'error': 'Missing or invalid channelId'};
        }
        final permError = await checkBotGuildPermission(
          client,
          guildId: guildId,
          requiredPermissions: [
            Permissions.manageMessages,
            Permissions.readMessageHistory,
          ],
          actionLabel: 'delete messages',
        );
        budget?.check();
        if (permError != null) return {'error': permError};
        final deleted = await deleteMessage(
          client,
          Snowflake(channel),
          count: request.count,
          onlyThisUserID: request.onlyUserId,
          deletePinned: request.removePinned,
          reason: request.reason,
        );
        budget?.check();
        if (deleted['error'] != null) return {'error': deleted['error']!};
        return {'value': ''};
      case BotModerationOperation.setNickname:
        final result = await setNicknameAction(
          client,
          guildId: guildId,
          payload: {
            'userId': request.userId,
            'nickname': request.nickname,
            // BDFD passes none; the visual block forwards its audit reason.
            if (request.reason.isNotEmpty) 'reason': request.reason,
          },
        );
        budget?.check();
        if (result['error'] != null) return {'error': result['error']!};
        return {'userId': request.userId};
      case BotModerationOperation.registerGuildCommands:
      case BotModerationOperation.unregisterGuildCommands:
        if (store == null || botId == null) {
          return {'error': 'Guild command registration is not configured'};
        }
        final target = int.tryParse(request.targetGuildId.trim());
        final scope = target == null ? guildId : Snowflake(target);
        final result =
            request.operation == BotModerationOperation.registerGuildCommands
            ? await registerGuildCommandsAction(
                client,
                botId: botId,
                store: store,
                guildId: scope,
                payload: const {},
              )
            : await unregisterGuildCommandsAction(
                client,
                botId: botId,
                store: store,
                guildId: scope,
                payload: const {},
              );
        budget?.check();
        if (result['error'] != null) return {'error': result['error']!};
        return {'value': ''};
      case BotModerationOperation.isBanned:
      case BotModerationOperation.banReason:
        final user = int.tryParse(request.userId.trim());
        if (user == null || user <= 0) {
          return {'error': 'Missing or invalid userId'};
        }
        final scope = int.tryParse(request.targetGuildId.trim());
        final guild = scope == null ? guildId : Snowflake(scope);
        final permError = await checkBotGuildPermission(
          client,
          guildId: guild,
          requiredPermissions: [Permissions.banMembers],
          actionLabel: 'read bans',
        );
        budget?.check();
        if (permError != null) return {'error': permError};
        Ban? ban;
        try {
          ban = await client.guilds.fetchBan(guild, Snowflake(user));
        } on HttpResponseError catch (error) {
          if (error.statusCode != 404) rethrow;
        }
        budget?.check();
        return {
          'value': request.operation == BotModerationOperation.isBanned
              ? '${ban != null}'
              : (ban?.reason ?? ''),
        };
      default:
        break;
    }
    if (request.operation == BotModerationOperation.setUserRoles) {
      return await _replaceRoles(client, guildId, request, budget);
    }
    if (request.operation == BotModerationOperation.createRole ||
        request.operation == BotModerationOperation.updateRole ||
        request.operation == BotModerationOperation.deleteRole) {
      return await _roleDefinition(client, guildId, request, budget);
    }
    if (request.operation == BotModerationOperation.unban) {
      return await _unban(client, guildId, request, budget);
    }
    if (request.operation == BotModerationOperation.timeout ||
        request.operation == BotModerationOperation.untimeout) {
      return await _timeout(client, guildId, request, budget);
    }
    if (request.operation == BotModerationOperation.addRole ||
        request.operation == BotModerationOperation.removeRole) {
      return await _role(client, guildId, request, budget);
    }
    final parsed = int.tryParse(request.userId.trim());
    if (parsed == null || parsed <= 0) {
      return {'error': 'Missing or invalid userId', 'userId': ''};
    }
    final userId = Snowflake(parsed);
    await checkModerationActorPermission(client, guildId, request, budget);
    final permissionError = await checkBotCanModerate(
      client,
      guildId: guildId,
      targetUserId: userId,
      requiredPermission: request.operation == BotModerationOperation.kick
          ? Permissions.kickMembers
          : Permissions.banMembers,
      actionLabel: label,
      allowNonMember: request.operation == BotModerationOperation.ban,
    );
    budget?.check();
    if (permissionError != null) {
      return {'error': permissionError, 'userId': ''};
    }
    final guild = await fetchGuildCached(client, guildId);
    budget?.check();
    if (guild == null) return {'error': 'Guild not found', 'userId': ''};
    final auditReason = request.auditLogReason;
    if (request.operation == BotModerationOperation.kick) {
      await guild.members[userId].delete(auditLogReason: auditReason);
    } else {
      await guild.createBan(
        userId,
        deleteMessages: Duration(days: request.deleteMessageDays.clamp(0, 7)),
        auditLogReason: auditReason,
      );
    }
    budget?.check();
    return {'userId': userId.toString()};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to $label user: $error', 'userId': ''};
  }
}

Future<Map<String, String>> _unban(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  final rawId = request.userId.trim();
  final parsed = int.tryParse(rawId);
  final username = request.username.trim();
  if (rawId.isNotEmpty && (parsed == null || parsed <= 0)) {
    return {'error': 'Missing or invalid userId', 'userId': ''};
  }
  if (rawId.isEmpty && username.isEmpty) {
    return {'error': 'Banned user not found', 'userId': ''};
  }
  final permissionError = await checkBotGuildPermission(
    client,
    guildId: guildId,
    requiredPermissions: [Permissions.banMembers],
    actionLabel: 'unban this user',
  );
  budget?.check();
  if (permissionError != null) return {'error': permissionError, 'userId': ''};
  Snowflake? userId = parsed == null ? null : Snowflake(parsed);
  if (userId == null) {
    Snowflake? cursor;
    final cursors = <Snowflake>{};
    while (true) {
      budget?.check();
      final page = await client.guilds.listBans(
        guildId,
        limit: 1000,
        after: cursor,
      );
      budget?.check();
      for (final ban in page) {
        if (ban.user.username.toLowerCase() == username.toLowerCase()) {
          userId = ban.user.id;
          break;
        }
      }
      if (userId != null || page.length < 1000) break;
      final next = page.last.user.id;
      if (!cursors.add(next)) break;
      cursor = next;
    }
  }
  if (userId == null) return {'error': 'Banned user not found', 'userId': ''};
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) return {'error': 'Guild not found', 'userId': ''};
  await guild.deleteBan(userId, auditLogReason: request.auditLogReason);
  budget?.check();
  return {'userId': userId.toString()};
}

Future<Map<String, String>> _timeout(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  final parsed = int.tryParse(request.userId.trim());
  if (parsed == null || parsed <= 0) {
    return {'error': 'Missing or invalid userId/memberId', 'userId': ''};
  }
  final userId = Snowflake(parsed);
  final error = await checkBotCanModerate(
    client,
    guildId: guildId,
    targetUserId: userId,
    requiredPermission: Permissions.moderateMembers,
    actionLabel: request.operation == BotModerationOperation.timeout
        ? 'mute'
        : 'unmute',
    disallowAdministrator: true,
  );
  budget?.check();
  if (error != null) return {'error': error, 'userId': ''};
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) return {'error': 'Guild not found', 'userId': ''};
  final until = request.operation == BotModerationOperation.timeout
      ? request.timeoutDeadline(DateTime.now().toUtc())
      : null;
  final member = await guild.members[userId].update(
    MemberUpdateBuilder(communicationDisabledUntil: until),
    auditLogReason: request.auditLogReason,
  );
  budget?.check();
  return {
    'userId': member.id.toString(),
    if (until != null) 'until': until.toIso8601String(),
    'status': until == null ? 'unmuted' : 'muted',
  };
}

/// Historical visual block duration precedence and default; native signatures
/// use the strict BDFD parser instead of these payload conveniences.
Duration visualTimeoutDuration(Map<String, dynamic> payload) {
  for (final entry in {
    'durationSeconds': 1,
    'durationMinutes': 60,
    'durationHours': 3600,
    'duration': 1,
  }.entries) {
    final amount = int.tryParse(payload[entry.key]?.toString() ?? '');
    if (amount != null) return Duration(seconds: amount * entry.value);
  }
  final match = RegExp(
    r'^(\d+)\s*([smhd])$',
    caseSensitive: false,
  ).firstMatch(payload['duration']?.toString().trim() ?? '');
  if (match != null) {
    final multiplier = switch (match[2]!.toLowerCase()) {
      'm' => 60,
      'h' => 3600,
      'd' => 86400,
      _ => 1,
    };
    return Duration(seconds: int.parse(match[1]!) * multiplier);
  }
  return const Duration(minutes: 10);
}

/// Both SDK and fixture adapters enforce the same kickMention author policy.
Future<void> checkModerationActorPermission(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  if (request.kickPermissionActorId == null) return;
  if (request.operation != BotModerationOperation.kick) {
    throw ArgumentError(
      'Author kick permission is only valid for a kick request.',
    );
  }
  final actor = int.tryParse(request.kickPermissionActorId!.trim());
  if (actor == null || actor <= 0) {
    throw StateError('A valid command author ID is required.');
  }
  final error = await checkMemberGuildPermission(
    client,
    guildId: guildId,
    memberId: Snowflake(actor),
    requiredPermission: Permissions.kickMembers,
  );
  budget?.check();
  if (error != null) throw StateError(error);
}

Future<Map<String, String>> _role(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  final user = int.tryParse(request.userId.trim());
  final role = int.tryParse(request.roleId.trim());
  if (user == null || user <= 0 || role == null || role <= 0) {
    return {
      'error': 'Missing or invalid userId/roleId',
      'userId': '',
      'roleId': '',
    };
  }
  final roleId = Snowflake(role);
  final error = await checkBotCanManageRole(
    client,
    guildId: guildId,
    roleId: roleId,
  );
  budget?.check();
  if (error != null) return {'error': error, 'userId': '', 'roleId': ''};
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) {
    return {'error': 'Guild not found', 'userId': '', 'roleId': ''};
  }
  final member = guild.members[Snowflake(user)];
  final add = request.operation == BotModerationOperation.addRole;
  if (add) {
    await member.addRole(roleId, auditLogReason: request.auditLogReason);
  } else {
    await member.removeRole(roleId, auditLogReason: request.auditLogReason);
  }
  budget?.check();
  return {
    'userId': user.toString(),
    'roleId': role.toString(),
    'status': add ? 'added' : 'removed',
  };
}

Future<Map<String, String>> _roleDefinition(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  final create = request.operation == BotModerationOperation.createRole;
  final delete = request.operation == BotModerationOperation.deleteRole;
  final definition = request.roleDefinition;
  if (!delete) {
    if (definition == null) return {'error': 'Missing role definition'};
    final error = definition.validate(create: create);
    if (error != null) return {'error': error};
  }
  final parsed = int.tryParse(request.roleId.trim());
  if (!create && (parsed == null || parsed <= 0)) {
    return {'error': 'Invalid role ID'};
  }
  final roleId = Snowflake(parsed ?? 0);
  final permissionError = create
      ? await checkBotGuildPermission(
          client,
          guildId: guildId,
          requiredPermissions: [Permissions.manageRoles],
          actionLabel: 'create roles',
        )
      : await checkBotCanManageRole(
          client,
          guildId: guildId,
          roleId: roleId,
          allowEveryone: !delete,
        );
  budget?.check();
  if (permissionError != null) return {'error': permissionError};
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) return {'error': 'Guild not found'};
  final manager = guild.roles;
  final reason = request.auditLogReason;
  if (create) {
    final created = await manager.create(
      RoleBuilder(
        name: definition!.name,
        colors: RoleColorsBuilder(primary: DiscordColor(definition.color!)),
        isHoisted: definition.hoist ?? false,
        isMentionable: definition.mentionable ?? false,
      ),
      auditLogReason: reason,
    );
    budget?.check();
    return {'roleId': created.id.toString(), 'status': 'created'};
  }
  if (delete) {
    await manager.delete(roleId, auditLogReason: reason);
    budget?.check();
    return {'roleId': roleId.toString(), 'status': 'deleted'};
  }
  final position = definition!.position;
  if (position != null) {
    final bot = await guild.members.get(client.user.id);
    budget?.check();
    final positions = guild.roleList
        .where((r) => bot.roleIds.contains(r.id))
        .map((r) => r.position);
    final highest = positions.fold<int>(0, (a, b) => a > b ? a : b);
    if (roleId == guildId || position >= highest) {
      return {'error': 'Invalid role position: must be below the bot'};
    }
  }
  Permissions? permissions;
  if (definition.togglePermissions != null) {
    final role = await manager.fetch(roleId);
    budget?.check();
    var mask = role.permissions.value;
    for (final flag in definition.togglePermissions!) {
      mask ^= flag;
    }
    permissions = Permissions(mask);
  }
  budget?.check();
  await manager.update(
    roleId,
    RoleUpdateBuilder(
      name: definition.name,
      colors: definition.color == null
          ? null
          : RoleColorsBuilder(primary: DiscordColor(definition.color!)),
      isHoisted: definition.hoist,
      isMentionable: definition.mentionable,
      permissions: permissions,
    ),
    auditLogReason: reason,
  );
  budget?.check();
  if (position != null) {
    await manager.updatePositions({roleId: position}, auditLogReason: reason);
    budget?.check();
  }
  return {'roleId': roleId.toString(), 'status': 'updated'};
}

Future<Map<String, String>> _replaceRoles(
  NyxxGateway client,
  Snowflake guildId,
  BotModerationRequest request,
  CommandExecutionBudget? budget,
) async {
  final parsedUser = int.tryParse(request.userId.trim());
  if (parsedUser == null || parsedUser <= 0) {
    return {
      'error': 'Missing or invalid userId/memberId',
      'userId': '',
      'roleId': '',
    };
  }
  final rawRoles = request.roleReplacement?.roleIds;
  if (rawRoles == null) {
    return {'error': 'Missing role replacement', 'userId': '', 'roleId': ''};
  }
  final ids = <Snowflake>{};
  for (final raw in rawRoles) {
    final parsed = int.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) {
      return {
        'error': 'setRoles contains an invalid role ID',
        'userId': '',
        'roleId': '',
      };
    }
    ids.add(Snowflake(parsed));
  }
  final userId = Snowflake(parsedUser);
  final error = await checkBotCanReplaceRoles(
    client,
    guildId: guildId,
    userId: userId,
    roleIds: ids.toList(),
    budget: budget,
  );
  budget?.check();
  if (error != null) return {'error': error, 'userId': '', 'roleId': ''};
  final guild = await fetchGuildCached(client, guildId);
  budget?.check();
  if (guild == null) {
    return {'error': 'Guild not found', 'userId': '', 'roleId': ''};
  }
  await guild.members[userId].update(
    MemberUpdateBuilder(roleIds: ids.toList()),
    auditLogReason: request.auditLogReason,
  );
  budget?.check();
  return {
    'userId': userId.toString(),
    'roleId': ids.join(','),
    'status': 'set',
  };
}
