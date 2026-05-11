part of 'discord_runner.dart';

extension DiscordRunnerInteractionsExtension on DiscordRunner {
  Future<void> _handleInteraction(InteractionCreateEvent event) async {
    final interaction = event.interaction;
    final client = event.gateway.client;
    final botId = client.user.id.toString();

    if (interaction is ApplicationCommandAutocompleteInteraction) {
      final commandId = interaction.data.id.toString();
      final commandData = _findCommand(
        commandId,
        name: interaction.data.name,
        type: _commandTypeToStorage(interaction.data.type),
      );
      if (commandData == null) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      await _executeAutocomplete(
        client: client,
        botId: botId,
        interaction: interaction,
        commandData: commandData,
      );
    } else if (interaction is ApplicationCommandInteraction) {
      final commandId = interaction.data.id.toString();
      final interactionType = _commandTypeToStorage(interaction.data.type);

      // Match by Discord command ID (same logic as bot.commands.dart)
      final commandData = _findCommand(
        commandId,
        name: interaction.data.name,
        type: interactionType,
      );
      if (commandData == null) {
        _log.warning(
          'Command $commandId (${interaction.data.name}, type=$interactionType) not found in config',
        );
        await _safeRespond(
          interaction,
          'Command not found.',
          isEphemeral: true,
        );
        return;
      }

      final storedType = _storedCommandType(commandData);
      if (storedType != interactionType) {
        _log.warning(
          'Command type mismatch for ${interaction.data.name} ($commandId): stored=$storedType, incoming=$interactionType. Executing anyway.',
        );
      } else {
        _log.info(
          'Executing ${interaction.data.name} ($commandId) as $interactionType command.',
        );
      }

      final stopwatch = Stopwatch()..start();
      var success = true;
      try {
        await _executeCommand(
          client: client,
          botId: botId,
          interaction: interaction,
          commandData: commandData,
        );
      } catch (e, st) {
        success = false;
        _log.severe('Error handling command: $e', e, st);
      } finally {
        stopwatch.stop();

        String normalizeLocale(dynamic rawValue) {
          final raw = (rawValue ?? '').toString().trim();
          if (raw.isEmpty) {
            return '';
          }
          if (raw.contains('.')) {
            return raw.split('.').last.toLowerCase();
          }
          return raw.toLowerCase();
        }

        final dynamic rawInteraction = interaction;

        // Record command usage + execution health metrics.
        statsStore?.record(
          botId: botId,
          commandName: interaction.data.name,
          guildId: interaction.guild?.id.toString() ?? '',
          locale: normalizeLocale(rawInteraction.locale),
          guildLocale: normalizeLocale(rawInteraction.guildLocale),
          success: success,
          latencyMs: stopwatch.elapsedMilliseconds,
        );
      }
    } else if (interaction is MessageComponentInteraction) {
      await handleComponentInteraction(client, interaction, store, botId);
    } else if (interaction is ModalSubmitInteraction) {
      await handleModalSubmitInteraction(client, interaction, store, botId);
    }
  }

  Map<String, dynamic>? _findCommand(
    String discordCommandId, {
    String? name,
    String? type,
  }) {
    for (final cmd in config.commands) {
      if ((cmd['id'] ?? '').toString() == discordCommandId) {
        return cmd;
      }
    }
    // Fallback: match by name+type when the local ID is a stale temp ID.
    if (name != null) {
      final normalizedType = (type ?? 'chatinput').toLowerCase();
      for (final cmd in config.commands) {
        if ((cmd['name'] ?? '').toString() == name &&
            (cmd['type'] ?? 'chatInput').toString().toLowerCase() ==
                normalizedType) {
          return cmd;
        }
      }
    }
    return null;
  }

