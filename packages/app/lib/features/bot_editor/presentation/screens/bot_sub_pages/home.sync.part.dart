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

    _isSyncingApp = true;
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
            await appManager.saveApp(botId, remoteConfig);
            appendBotDebugLog(
              '[_syncAppFromRemote] Pulled bot config from Manager for $botId',
            );

            // Also save individual commands from the Manager config so their
            // full data (actions, options, workflows) is available locally.
            final remoteCommands = remoteConfig['commands'];
            if (remoteCommands is List && remoteCommands.isNotEmpty) {
              for (final cmd in remoteCommands) {
                if (cmd is! Map) continue;
                final cmdId = (cmd['id'] ?? cmd['commandId'] ?? '').toString();
                final cmdName = (cmd['name'] ?? '').toString();
                if (cmdId.isEmpty || cmdName.isEmpty) continue;

                // Only save if we don't already have this command locally
                // (local edits should not be overwritten by remote pulls)
                final localCmd = await appManager.getAppCommand(botId, cmdId);
                if (localCmd.isNotEmpty) continue;

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
                  'createdAt': DateTime.now().toIso8601String(),
                  'updatedAt': DateTime.now().toIso8601String(),
                });
              }
              appendBotDebugLog(
                '[_syncAppFromRemote] Saved ${remoteCommands.length} commands from Manager config for $botId',
              );

              // Also save workflows from the Manager config
              final remoteWorkflows = remoteConfig['workflows'];
              if (remoteWorkflows is List && remoteWorkflows.isNotEmpty) {
                for (final wf in remoteWorkflows) {
                  if (wf is! Map) continue;
                  final wfName = (wf['name'] ?? '').toString();
                  if (wfName.isEmpty) continue;

                  // Only save if we don't already have this workflow locally
                  final existingWorkflows = (local['workflows'] as List?) ?? [];
                  final alreadyExists = existingWorkflows.any(
                    (w) => (w is Map) && (w['name'] ?? '').toString() == wfName,
                  );
                  if (alreadyExists) continue;

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
                  '[_syncAppFromRemote] Saved ${remoteWorkflows.length} workflows from Manager config for $botId',
                );
              }
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
      } catch (_) {}

      final refreshed = await appManager.getApp(botId);
      if (mounted) {
        _setState(() {
          _appName = (refreshed['name'] ?? _appName).toString();
          avatar = (refreshed['avatar'] ?? avatar).toString();
        });
      }

      // Push full bot configuration to Manager so it's available
      // for sync on other devices (workflows, variables, triggers, etc.)
      try {
        final mainClient = await _resolveMainApiClientForBot(
          botId: botId,
          botToken: token,
          attemptSessionRestore: true,
        );
        if (mainClient != null) {
          final botConfig = Map<String, dynamic>.from(refreshed);
          botConfig.remove('token');
          appendBotDebugLog('[_syncAppFromRemote] pushing bot config to Manager...');
          await mainClient.syncBot(
            botId,
            user.username,
            botConfig,
            force: true,
          ).timeout(const Duration(seconds: 20));
          appendBotDebugLog(
            '[_syncAppFromRemote] Pushed full bot config to Manager for $botId',
          );
        }
      } catch (e) {
        appendBotDebugLog(
          '[_syncAppFromRemote] Failed to push bot config to Manager: $e',
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
      _isSyncingApp = false;
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
