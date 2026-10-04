import '../../services/bot_component_service.dart';
import '../../services/bot_cooldown_service.dart';
import '../../services/bot_timing_service.dart';
import 'component_functions.dart';
import 'cooldown_functions.dart';
import 'timing_functions.dart';
import '../../services/bot_webhook_service.dart';
import 'webhook_functions.dart';
import 'ticket_functions.dart';
import 'bot_query_functions.dart';
import 'canvas_functions.dart';
import 'advanced_language_functions.dart';
import 'leaderboard_functions.dart';
import 'music_functions.dart';
import '../../services/bot_command_query_service.dart';
import 'command_query_functions.dart';
import '../../services/bot_emoji_service.dart';
import 'emoji_functions.dart';
import 'member_query_functions.dart';
import 'interaction_functions.dart';
import 'access_guard_functions.dart';
import '../../services/bot_member_query_service.dart';
import 'message_query_functions.dart';
import 'reaction_functions.dart';
import '../../services/bot_message_query_service.dart';
import '../../services/bot_reaction_service.dart';
import 'channel_permission_functions.dart';
import 'permission_query_functions.dart';
import 'random_functions.dart';
import 'time_functions.dart';
import 'user_query_functions.dart';
import 'guild_query_functions.dart';
import 'thread_functions.dart';
import '../../services/bot_user_query_service.dart';
import '../../services/bot_guild_query_service.dart';
import '../../services/bot_thread_service.dart';
import '../../services/bot_permission_query_service.dart';
import '../../services/bot_channel_permission_service.dart';
import '../execution_budget.dart';
import '../../bot/bot_data_store.dart';
import '../../services/http_service.dart';
import '../../services/bot_message_service.dart';
import '../../services/bot_moderation_service.dart';
import '../../services/bot_role_query_service.dart';
import '../../services/bot_channel_query_service.dart';
import 'channel_query_functions.dart';
import 'channel_mutation_functions.dart';
import '../../services/bot_channel_mutation_service.dart';
import '../../services/variable_service.dart';
import 'context_functions.dart';
import 'context_guard_functions.dart';
import 'http_functions.dart';
import 'json_functions.dart';
import 'message_functions.dart';
import 'moderation_functions.dart';
import 'role_functions.dart';
import 'role_query_functions.dart';
import 'program.dart';
import 'runtime.dart';
import '../../services/bot_music_service.dart';
import 'text_functions.dart';
import 'text_utility_functions.dart';
import 'variable_functions.dart';
import 'workflow_functions.dart';

