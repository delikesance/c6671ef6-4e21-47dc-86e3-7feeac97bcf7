part of 'discord_runner.dart';

extension DiscordRunnerLegacyExtension on DiscordRunner {
  bool _isLegacyCommandEnabled(Map<String, dynamic> command) {
    return isLegacyCommandEnabledInConfigEntry(command);
  }

  List<String> _splitLegacyTokens(String input) {
    final tokens = <String>[];
    final regex = RegExp(r'"([^"]*)"|(\S+)');
    final matches = regex.allMatches(input);
    for (final match in matches) {
      if (match.group(1) != null) {
        tokens.add(match.group(1)!);
      } else if (match.group(2) != null) {
        tokens.add(match.group(2)!);
      }
    }
    return tokens;
  }

  String _effectiveLegacyResponseTarget(Map<String, dynamic> value) {
    final raw = (value['legacyResponseTarget'] ?? 'reply').toString().trim();
    return raw == 'channelSend' ? 'channelSend' : 'reply';
  }

  Future<String?> _resolveLegacyPrefix({
    required Map<String, dynamic> value,
    required Map<String, String> runtimeVariables,
  }) async {
    final commandOverride =
        (value['legacyPrefixOverride'] ?? '').toString().trim();
    final globalPrefix = config.prefix.trim().isEmpty ? '!' : config.prefix;
    final rawPrefix =
        commandOverride.isNotEmpty ? commandOverride : globalPrefix;
    final resolved =
        resolveTemplatePlaceholders(rawPrefix, runtimeVariables).trim();
    if (resolved.isEmpty) {
      return null;
    }
    return resolved;
  }

  String _legacyOptionTypeLabel(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    switch (normalized) {
      case 'string':
        return 'text';
      case 'integer':
        return 'int';
      case 'number':
        return 'number';
      case 'boolean':
        return 'bool';
      case 'user':
      case 'channel':
      case 'role':
      case 'mentionable':
        return normalized;
      default:
        return normalized.isEmpty ? 'value' : normalized;
    }
  }

  String _legacyUsageSignature({
    required String prefix,
    required String commandName,
    required List<Map<String, dynamic>> options,
  }) {
    final parts = <String>[];
    for (final option in options) {
      final optionName = (option['name'] ?? '').toString().trim();
      if (optionName.isEmpty) {
        continue;
      }
      final type = _legacyOptionTypeLabel((option['type'] ?? '').toString());
      final isRequired =
          option['required'] == true || option['isRequired'] == true;
      final segment =
          isRequired ? '<$optionName:$type>' : '[$optionName:$type]';
      parts.add(segment);
    }
    final args = parts.isEmpty ? '' : ' ${parts.join(' ')}';
    return '$prefix$commandName$args';
  }

