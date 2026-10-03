part of 'copilot_mcp.dart';

extension CopilotConfigurationTools on CopilotMcp {
  Future<ApplicationCommand> _patchDiscordCommand(
    NyxxRest rest,
    Map<String, dynamic> command,
    ApplicationCommandUpdateBuilder update,
  ) async {
    // A restored local ID may be a UUID rather than a Discord snowflake.
    final storedID = (command['discordId'] ?? command['id'])?.toString();
    final numericID = storedID != null && RegExp(r'^\d+$').hasMatch(storedID)
        ? int.tryParse(storedID)
        : null;
    if (numericID != null && numericID > 0) {
      try {
        return await rest.commands.update(Snowflake(numericID), update);
      } on HttpResponseError catch (error) {
        // Only a definitively missing command permits identity recovery.
        if (error.errorCode != 10063) rethrow;
      }
    }
    final type = switch (command['type'] ?? 'chatInput') {
      'chatInput' || 'command' => ApplicationCommandType.chatInput,
      'user' => ApplicationCommandType.user,
      'message' => ApplicationCommandType.message,
      _ => throw const FormatException('Unsupported Discord command type'),
    };
    final matches = (await rest.commands.list())
        .where((c) => c.name == command['name'] && c.type == type)
        .toList();
    if (matches.isEmpty) throw StateError('Discord command identity not found');
    if (matches.length != 1) {
      throw StateError('Discord command identity is ambiguous');
    }
    return rest.commands.update(matches.single.id, update);
  }

  Future<bool> retryCloudConfiguration(String botID) async {
    if (botId != null && botId != botID) {
      throw StateError('Tool targets another bot');
    }
    final result = await _syncConfiguration(botID);
    return result['runner_synced'] == true && result['runner_running'] == true;
  }

  Future<Map<String, dynamic>> _configurationSnapshot(String botID) async {
    final app = await _localBot(botID);
    final sections = <String, dynamic>{
      'profile': {'username': app['name'] ?? app['username'] ?? ''},
      'presence': copilotPresence(app),
      'variables': {
        'global': await AppManager().getGlobalVariables(botID),
        'definitions': await AppManager().getScopedVariableDefinitions(botID),
      },
      'scheduled_triggers': await AppManager().getScheduledTriggers(botID),
      'inbound_webhooks': await AppManager().getInboundWebhooks(botID),
      'intents': app['intents'] ?? {},
    };
    return {
      'configuration': CopilotMcp.redact(sections),
      'revisions': {
        for (final e in sections.entries)
          e.key: HashUtil.calculateHash(e.value),
      },
      'runtime_engine': await getBotRuntimeEngine(botID),
      'bdfdUserVariableSemantics': app['bdfdUserVariableSemantics'] == 2
          ? 2
          : 1,
    };
  }