/// Native execution API for command, event, workflow and sandbox adapters.
/// The AST and its control flow never pass through the visual Action model.
/// Unsupported known capabilities fail before effects; unknown functions are
/// opaque literals. This engine has no automatic fallback to a legacy backend.
class BdfdEngine {
  BdfdEngine({
    required BotDataStore store,
    required String botId,
    bool legacyUserVariables = false,
    HttpService? http,
    BotMessageService? messages,
    BotModerationService? moderation,
    BotComponentService? components,
    BotTimingService? timing,
    BotDelayService delays = const RuntimeBotDelayService(),
    BotWebhookService? webhooks,
    BotCommandQueryService? commandQueries,
    BotRoleQueryService? roleQueries,
    BotChannelQueryService? channelQueries,
    BotChannelMutationService? channelMutations,
    BotChannelPermissionService? channelPermissions,
    BotPermissionQueryService? permissionQueries,
    BotUserQueryService? userQueries,
    BotGuildQueryService? guildQueries,
    BotThreadService? threads,
    BotMessageQueryService? messageQueries,
    BotReactionService? reactions,
    BotMemberQueryService? memberQueries,
    BotEmojiService? emojis,
    BotMusicService? music,
    BdfdVisualWorkflowRunner? runVisualWorkflow,
    Map<String, BdfdNativeFunction> functions = const {},
  }) : _components = components,
       _timing = timing,
       _webhooks =
           webhooks ??
           (moderation is BotWebhookService
               ? moderation as BotWebhookService
               : null),
       _messages = messages,
       _messageQueries =
           messageQueries ??
           (moderation is BotMessageQueryService
               ? moderation as BotMessageQueryService
               : null),
       _reactions =
           reactions ??
           (moderation is BotReactionService
               ? moderation as BotReactionService
               : null),
       _runtime = BdfdRuntime(
         functions: {
           if (messageQueries != null)
             ...bdfdMessageQueryFunctions(messageQueries)
           else if (moderation is BotMessageQueryService)
             ...bdfdMessageQueryFunctions(moderation as BotMessageQueryService),
           if (reactions != null)
             ...bdfdReactionFunctions(reactions)
           else if (moderation is BotReactionService)
             ...bdfdReactionFunctions(moderation as BotReactionService),
           if (emojis != null)
             ...bdfdEmojiFunctions(emojis)
           else if (moderation is BotEmojiService)
             ...bdfdEmojiFunctions(moderation as BotEmojiService),
           if (webhooks != null)
             ...bdfdWebhookFunctions(webhooks)
           else if (moderation is BotWebhookService)
             ...bdfdWebhookFunctions(moderation as BotWebhookService),
           if (commandQueries != null)
             ...bdfdCommandQueryFunctions(commandQueries),
           ...bdfdCooldownFunctions(
             StoredBotCooldownService(store),
             botId: botId,
           ),
           ...bdfdTimingFunctions(
             delays: delays,
             messages:
                 messageQueries ??
                 (moderation is BotMessageQueryService
                     ? moderation as BotMessageQueryService
                     : null),
           ),
           ...bdfdComponentFunctions(components),
           ...bdfdContextFunctions(),
           ...bdfdInteractionFunctions(),
           if (memberQueries != null)
             ...bdfdMemberQueryFunctions(memberQueries)
           else if (moderation is BotMemberQueryService)
             ...bdfdMemberQueryFunctions(moderation as BotMemberQueryService),
           ...bdfdContextGuardFunctions(),
           ..._accessGuards(
             permissionQueries ??
                 (moderation is BotPermissionQueryService
                     ? moderation as BotPermissionQueryService
                     : null),
             roleQueries ??
                 (moderation is BotRoleQueryService
                     ? moderation as BotRoleQueryService
                     : null),
             channelQueries ??
                 (moderation is BotChannelQueryService
                     ? moderation as BotChannelQueryService
                     : null),
           ),
           ...bdfdRandomFunctions(),
           ...bdfdTimeFunctions(),
           if (userQueries != null)
             ...bdfdUserQueryFunctions(userQueries)
           else if (moderation is BotUserQueryService)
             ...bdfdUserQueryFunctions(moderation as BotUserQueryService),
           if (guildQueries != null)
             ...bdfdGuildQueryFunctions(guildQueries)
           else if (moderation is BotGuildQueryService)
             ...bdfdGuildQueryFunctions(moderation as BotGuildQueryService),
           ...bdfdGuildQueryAliases(
             guildQueries ??
                 (moderation is BotGuildQueryService
                     ? moderation as BotGuildQueryService
                     : null),
           ),
           if (threads != null)
             ...bdfdThreadFunctions(threads)
           else if (moderation is BotThreadService)
             ...bdfdThreadFunctions(moderation as BotThreadService),
           if (permissionQueries != null)
             ...bdfdPermissionQueryFunctions(permissionQueries)
           else if (moderation is BotPermissionQueryService)
             ...bdfdPermissionQueryFunctions(
               moderation as BotPermissionQueryService,
             ),
           if (channelPermissions != null)
             ...bdfdChannelPermissionFunctions(channelPermissions)
           else if (moderation is BotChannelPermissionService)
             ...bdfdChannelPermissionFunctions(
               moderation as BotChannelPermissionService,
             ),
           if (channelMutations != null)
             ...bdfdChannelMutationFunctions(
               channelMutations,
               queries:
                   channelQueries ??
                   (moderation is BotChannelQueryService
                       ? moderation as BotChannelQueryService
                       : null),
             )
           else if (moderation is BotChannelMutationService)
             ...bdfdChannelMutationFunctions(
               moderation as BotChannelMutationService,
               queries:
                   channelQueries ??
                   (moderation is BotChannelQueryService
                       ? moderation as BotChannelQueryService
                       : null),
             ),
           if (channelQueries != null)
             ...bdfdChannelQueryFunctions(channelQueries)
           else if (moderation is BotChannelQueryService)
             ...bdfdChannelQueryFunctions(moderation as BotChannelQueryService),
           ...bdfdVariableFunctions(
             VariableService(store, botId),
             legacyUserVariables: legacyUserVariables,
           ),
           ...bdfdJsonFunctions(),
           ...bdfdTextFunctions(),
           ...bdfdTextUtilityFunctions(),
           ...bdfdWorkflowFunctions(
             store,
             botId,
             runVisualWorkflow: runVisualWorkflow,
           ),
           if (messages != null) ...bdfdMessageFunctions(),
           if (moderation != null) ...bdfdModerationFunctions(moderation),
           if (moderation != null) ...bdfdRoleFunctions(moderation),
           if (roleQueries != null)
             ...bdfdRoleQueryFunctions(roleQueries)
           else if (moderation is BotRoleQueryService)
             ...bdfdRoleQueryFunctions(moderation as BotRoleQueryService),
           ...bdfdHttpFunctions(http ?? HttpService()),
           ...bdfdTicketFunctions(
             service:
                 channelMutations ??
                 (moderation is BotChannelMutationService
                     ? moderation as BotChannelMutationService
                     : null),
             queries:
                 channelQueries ??
                 (moderation is BotChannelQueryService
                     ? moderation as BotChannelQueryService
                     : null),
           ),
           ...bdfdBotQueryFunctions(moderation: moderation),
           ...bdfdCanvasFunctions(),
           ...bdfdAdvancedLanguageFunctions(),
           ...bdfdAwaitFunctions(store, botId),
           ...bdfdLeaderboardFunctions(
             store: store,
             botId: botId,
             legacyUserVariables: legacyUserVariables,
             users:
                 userQueries ??
                 (moderation is BotUserQueryService
                     ? moderation as BotUserQueryService
                     : null),
             guilds:
                 guildQueries ??
                 (moderation is BotGuildQueryService
                     ? moderation as BotGuildQueryService
                     : null),
           ),
           ...bdfdMusicFunctions(music),
           ...functions,
         },
       );

