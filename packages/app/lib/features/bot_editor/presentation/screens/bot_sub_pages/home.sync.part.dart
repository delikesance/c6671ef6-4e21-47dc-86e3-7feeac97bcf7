part of 'home.dart';

extension _AppHomePageSync on _AppHomePageState {
  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 25),
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
          postTimeout = const Duration(seconds: 25),
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
        _sessionExpiresAt = null;
        _fundingMode = '';
      });
      return;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      final funding = (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      final expires = _extractSessionExpiresAt(runtime);
      final balance = funding == 'premium'
          ? 0
          : (expires != null && funding == 'free'
                ? _remainingMinutesUntil(expires)
                : _extractFreeMinutes(
                    runtime['free_minutes_balance'] ??
                        runtime['freeMinutesBalance'],
                  ));
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] botId=$botId balance=$balance funding=$funding expires=$expires.',
      );
      if (!mounted) {
        return;
      }
      _setState(() {
        _fundingMode = funding;
        _sessionExpiresAt = funding == 'free' ? expires : null;
        _freeMinutesBalance = balance;
      });
    } catch (error) {
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] getBotRuntime failed for botId=$botId: $error',
      );
    }
  }

  Future<void> _pushToRemote({required bool showSnack}) async {
    if (_isPushingApp) {
      return;
    }

    _setState(() => _isPushingApp = true);
    try {
      appendBotDebugLog('[_pushToRemote] START');
      final user = await widget.client.user.get().timeout(
        const Duration(seconds: 10),
      );
      final botId = user.id.toString();
      appendBotDebugLog(
        '[_pushToRemote] botId=$botId username=${user.username}',
      );
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Token not found');
      }
      appendBotDebugLog(
        '[_pushToRemote] token present, length=${token.length}',
      );

      await appManager.createOrUpdateApp(
        id: user.id,
        username: user.username,
        avatarHash: user.avatarHash,
        discriminator: user.discriminator.toString(),
        token: token,
      );

      // Push the full local config to Manager
      final mainClient = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: token,
        attemptSessionRestore: true,
      );
      if (mainClient != null) {
        appendBotDebugLog(
          '[_pushToRemote] Manager client ok, building canonical payload...',
        );

        // Safety: refuse to push if config is suspiciously small (prevents accidental wipes)
        final localCommands = await appManager.listAppCommands(botId);
        if (localCommands.isEmpty) {
          final localConfigSize = jsonEncode(
            await appManager.getApp(botId),
          ).length;
          appendBotDebugLog(
            '[_pushToRemote] No commands, configSize=$localConfigSize',
          );
          if (localConfigSize < 50) {
            appendBotDebugLog(
              '[_pushToRemote] REFUSING PUSH: config is empty or near-empty ($localConfigSize bytes)',
            );
            if (showSnack && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr.bot_home_push_refused_empty),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
            return;
          }
        }

        // Build canonical BotConfig payload — ensures workflows, scoped variables,
        // scheduled triggers, webhook endpoints, statuses, and lavalink config
        // are all properly serialized via BotConfig.toJson().  The previous manual
        // approach (localConfig + commands) was not routing through BotConfig,
        // causing workflows and other structured data to be lost or malformed on push.
        final payload = await buildRemotePayload(botId);
        final wfCount = (payload['workflows'] as List?)?.length ?? 0;
        final cmdCount = (payload['commands'] as List?)?.length ?? 0;
        appendBotDebugLog(
          '[_pushToRemote] Payload built: commands=$cmdCount workflows=$wfCount',
        );

        final pushed = await _pushPayloadToManager(
          client: mainClient,
          botId: botId,
          botName: user.username,
          payload: payload,
          notify: showSnack,
        );
        if (!pushed) {
          // Rien n'est parti : l'utilisateur a gardé sa version locale (ou le
          // serveur refuse même sur accord). On sort AVANT le message de succès —
          // annoncer un envoi qui n'a pas eu lieu est exactement le mensonge que
          // ce lot corrige.
          return;
        }
        appendBotDebugLog(
          '[_pushToRemote] Pushed canonical config to Manager for $botId',
        );
      }

      appendBotDebugLog('[_pushToRemote] DONE — success');
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_push_success)),
        );
      }
    } catch (e) {
      appendBotDebugLog('[_pushToRemote] FAILED: $e');
      if (showSnack && mounted) {
        // Refus de la garde anti-config-vide : la copie locale est restée
        // intacte et rien n'a été envoyé. Afficher le diagnostic brut ferait
        // croire à une panne ; on montre donc le message dédié, traduit.
        // Même raison pour le refus SERVEUR de sur-réduction : il ne doit ni
        // passer pour une panne, ni pour une erreur de l'application.
        final refusal =
            localizedBotPayloadRefusalMessage(context.tr, e) ??
            localizedBotConfigOvershrinkNothingSent(context.tr, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(refusal ?? e.toString()),
            backgroundColor: refusal == null ? null : AppTheme.error,
          ),
        );
      }
    } finally {
      _setState(() => _isPushingApp = false);
    }
  }

  /// Pousse [payload] vers le Manager et traite le refus de SUR-RÉDUCTION
  /// (`409 bot_config_overshrink`).
  ///
  /// Le manager refuse une configuration nettement plus petite que la
  /// configuration vivante : c'est une suppression MASSIVE, souvent volontaire.
  /// Il n'a RIEN appliqué et a restauré la version précédente ; la même poussée,
  /// rejouée avec le drapeau du contrat (`confirmOvershrink: true`), passe. C'est
  /// donc une QUESTION à poser, pas une panne : on demande, et on ne rejoue que
  /// sur accord.
  ///
  /// Rend `true` seulement quand la configuration est réellement partie (l'envoi
  /// rejoué après accord EST un envoi) ; `false` quand l'utilisateur a gardé sa
  /// version locale — l'appelant ne doit alors pas annoncer un succès.
  Future<bool> _pushPayloadToManager({
    required MainApiClient client,
    required String botId,
    required String botName,
    required Map<String, dynamic> payload,
    required bool notify,
  }) async {
    final outcome = await pushBotConfigToleratingOvershrink(
      push: (confirmOvershrink) => client
          .syncBot(
            botId,
            botName,
            payload,
            force: true,
            confirmOvershrink: confirmOvershrink,
          )
          .timeout(const Duration(seconds: 20)),
      askConfirmation: _askOvershrinkConfirmation,
    );

    if (outcome == BotConfigPushOutcome.sent) {
      return true;
    }

    appendBotDebugLog(
      '[_pushToRemote] Nothing sent ($outcome): local configuration kept for $botId',
    );
    if (notify) {
      _reportOvershrinkNothingSent();
    }
    return false;
  }

  /// Pose la question du refus de sur-réduction.
  ///
  /// Sans interface pour la poser (page quittée pendant la tentative), la réponse
  /// est NON : ne rien envoyer est la seule issue qui ne peut pas remplacer la
  /// configuration vivante du bot.
  Future<bool> _askOvershrinkConfirmation() async {
    if (!mounted) {
      return false;
    }
    return showBotConfigOvershrinkConfirmation(context);
  }

  /// Dit que la poussée n'a rien envoyé et n'a rien effacé.
  ///
  /// POURQUOI la phrase du dialogue sert aussi ici : elle dit exactement cela
  /// (rien n'est parti, la configuration locale est intacte, le serveur tourne
  /// toujours sur la précédente), et l'i18n de ce lot reste à quatre clés.
  void _reportOvershrinkNothingSent() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizedBotConfigOvershrinkConfirmation(context.tr).body),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  // ─── Pull from Cloud ────────────────────────────────────────────

  Future<void> _pullFromRemote({required bool showSnack}) async {
    if (_isPullingApp) return;

    _setState(() => _isPullingApp = true);
    try {
      appendBotDebugLog('[_pullFromRemote] START');
      final user = await widget.client.user.get().timeout(
        const Duration(seconds: 10),
      );
      final botId = user.id.toString();
      appendBotDebugLog(
        '[_pullFromRemote] botId=$botId username=${user.username}',
      );

      final mainClient = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: null,
        attemptSessionRestore: true,
      );
      if (mainClient == null) {
        throw Exception('Could not connect to Manager');
      }

      // 1. Fetch remote config
      appendBotDebugLog('[_pullFromRemote] Fetching remote config...');
      final remoteConfig = await mainClient.getBotConfig(botId);
      final remoteCommands = _extractCommandList(remoteConfig['commands']);
      appendBotDebugLog(
        '[_pullFromRemote] Remote has ${remoteCommands.length} commands',
      );

      // 2. Get local commands
      final localCommands = await appManager.listAppCommands(
        botId,
        forceRefresh: true,
      );
      appendBotDebugLog(
        '[_pullFromRemote] Local has ${localCommands.length} commands',
      );

      // 3. Compute merge diff
      final diff = _computeMergeDiff(localCommands, remoteCommands);
      appendBotDebugLog(
        '[_pullFromRemote] Diff: new=${diff.newCommands.length}, updated=${diff.updatedCommands.length}, unchanged=${diff.unchangedCount}, localOnly=${diff.localOnlyCount}',
      );

      // 4. Show confirmation dialog
      if (!mounted) return;
      final confirmed = await _showPullConfirmDialog(
        diff: diff,
        remoteTimestamp: _extractTimestamp(remoteConfig),
        localTimestamp: await _getLocalMaxTimestamp(botId),
      );
      if (!confirmed || !mounted) {
        appendBotDebugLog('[_pullFromRemote] User cancelled');
        return;
      }

      // 5. Apply merge
      appendBotDebugLog('[_pullFromRemote] Applying merge...');
      await _applyMerge(botId, diff, remoteCommands);
      await applyManagerWorkflowsToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remoteConfig,
      );

      // 6. Update app metadata
      final app = await appManager.getApp(botId);
      await appManager.createOrUpdateApp(
        id: user.id,
        username: user.username,
        avatarHash: user.avatarHash,
        discriminator: user.discriminator.toString(),
        token: (app['token'] ?? '').toString(),
      );

      appendBotDebugLog('[_pullFromRemote] DONE — success');
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_pull_success)),
        );
      }
    } catch (e) {
      appendBotDebugLog('[_pullFromRemote] FAILED: $e');
      if (showSnack && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _setState(() => _isPullingApp = false);
    }
  }

  // ─── Merge helpers ──────────────────────────────────────────────

  /// Extracts a normalized command list from the remote config payload.
  /// The remote format can be a List of Maps or a Map keyed by command ID.
  List<Map<String, dynamic>> _extractCommandList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    if (raw is Map) {
      return raw.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  String _extractTimestamp(Map<String, dynamic> config) {
    final commands = _extractCommandList(config['commands']);
    DateTime? latest;
    for (final cmd in commands) {
      final t = _parseTimestamp(cmd['updatedAt']);
      if (t != null && (latest == null || t.isAfter(latest))) {
        latest = t;
      }
    }
    if (latest != null) {
      return latest.toLocal().toString().substring(0, 19);
    }
    final configTs = _parseTimestamp(config['updatedAt'] ?? config['savedAt']);
    if (configTs != null) {
      return configTs.toLocal().toString().substring(0, 19);
    }
    return 'Unknown';
  }

  Future<String> _getLocalMaxTimestamp(String botId) async {
    final commands = await appManager.listAppCommands(
      botId,
      forceRefresh: true,
    );
    DateTime? latest;
    for (final cmd in commands) {
      final t = _parseTimestamp(cmd['updatedAt']);
      if (t != null && (latest == null || t.isAfter(latest))) {
        latest = t;
      }
    }
    if (latest != null) {
      return latest.toLocal().toString().substring(0, 19);
    }
    return 'Unknown';
  }

  _MergeDiff _computeMergeDiff(
    List<Map<String, dynamic>> localCommands,
    List<Map<String, dynamic>> remoteCommands,
  ) {
    final localById = <String, Map<String, dynamic>>{};
    for (final cmd in localCommands) {
      final id = (cmd['id'] ?? cmd['name'] ?? '').toString();
      if (id.isNotEmpty) localById[id] = cmd;
    }

    final newCommands = <Map<String, dynamic>>[];
    final updatedCommands = <Map<String, dynamic>>[];
    var unchangedCount = 0;

    for (final remoteCmd in remoteCommands) {
      final id = (remoteCmd['id'] ?? remoteCmd['name'] ?? '').toString();
      if (id.isEmpty) continue;

      final localCmd = localById[id];
      if (localCmd == null) {
        newCommands.add(remoteCmd);
      } else {
        final remoteUpdated = _parseTimestamp(remoteCmd['updatedAt']);
        final localUpdated = _parseTimestamp(localCmd['updatedAt']);
        if (remoteUpdated != null &&
            localUpdated != null &&
            remoteUpdated.isAfter(localUpdated)) {
          updatedCommands.add(remoteCmd);
        } else {
          unchangedCount++;
        }
        localById.remove(id);
      }
    }

    return _MergeDiff(
      newCommands: newCommands,
      updatedCommands: updatedCommands,
      unchangedCount: unchangedCount,
      localOnlyCount: localById.length,
    );
  }

  Future<void> _applyMerge(
    String botId,
    _MergeDiff diff,
    List<Map<String, dynamic>> remoteCommands,
  ) async {
    for (final cmd in diff.newCommands) {
      final cmdId = (cmd['id'] ?? cmd['name'] ?? '').toString();
      if (cmdId.isEmpty) continue;
      await appManager.saveAppCommand(botId, cmdId, cmd);
    }

    for (final cmd in diff.updatedCommands) {
      final cmdId = (cmd['id'] ?? cmd['name'] ?? '').toString();
      if (cmdId.isEmpty) continue;
      await appManager.saveAppCommand(botId, cmdId, cmd);
    }
  }

  // ─── Pull confirmation dialog ───────────────────────────────────

  Future<bool> _showPullConfirmDialog({
    required _MergeDiff diff,
    required String remoteTimestamp,
    required String localTimestamp,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;

    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cloud_download, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.tr.bot_home_pull,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp comparison
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildTimestampRow(
                      icon: Icons.cloud,
                      label: context.tr.bot_home_pull_dialog_remote,
                      timestamp: remoteTimestamp,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _buildTimestampRow(
                      icon: Icons.phone_android,
                      label: context.tr.bot_home_pull_dialog_local,
                      timestamp: localTimestamp,
                      color: colorScheme.secondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Change summary
              if (diff.hasChanges) ...[
                Text(
                  context.tr.bot_home_pull_dialog_changes,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (diff.newCommands.isNotEmpty)
                  _buildChangeRow(
                    Icons.add_circle_outline,
                    '${diff.newCommands.length} ${context.tr.bot_home_pull_dialog_new_commands}',
                    AppTheme.successAccent,
                  ),
                if (diff.updatedCommands.isNotEmpty)
                  _buildChangeRow(
                    Icons.update,
                    '${diff.updatedCommands.length} ${context.tr.bot_home_pull_dialog_updated_commands}',
                    AppTheme.warning,
                  ),
                _buildChangeRow(
                  Icons.check_circle_outline,
                  '${diff.unchangedCount} ${context.tr.bot_home_pull_dialog_unchanged}',
                  AppTheme.grey,
                ),
                _buildChangeRow(
                  Icons.phone_android,
                  '${diff.localOnlyCount} ${context.tr.bot_home_pull_dialog_local_only}',
                  colorScheme.secondary,
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr.bot_home_pull_dialog_up_to_date,
                          style: TextStyle(color: AppTheme.successAccent),
                        ),
                      ),
                    ],
                  ),
                ),

              // Warning about local-only commands
              if (diff.localOnlyCount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${diff.localOnlyCount} ${context.tr.bot_home_pull_dialog_local_preserved}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr.common_cancel),
          ),
          FilledButton.icon(
            onPressed: diff.hasChanges
                ? () => Navigator.of(ctx).pop(true)
                : null,
            icon: const Icon(Icons.cloud_download, size: 18),
            label: Text(
              diff.hasChanges
                  ? '${context.tr.bot_home_pull} (${diff.newCommands.length + diff.updatedCommands.length})'
                  : context.tr.bot_home_pull,
            ),
          ),
        ],
      ),
    ).then((v) => v ?? false);
  }

  Widget _buildTimestampRow({
    required IconData icon,
    required String label,
    required String timestamp,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
        const Spacer(),
        Flexible(
          child: Text(
            timestamp,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChangeRow(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
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
        final funding =
            (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
                .toString()
                .trim()
                .toLowerCase();
        final expires = _extractSessionExpiresAt(runtime);
        final balance = funding == 'premium'
            ? 0
            : (expires != null && funding == 'free'
                  ? _remainingMinutesUntil(expires)
                  : _extractFreeMinutes(
                      runtime['free_minutes_balance'] ??
                          runtime['freeMinutesBalance'],
                    ));

        if (mounted) {
          _setState(() {
            _fundingMode = funding;
            _sessionExpiresAt = funding == 'free' ? expires : null;
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

  // ─── Reconciliation (Launch & Live WebSocket) ───────────────────

  Future<void> _reconcileOnLaunch() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog(
      '[_reconcileOnLaunch] Starting startup reconciliation for botId=$botId',
    );

    final app = await appManager.getApp(botId);
    final token = (app['token'] ?? '').toString().trim();

    final mainClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: token.isNotEmpty ? token : null,
      attemptSessionRestore: true,
    );

    if (mainClient == null) {
      appendBotDebugLog(
        '[_reconcileOnLaunch] No MainApiClient available; skipping startup reconciliation.',
      );
      return;
    }

    await _performReconciliation(
      mainClient: mainClient,
      botId: botId,
      isLiveUpdate: false,
    );
  }

  Future<void> _reconcileLiveUpdate() async {
    if (_isReconciling || _isConflictDialogOpen || !mounted) return;

    final now = DateTime.now();
    if (_lastReconcileCheckAt != null &&
        now.difference(_lastReconcileCheckAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastReconcileCheckAt = now;

    final botId = widget.client.user.id.toString();
    appendBotDebugLog(
      '[_reconcileLiveUpdate] Checking live sync for botId=$botId',
    );

    final app = await appManager.getApp(botId);
    final token = (app['token'] ?? '').toString().trim();

    final mainClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: token.isNotEmpty ? token : null,
      attemptSessionRestore: true,
    );

    if (mainClient == null) return;

    await _performReconciliation(
      mainClient: mainClient,
      botId: botId,
      isLiveUpdate: true,
    );
  }

  Future<void> _performReconciliation({
    required MainApiClient mainClient,
    required String botId,
    required bool isLiveUpdate,
  }) async {
    if (_isReconciling) return;
    _isReconciling = true;

    try {
      final result = await BotReconciliationService.checkSyncStatus(
        botId: botId,
        client: mainClient,
        appManager: appManager,
      );

      appendBotDebugLog(
        '[_performReconciliation] Status: ${result.status} (isLiveUpdate=$isLiveUpdate)',
      );

      if (!mounted) return;

      switch (result.status) {
        case BotSyncStatus.inSync:
        case BotSyncStatus.noRemoteConfig:
        case BotSyncStatus.error:
          break;

        case BotSyncStatus.cloudNewer:
          if (result.remoteConfig != null) {
            appendBotDebugLog(
              '[_performReconciliation] Auto-applying Cloud updates to local...',
            );
            await BotReconciliationService.applyCloudToLocal(
              botId: botId,
              remoteConfig: result.remoteConfig!,
              appManager: appManager,
            );
            await _reloadAppLocally();
            if (mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isLiveUpdate
                              ? _uiCopy(
                                  fr: 'Mise à jour Cloud appliquée avec succès',
                                  en: 'Cloud update applied successfully',
                                )
                              : _uiCopy(
                                  fr: 'Synchronisé avec la version Cloud',
                                  en: 'Synced with Cloud version',
                                ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.success,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
          break;

        case BotSyncStatus.localNewer:
          // Local has newer edits. It will be pushed by auto-reload batcher or user action.
          break;

        case BotSyncStatus.conflict:
          if (result.remoteConfig != null && !_isConflictDialogOpen) {
            _isConflictDialogOpen = true;
            try {
              await _showReconciliationConflictDialog(
                botId: botId,
                client: mainClient,
                result: result,
              );
            } finally {
              _isConflictDialogOpen = false;
            }
          }
          break;
      }
    } catch (e) {
      appendBotDebugLog('[_performReconciliation] Failed: $e');
    } finally {
      _isReconciling = false;
    }
  }

  Future<void> _reloadAppLocally() async {
    final botId = widget.client.user.id.toString();
    final app = await appManager.getApp(botId);
    final capabilities = await getBotRuntimeCapabilities(botId);
    if (!mounted) return;
    _setState(() {
      _appName = (app['username'] ?? app['name'] ?? _appName).toString();
      avatar = (app['avatar'] ?? avatar).toString();
      _runtimeCapabilities = capabilities;
    });
    await appManager.refreshApps();
  }

  Future<void> _showReconciliationConflictDialog({
    required String botId,
    required MainApiClient client,
    required BotReconciliationCheckResult result,
  }) async {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;

    final remoteTsStr = result.remoteTimestamp != null
        ? result.remoteTimestamp!.toLocal().toString().substring(0, 19)
        : 'Unknown';
    final localTsStr = result.localTimestamp != null
        ? result.localTimestamp!.toLocal().toString().substring(0, 19)
        : 'Unknown';

    final diff = result.diff;
    final newCount = diff?.newCommands.length ?? 0;
    final updatedCount = diff?.updatedCommands.length ?? 0;
    final localOnlyCount = diff?.localOnlyCount ?? 0;

    var isProcessing = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sync_problem_rounded,
                      color: AppTheme.warning,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uiCopy(
                        fr: 'Conflit de synchronisation',
                        en: 'Sync Conflict Detected',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _uiCopy(
                          fr: 'Des modifications divergentes existent entre cette session locale et la version Cloud (Mobile). Choisissez comment résoudre ce conflit :',
                          en: 'Divergent changes exist between this local session and Cloud (Mobile). Choose how to resolve this conflict:',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Summary box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTimestampRow(
                              icon: Icons.cloud_outlined,
                              label: _uiCopy(
                                fr: 'Version Cloud (Mobile)',
                                en: 'Cloud Version (Mobile)',
                              ),
                              timestamp: remoteTsStr,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            _buildTimestampRow(
                              icon: Icons.computer_outlined,
                              label: _uiCopy(
                                fr: 'Version Locale (Desktop)',
                                en: 'Local Version (Desktop)',
                              ),
                              timestamp: localTsStr,
                              color: colorScheme.secondary,
                            ),
                            if (newCount > 0 ||
                                updatedCount > 0 ||
                                localOnlyCount > 0) ...[
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (newCount > 0)
                                    Text(
                                      '+$newCount ${_uiCopy(fr: "nouveaux", en: "new")}',
                                      style: const TextStyle(
                                        color: AppTheme.successAccent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (updatedCount > 0)
                                    Text(
                                      '$updatedCount ${_uiCopy(fr: "modifiés", en: "updated")}',
                                      style: const TextStyle(
                                        color: AppTheme.warning,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (localOnlyCount > 0)
                                    Text(
                                      '$localOnlyCount ${_uiCopy(fr: "locaux", en: "local only")}',
                                      style: TextStyle(
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (isProcessing)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Column(
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  _uiCopy(
                                    fr: 'Synchronisation en cours...',
                                    en: 'Sync in progress...',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Option 1: Smart Merge
                        _buildReconciliationOptionCard(
                          icon: Icons.merge_type_rounded,
                          title: _uiCopy(
                            fr: 'Fusionner intelligemment (Recommandé)',
                            en: 'Smart Merge (Recommended)',
                          ),
                          description: _uiCopy(
                            fr: 'Conserve tous les ajouts des deux côtés et retient la commande la plus récente lors d\'un doublon.',
                            en: 'Combines additions from both sides and keeps the newest command in case of duplicates.',
                          ),
                          isRecommended: true,
                          colorScheme: colorScheme,
                          onTap: () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              await BotReconciliationService.smartMerge(
                                botId: botId,
                                remoteConfig: result.remoteConfig!,
                                client: client,
                                appManager: appManager,
                                botName: _appName,
                              );
                              await _reloadAppLocally();
                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _uiCopy(
                                        fr: 'Fusion intelligente effectuée et synchronisée sur le Cloud',
                                        en: 'Smart merge completed and synced to Cloud',
                                      ),
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (mounted) {
                                // Les trois issues touchent le Cloud : la garde
                                // anti-config-vide peut les refuser. Le refus a
                                // son message (rien n'est parti, rien n'a été
                                // effacé en local) ; sinon, message habituel.
                                final refusal =
                                    localizedBotPayloadRefusalMessage(
                                      context.tr,
                                      e,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(refusal ?? 'Erreur: $e'),
                                    backgroundColor: refusal == null
                                        ? null
                                        : AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 2: Cloud Version
                        _buildReconciliationOptionCard(
                          icon: Icons.cloud_download_outlined,
                          title: _uiCopy(
                            fr: 'Prendre la version Cloud (Mobile)',
                            en: 'Take Cloud Version (Mobile)',
                          ),
                          description: _uiCopy(
                            fr: 'Écrase les modifications locales non envoyées par la version Cloud.',
                            en: 'Replaces local un-pushed changes with the Cloud version.',
                          ),
                          isRecommended: false,
                          colorScheme: colorScheme,
                          onTap: () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              await BotReconciliationService.applyCloudToLocal(
                                botId: botId,
                                remoteConfig: result.remoteConfig!,
                                appManager: appManager,
                              );
                              await _reloadAppLocally();
                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _uiCopy(
                                        fr: 'Version Cloud appliquée avec succès',
                                        en: 'Cloud version applied successfully',
                                      ),
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (mounted) {
                                // Les trois issues touchent le Cloud : la garde
                                // anti-config-vide peut les refuser. Le refus a
                                // son message (rien n'est parti, rien n'a été
                                // effacé en local) ; sinon, message habituel.
                                final refusal =
                                    localizedBotPayloadRefusalMessage(
                                      context.tr,
                                      e,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(refusal ?? 'Erreur: $e'),
                                    backgroundColor: refusal == null
                                        ? null
                                        : AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 3: Keep Local
                        _buildReconciliationOptionCard(
                          icon: Icons.computer_rounded,
                          title: _uiCopy(
                            fr: 'Conserver la version Locale (Desktop)',
                            en: 'Keep Local Version (Desktop)',
                          ),
                          description: _uiCopy(
                            fr: 'Conserve vos modifications locales et les envoie pour mettre à jour le Cloud.',
                            en: 'Keeps your local modifications and pushes them to update Cloud.',
                          ),
                          isRecommended: false,
                          colorScheme: colorScheme,
                          onTap: () async {
                            setDialogState(() => isProcessing = true);
                            try {
                              await BotReconciliationService.keepLocalAndPushToCloud(
                                botId: botId,
                                client: client,
                                botName: _appName,
                                appManager: appManager,
                              );
                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _uiCopy(
                                        fr: 'Version locale conservée et mise à jour sur le Cloud',
                                        en: 'Local version kept and synced to Cloud',
                                      ),
                                    ),
                                    backgroundColor: AppTheme.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isProcessing = false);
                              if (mounted) {
                                // Les trois issues touchent le Cloud : la garde
                                // anti-config-vide peut les refuser. Le refus a
                                // son message (rien n'est parti, rien n'a été
                                // effacé en local) ; sinon, message habituel.
                                final refusal =
                                    localizedBotPayloadRefusalMessage(
                                      context.tr,
                                      e,
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(refusal ?? 'Erreur: $e'),
                                    backgroundColor: refusal == null
                                        ? null
                                        : AppTheme.error,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (!isProcessing)
                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(context.tr.common_cancel),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReconciliationOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isRecommended,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRecommended
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isRecommended
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isRecommended ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (isRecommended ? colorScheme.primary : colorScheme.surface)
                        .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isRecommended
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRecommended
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isRecommended
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Merge diff data class ────────────────────────────────────────

class _MergeDiff {
  final List<Map<String, dynamic>> newCommands;
  final List<Map<String, dynamic>> updatedCommands;
  final int unchangedCount;
  final int localOnlyCount;

  const _MergeDiff({
    required this.newCommands,
    required this.updatedCommands,
    required this.unchangedCount,
    required this.localOnlyCount,
  });

  bool get hasChanges => newCommands.isNotEmpty || updatedCommands.isNotEmpty;
}
