import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounces edits and serializes full synchronizations for each bot.
/// Edits during a running sync are coalesced into one subsequent sync so the
/// latest configuration is sent without overlapping the previous request.
class BotSyncBatcher {
  final Map<String, Timer> _timers = {};
  final Map<String, DateTime> _firstRequests = {};
  final Set<String> _running = {};
  final Map<String, Future<void> Function(String)> _pending = {};

  /// Vrai tant qu'une synchronisation de [botId] est planifiée, en cours ou en
  /// attente derrière celle qui tourne : le cloud est alors PLUS ANCIEN que le
  /// local, et l'appliquer par-dessus écraserait l'édition qui part.
  bool isBusy(String botId) =>
      _timers.containsKey(botId) ||
      _running.contains(botId) ||
      _pending.containsKey(botId);

  void requestSync(
    String botId,
    Future<void> Function(String) task, {
    bool immediate = false,
  }) {
    _timers.remove(botId)?.cancel();
    if (_running.contains(botId)) {
      _firstRequests.remove(botId);
      _pending[botId] = task;
      return;
    }
    final now = DateTime.now();
    final first = _firstRequests.putIfAbsent(botId, () => now);
    if (immediate || now.difference(first) >= const Duration(seconds: 15)) {
      _performSync(botId, task);
    } else {
      _timers[botId] = Timer(const Duration(seconds: 3), () {
        _performSync(botId, task);
      });
    }
  }

  void _performSync(String botId, Future<void> Function(String) task) {
    _timers.remove(botId)?.cancel();
    _firstRequests.remove(botId);
    if (!_running.add(botId)) {
      _pending[botId] = task;
      return;
    }
    unawaited(_run(botId, task));
  }

  Future<void> _run(String botId, Future<void> Function(String) task) async {
    try {
      await task(botId);
    } catch (error) {
      debugPrint('[AutoReload] Batched sync failed for $botId: $error');
    } finally {
      _running.remove(botId);
      final pending = _pending.remove(botId);
      if (pending != null) {
        _performSync(botId, pending);
      }
    }
  }
}