  /// Preflight uses the production registry with services that reject calls.
  /// It cannot read storage, send a message or execute a request.
  factory BdfdEngine.validation() => BdfdEngine(
    store: _ValidationStore(),
    botId: 'validation',
    http: HttpService(
      clientFactory: () => throw StateError('Validation cannot access HTTP.'),
    ),
    messages: _ValidationMessages(),
    moderation: _ValidationModeration(),
    commandQueries: _ValidationCommandQueries(),
  );

  static const backendId = 'native-v1';
  final BdfdRuntime _runtime;
  final BotWebhookService? _webhooks;
  final BotComponentService? _components;
  final BotTimingService? _timing;
  final BotMessageService? _messages;
  final BotMessageQueryService? _messageQueries;
  final BotReactionService? _reactions;

  BdfdContext _context(BdfdContext? context) {
    final invocation = context ?? BdfdContext();
    if (_messages != null) {
      invocation.output ??= BdfdMessageOutput(
        _messages,
        messageQueries: _messageQueries,
        reactions: _reactions,
        components: _components,
        timing:
            _timing ??
            (_messageQueries == null
                ? null
                : RuntimeBotTimingService(_messageQueries)),
      );
    }
    return invocation;
  }

  Set<String> get supportedFunctions => _runtime.supportedFunctions;

  /// Entry points can preflight source without performing any bot effects.
  BdfdProgram prepare(String source) => _runtime.prepare(source);

  Future<String> execute(String source, {BdfdContext? context}) async =>
      executeProgram(prepare(source), context: context);

  Future<String> executeProgram(
    BdfdProgram program, {
    BdfdContext? context,
  }) async {
    final invocation = _context(context);
    final state = bdfdWebhookState(invocation);
    try {
      final result = await _runtime.executeProgram(
        program,
        context: invocation,
      );
      if (invocation.stopped) {
        state.discard();
      } else if (_webhooks != null) {
        await state.flush(_webhooks, invocation);
      }
      return result;
    } catch (_) {
      state.discard();
      rethrow;
    }
  }
}

Map<String, BdfdNativeFunction> _accessGuards(
  BotPermissionQueryService? permissions,
  BotRoleQueryService? roles,
  BotChannelQueryService? channels,
) => permissions == null || roles == null || channels == null
    ? {}
    : bdfdAccessGuardFunctions(
        permissions: permissions,
        roles: roles,
        channels: channels,
      );

class _ValidationStore implements BotDataStore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Validation cannot access storage.');
}

class _ValidationMessages implements BotMessageService {
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async => throw StateError('Validation cannot send messages.');
}

class _ValidationModeration
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
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Validation cannot execute Discord effects.');

  @override
  Future<BotEmoji?> emoji(
    String id, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read emojis.');
  @override
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read emojis.');
  @override
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot list emojis.');
  @override
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot create emojis.');
  @override
  Future<void> deleteEmoji(
    String id, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot delete emojis.');
  @override
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot list members.');
  @override
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read members.');
  @override
  Future<int> allGuildMembersCount({
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot count members.');
  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read message channels.');
  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read messages.');
  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot mutate messages.');
  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot add reactions.');
  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot clear reactions.');
  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read reactions.');
  @override
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot create threads.');
  @override
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot edit threads.');
  @override
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot add thread members.');
  @override
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot remove thread members.');
  @override
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read threads.');
  @override
  Future<BotUser?> user(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read users.');
  @override
  Future<BotUserMember?> member(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read members.');
  @override
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read guilds.');
  @override
  Future<List<BotGuild>> guilds({
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot list guilds.');
  @override
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async =>
      throw StateError('Validation cannot read guild channel settings.');
  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read permissions.');
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read permissions.');
  @override
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot edit channel permissions.');
  @override
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot create channels.');
  @override
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot modify channels.');
  @override
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot delete channels.');
  @override
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot change channels.');
  @override
  Future<int> countChannels({required CommandExecutionBudget budget}) async =>
      throw StateError('Validation cannot count channels.');
  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read channels.');
  @override
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read channels.');
  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read roles.');
  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot read members.');
  @override
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('Validation cannot moderate users.');
}

class _ValidationCommandQueries implements BotCommandQueryService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Validation cannot access commands or guilds.');
}
