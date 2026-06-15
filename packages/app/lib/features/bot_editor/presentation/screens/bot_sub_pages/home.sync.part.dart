part of 'home.dart';

extension _AppHomePageSync on _AppHomePageState {
  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 90),
  }) async {
    return resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: widget.client.user.id.toString(),
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  MainApiOwnerSyncHelper get _ownerSyncHelper => MainApiOwnerSyncHelper(
    resolveRuntime:
        ({
          getTimeout = const Duration(seconds: 30),
          postTimeout = const Duration(seconds: 90),
        }) => _resolveRemoteRuntime(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
    loadLocalBotById: (botId) async => await appManager.getApp(botId),
    log: appendBotDebugLog,
  );

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
  }) async {
    return _ownerSyncHelper.restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: botToken,
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForBot({
    required String botId,
    required String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    return _ownerSyncHelper.resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: attemptSessionRestore,
    );
  }

  Future<void> _refreshFreeRuntimeBalance() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog(
      '[_refreshFreeRuntimeBalance] Fetching runtime balance for botId=$botId.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] No MainApiClient available (source=${remoteRuntime.source}); balance cleared.',
      );
      if (!mounted) {
        return;
      }
      _setState(() {
        _freeMinutesBalance = null;
      });
      return;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      final balance = _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] botId=$botId balance=$balance.',
      );
      if (!mounted) {
        return;
      }
      _setState(() {
        _freeMinutesBalance = balance;
      });
    } catch (error) {
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] getBotRuntime failed for botId=$botId: $error',
      );
    }
  }

  Future<void> _syncAppFromRemote({required bool showSnack}) async {
    if (_isSyncingApp) {
      return;
    }

    _setState(() => _isSyncingApp = true);
    try {
      appendBotDebugLog('[_syncAppFromRemote] START');
      final user = await widget.client.user.get().timeout(const Duration(seconds: 10));
      final botId = user.id.toString();
      appendBotDebugLog('[_syncAppFromRemote] botId=$botId username=${user.username}');
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Token not found');
      }
      appendBotDebugLog('[_syncAppFromRemote] token present, length=${token.length}');

      await appManager.createOrUpdateApp(
        id: user.id,
        username: user.username,
        avatarHash: user.avatarHash,
        discriminator: user.discriminator.toString(),
        token: token,
      );

      // Pull latest bot config from Manager (synced from other devices)
      try {
        appendBotDebugLog('[_syncAppFromRemote] resolving Manager client...');
        final mainClient = await _resolveMainApiClientForBot(
          botId: botId,
          botToken: token,
          attemptSessionRestore: true,
        );
        if (mainClient != null) {
          appendBotDebugLog('[_syncAppFromRemote] Manager client ok, fetching config...');
          final remoteConfig = await mainClient.getBotConfig(botId).timeout(const Duration(seconds: 15));
          if (remoteConfig.isNotEmpty) {
            // Preserve local-only fields that the Manager doesn't store:
            // avatar and name are set locally and should survive cross-device sync.
            final local = await appManager.getApp(botId);
            remoteConfig['token'] = token;
            // Strip payload-only boolean fields that collide with local DB list fields.
            // BotConfig.inboundWebhooks is a premium-capability bool; the local DB uses
            // the same key for the list of webhook endpoint definitions.
            if (remoteConfig['inboundWebhooks'] is bool) {
              remoteConfig.remove('inboundWebhooks');
            }
            if (local['avatar'] != null && remoteConfig['avatar'] == null) {
              remoteConfig['avatar'] = local['avatar'];
            }
            if (local['name'] != null && remoteConfig['name'] == null) {
              remoteConfig['name'] = local['name'];
            }

            // Merge global variables so local-only definitions survive sync
            final localGlobals = local['globalVariables'];
            final remoteGlobals = remoteConfig['globalVariables'];
            if (localGlobals is Map) {
              final mergedGlobals = Map<String, dynamic>.from(localGlobals);
              if (remoteGlobals is Map) {
                mergedGlobals.addAll(Map<String, dynamic>.from(remoteGlobals));
              }
              remoteConfig['globalVariables'] = mergedGlobals;
            }

            // Merge scoped variables so local-only definitions survive sync
            final localScoped = local['scopedVariables'];
            final remoteScoped = remoteConfig['scopedVariables'];
            if (localScoped is Map) {
              final mergedScoped = Map<String, dynamic>.from(localScoped);
              if (remoteScoped is Map) {
                mergedScoped.addAll(Map<String, dynamic>.from(remoteScoped));
              }
              remoteConfig['scopedVariables'] = mergedScoped;
            }

            // Merge scoped variable definitions so local-only definitions survive sync
            final localScopedDefs = local['scopedVariableDefinitions'];
            final remoteScopedDefs = remoteConfig['scopedVariableDefinitions'];
            if (localScopedDefs is List) {
              final mergedScopedDefs = List<dynamic>.from(localScopedDefs);
              if (remoteScopedDefs is List) {
                final remoteNames = remoteScopedDefs
                    .whereType<Map>()
                    .map((d) => (d['name'] ?? '').toString())
                    .toSet();
                for (final def in localScopedDefs) {
                  if (def is! Map) continue;
                  final name = (def['name'] ?? '').toString();
                  if (name.isNotEmpty && !remoteNames.contains(name)) {
                    mergedScopedDefs.add(def);
                  }
                }
              }
              remoteConfig['scopedVariableDefinitions'] = mergedScopedDefs;
            }

            AppManager.isSyncingFromRemote = true;
            try {
              await appManager.saveApp(botId, remoteConfig);
              appendBotDebugLog(
                '[_syncAppFromRemote] Pulled bot config from Manager for $botId',
              );

              // Also save individual commands from the Manager config so their
              // full data (actions, options, workflows) is available locally.
              final remoteCommands = remoteConfig['commands'];
              final remoteCommandIds = <String>{};
              if (remoteCommands is List && remoteCommands.isNotEmpty) {
                for (final cmd in remoteCommands) {
                  if (cmd is! Map) continue;
                  final cmdId = (cmd['id'] ?? cmd['commandId'] ?? '').toString();
                  final cmdName = (cmd['name'] ?? '').toString();
                  if (cmdId.isEmpty || cmdName.isEmpty) continue;
                  remoteCommandIds.add(cmdId);

                  // Always overwrite the local command with the Manager version:
                  // the user pressed Sync explicitly, so the Manager is the source of truth.
                  final localCmd = await appManager.getAppCommand(botId, cmdId);

                  // Strip legacy response/simpleConfig from imported commands
                  final cmdData = Map<String, dynamic>.from(cmd['data'] ?? cmd);
                  if (cmdData['response'] is Map &&
                      (cmdData['response'] as Map).containsKey('_migrated')) {
                    cmdData.remove('response');
                  }
                  cmdData.remove('simpleConfig');

                  await appManager.saveAppCommand(botId, cmdId, <String, dynamic>{
                    'name': cmdName,
                    'description': (cmd['description'] ?? '').toString(),
                    'type': cmdData['commandType'] ?? cmd['type'] ?? 'chatInput',
                    'id': cmdId,
                    'data': cmdData,
                    'createdAt': (localCmd['createdAt'] ?? DateTime.now().toIso8601String()).toString(),
                    'updatedAt': (cmd['updatedAt'] ?? DateTime.now().toIso8601String()).toString(),
                  });
                }
                appendBotDebugLog(
                  '[_syncAppFromRemote] Upserted ${remoteCommands.length} commands from Manager config for $botId',
                );
              }

              final lastSyncedAtStr = local['lastSyncedAt']?.toString();
              final lastSyncedAt = lastSyncedAtStr != null ? DateTime.tryParse(lastSyncedAtStr) : null;

              // Collect local-only commands and detect deleted commands.
              final localCommands = await appManager.listAppCommands(botId);
              final localOnlyCommands = <Map<String, dynamic>>[];
              final commandsToDelete = <String>[];
              for (final localCmd in localCommands) {
                final localCmdId = (localCmd['id'] ?? '').toString();
                if (localCmdId.isEmpty) continue;
                if (!remoteCommandIds.contains(localCmdId)) {
                  final cmdUpdatedAtStr = localCmd['updatedAt']?.toString();
                  final cmdUpdatedAt = cmdUpdatedAtStr != null ? DateTime.tryParse(cmdUpdatedAtStr) : null;
                  final isDiscordId = RegExp(r'^\d+$').hasMatch(localCmdId);

                  if (isDiscordId && lastSyncedAt != null && cmdUpdatedAt != null && cmdUpdatedAt.isBefore(lastSyncedAt)) {
                    // This command existed before the last sync but is now missing from the remote.
                    // This means it was deleted on another device.
                    commandsToDelete.add(localCmdId);
                  } else {
                    localOnlyCommands.add(Map<String, dynamic>.from(localCmd));
                  }
                }
              }

              for (final cmdId in commandsToDelete) {
                await appManager.deleteAppCommand(botId, cmdId);
              }
              if (commandsToDelete.isNotEmpty) {
                appendBotDebugLog(
                  '[_syncAppFromRemote] Deleted ${commandsToDelete.length} locally-deleted commands on $botId',
                );
              }

              // Also upsert workflows from the Manager config
              final remoteWorkflows = remoteConfig['workflows'];
              final remoteWorkflowNames = <String>{};
              if (remoteWorkflows is List && remoteWorkflows.isNotEmpty) {
                for (final wf in remoteWorkflows) {
                  if (wf is! Map) continue;
                  final wfName = (wf['name'] ?? '').toString();
                  if (wfName.isEmpty) continue;
                  remoteWorkflowNames.add(wfName);

                  // Always overwrite the local workflow with the Manager version.
                  await appManager.saveWorkflow(
                    botId,
                    name: wfName,
                    actions: ((wf['actions'] as List?) ?? [])
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList(),
                    entryPoint: wf['entryPoint']?.toString(),
                    arguments: ((wf['arguments'] as List?) ?? [])
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList(),
                    workflowType: wf['workflowType']?.toString(),
                    eventTrigger: wf['eventTrigger'] != null
                        ? Map<String, dynamic>.from(wf['eventTrigger'] as Map)
                        : null,
                    folder: wf['folder']?.toString(),
                  );
                }
                appendBotDebugLog(
                  '[_syncAppFromRemote] Upserted ${remoteWorkflows.length} workflows from Manager config for $botId',
                );
              }

              // Collect local-only workflows and detect deleted workflows.
              final localWorkflows = (local['workflows'] as List?)
                      ?.whereType<Map>()
                      .map((w) => Map<String, dynamic>.from(w))
                      .toList() ??
                  [];
              final localOnlyWorkflows = <Map<String, dynamic>>[];
              final workflowsToDelete = <String>[];
              for (final wf in localWorkflows) {
                final wfName = (wf['name'] ?? '').toString();
                if (wfName.isEmpty) continue;
                if (!remoteWorkflowNames.contains(wfName)) {
                  final wfUpdatedAtStr = wf['updatedAt']?.toString();
                  final wfUpdatedAt = wfUpdatedAtStr != null ? DateTime.tryParse(wfUpdatedAtStr) : null;

                  if (lastSyncedAt != null && wfUpdatedAt != null && wfUpdatedAt.isBefore(lastSyncedAt)) {
                    // This workflow existed before the last sync but is now missing from the remote.
                    // This means it was deleted on another device.
                    workflowsToDelete.add(wfName);
                  } else {
                    localOnlyWorkflows.add(wf);
                  }
                }
              }

              for (final wfName in workflowsToDelete) {
                await appManager.deleteWorkflow(botId, wfName);
              }
              if (workflowsToDelete.isNotEmpty) {
                appendBotDebugLog(
                  '[_syncAppFromRemote] Deleted ${workflowsToDelete.length} locally-deleted workflows on $botId',
                );
              }

              // Re-save local-only workflows to database so they survive sync and get pushed back to Manager
              for (final wf in localOnlyWorkflows) {
                await appManager.saveWorkflow(
                  botId,
                  name: (wf['name'] ?? '').toString(),
                  actions: ((wf['actions'] as List?) ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  entryPoint: wf['entryPoint']?.toString(),
                  arguments: ((wf['arguments'] as List?) ?? [])
                      .map((e) => Map<String, dynamic>.from(e as Map))
                      .toList(),
                  workflowType: wf['workflowType']?.toString(),
                  eventTrigger: wf['eventTrigger'] != null
                      ? Map<String, dynamic>.from(wf['eventTrigger'] as Map)
                      : null,
                  folder: wf['folder']?.toString(),
                  eventVariableAliases: wf['eventVariableAliases'] != null
                      ? Map<String, String>.from(wf['eventVariableAliases'] as Map)
                      : null,
                );
              }
              if (localOnlyWorkflows.isNotEmpty) {
                appendBotDebugLog(
                  '[_syncAppFromRemote] Restored and saved ${localOnlyWorkflows.length} local-only workflows back to storage for $botId',
                );
              }
            } finally {
              AppManager.isSyncingFromRemote = false;
            }
          }
        }
      } catch (e) {
        appendBotDebugLog(
          '[_syncAppFromRemote] Pull from Manager skipped: $e',
        );
      }

      try {
        appendBotDebugLog('[_syncAppFromRemote] syncing Discord commands...');
        final remoteCommands = await widget.client.commands.list(
          withLocalizations: true,
        ).timeout(const Duration(seconds: 15));

        final allLocal = await appManager.listAppCommands(botId);
        final reconciledLocalIds = <String>{};

        AppManager.isSyncingFromRemote = true;
        try {
          for (final command in remoteCommands) {
            final commandId = command.id.toString();
            var local = await appManager.getAppCommand(botId, commandId);

            if (local.isEmpty) {
              final commandType =
                  command.type == ApplicationCommandType.user
                      ? 'user'
                      : command.type == ApplicationCommandType.message
                      ? 'message'
                      : 'chatinput';
              final match = allLocal.cast<Map<String, dynamic>?>().firstWhere((
                c,
              ) {
                final localId = (c!['id'] ?? '').toString();
                if (reconciledLocalIds.contains(localId)) return false;
                if (localId == commandId) return false;
                final localData = (c['data'] as Map?)?.cast<String, dynamic>();
                if (localData != null &&
                    localData['legacyModeEnabled'] == true &&
                    localData['legacyLocalOnly'] == true) {
                  return false;
                }
                final localName = (c['name'] ?? '').toString();
                final localType =
                    (c['type'] ?? 'chatInput').toString().toLowerCase();
                return localName == command.name && localType == commandType;
              }, orElse: () => null);

              if (match != null) {
                final oldId = (match['id'] ?? '').toString();
                local = match;
                reconciledLocalIds.add(oldId);
                await appManager.deleteAppCommand(botId, oldId);
              } else {
                // Skip importing this command: it exists on Discord but not in our Cloud config.
                continue;
              }
            }

            final merged = <String, dynamic>{
              ...local,
              'id': commandId,
              'name': command.name,
              'description': command.description,
            };
            await appManager.saveAppCommand(botId, commandId, merged);
          }
        } finally {
          AppManager.isSyncingFromRemote = false;
        }
      } catch (_) {}

      final refreshed = await appManager.getApp(botId);
      if (mounted) {
        _setState(() {
          _appName = (refreshed['name'] ?? _appName).toString();
          avatar = (refreshed['avatar'] ?? avatar).toString();
        });
      }

      // Push Discord-reconciled command IDs back to Manager so other devices
      // get the correct Discord IDs. We do NOT push the full local config here
      // because we just pulled from Manager — pushing back would risk overwriting
      // concurrent changes from another device.
      try {
        final mainClient = await _resolveMainApiClientForBot(
          botId: botId,
          botToken: token,
          attemptSessionRestore: true,
        );
        if (mainClient != null) {
          // Re-read the local state that now reflects the Manager pull + Discord reconciliation.
          final afterSync = await appManager.getApp(botId);
          final localCommands = await appManager.listAppCommands(botId);

          // Build a minimal patch: only the fields the Manager needs to keep
          // command IDs aligned with Discord. Do not include token.
          final patch = Map<String, dynamic>.from(afterSync);
          patch.remove('token');
          // Replace the commands list with the fully-reconciled local list
          // so Discord IDs are up-to-date on the Manager.
          patch['commands'] = localCommands;

          appendBotDebugLog('[_syncAppFromRemote] pushing reconciled IDs to Manager...');
          await mainClient.syncBot(
            botId,
            user.username,
            patch,
            force: true,
          ).timeout(const Duration(seconds: 20));
          appendBotDebugLog(
            '[_syncAppFromRemote] Pushed reconciled config to Manager for $botId',
          );

          // Save the last synced timestamp in the local app config
          final currentApp = await appManager.getApp(botId);
          final updatedApp = Map<String, dynamic>.from(currentApp)
            ..['lastSyncedAt'] = DateTime.now().toUtc().toIso8601String();
          await appManager.saveApp(botId, updatedApp);
          appendBotDebugLog('[_syncAppFromRemote] Updated lastSyncedAt timestamp.');
        }
      } catch (e) {
        appendBotDebugLog(
          '[_syncAppFromRemote] Failed to push reconciled config to Manager: $e',
        );
      }

      appendBotDebugLog('[_syncAppFromRemote] DONE — success');
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_sync_success)),
        );
      }
    } catch (e) {
      appendBotDebugLog('[_syncAppFromRemote] FAILED: $e');
      if (showSnack && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _setState(() => _isSyncingApp = false);
    }
  }

  Future<int?> _fetchMainApiRuntimeBalance(String botId) async {
    appendBotDebugLog(
      '[_fetchMainApiRuntimeBalance] Fetching runtime balance for botId=$botId.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      appendBotDebugLog(
        '[_fetchMainApiRuntimeBalance] No MainApiClient (source=${remoteRuntime.source}); returning null.',
      );
      return null;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      final balance = _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
      return balance;
    } catch (error) {
      appendBotDebugLog(
        '[_fetchMainApiRuntimeBalance] getBotRuntime failed for botId=$botId: $error',
      );
      return null;
    }
  }

  Future<bool> _waitForMainApiRewardCredit({
    required String botId,
    required int? previousBalance,
  }) async {
    appendBotDebugLog(
      '[_waitForMainApiRewardCredit] Starting poll for botId=$botId previousBalance=$previousBalance.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return true;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final balance = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );

        if (mounted) {
          _setState(() {
            _freeMinutesBalance = balance;
          });
        }

        if ((previousBalance != null && balance > previousBalance) ||
            _hasFreeRuntimeAvailable(runtime, balance)) {
          return true;
        }
      } catch (_) {}

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    return false;
  }

}
