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

  Future<void> _pushToRemote({required bool showSnack}) async {
    if (_isPushingApp) {
      return;
    }

    _setState(() => _isPushingApp = true);
    try {
      appendBotDebugLog('[_pushToRemote] START');
      final user = await widget.client.user.get().timeout(const Duration(seconds: 10));
      final botId = user.id.toString();
      appendBotDebugLog('[_pushToRemote] botId=$botId username=${user.username}');
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Token not found');
      }
      appendBotDebugLog('[_pushToRemote] token present, length=${token.length}');

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
        appendBotDebugLog('[_pushToRemote] Manager client ok, collecting local config...');
        final localConfig = await appManager.getApp(botId);
        final localCommands = await appManager.listAppCommands(botId);

        // Safety: refuse to push if config is suspiciously small (prevents accidental wipes)
        final localConfigSize = jsonEncode(localConfig).length;
        appendBotDebugLog('[_pushToRemote] localCommands=${localCommands.length} configSize=$localConfigSize');
        if (localCommands.isEmpty && localConfigSize < 50) {
          appendBotDebugLog('[_pushToRemote] REFUSING PUSH: config is empty or near-empty ($localConfigSize bytes)');
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

        final pushData = Map<String, dynamic>.from(localConfig);
        pushData['commands'] = localCommands;
        await mainClient.syncBot(
          botId,
          user.username,
          pushData,
          force: true,
        ).timeout(const Duration(seconds: 20));
        appendBotDebugLog('[_pushToRemote] Pushed local config to Manager for $botId');
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _setState(() => _isPushingApp = false);
    }
  }

  // ─── Pull from Cloud ────────────────────────────────────────────

  Future<void> _pullFromRemote({required bool showSnack}) async {
    if (_isPullingApp) return;

    _setState(() => _isPullingApp = true);
    try {
      appendBotDebugLog('[_pullFromRemote] START');
      final user = await widget.client.user.get().timeout(const Duration(seconds: 10));
      final botId = user.id.toString();
      appendBotDebugLog('[_pullFromRemote] botId=$botId username=${user.username}');

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
      appendBotDebugLog('[_pullFromRemote] Remote has ${remoteCommands.length} commands');

      // 2. Get local commands
      final localCommands = await appManager.listAppCommands(botId, forceRefresh: true);
      appendBotDebugLog('[_pullFromRemote] Local has ${localCommands.length} commands');

      // 3. Compute merge diff
      final diff = _computeMergeDiff(localCommands, remoteCommands);
      appendBotDebugLog('[_pullFromRemote] Diff: new=${diff.newCommands.length}, updated=${diff.updatedCommands.length}, unchanged=${diff.unchangedCount}, localOnly=${diff.localOnlyCount}');

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
    final commands = await appManager.listAppCommands(botId, forceRefresh: true);
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
        if (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated)) {
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                      Icon(Icons.info_outline, size: 16, color: colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${diff.localOnlyCount} ${context.tr.bot_home_pull_dialog_local_preserved}',
                          style: TextStyle(fontSize: 12, color: colorScheme.secondary),
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
            onPressed: diff.hasChanges ? () => Navigator.of(ctx).pop(true) : null,
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
        Text(timestamp, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
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
