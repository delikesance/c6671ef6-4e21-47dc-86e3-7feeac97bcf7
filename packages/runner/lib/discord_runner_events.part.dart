part of 'discord_runner.dart';

extension DiscordRunnerEventsExtension on DiscordRunner {
  List<Map<String, dynamic>> get _eventWorkflows {
    final result = <Map<String, dynamic>>[];
    for (final workflow in config.workflows) {
      final normalized = normalizeStoredWorkflowDefinition(workflow);
      if (normalizeWorkflowType(normalized['workflowType']) ==
          workflowTypeEvent) {
        result.add(normalized);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> get _scheduledTriggers {
    return config.scheduledTriggers
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) {
          if (entry['enabled'] == false) {
            return false;
          }
          final workflowName = (entry['workflowName'] ?? '').toString().trim();
          final everyMinutes =
              int.tryParse((entry['everyMinutes'] ?? '').toString()) ?? 0;
          return workflowName.isNotEmpty && everyMinutes > 0;
        })
        .toList(growable: false);
  }

  void _registerEventWorkflowListeners() {
    final gateway = _gateway;
    if (gateway == null) {
      return;
    }

    final mode = resolveEventWorkflowListenerMode(config);
    if (mode == EventWorkflowListenerMode.none) {
      return;
    }

    void registerEvent<T extends GatewayEvent>(
      Stream<T> stream,
      String eventName, {
      FutureOr<EventExecutionContext> Function(T)? buildContext,
    }) {
      _eventWorkflowSubscriptions.add(
        stream.listen((event) async {
          try {
            final context =
                buildContext != null
                    ? await buildContext(event)
                    : _baseEventContext(
                      eventName: eventName,
                      guildId: (event as dynamic).guildId,
                      channelId: (event as dynamic).channelId,
                      userId: (event as dynamic).userId,
                    );
            await _dispatchEventWorkflows(eventName: eventName, context: context);
          } catch (error, stackTrace) {
            _log.warning(
              'Error handling event "$eventName": $error\n$stackTrace',
            );
          }
        }),
      );
    }

    // Message events
    registerEvent<MessageCreateEvent>(
      gateway.onMessageCreate,
      'messageCreate',
      buildContext: buildMessageCreateEventContext,
    );
    registerEvent<MessageUpdateEvent>(
      gateway.onMessageUpdate,
      'messageUpdate',
      buildContext: buildMessageUpdateEventContext,
    );
    registerEvent<MessageDeleteEvent>(
      gateway.onMessageDelete,
      'messageDelete',
      buildContext: buildMessageDeleteEventContext,
    );

    if (mode == EventWorkflowListenerMode.messageCreateOnly) {
      return;
    }

    // Member events
    registerEvent<GuildMemberAddEvent>(
      gateway.onGuildMemberAdd,
      'guildMemberAdd',
      buildContext: buildGuildMemberAddEventContext,
    );
    registerEvent<GuildMemberRemoveEvent>(
      gateway.onGuildMemberRemove,
      'guildMemberRemove',
      buildContext: buildGuildMemberRemoveEventContext,
    );

    // Interaction events (Generic catch-all for workflows)
    registerEvent<InteractionCreateEvent>(
      gateway.onInteractionCreate,
      'interactionCreate',
      buildContext: buildInteractionCreateEventContext,
    );

    // Thread events
    registerEvent<ThreadCreateEvent>(
      gateway.onThreadCreate,
      'threadCreate',
      buildContext: buildThreadCreateEventContext,
    );
    registerEvent<ThreadUpdateEvent>(
      gateway.onThreadUpdate,
      'threadUpdate',
      buildContext: buildThreadUpdateEventContext,
    );
    registerEvent<ThreadDeleteEvent>(
      gateway.onThreadDelete,
      'threadDelete',
      buildContext: buildThreadDeleteEventContext,
    );
    registerEvent<ThreadListSyncEvent>(
      gateway.onThreadListSync,
      'threadListSync',
    );
    registerEvent<ThreadMemberUpdateEvent>(
      gateway.onThreadMemberUpdate,
      'threadMemberUpdate',
      buildContext: buildThreadMemberUpdateEventContext,
    );
    registerEvent<ThreadMembersUpdateEvent>(
      gateway.onThreadMembersUpdate,
      'threadMembersUpdate',
      buildContext: buildThreadMembersUpdateEventContext,
    );

    // Channel events
    registerEvent<ChannelCreateEvent>(
      gateway.onChannelCreate,
      'channelCreate',
      buildContext: buildChannelCreateEventContext,
    );
    registerEvent<ChannelUpdateEvent>(
      gateway.onChannelUpdate,
      'channelUpdate',
      buildContext: buildChannelUpdateEventContext,
    );
    registerEvent<ChannelDeleteEvent>(
      gateway.onChannelDelete,
      'channelDelete',
      buildContext: buildChannelDeleteEventContext,
    );
    registerEvent<ChannelPinsUpdateEvent>(
      gateway.onChannelPinsUpdate,
      'channelPinsUpdate',
      buildContext: buildChannelPinsUpdateEventContext,
    );

    // Guild events
    registerEvent<GuildCreateEvent>(
      gateway.onGuildCreate.cast<GuildCreateEvent>(),
      'guildCreate',
      buildContext: buildGuildCreateEventContext,
    );
    registerEvent<GuildUpdateEvent>(
      gateway.onGuildUpdate,
      'guildUpdate',
      buildContext: buildGuildUpdateEventContext,
    );
    registerEvent<GuildDeleteEvent>(
      gateway.onGuildDelete,
      'guildDelete',
      buildContext: buildGuildDeleteEventContext,
    );
    registerEvent<GuildAuditLogCreateEvent>(
      gateway.onGuildAuditLogCreate,
      'guildAuditLogCreate',
      buildContext: buildGuildAuditLogCreateEventContext,
    );
    registerEvent<GuildBanAddEvent>(gateway.onGuildBanAdd, 'guildBanAdd');
    registerEvent<GuildBanRemoveEvent>(
      gateway.onGuildBanRemove,
      'guildBanRemove',
    );
    registerEvent<GuildEmojisUpdateEvent>(
      gateway.onGuildEmojisUpdate,
      'guildEmojisUpdate',
    );
    registerEvent<GuildStickersUpdateEvent>(
      gateway.onGuildStickersUpdate,
      'guildStickersUpdate',
    );
    registerEvent<GuildIntegrationsUpdateEvent>(
      gateway.onGuildIntegrationsUpdate,
      'guildIntegrationsUpdate',
    );
    registerEvent<GuildMemberUpdateEvent>(
      gateway.onGuildMemberUpdate,
      'guildMemberUpdate',
    );
    registerEvent<GuildMembersChunkEvent>(
      gateway.onGuildMembersChunk,
      'guildMembersChunk',
    );
    registerEvent<GuildRoleCreateEvent>(
      gateway.onGuildRoleCreate,
      'guildRoleCreate',
      buildContext: buildGuildRoleCreateEventContext,
    );
    registerEvent<GuildRoleUpdateEvent>(
      gateway.onGuildRoleUpdate,
      'guildRoleUpdate',
      buildContext: buildGuildRoleUpdateEventContext,
    );
    registerEvent<GuildRoleDeleteEvent>(
      gateway.onGuildRoleDelete,
      'guildRoleDelete',
      buildContext: buildGuildRoleDeleteEventContext,
    );
    registerEvent<GuildScheduledEventCreateEvent>(
      gateway.onGuildScheduledEventCreate,
      'guildScheduledEventCreate',
    );
    registerEvent<GuildScheduledEventUpdateEvent>(
      gateway.onGuildScheduledEventUpdate,
      'guildScheduledEventUpdate',
    );
    registerEvent<GuildScheduledEventDeleteEvent>(
      gateway.onGuildScheduledEventDelete,
      'guildScheduledEventDelete',
    );
    registerEvent<GuildScheduledEventUserAddEvent>(
      gateway.onGuildScheduledEventUserAdd,
      'guildScheduledEventUserAdd',
    );
    registerEvent<GuildScheduledEventUserRemoveEvent>(
      gateway.onGuildScheduledEventUserRemove,
      'guildScheduledEventUserRemove',
    );
    registerEvent<IntegrationCreateEvent>(
      gateway.onIntegrationCreate,
      'integrationCreate',
    );
    registerEvent<IntegrationUpdateEvent>(
      gateway.onIntegrationUpdate,
      'integrationUpdate',
    );
    registerEvent<IntegrationDeleteEvent>(
      gateway.onIntegrationDelete,
      'integrationDelete',
    );
    registerEvent<InviteDeleteEvent>(
      gateway.onInviteDelete,
      'inviteDelete',
      buildContext: buildInviteDeleteEventContext,
    );
    registerEvent<MessageBulkDeleteEvent>(
      gateway.onMessageBulkDelete,
      'messageBulkDelete',
    );
    registerEvent<MessageReactionAddEvent>(
      gateway.onMessageReactionAdd,
      'messageReactionAdd',
      buildContext: buildMessageReactionAddEventContext,
    );
    registerEvent<MessageReactionRemoveEvent>(
      gateway.onMessageReactionRemove,
      'messageReactionRemove',
      buildContext: buildMessageReactionRemoveEventContext,
    );
    registerEvent<MessageReactionRemoveAllEvent>(
      gateway.onMessageReactionRemoveAll,
      'messageReactionRemoveAll',
      buildContext: buildMessageReactionRemoveAllEventContext,
    );
    registerEvent<MessageReactionRemoveEmojiEvent>(
      gateway.onMessageReactionRemoveEmoji,
      'messageReactionRemoveEmoji',
      buildContext: buildMessageReactionRemoveEmojiEventContext,
    );
    registerEvent<PresenceUpdateEvent>(
      gateway.onPresenceUpdate,
      'presenceUpdate',
      buildContext: buildPresenceUpdateEventContext,
    );
    registerEvent<TypingStartEvent>(
      gateway.onTypingStart,
      'typingStart',
      buildContext: buildTypingStartEventContext,
    );
    registerEvent<UserUpdateEvent>(
      gateway.onUserUpdate,
      'userUpdate',
      buildContext: buildUserUpdateEventContext,
    );
    registerEvent<VoiceStateUpdateEvent>(
      gateway.onVoiceStateUpdate,
      'voiceStateUpdate',
      buildContext: buildVoiceStateUpdateEventContext,
    );
    registerEvent<VoiceServerUpdateEvent>(
      gateway.onVoiceServerUpdate,
      'voiceServerUpdate',
      buildContext: buildVoiceServerUpdateEventContext,
    );
    registerEvent<WebhooksUpdateEvent>(
      gateway.onWebhooksUpdate,
      'webhooksUpdate',
    );
    registerEvent<StageInstanceCreateEvent>(
      gateway.onStageInstanceCreate,
      'stageInstanceCreate',
    );
    registerEvent<StageInstanceUpdateEvent>(
      gateway.onStageInstanceUpdate,
      'stageInstanceUpdate',
    );
    registerEvent<StageInstanceDeleteEvent>(
      gateway.onStageInstanceDelete,
      'stageInstanceDelete',
    );
    registerEvent<EntitlementCreateEvent>(
      gateway.onEntitlementCreate,
      'entitlementCreate',
    );
    registerEvent<EntitlementUpdateEvent>(
      gateway.onEntitlementUpdate,
      'entitlementUpdate',
    );
    registerEvent<EntitlementDeleteEvent>(
      gateway.onEntitlementDelete,
      'entitlementDelete',
    );
    registerEvent<MessagePollVoteAddEvent>(
      gateway.onMessagePollVoteAdd,
      'messagePollVoteAdd',
      buildContext: buildMessagePollVoteAddEventContext,
    );
    registerEvent<MessagePollVoteRemoveEvent>(
      gateway.onMessagePollVoteRemove,
      'messagePollVoteRemove',
      buildContext: buildMessagePollVoteRemoveEventContext,
    );
    registerEvent<SoundboardSoundCreateEvent>(
      gateway.onSoundboardSoundCreate,
      'soundboardSoundCreate',
    );
    registerEvent<SoundboardSoundUpdateEvent>(
      gateway.onSoundboardSoundUpdate,
      'soundboardSoundUpdate',
    );
    registerEvent<SoundboardSoundDeleteEvent>(
      gateway.onSoundboardSoundDelete,
      'soundboardSoundDelete',
    );
    registerEvent<SoundboardSoundsUpdateEvent>(
      gateway.onSoundboardSoundsUpdate,
      'soundboardSoundsUpdate',
    );
    registerEvent<VoiceChannelEffectSendEvent>(
      gateway.onVoiceChannelEffectSend,
      'voiceChannelEffectSend',
      buildContext: buildVoiceChannelEffectSendEventContext,
    );
  }

  Future<void> _cancelEventWorkflowListeners() async {
    for (final subscription in _eventWorkflowSubscriptions) {
      await subscription.cancel();
    }
    _eventWorkflowSubscriptions.clear();
  }

  Future<void> _rebindEventWorkflowListeners() async {
    await _cancelEventWorkflowListeners();
    _registerEventWorkflowListeners();
  }

  EventExecutionContext _baseEventContext({
    required String eventName,
    required Snowflake? guildId,
    required Snowflake? channelId,
    required Snowflake? userId,
  }) {
    return EventExecutionContext(
      eventName: eventName,
      variables: const <String, String>{},
      guildId: guildId,
      channelId: channelId,
      userId: userId,
    );
  }

  Future<void> _dispatchEventWorkflows({
    required String eventName,
    required EventExecutionContext context,
  }) async {
    final normalizedEventName = eventName.toLowerCase();
    if (normalizedEventName == 'interactioncreate') {
      final interaction = context.interaction;
      if (interaction != null && isInteractionAcknowledged(interaction)) {
        return;
      }
    }

    final botId = _gateway?.user.id.toString() ?? store.botId;
    final matching = _eventWorkflows
        .where((workflow) {
          final trigger = normalizeWorkflowEventTrigger(
            workflow['eventTrigger'],
          );
          return (trigger['event'] ?? '').toString() == eventName;
        })
        .toList(growable: false);

    Future<void> executeMatchingWorkflows() async {
      if (matching.isEmpty) {
        return;
      }

      final futures = matching
          .map((workflow) async {
            try {
              await _executeEventWorkflow(
                botId: botId,
                workflow: workflow,
                context: context,
              );
            } catch (error, stackTrace) {
              _log.warning(
                'Event workflow failed for "$eventName": $error\n$stackTrace',
              );
            }
          })
          .toList(growable: false);

      await Future.wait(futures, eagerError: false);
    }

    if (normalizedEventName == 'messagecreate') {
      final isBotMessage =
          (context.variables['message.isBot'] ??
                  context.variables['author.isBot'] ??
                  '')
              .toLowerCase() ==
          'true';
      if (isBotMessage) {
        return;
      }

      await Future.wait<dynamic>([
        _tryExecuteLegacyCommand(context),
        executeMatchingWorkflows(),
      ], eagerError: false);
      return;
    }

    await executeMatchingWorkflows();
  }

  void _startScheduledWorkflowLoop() {
    _scheduledWorkflowTimer?.cancel();
    _scheduledWorkflowTimer = Timer.periodic(const Duration(minutes: 1), (
      timer,
    ) {
      _tickScheduledWorkflows();
    });
  }

  Future<void> _tickScheduledWorkflows() async {
    final now = DateTime.now();
    final triggers = _scheduledTriggers;
    if (triggers.isEmpty) {
      return;
    }

    final botId = _gateway?.user.id.toString() ?? store.botId;
    for (final trigger in triggers) {
      final workflowName = (trigger['workflowName'] ?? '').toString();
      final everyMinutes =
          int.tryParse((trigger['everyMinutes'] ?? '').toString()) ?? 0;
      final lastRun = _scheduledLastRun[workflowName];

      if (lastRun == null ||
          now.difference(lastRun).inMinutes >= everyMinutes) {
        _scheduledLastRun[workflowName] = now;
        unawaited(_executeScheduledWorkflow(botId, trigger));
      }
    }
  }

  Future<void> _executeScheduledWorkflow(
    String botId,
    Map<String, dynamic> trigger,
  ) async {
    final workflowName = (trigger['workflowName'] ?? '').toString().trim();
    final workflow = await store.getWorkflowByName(botId, workflowName);
    if (workflow == null) {
      _log.warning('Scheduled workflow "$workflowName" not found.');
      return;
    }

    final normalized = normalizeStoredWorkflowDefinition(workflow);
    if (normalizeWorkflowType(normalized['workflowType']) !=
        workflowTypeGeneral) {
      _log.warning(
        'Scheduled workflow "$workflowName" must be of type General.',
      );
      return;
    }

    final actionsJson = List<Map<String, dynamic>>.from(
      (normalized['actions'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    );
    if (actionsJson.isEmpty) {
      return;
    }

    final runtimeVariables = <String, String>{
      'workflow.type': workflowTypeGeneral,
      'workflow.trigger': 'scheduled',
      'trigger.minutes': (trigger['everyMinutes'] ?? '').toString(),
    };
    if (_gateway != null) {
      runtimeVariables.addAll(extractBotRuntimeDetails(_gateway!));
    }
    _injectGatewayBotVariables(runtimeVariables);

    await hydrateRuntimeVariables(
      store: store,
      botId: botId,
      runtimeVariables: runtimeVariables,
    );

    final actions = actionsJson.map(Action.fromJson).toList(growable: false);
    try {
      await _runActionsWithReplay(
        replayLabel: 'scheduled:$workflowName',
        client: _gateway!,
        interaction: null,
        actions: actions,
        botId: botId,
        runtimeVariables: runtimeVariables,
      );
      _log.info('Executed scheduled workflow: $workflowName');
    } catch (e, st) {
      _log.severe('Error executing scheduled workflow $workflowName: $e', e, st);
    }
  }

  Future<void> _executeEventWorkflow({
    required String botId,
    required Map<String, dynamic> workflow,
    required EventExecutionContext context,
  }) async {
    final workflowName = (workflow['name'] ?? '').toString().trim();
    final actions = List<Action>.from(
      ((workflow['actions'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((json) => Action.fromJson(Map<String, dynamic>.from(json))),
    );
    if (actions.isEmpty) {
      return;
    }

    final runtimeVariables = <String, String>{
      ...context.variables,
      'workflow.type': workflowTypeEvent,
    };

    // Inject bot-level variables.
    if (_gateway != null) {
      runtimeVariables.addAll(extractBotRuntimeDetails(_gateway!));
    }
    _injectGatewayBotVariables(runtimeVariables);

    // Fast-path: when every action is a listener registration, skip expensive
    // guild/channel/member fetches and DB variable hydration — the listener
    // executor only needs the context variables already present.
    const listenerOnlyTypes = {
      BotCreatorActionType.listenForButtonClick,
      BotCreatorActionType.listenForSelectMenu,
      BotCreatorActionType.listenForModalSubmit,
    };
    final enabledActions = actions.where((a) => a.enabled);
    final listenerOnly = enabledActions.every(
      (a) => listenerOnlyTypes.contains(a.type),
    );

    if (!listenerOnly) {
      // Inject guild, channel and member variables for event workflows.
      // Fetch guild and channel in parallel to reduce latency.
      final eventGuildId = context.guildId;
      final eventChannelId = context.channelId;
      Guild? eventGuild;

      await Future.wait(<Future<void>>[
        if (eventGuildId != null && _gateway != null)
          (() async {
            try {
              final fetched = await fetchGuildCached(_gateway!, eventGuildId);
              eventGuild = fetched;
              if (fetched != null) {
                runtimeVariables.addAll(
                  await extractGuildRuntimeDetails(
                    fetched,
                    client: _gateway!,
                    guildId: eventGuildId,
                  ),
                );
              }
            } catch (_) {}
          })(),
        if (eventChannelId != null && _gateway != null)
          (() async {
            try {
              final channel = await fetchChannelCached(
                _gateway!,
                eventChannelId,
              );
              if (channel != null) {
                runtimeVariables.addAll(extractChannelRuntimeDetails(channel));
              }
            } catch (_) {}
          })(),
      ]);

      final eventUserId = context.userId;
      if (eventGuild != null && eventUserId != null) {
        try {
          final member = await eventGuild!.members.fetch(eventUserId);
          runtimeVariables.addAll(
            extractMemberRuntimeDetails(
              member: member,
              guild: eventGuild!,
              guildId: eventGuildId.toString(),
            ),
          );
        } catch (_) {}
      }

      await hydrateRuntimeVariables(
        store: store,
        botId: botId,
        runtimeVariables: runtimeVariables,
        guildContextId: context.guildId?.toString(),
        channelContextId: context.channelId?.toString(),
        userContextId: context.userId?.toString(),
      );
    }

    // Apply entry point logic if necessary (though usually Event workflows have a single entry point)
    // For now we just run all actions.
    try {
      await _runActionsWithReplay(
        replayLabel: 'event:$workflowName',
        client: _gateway!,
        interaction: context.interaction,
        actions: actions,
        botId: botId,
        runtimeVariables: runtimeVariables,
      );
    } catch (e, st) {
      _log.severe('Error executing event workflow $workflowName: $e', e, st);
    }
  }
}