  Future<Object?> _configurationTool(
    String name,
    Map<String, dynamic> args,
  ) async {
    if (name == 'local_list_events') {
      return EventCatalog.getEvents()
          .map(
            (e) => {
              'category': e.category,
              'event': e.event,
              'label': e.label,
              'description': e.description,
            },
          )
          .toList();
    }
    final botID = args['bot_id'] as String;
    final app = await _localBot(botID);
    final manager = AppManager();
    switch (name) {
      case 'local_get_bot_configuration':
        return _configurationSnapshot(botID);
      case 'local_get_bot_presence':
        final presence = copilotPresence(app);
        return {
          'presence': presence,
          'revision': HashUtil.calculateHash(presence),
        };
      case 'local_update_command_options':
      case 'local_update_command_settings':
        final commandID = _commandID(args);
        final before = await manager.getAppCommand(botID, commandID);
        if (before.isEmpty) throw StateError('Command not found');
        requireCopilotRevision(before, args['expected_revision'] as String);
        Map<String, dynamic> after;
        final update = ApplicationCommandUpdateBuilder();
        if (name == 'local_update_command_options') {
          after = updateCopilotOptions(before, args);
          update.options = deserializeCommandOptions(
            (after['data'] as Map)['options'] as List,
          );
        } else {
          after = copyCopilotMap(before);
          final data = copyCopilotMap(after['data'] as Map? ?? {});
          if (args['description'] != null) {
            if ((before['type'] ?? 'chatInput') != 'chatInput') {
              throw const FormatException(
                'Only slash commands have a description',
              );
            }
            after['description'] = args['description'];
            update.description = args['description'] as String;
          }
          if (args['default_member_permissions'] != null) {
            final permissions = int.tryParse(
              args['default_member_permissions'] as String,
            );
            if (permissions == null || permissions < 0) {
              throw const FormatException('Invalid permissions');
            }
            data['defaultMemberPermissions'] = '$permissions';
            update.defaultMemberPermissions = Permissions(permissions);
          }
          if (args['contexts'] != null) {
            data['contexts'] = args['contexts'];
            update.contexts = (args['contexts'] as List)
                .map((v) => InteractionContextType(v as int))
                .toList();
          }
          if (args['integration_types'] != null) {
            data['integrationTypes'] = args['integration_types'];
            update.integrationTypes = (args['integration_types'] as List)
                .map((v) => ApplicationIntegrationType(v as int))
                .toList();
          }
          after['data'] = data;
          if (HashUtil.calculateHash(after) == HashUtil.calculateHash(before)) {
            return {
              'unchanged': true,
              'saved': false,
              'discord_updated': false,
              'bot_id': botID,
              'command_id': commandID,
              'before': copilotCommandSettings(before),
              'after': copilotCommandSettings(before),
              'revision': HashUtil.calculateHash(before),
            };
          }
        }
        final usesDiscord = copilotCommandUsesDiscord(before);
        if (usesDiscord) {
          final rest = await _verifiedDiscord(botID, app);
          try {
            final saved = await _patchDiscordCommand(rest, before, update);
            after['discordId'] = saved.id.toString();
          } finally {
            rest.close();
          }
        }
        await manager.saveAppCommand(botID, commandID, after);
        final synced = await syncCloudCommand(botID, commandID);
        return {
          'saved': true,
          'discord_updated': usesDiscord,
          'bot_id': botID,
          'command_id': commandID,
          'runner_synced': synced,
          'before': name == 'local_update_command_settings'
              ? copilotCommandSettings(before)
              : before,
          'after': name == 'local_update_command_settings'
              ? copilotCommandSettings(after)
              : after,
          'revision': HashUtil.calculateHash(
            await manager.getAppCommand(botID, commandID),
          ),
        };
      case 'local_list_workflows':
        return (await manager.getWorkflows(
          botID,
        )).map((w) => {...w, 'revision': HashUtil.calculateHash(w)}).toList();
      case 'local_get_workflow':
        final workflow = await manager.getWorkflowByName(
          botID,
          args['name'] as String,
        );
        if (workflow == null) throw StateError('Workflow not found');
        return {
          'workflow': workflow,
          'revision': HashUtil.calculateHash(workflow),
        };
      case 'local_create_workflow':
      case 'local_update_workflow':
        final existing = await manager.getWorkflowByName(
          botID,
          args['name'] as String,
        );
        if (name == 'local_create_workflow' && existing != null) {
          throw StateError('Workflow already exists');
        }
        if (name == 'local_update_workflow') {
          if (existing == null) throw StateError('Workflow not found');
          requireCopilotRevision(existing, args['expected_revision'] as String);
        }
        final next = buildCopilotWorkflow(
          args,
          legacyUserVariables:
              (await _localBot(botID))['bdfdUserVariableSemantics'] != 2,
          existing: existing,
          javascriptRuntime:
              await getBotRuntimeEngine(botID) == runtimeEngineJavascript,
        );
        await manager.saveWorkflow(
          botID,
          name: next['name'] as String,
          actions: (next['actions'] as List)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList(),
          entryPoint: next['entryPoint'] as String,
          arguments: (next['arguments'] as List)
              .map((a) => Map<String, dynamic>.from(a as Map))
              .toList(),
          workflowType: next['workflowType'] as String,
          eventTrigger: next['eventTrigger'] as Map<String, dynamic>?,
          executionMode: next['executionMode'] as String,
          jsScriptContent: next['jsScriptContent'] as String? ?? '',
        );
        final saved = (await manager.getWorkflowByName(
          botID,
          next['name'] as String,
        ))!;
        final synced = await _syncWorkflow(botID, saved);
        final needsTrigger =
            await getBotRuntimeEngine(botID) == runtimeEngineJavascript &&
            !await _workflowHasTrigger(botID, saved);
        return {
          'saved': true,
          'bot_id': botID,
          'workflow_name': next['name'],
          'runner_synced': synced,
          if (needsTrigger) 'activation_requires_trigger': true,
          if (needsTrigger)
            'message':
                'Automation saved; attach an event, schedule or webhook before it can run.',
          'before': existing,
          'after': saved,
          'revision': HashUtil.calculateHash(saved),
        };
      case 'local_update_bot_presence':
        final before = copilotPresence(app);
        requireCopilotRevision(before, args['expected_revision'] as String);
        final after = validateCopilotPresence(args);
        app.addAll(after);
        app['statuses'] = after['activities'];
        await manager.saveApp(botID, app);
        await refreshBotRuntime(botID);
        return {
          'saved': true,
          'bot_id': botID,
          'before': before,
          'after': after,
          ...await _syncConfiguration(botID),
          'revision': HashUtil.calculateHash(after),
        };
      case 'local_update_bot_profile':
        final before = {'username': app['name'] ?? app['username'] ?? ''};
        requireCopilotRevision(before, args['expected_revision'] as String);
        final rest = await _verifiedDiscord(botID, app);
        try {
          final user = await rest.users.updateCurrentUser(
            UserUpdateBuilder(username: args['username'] as String),
          );
          await manager.createOrUpdateApp(
            id: user.id,
            username: user.username,
            token: (app['token'] ?? '').toString(),
            avatarHash: user.avatarHash,
            discriminator: user.discriminator.toString(),
            intents: Map<String, bool>.from(app['intents'] as Map? ?? {}),
            prefix: (app['prefix'] ?? '!').toString(),
          );
          final after = {'username': user.username};
          return {
            'saved': true,
            'discord_updated': true,
            'bot_id': botID,
            'before': before,
            'after': after,
            ...await _syncConfiguration(botID),
            'revision': HashUtil.calculateHash(after),
          };
        } finally {
          rest.close();
        }
      case 'local_set_variable':
        final before = {
          'global': await manager.getGlobalVariables(botID),
          'definitions': await manager.getScopedVariableDefinitions(botID),
        };
        requireCopilotRevision(before, args['expected_revision'] as String);
        final scope = args['scope'] as String;
        if (scope == 'global') {
          await manager.setGlobalVariable(
            botID,
            args['key'] as String,
            args['value'],
          );
        } else {
          await manager.setScopedVariableDefinition(
            botID,
            args['key'] as String,
            scope,
            args['value'],
            valueType: args['value_type'] as String? ?? 'string',
          );
        }
        final synced = await _syncVariable(botID, args);
        return {
          'saved': true,
          'bot_id': botID,
          'scope': scope,
          'key': args['key'],
          'runner_synced': synced,
          'revision': HashUtil.calculateHash({
            'global': await manager.getGlobalVariables(botID),
            'definitions': await manager.getScopedVariableDefinitions(botID),
          }),
        };
      case 'local_update_scheduled_trigger':
        final before = await manager.getScheduledTriggers(botID);
        requireCopilotRevision(before, args['expected_revision'] as String);
        final workflow = await manager.getWorkflowByName(
          botID,
          args['workflow_name'] as String,
        );
        if (workflow == null) throw StateError('Workflow not found');
        await manager.saveScheduledTrigger(
          botID,
          triggerId: args['trigger_id'] as String? ?? const Uuid().v4(),
          workflowName: args['workflow_name'] as String,
          everyMinutes: args['every_minutes'] as int,
          enabled: args['enabled'] as bool? ?? true,
          label: args['label'] as String?,
        );
        return {
          'saved': true,
          'bot_id': botID,
          'before': before,
          'after': await manager.getScheduledTriggers(botID),
          ...await _syncConfiguration(botID),
        };
      case 'local_update_inbound_webhook':
        final before = await manager.getInboundWebhooks(botID);
        requireCopilotRevision(before, args['expected_revision'] as String);
        if (await manager.getWorkflowByName(
              botID,
              args['workflow_name'] as String,
            ) ==
            null) {
          throw StateError('Workflow not found');
        }
        final id = args['webhook_id'] as String? ?? const Uuid().v4();
        final matches = before.where((w) => w['id'] == id).toList();
        final secret = matches.isEmpty
            ? base64UrlEncode(
                List<int>.generate(32, (_) => Random.secure().nextInt(256)),
              )
            : matches.single['secret'] as String;
        await manager.saveInboundWebhook(
          botID,
          webhookId: id,
          path: args['path'] as String,
          workflowName: args['workflow_name'] as String,
          secret: secret,
          enabled: args['enabled'] as bool? ?? true,
        );
        return {
          'saved': true,
          'bot_id': botID,
          'webhook_id': id,
          'before': CopilotMcp.redact(before),
          'after': CopilotMcp.redact(await manager.getInboundWebhooks(botID)),
          ...await _syncConfiguration(botID),
          'credentials_location':
              'Webhook credentials are available in the bot settings; never include them in chat.',
        };
    }
    throw StateError('Unsupported configuration tool');
  }

