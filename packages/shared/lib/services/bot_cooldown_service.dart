import 'dart:async';
import 'dart:convert';

import '../bot/bot_data_store.dart';
import '../engine/execution_budget.dart';

/// Cooldown state is isolated by bot, command and the official scope.
enum BotCooldownType { normal, server, global }

class BotCooldownKey {
  const BotCooldownKey({
    required this.botId,
    required this.commandId,
    required this.type,
    this.userId,
    this.guildId,
  });
  final String botId, commandId;
  final BotCooldownType type;
  final String? userId, guildId;
  String get contextId => jsonEncode([
    botId,
    type.name,
    commandId,
    if (type != BotCooldownType.server) userId,
    if (type != BotCooldownType.global) guildId,
  ]);
}

abstract interface class BotCooldownService {
  /// Atomically returns zero and starts a cooldown, or returns the existing
  /// remaining duration without extending it.
  Future<Duration> acquire(
    BotCooldownKey key,
    Duration duration, {
    required CommandExecutionBudget budget,
  });
  Future<Duration> remaining(
    BotCooldownKey key, {
    required CommandExecutionBudget budget,
  });
}

/// Uses a reserved internal scope, keeping runtime keys out of user variables.
/// Claims are serialized across services sharing this store in this isolate.
/// Multi-process callers require a store with transactional compare-and-set;
/// BotDataStore does not currently expose that capability.
class StoredBotCooldownService implements BotCooldownService {
  StoredBotCooldownService(this.store, {int Function()? nowMilliseconds})
    : nowMilliseconds = nowMilliseconds ?? _now;
  final BotDataStore store;
  final int Function() nowMilliseconds;
  static int _now() => DateTime.now().millisecondsSinceEpoch;
  static final _locks = Expando<Map<String, Future<void>>>();
  static const storageScope = '_bdfdCooldown';
  static const expirationKey = 'expiration';

  Future<T> _locked<T>(
    BotCooldownKey key,
    CommandExecutionBudget budget,
    Future<T> Function() action,
  ) async {
    final locks = _locks[store] ??= <String, Future<void>>{};
    final lockKey = jsonEncode([key.botId, key.contextId]);
    final previous = locks[lockKey] ?? Future<void>.value();
    final completion = Completer<void>();
    locks[lockKey] = completion.future;
    try {
      await budget.run(() => previous);
      budget.check();
      return await action();
    } finally {
      // Waiters must still follow the preceding holder if this waiter timed out.
      previous.then((_) {
        completion.complete();
        if (identical(locks[lockKey], completion.future)) locks.remove(lockKey);
      });
    }
  }

  Future<Duration> _remaining(
    BotCooldownKey key,
    CommandExecutionBudget budget,
  ) async {
    final value = await budget.run(
      () => store.getScopedVariable(
        key.botId,
        storageScope,
        key.contextId,
        expirationKey,
      ),
    );
    budget.check();
    if (value == null) return Duration.zero;
    final expiration = value is int ? value : int.tryParse(value.toString());
    if (expiration == null) throw StateError('Malformed stored cooldown.');
    final milliseconds = expiration - nowMilliseconds();
    return milliseconds > 0
        ? Duration(milliseconds: milliseconds)
        : Duration.zero;
  }

  @override
  Future<Duration> acquire(
    BotCooldownKey key,
    Duration duration, {
    required CommandExecutionBudget budget,
  }) => _locked(key, budget, () async {
    final remaining = await _remaining(key, budget);
    if (remaining > Duration.zero) return remaining;
    budget.check();
    await budget.run(
      () => store.setScopedVariable(
        key.botId,
        storageScope,
        key.contextId,
        expirationKey,
        nowMilliseconds() + (duration.inMicroseconds / 1000).ceil(),
      ),
    );
    budget.check();
    return Duration.zero;
  });

  @override
  Future<Duration> remaining(
    BotCooldownKey key, {
    required CommandExecutionBudget budget,
  }) => _locked(key, budget, () => _remaining(key, budget));
}

/// Injectable sleep transport; sandbox implementations can record/advance time.
abstract interface class BotDelayService {
  Future<void> delay(
    Duration duration, {
    required CommandExecutionBudget budget,
  });
}

class RuntimeBotDelayService implements BotDelayService {
  const RuntimeBotDelayService();
  @override
  Future<void> delay(
    Duration duration, {
    required CommandExecutionBudget budget,
  }) => budget.run(() => Future<void>.delayed(duration));
}