  String _buildLegacyHelpMessage({
    required String prefix,
    required List<Map<String, dynamic>> legacyCommands,
    String? specificCommand,
  }) {
    final normalizedSpecific = (specificCommand ?? '').trim().toLowerCase();
    final publicLegacyCommands = legacyCommands
        .where((command) {
          return _parseAwaitedLegacyTrigger(
                (command['name'] ?? '').toString(),
              ) ==
              null;
        })
        .toList(growable: false);
    final sorted = List<Map<String, dynamic>>.from(publicLegacyCommands)..sort(
      (a, b) => (a['name'] ?? '').toString().toLowerCase().compareTo(
        (b['name'] ?? '').toString().toLowerCase(),
      ),
    );

    final matches =
        normalizedSpecific.isEmpty
            ? sorted
            : sorted
                .where((command) {
                  final name =
                      (command['name'] ?? '').toString().trim().toLowerCase();
                  return name == normalizedSpecific;
                })
                .toList(growable: false);

    if (matches.isEmpty && normalizedSpecific.isNotEmpty) {
      return 'Command "$specificCommand" not found.';
    }

    final buffer = StringBuffer();
    if (normalizedSpecific.isEmpty) {
      buffer.writeln('**Available Commands:**');
    }

    for (final command in matches) {
      final name = (command['name'] ?? '').toString().trim();
      final description = (command['description'] ?? '').toString().trim();
      final data = Map<String, dynamic>.from(
        (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final value = Map<String, dynamic>.from(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
      );
      final options = List<Map<String, dynamic>>.from(
        (value['options'] as List?)?.whereType<Map>().map(
              (entry) => Map<String, dynamic>.from(entry),
            ) ??
            const <Map<String, dynamic>>[],
      );

      final signature = _legacyUsageSignature(
        prefix: prefix,
        commandName: name,
        options: options,
      );
      buffer.writeln('`$signature`');
      if (description.isNotEmpty) {
        buffer.writeln(description);
      }
      buffer.writeln();
    }

    if (normalizedSpecific.isEmpty) {
      buffer.write('Use `${prefix}help <command>` for more details.');
    }

    return buffer.toString().trim();
  }

  Future<bool> _tryExecuteBuiltInLegacyHelp(
    EventExecutionContext context, {
    required String content,
    required String botId,
    required bool builtInLegacyHelpEnabled,
    required List<Map<String, dynamic>> legacyCommands,
    required Map<String, String> runtimeVariables,
  }) async {
    if (!builtInLegacyHelpEnabled) {
      return false;
    }

    final prefix = config.prefix.trim().isEmpty ? '!' : config.prefix.trim();
    if (!content.startsWith(prefix)) {
      return false;
    }

    final remainder = content.substring(prefix.length).trimLeft();
    final tokens = _splitLegacyTokens(remainder);
    if (tokens.isEmpty) {
      return false;
    }

    final first = tokens.first.trim().toLowerCase();
    if (first != 'help') {
      return false;
    }

    final specificCommand = tokens.length > 1 ? tokens[1] : null;
    final helpMessage = _buildLegacyHelpMessage(
      prefix: prefix,
      legacyCommands: legacyCommands,
      specificCommand: specificCommand,
    );

    await _sendLegacyMessage(
      context: context,
      content: helpMessage,
      embeds: const <EmbedBuilder>[],
      asReply: true,
    );
    return true;
  }

  Future<String?> _bindLegacyPositionalOptions({
    required Map<String, dynamic> value,
    required List<String> args,
    required String prefix,
    required String commandName,
    required EventExecutionContext context,
    required Map<String, String> runtimeVariables,
  }) async {
    final options = List<Map<String, dynamic>>.from(
      (value['options'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    );

    for (var i = 0; i < options.length; i++) {
      final option = options[i];
      final name = (option['name'] ?? '').toString().trim();
      final type = (option['type'] ?? 'string').toString().trim().toLowerCase();
      final isRequired =
          option['required'] == true || option['isRequired'] == true;

      if (i >= args.length) {
        if (isRequired) {
          final signature = _legacyUsageSignature(
            prefix: prefix,
            commandName: commandName,
            options: options,
          );
          return 'Missing required argument: `$name`.\nUsage: `$signature`';
        }
        continue;
      }

      final rawValue = args[i];
      runtimeVariables['option.$name'] = rawValue;

      // Type-specific validation/formatting
      if (type == 'user' || type == 'channel' || type == 'role') {
        final mentionMatch = RegExp(r'<[#@][!&]?(\d+)>').firstMatch(rawValue);
        if (mentionMatch != null) {
          runtimeVariables['option.$name.id'] = mentionMatch.group(1)!;
        } else if (RegExp(r'^\d+$').hasMatch(rawValue)) {
          runtimeVariables['option.$name.id'] = rawValue;
        }
      }
    }
    return null;
  }

  Future<bool> _tryExecuteAwaitedLegacyInput(
    EventExecutionContext context, {
    required String botId,
    required List<Map<String, dynamic>> legacyCommands,
  }) async {
    final authorId =
        (context.variables['author.id'] ?? context.variables['user.id'] ?? '')
            .trim();
    final channelId =
        (context.variables['channel.id'] ?? context.channelId?.toString() ?? '')
            .trim();
    final messageContent = (context.variables['message.content'] ?? '').trim();
    if (authorId.isEmpty || channelId.isEmpty || messageContent.isEmpty) {
      return false;
    }

    final callbacks = <String, _AwaitedLegacyCallbacks>{};
    for (final command in legacyCommands) {
      final trigger = _parseAwaitedLegacyTrigger(
        (command['name'] ?? '').toString(),
      );
      if (trigger == null) {
        continue;
      }

      final current =
          callbacks[trigger.name] ?? const _AwaitedLegacyCallbacks();
      callbacks[trigger.name] =
          trigger.isErrorTrigger
              ? current.copyWith(errorCommand: command)
              : current.copyWith(
                successCommand: command,
                filter: trigger.filter,
              );
    }

    if (callbacks.isEmpty) {
      return false;
    }

    for (final entry in callbacks.entries) {
      final awaitName = entry.key;
      final awaitKey = 'await_$awaitName';
      final pendingRaw = await store.getScopedVariable(
        botId,
        'user',
        authorId,
        awaitKey,
      );
      if (pendingRaw == null) {
        continue;
      }

      Map<String, dynamic> pending = <String, dynamic>{};
      if (pendingRaw is Map) {
        pending = Map<String, dynamic>.from(pendingRaw);
      } else {
        final text = pendingRaw.toString();
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map) {
            pending = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          pending = <String, dynamic>{};
        }
      }

      final expectedUser = (pending['userId'] ?? authorId).toString().trim();
      final expectedChannel =
          (pending['channelId'] ?? channelId).toString().trim();
      if (expectedUser.isNotEmpty && expectedUser != authorId) {
        continue;
      }
      if (expectedChannel.isNotEmpty && expectedChannel != channelId) {
        continue;
      }

      final callbackSet = entry.value;
      final passesFilter = _matchesAwaitedFilter(
        messageContent,
        callbackSet.filter,
      );
      final selected =
          passesFilter ? callbackSet.successCommand : callbackSet.errorCommand;

      if (selected == null) {
        return true;
      }

      final data = Map<String, dynamic>.from(
        (selected['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final value = Map<String, dynamic>.from(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
      );

      final runtimeVariables = <String, String>{
        ...context.variables,
        'workflow.type': 'command',
      };
      await hydrateRuntimeVariables(
        store: store,
        botId: botId,
        runtimeVariables: runtimeVariables,
        guildContextId:
            context.variables['guildId'] ?? context.guildId?.toString(),
        channelContextId: channelId,
        userContextId: authorId,
        messageContextId:
            context.variables['messageId'] ?? context.variables['message.id'],
      );

      final commandName =
          (selected['name'] ?? '').toString().trim().toLowerCase();
      runtimeVariables['legacy.command.name'] = commandName;
      runtimeVariables['command.type'] = 'legacy';
      runtimeVariables['interaction.command.type'] = 'legacy';
      runtimeVariables['config.command.type'] = 'chatInput';
      runtimeVariables['interaction.isSlash'] = 'false';
      runtimeVariables['interaction.command.name'] = commandName;
      runtimeVariables['interaction.command.route'] = '';

      final response = Map<String, dynamic>.from(
        (value['response'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

      await store.removeScopedVariable(botId, 'user', authorId, awaitKey);

      late final List<Map<String, dynamic>> actionsJson;
      try {
        actionsJson = await _resolveLegacyActionsJson(
          value: value,
          commandName: commandName,
        );
      } catch (e) {
        await _sendLegacyMessage(
          context: context,
          content: 'Failed to run BDFD script for command "$commandName": $e',
          embeds: const <EmbedBuilder>[],
          asReply: _effectiveLegacyResponseTarget(value) == 'reply',
        );
        return true;
      }
      if (actionsJson.isNotEmpty) {
        final actions = actionsJson
            .map((json) => _adaptLegacyActionForMessageCreate(json, context))
            .map(Action.fromJson)
            .toList(growable: false);
        final actionResults = await _runActionsWithReplay(
          replayLabel: 'awaited:$commandName',
          client: _gateway!,
          interaction: null,
          actions: actions,
          botId: botId,
          runtimeVariables: runtimeVariables,
          fallbackChannelId: context.channelId,
          fallbackGuildId: context.guildId,
          nestedActionsPreprocessor:
              (nestedActions) => nestedActions
                  .map(
                    (a) => Action.fromJson(
                      _adaptLegacyActionForMessageCreate(a.toJson(), context),
                    ),
                  )
                  .toList(growable: false),
        );
        for (final resultEntry in actionResults.entries) {
          runtimeVariables['action.${resultEntry.key}'] = resultEntry.value;
        }
      }

      await _sendLegacyWorkflowResponse(
        context: context,
        response: response,
        runtimeVariables: runtimeVariables,
        responseTarget: _effectiveLegacyResponseTarget(value),
      );

      return true;
    }

    return false;
  }

  Future<List<Map<String, dynamic>>> _resolveLegacyActionsJson({
    required Map<String, dynamic> value,
    required String commandName,
  }) async {
    final executionMode =
        (value['executionMode'] ?? 'workflow').toString().trim().toLowerCase();
    final source = (value['bdfdScriptContent'] ?? '').toString();
    final shouldCompileFromBdfdSource =
        executionMode == 'bdfd_script' || source.trim().isNotEmpty;

    if (!shouldCompileFromBdfdSource) {
      return List<Map<String, dynamic>>.from(
        (value['actions'] as List?)?.whereType<Map>().map(
              (entry) => Map<String, dynamic>.from(entry),
            ) ??
            const <Map<String, dynamic>>[],
      );
    }

    if (_bdfdCompileCache.containsKey(source)) {
      return _bdfdCompileCache[source]!;
    }

    final compileResult = BdfdCompiler().compile(source);
    if (compileResult.hasErrors) {
      final diagnostics = _formatRunnerBdfdDiagnostics(
        compileResult.diagnostics,
      );
      _log.warning(
        'BDFD compile errors in legacy command "$commandName": $diagnostics',
      );
      throw StateError('BDFD compile error: $diagnostics');
    }

    final actions = compileResult.actions
        .map((action) => action.toJson())
        .toList(growable: false);
    _bdfdCompileCache[source] = actions;
    return actions;
  }

  Future<void> _sendLegacyWorkflowResponse({
    required EventExecutionContext context,
    required Map<String, dynamic> response,
    required Map<String, String> runtimeVariables,
    required String responseTarget,
  }) async {
    final workflowConditional = Map<String, dynamic>.from(
      (response['workflow']?['conditional'] as Map?)?.cast<String, dynamic>() ??
          const {},
    );

    final useCondition = workflowConditional['enabled'] == true;
    final conditionVariable =
        (workflowConditional['variable'] ?? '').toString().trim();
    final whenTrueType =
        (workflowConditional['whenTrueType'] ?? 'normal').toString();
    final whenFalseType =
        (workflowConditional['whenFalseType'] ?? 'normal').toString();
    final whenTrueText = (workflowConditional['whenTrueText'] ?? '').toString();
    final whenFalseText =
        (workflowConditional['whenFalseText'] ?? '').toString();

    var activeResponseType = (response['type'] ?? 'normal').toString();
    var responseText = (response['text'] ?? '').toString();
    var embedsRaw =
        (response['embeds'] is List)
            ? List<Map<String, dynamic>>.from(
              (response['embeds'] as List).whereType<Map>().map(
                (entry) => Map<String, dynamic>.from(entry),
              ),
            )
            : <Map<String, dynamic>>[];

    if (useCondition && conditionVariable.isNotEmpty) {
      final variableValue =
          conditionVariable.contains('((')
              ? resolveTemplatePlaceholders(
                conditionVariable,
                runtimeVariables,
              ).trim()
              : (runtimeVariables[conditionVariable] ?? '').trim();
      final matched = variableValue.isNotEmpty;
      if (matched) {
        activeResponseType = whenTrueType;
        if (whenTrueText.trim().isNotEmpty) {
          responseText = whenTrueText;
        }
        embedsRaw = List<Map<String, dynamic>>.from(
          (workflowConditional['whenTrueEmbeds'] as List?)
                  ?.whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry)) ??
              const <Map<String, dynamic>>[],
        );
      } else {
        activeResponseType = whenFalseType;
        if (whenFalseText.trim().isNotEmpty) {
          responseText = whenFalseText;
        }
        embedsRaw = List<Map<String, dynamic>>.from(
          (workflowConditional['whenFalseEmbeds'] as List?)
                  ?.whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry)) ??
              const <Map<String, dynamic>>[],
        );
      }
    }

    if (activeResponseType == 'modal') {
      await _sendLegacyMessage(
        context: context,
        content: 'Modal responses are not supported in legacy command mode.',
        embeds: const <EmbedBuilder>[],
        asReply: responseTarget == 'reply',
      );
      return;
    }

    if (embedsRaw.isEmpty) {
      final legacyEmbed = Map<String, dynamic>.from(
        (response['embed'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final hasLegacyEmbed =
          (legacyEmbed['title']?.toString().isNotEmpty ?? false) ||
          (legacyEmbed['description']?.toString().isNotEmpty ?? false) ||
          (legacyEmbed['url']?.toString().isNotEmpty ?? false);
      if (hasLegacyEmbed) {
        embedsRaw.add(legacyEmbed);
      }
    }

    final embeds = <EmbedBuilder>[];
    for (final embedJson in embedsRaw.take(10)) {
      final embed = EmbedBuilder();
      final title = resolveTemplatePlaceholders(
        (embedJson['title'] ?? '').toString(),
        runtimeVariables,
      );
      final description = resolveTemplatePlaceholders(
        (embedJson['description'] ?? '').toString(),
        runtimeVariables,
      );
      final urlText =
          resolveTemplatePlaceholders(
            (embedJson['url'] ?? '').toString(),
            runtimeVariables,
          ).trim();
      if (title.isNotEmpty) {
        embed.title = title;
      }
      if (description.isNotEmpty) {
        embed.description = description;
      }
      if (urlText.isNotEmpty) {
        final uri = Uri.tryParse(urlText);
        if (uri != null && uri.hasScheme) {
          embed.url = uri;
        }
      }
      if (embed.title != null ||
          embed.description != null ||
          embed.url != null) {
        embeds.add(embed);
      }
    }

    final resolvedText =
        resolveTemplatePlaceholders(responseText, runtimeVariables).trim();
    if (resolvedText.isEmpty && embeds.isEmpty) {
      return;
    }
    final contentToSend = resolvedText;

    await _sendLegacyMessage(
      context: context,
      content: contentToSend,
      embeds: embeds,
      asReply: responseTarget == 'reply',
    );
  }

  Future<void> _sendLegacyMessage({
    required EventExecutionContext context,
    required String content,
    required List<EmbedBuilder> embeds,
    required bool asReply,
  }) async {
    if (_gateway == null || context.channelId == null) {
      return;
    }

    final channel = await fetchChannelCached(_gateway!, context.channelId!);
    if (channel == null) return;
    final builder = MessageBuilder(
      content: content.isEmpty ? null : content,
      embeds: embeds.isEmpty ? null : embeds,
    );

    if (asReply) {
      final messageIdText = (context.variables['message.id'] ?? '').trim();
      final messageId = int.tryParse(messageIdText);
      if (messageId != null) {
        builder.referencedMessage = MessageReferenceBuilder.reply(
          messageId: Snowflake(messageId),
          channelId: context.channelId,
          guildId: context.guildId,
          failIfInexistent: false,
        );
      }
    }

    await (channel as dynamic).sendMessage(builder);
  }

  Future<bool> _tryExecuteLegacyCommand(
    EventExecutionContext context, {
    required Map<String, String> sharedVariables,
  }) async {
    final gateway = _gateway;
    if (gateway == null) {
      return false;
    }

    final content = (sharedVariables['message.content'] ?? '').trim();
    if (content.isEmpty) {
      return false;
    }

    final botId = gateway.user.id.toString();
    final legacyCommands = config.commands
        .where(_isLegacyCommandEnabled)
        .toList(growable: false);
    if (legacyCommands.isEmpty) {
      return false;
    }

    final handledAwaited = await _tryExecuteAwaitedLegacyInput(
      context,
      botId: botId,
      legacyCommands: legacyCommands,
    );
    if (handledAwaited) {
      return true;
    }


    final handledBuiltInHelp = await _tryExecuteBuiltInLegacyHelp(
      context,
      content: content,
      botId: botId,
      builtInLegacyHelpEnabled: config.builtInLegacyHelpEnabled,
      legacyCommands: legacyCommands,
      runtimeVariables: sharedVariables,
    );
    if (handledBuiltInHelp) {
      return true;
    }

    for (final command in legacyCommands) {
      if (_parseAwaitedLegacyTrigger((command['name'] ?? '').toString()) !=
          null) {
        continue;
      }
      final data = Map<String, dynamic>.from(
        (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final value = Map<String, dynamic>.from(
        (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
      );
      final runtimeVariables = <String, String>{...sharedVariables};

      final prefix = await _resolveLegacyPrefix(
        value: value,
        runtimeVariables: runtimeVariables,
      );
      if (prefix == null || prefix.isEmpty || !content.startsWith(prefix)) {
        continue;
      }

      final remainder = content.substring(prefix.length).trimLeft();
      if (remainder.isEmpty) {
        continue;
      }
      final tokens = _splitLegacyTokens(remainder);
      if (tokens.isEmpty) {
        continue;
      }

      final incomingName = tokens.first.trim().toLowerCase();
      final commandName =
          (command['name'] ?? '').toString().trim().toLowerCase();
      if (incomingName != commandName) {
        continue;
      }

      final args = tokens.length > 1 ? tokens.sublist(1) : const <String>[];
      runtimeVariables['message.content'] = args.join(' ');
      runtimeVariables['message.content[0]'] = commandName;
      for (var i = 0; i < args.length; i++) {
        runtimeVariables['message.content[${i + 1}]'] = args[i];
      }
      runtimeVariables['legacy.prefix'] = prefix;
      runtimeVariables['legacy.command.name'] = commandName;
      runtimeVariables['command.type'] = 'legacy';
      runtimeVariables['interaction.command.type'] = 'legacy';
      runtimeVariables['config.command.type'] = 'chatInput';
      runtimeVariables['interaction.isSlash'] = 'false';
      runtimeVariables['interaction.command.name'] = commandName;
      runtimeVariables['interaction.command.route'] = '';

      final optionError = await _bindLegacyPositionalOptions(
        value: value,
        args: args,
        prefix: prefix,
        commandName: commandName,
        context: context,
        runtimeVariables: runtimeVariables,
      );
      if (optionError != null) {
        await _sendLegacyMessage(
          context: context,
          content: optionError,
          embeds: const <EmbedBuilder>[],
          asReply: _effectiveLegacyResponseTarget(value) == 'reply',
        );
        return true;
      }

      final response = Map<String, dynamic>.from(
        (value['response'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final executionMode =
          (value['executionMode'] ?? 'workflow')
              .toString()
              .trim()
              .toLowerCase();
      late final List<Map<String, dynamic>> actionsJson;
      try {
        actionsJson = await _resolveLegacyActionsJson(
          value: value,
          commandName: commandName,
        );
      } catch (e) {
        await _sendLegacyMessage(
          context: context,
          content: 'Failed to run BDFD script for command "$commandName": $e',
          embeds: const <EmbedBuilder>[],
          asReply: _effectiveLegacyResponseTarget(value) == 'reply',
        );
        return true;
      }

      if (actionsJson.isNotEmpty) {
        final actions = actionsJson
            .map((json) => _adaptLegacyActionForMessageCreate(json, context))
            .map(Action.fromJson)
            .toList(growable: false);
        final actionResults = await _runActionsWithReplay(
          replayLabel: 'legacy:$commandName',
          client: gateway,
          interaction: null,
          actions: actions,
          botId: botId,
          runtimeVariables: runtimeVariables,
          fallbackChannelId: context.channelId,
          fallbackGuildId: context.guildId,
          nestedActionsPreprocessor:
              (nestedActions) => nestedActions
                  .map(
                    (a) => Action.fromJson(
                      _adaptLegacyActionForMessageCreate(a.toJson(), context),
                    ),
                  )
                  .toList(growable: false),
        );
        for (final entry in actionResults.entries) {
          runtimeVariables['action.${entry.key}'] = entry.value;
        }
      }

      if (executionMode != 'bdfd_script') {
        await _sendLegacyWorkflowResponse(
          context: context,
          response: response,
          runtimeVariables: runtimeVariables,
          responseTarget: _effectiveLegacyResponseTarget(value),
        );
      }
      _log.info('Legacy command executed: $commandName');
      return true;
    }

    return false;
  }
}