  Future<NyxxRest> _verifiedDiscord(String botID, Map app) async {
    final token = (app['token'] ?? '').toString();
    if (token.isEmpty) {
      throw StateError('Configure the bot credentials in the application');
    }
    final rest = await _connectDiscord(token);
    if (rest.user.id.toString() != botID) {
      rest.close();
      throw StateError('Bot identity does not match its credentials');
    }
    return rest;
  }

  Future<bool> _syncWorkflow(
    String botID,
    Map<String, dynamic> workflow,
  ) async {
    final javascript =
        await getBotRuntimeEngine(botID) == runtimeEngineJavascript;
    if (javascript) {
      if (!await _workflowHasTrigger(botID, workflow)) return false;
      final full = await _syncConfiguration(botID);
      return full['runner_synced'] == true && full['runner_running'] == true;
    }
    Future<bool> delta() async {
      final app = await _localBot(botID);
      return api.syncWorkflowWithStatus(
        botID,
        (app['name'] ?? botID).toString(),
        workflow['name'] as String,
        workflow,
      );
    }

    try {
      if (await delta()) return true;
    } catch (_) {}
    final full = await _syncConfiguration(botID);
    if (full['runner_synced'] != true) return false;
    try {
      return await delta();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _workflowHasTrigger(String botID, Map workflow) async {
    if (workflow['workflowType'] == 'event') return true;
    final triggers = [
      ...await AppManager().getScheduledTriggers(botID),
      ...await AppManager().getInboundWebhooks(botID),
    ];
    return triggers.any(
      (t) => t['workflowName'] == workflow['name'] && t['enabled'] != false,
    );
  }

  Future<bool> _syncVariable(String botID, Map<String, dynamic> args) async {
    try {
      return await api.setVariableWithStatus(botID, args);
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _syncConfiguration(String botID) async {
    var synced = false;
    bool? running;
    try {
      final app = await _localBot(botID);
      synced = await api.syncBotConfigurationWithStatus(
        botID,
        (app['name'] ?? botID).toString(),
        await buildRemotePayload(botID),
      );
      running = (await api.getStatus(botId: botID)).isBotRunning(botID);
    } catch (_) {}
    return {
      'runner_synced': synced,
      'runner_running': running,
      'message': synced && running == true
          ? 'Configuration sent to the running cloud bot'
          : synced && running == false
          ? 'Configuration sent; cloud bot is stopped'
          : synced
          ? 'Configuration sent; cloud runtime state is not confirmed'
          : 'Saved in the application; cloud update not confirmed',
    };
  }

  /// Preview uses the same revision guards and transformation as execution.
  Future<Map<String, dynamic>?> previewConfiguration(
    String name,
    Map<String, dynamic> args,
  ) async {
    final botID = args['bot_id'] as String?;
    if (botID == null) return null;
    if (name == 'local_update_command_options') {
      final before = await AppManager().getAppCommand(botID, _commandID(args));
      final after = updateCopilotOptions(before, args);
      return {
        'before': (before['data'] as Map?)?['options'] ?? [],
        'after': (after['data'] as Map)['options'],
      };
    }
    if (name == 'local_update_bot_presence') {
      final before = copilotPresence(await _localBot(botID));
      requireCopilotRevision(before, args['expected_revision'] as String);
      return {'before': before, 'after': validateCopilotPresence(args)};
    }
    return null;
  }
}
