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

  Future<DiscordApplicationOwnerMetadata?>
  _resolveDiscordOwnerMetadataForBotStart({
    required String botId,
    required String? token,
  }) async {
    return _ownerSyncHelper.resolveDiscordOwnerMetadataForBotStart(
      botId: botId,
      token: token,
    );
  }

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
    String? preferredOwnerId,
    Iterable<String> acceptableOwnerIds = const <String>[],
  }) async {
    return _ownerSyncHelper.restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: botToken,
      preferredOwnerId: preferredOwnerId,
      acceptableOwnerIds: acceptableOwnerIds,
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
      final user = await widget.client.user.get();
      final botId = user.id.toString();
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Token not found');
      }

      await appManager.createOrUpdateApp(
        id: user.id,
        username: user.username,
        avatarHash: user.avatarHash,
        discriminator: user.discriminator.toString(),
        token: token,
      );

      try {
        final remoteCommands = await widget.client.commands.list(
          withLocalizations: true,
        );

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

      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_sync_success)),
        );
      }
    } catch (e) {
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