  String _storedCommandType(Map<String, dynamic> commandData) {
    final data = Map<String, dynamic>.from(
      (commandData['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final raw =
        (data['commandType'] ?? commandData['type'] ?? 'chatInput')
            .toString()
            .trim()
            .toLowerCase();

    switch (raw) {
      case 'user':
      case 'usercommand':
      case 'user_command':
      case 'user-command':
        return 'user';
      case 'message':
      case 'messagecommand':
      case 'message_command':
      case 'message-command':
        return 'message';
      case 'chatinput':
      case 'chat_input':
      case 'chat-input':
      case 'slash':
      default:
        return 'chatInput';
    }
  }

  String _commandTypeToStorage(ApplicationCommandType type) {
    if (type == ApplicationCommandType.user) {
      return 'user';
    }
    if (type == ApplicationCommandType.message) {
      return 'message';
    }
    return 'chatInput';
  }

  Future<void> _executeCommand({
    required NyxxGateway client,
    required String botId,
    required ApplicationCommandInteraction interaction,
    required Map<String, dynamic> commandData,
  }) async {
    final data = Map<String, dynamic>.from(
      (commandData['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final value = Map<String, dynamic>.from(
      (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
    );
    final subcommandRoute = resolveSubcommandRoute(interaction.data.options);
    final routePayload =
        (subcommandRoute == null)
            ? null
            : resolveSubcommandWorkflowPayload(value, subcommandRoute);
    final executionValue = routePayload ?? value;

    final response = Map<String, dynamic>.from(
      (executionValue['response'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final workflow = Map<String, dynamic>.from(
      (response['workflow'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final workflowConditional = Map<String, dynamic>.from(
      (workflow['conditional'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    // Build runtime variables from interaction
    final runtimeVariables = await generateKeyValues(interaction);
    _injectGatewayBotVariables(runtimeVariables);
    final interactionType = _commandTypeToStorage(interaction.data.type);
    final storedType = _storedCommandType(commandData);
    runtimeVariables['command.type'] = interactionType;
    runtimeVariables['interaction.command.type'] = interactionType;
    runtimeVariables['config.command.type'] = storedType;
    runtimeVariables['interaction.isSlash'] = 'true';
    runtimeVariables['interaction.command.name'] = interaction.data.name;
    runtimeVariables['interaction.command.id'] = interaction.data.id.toString();
    runtimeVariables['interaction.command.route'] = subcommandRoute ?? '';

    String? normalizeContextId(String? value) {
      final trimmed = (value ?? '').trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final lowered = trimmed.toLowerCase();
      if (lowered == 'unknown user' || lowered == 'dm') {
        return null;
      }
      return trimmed;
    }

    final dynamic rawInteraction = interaction;
    await hydrateRuntimeVariables(
      store: store,
      botId: botId,
      runtimeVariables: runtimeVariables,
      guildContextId:
          normalizeContextId(runtimeVariables['guildId']) ??
          normalizeContextId(runtimeVariables['guild.id']) ??
          normalizeContextId(rawInteraction.guildId?.toString()) ??
          normalizeContextId(rawInteraction.guild?.id?.toString()),
      channelContextId:
          normalizeContextId(runtimeVariables['channelId']) ??
          normalizeContextId(runtimeVariables['channel.id']) ??
          normalizeContextId(rawInteraction.channelId?.toString()) ??
          normalizeContextId(rawInteraction.channel?.id?.toString()) ??
          normalizeContextId(rawInteraction.message?.channelId?.toString()),
      userContextId:
          normalizeContextId(runtimeVariables['userId']) ??
          normalizeContextId(runtimeVariables['user.id']) ??
          normalizeContextId(runtimeVariables['interaction.userId']) ??
          normalizeContextId(rawInteraction.user?.id?.toString()) ??
          normalizeContextId(rawInteraction.member?.user?.id?.toString()) ??
          normalizeContextId(rawInteraction.author?.id?.toString()),
      messageContextId:
          normalizeContextId(runtimeVariables['messageId']) ??
          normalizeContextId(runtimeVariables['message.id']) ??
          normalizeContextId(rawInteraction.message?.id?.toString()) ??
          normalizeContextId(rawInteraction.id?.toString()),
    );

    final executionMode =
        (value['executionMode'] ?? 'workflow').toString().trim().toLowerCase();
    if (executionMode == 'bdfd_script') {
      final scriptSource =
          (executionValue['bdfdScriptContent'] ??
                  value['bdfdScriptContent'] ??
                  '')
              .toString();
      final compileResult = BdfdCompiler().compile(scriptSource);

      if (compileResult.hasErrors) {
        await sendWorkflowResponse(
          interaction: interaction,
          response: {
            'type': 'normal',
            'text': _formatRunnerBdfdDiagnostics(compileResult.diagnostics),
            'embeds': const <Map<String, dynamic>>[],
            'components': const <String, dynamic>{},
            'modal': const <String, dynamic>{},
            'workflow': const {
              'visibility': 'ephemeral',
              'conditional': {'enabled': false},
            },
          },
          runtimeVariables: runtimeVariables,
          botId: botId,
          isEphemeral: true,
          onLog: (msg, {required botId}) async => _log.info(msg),
          onDebugLog: (msg, {required botId}) async => _log.fine(msg),
        );
        return;
      }

      if (compileResult.actions.isEmpty) {
        await sendWorkflowResponse(
          interaction: interaction,
          response: {
            'type': 'normal',
            'text':
                'This BDFD script compiled successfully but did not produce any action.',
            'embeds': const <Map<String, dynamic>>[],
            'components': const <String, dynamic>{},
            'modal': const <String, dynamic>{},
            'workflow': const {
              'visibility': 'ephemeral',
              'conditional': {'enabled': false},
            },
          },
          runtimeVariables: runtimeVariables,
          botId: botId,
          isEphemeral: true,
          onLog: (msg, {required botId}) async => _log.info(msg),
          onDebugLog: (msg, {required botId}) async => _log.fine(msg),
        );
        return;
      }

      try {
        final actionResults = await _runActionsWithReplay(
          replayLabel: interaction.data.name,
          client: client,
          interaction: interaction,
          actions: compileResult.actions,
          botId: botId,
          runtimeVariables: runtimeVariables,
        );
        for (final entry in actionResults.entries) {
          runtimeVariables['action.${entry.key}'] = entry.value;
        }
      } catch (e, st) {
        _log.severe(
          'Error executing BDFD script ${commandData['name']}: $e',
          e,
          st,
        );
        try {
          await sendWorkflowResponse(
            interaction: interaction,
            response: {
              'type': 'normal',
              'text': 'An error occurred while executing this BDFD script.',
              'embeds': const <Map<String, dynamic>>[],
              'components': const <String, dynamic>{},
              'modal': const <String, dynamic>{},
              'workflow': const {
                'visibility': 'ephemeral',
                'conditional': {'enabled': false},
              },
            },
            runtimeVariables: runtimeVariables,
            botId: botId,
            isEphemeral: true,
            onLog: (msg, {required botId}) async => _log.info(msg),
            onDebugLog: (msg, {required botId}) async => _log.fine(msg),
          );
        } catch (innerError) {
          _log.warning('Could not send error response: $innerError');
        }
      }
      return;
    }

    // Collect actions
    var actionsJson = List<Map<String, dynamic>>.from(
      (executionValue['actions'] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          const [],
    );

    // If empty, try to load from a named workflow
    final workflowName = (workflow['name'] ?? '').toString().trim();
    if (workflowName.isNotEmpty && actionsJson.isEmpty) {
      final saved = await store.getWorkflowByName(botId, workflowName);
      if (saved != null) {
        actionsJson = List<Map<String, dynamic>>.from(
          (saved['actions'] as List?)?.whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ) ??
              const [],
        );
      }
    }

    final responseType = (response['type'] ?? 'normal').toString();
    final isBaseModal = responseType == 'modal';
    final whenTrueType =
        (workflowConditional['whenTrueType'] ?? 'normal').toString();
    final whenFalseType =
        (workflowConditional['whenFalseType'] ?? 'normal').toString();
    final useCondition = workflowConditional['enabled'] == true;
    final isConditionalModal =
        useCondition && (whenTrueType == 'modal' || whenFalseType == 'modal');
    final shouldDefer =
        actionsJson.isNotEmpty &&
        workflow['autoDeferIfActions'] != false &&
        !isBaseModal &&
        !isConditionalModal;
    final isEphemeral =
        workflow['visibility']?.toString().toLowerCase() == 'ephemeral';

    var didDefer = false;
    final interactionId = interaction.id.toString();

    try {
      _log.fine(
        'Interaction $interactionId: executing command with ${actionsJson.length} action(s), shouldDefer=$shouldDefer, responseType=$responseType',
      );

      if (shouldDefer) {
        int deferFlags = isEphemeral ? 64 : 0;
        if (requiresV2Flag(response)) {
          deferFlags |= 32768;
        }

        if (deferFlags == 0 || deferFlags == 64) {
          await interaction.acknowledge(isEphemeral: isEphemeral);
        } else {
          final builder = InteractionResponseBuilder(
            type: InteractionCallbackType.deferredChannelMessageWithSource,
            data: {'flags': deferFlags},
          );
          await interaction.manager.createResponse(
            interaction.id,
            interaction.token,
            builder,
          );
        }
        didDefer = true;
        _log.fine('Interaction $interactionId: defer acknowledged.');
      }

      if (actionsJson.isNotEmpty) {
        final actions = actionsJson.map(Action.fromJson).toList();
        final actionResults = await _runActionsWithReplay(
          replayLabel: interaction.data.name,
          client: client,
          interaction: interaction,
          actions: actions,
          botId: botId,
          runtimeVariables: runtimeVariables,
        );
        for (final entry in actionResults.entries) {
          runtimeVariables['action.${entry.key}'] = entry.value;
        }
      }

      await sendWorkflowResponse(
        interaction: interaction,
        response: response,
        runtimeVariables: runtimeVariables,
        botId: botId,
        didDefer: didDefer,
        isEphemeral: isEphemeral,
        onLog: (msg, {required botId}) async => _log.info(msg),
        onDebugLog: (msg, {required botId}) async => _log.fine(msg),
      );
      _log.fine('Interaction $interactionId: sendWorkflowResponse completed.');
    } catch (e, st) {
      _log.severe('Error executing command ${commandData['name']}: $e', e, st);
      // Surface specific, user-safe error messages from permission checks.
      final errorMsg = e.toString();
      String? userMessage;
      if (errorMsg.contains('I do not have permission') ||
          errorMsg.contains('I cannot')) {
        userMessage = errorMsg.replaceFirst('Exception: ', '');
      }
      await _safeErrorResponse(
        interaction,
        didDefer: didDefer,
        isEphemeral: isEphemeral,
        errorMessage: userMessage,
      );
    }
  }

  Future<void> _executeAutocomplete({
    required NyxxGateway client,
    required String botId,
    required ApplicationCommandAutocompleteInteraction interaction,
    required Map<String, dynamic> commandData,
  }) async {
    try {
      final data = Map<String, dynamic>.from(
        (commandData['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final value = Map<String, dynamic>.from(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
      );
      final autocompleteConfig = resolveAutocompleteConfigForInteraction(
        storedOptions: value['options'],
        interactionOptions: interaction.data.options,
      );
      if (autocompleteConfig == null || autocompleteConfig['enabled'] != true) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      // Static options mode: filter pre-defined choices by user query.
      if ((autocompleteConfig['mode'] ?? 'workflow').toString() == 'static') {
        final focusedOption = findFocusedOption(interaction.data.options);
        final query =
            (focusedOption?.value?.toString() ?? '').toLowerCase().trim();
        final rawChoices = autocompleteConfig['staticChoices'];
        final choices = <CommandOptionChoiceBuilder<dynamic>>[];
        if (rawChoices is List) {
          for (final raw in rawChoices) {
            if (raw is! Map) continue;
            final name = (raw['name'] ?? '').toString().trim();
            if (name.isEmpty) continue;
            if (query.isNotEmpty && !name.toLowerCase().contains(query)) {
              continue;
            }
            final value = raw['value'];
            choices.add(
              CommandOptionChoiceBuilder<dynamic>(
                name: name,
                value: value is num ? value : (value?.toString() ?? name),
              ),
            );
            if (choices.length >= 25) break;
          }
        }
        await interaction.respond(choices);
        return;
      }

      final workflowName =
          (autocompleteConfig['workflow'] ?? '').toString().trim();
      if (workflowName.isEmpty) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      final workflow = await store.getWorkflowByName(botId, workflowName);
      if (workflow == null) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      final normalizedWorkflow = normalizeStoredWorkflowDefinition(workflow);
      if (normalizeWorkflowType(normalizedWorkflow['workflowType']) !=
          workflowTypeGeneral) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      final focusedOption = findFocusedOption(interaction.data.options);
      final runtimeVariables = await generateKeyValues(interaction);
      _injectGatewayBotVariables(runtimeVariables);
      runtimeVariables['command.type'] = 'chatInput';
      runtimeVariables['interaction.command.type'] = 'chatInput';
      runtimeVariables['config.command.type'] = 'chatInput';
      runtimeVariables['interaction.command.name'] = interaction.data.name;
      runtimeVariables['interaction.command.id'] =
          interaction.data.id.toString();
      runtimeVariables['interaction.command.route'] =
          resolveSubcommandRoute(interaction.data.options) ?? '';
      runtimeVariables['autocomplete.query'] =
          focusedOption?.value?.toString() ?? '';
      runtimeVariables['autocomplete.optionName'] = focusedOption?.name ?? '';
      runtimeVariables['autocomplete.optionType'] =
          focusedOption == null
              ? 'string'
              : commandOptionTypeToText(focusedOption.type);
      runtimeVariables['workflow.type'] = workflowTypeGeneral;

      await hydrateRuntimeVariables(
        store: store,
        botId: botId,
        runtimeVariables: runtimeVariables,
        guildContextId: runtimeVariables['guildId'],
        channelContextId: runtimeVariables['channelId'],
        userContextId: runtimeVariables['userId'],
        messageContextId:
            runtimeVariables['messageId'] ?? runtimeVariables['message.id'],
      );

      final providedArguments = resolveWorkflowCallArguments(
        autocompleteConfig['arguments'],
        (input) => resolveTemplatePlaceholders(
          input,
          Map<String, String>.from(runtimeVariables),
        ),
      );
      applyWorkflowInvocationContext(
        variables: runtimeVariables,
        workflowName: workflowName,
        entryPoint: normalizeWorkflowEntryPoint(
          autocompleteConfig['entryPoint'] ?? normalizedWorkflow['entryPoint'],
        ),
        definitions: parseWorkflowArgumentDefinitions(
          normalizedWorkflow['arguments'],
        ),
        providedArguments: providedArguments,
        enforceRequired: false,
      );

      final actions = List<Action>.from(
        ((normalizedWorkflow['actions'] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((json) => Action.fromJson(Map<String, dynamic>.from(json))),
      );
      if (actions.isEmpty) {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
        return;
      }

      try {
        final actionResults = await _runActionsWithReplay(
          replayLabel: 'autocomplete:$workflowName',
          client: client,
          interaction: interaction,
          actions: actions,
          botId: botId,
          runtimeVariables: runtimeVariables,
        );

        if (!actionResults.containsKey('__stopped__')) {
          await interaction.respond(
            const <CommandOptionChoiceBuilder<dynamic>>[],
          );
        }
      } catch (error, stackTrace) {
        _log.warning(
          'Autocomplete workflow "$workflowName" failed: $error',
          error,
          stackTrace,
        );
        try {
          await interaction.respond(
            const <CommandOptionChoiceBuilder<dynamic>>[],
          );
        } catch (_) {}
      }
    } catch (error, stackTrace) {
      _log.warning(
        'Autocomplete interaction failed: $error',
        error,
        stackTrace,
      );
      try {
        await interaction.respond(
          const <CommandOptionChoiceBuilder<dynamic>>[],
        );
      } catch (_) {}
    }
  }

  Future<void> _safeRespond(
    Interaction interaction,
    String text, {
    bool isEphemeral = false,
  }) async {
    try {
      await (interaction as dynamic).respond(
        MessageBuilder(
          content: text,
          flags: isEphemeral ? MessageFlags.ephemeral : null,
        ),
      );
      markInteractionAcknowledged(interaction);
    } catch (e, st) {
      if (e.toString().contains('40060')) {
        markInteractionAcknowledged(interaction);
      } else {
        _log.warning(
          'Safe respond failed for ${interaction.runtimeType}: $e',
          e,
          st,
        );
      }
    }
  }

  Future<void> _safeErrorResponse(
    ApplicationCommandInteraction interaction, {
    required bool didDefer,
    required bool isEphemeral,
    String? errorMessage,
  }) async {
    final text =
        errorMessage ?? 'An error occurred while executing this command.';
    try {
      if (didDefer || isInteractionAcknowledged(interaction)) {
        await interaction.updateOriginalResponse(
          MessageUpdateBuilder(content: text, embeds: const []),
        );
      } else {
        await interaction.respond(
          MessageBuilder(content: text, flags: MessageFlags.ephemeral),
        );
      }
    } catch (e, st) {
      _log.warning(
        'Safe error response failed for ${interaction.runtimeType} (didDefer=$didDefer): $e',
        e,
        st,
      );
    }
  }
}
