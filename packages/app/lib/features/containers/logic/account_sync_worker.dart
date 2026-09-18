import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';

/// Periodic background sync worker that runs at launch and every 30 minutes.
/// Refreshes:
/// 1. Subscription & Account entitlement status
/// 2. Turnkey bot templates catalog
/// 3. Per-bot ad minutes from Manager
class AccountSyncWorker {
  AccountSyncWorker._();

  static Timer? _timer;
  static bool _isSyncing = false;
  static const Duration syncInterval = Duration(minutes: 30);

  static void start() {
    _timer?.cancel();
    // Run an initial sync
    unawaited(syncNow());
    // Schedule periodic sync every 30 minutes
    _timer = Timer.periodic(syncInterval, (_) {
      unawaited(syncNow());
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      final isConfigured = config.isConfigured;
      final hasSession = session != null && !session.isExpired;

      MainApiClient? client;
      if (isConfigured && hasSession) {
        client = MainApiClient(
          baseUrl: config.baseUrl,
          accessToken: session.accessToken,
        );
      }

      // 1. Sync subscription & account entitlement
      await SubscriptionService.resolveEffectivePremiumStatus(
        client: client,
        forceRefresh: true,
      );

      // 2. Refresh Turnkey template catalog
      if (isConfigured) {
        try {
          final publicClient = client ?? MainApiClient(baseUrl: config.baseUrl);
          final templatesData = await publicClient.getTurnkeyTemplates();
          if (templatesData.isNotEmpty) {
            final templates = templatesData
                .map(HostedAppTemplate.fromJson)
                .toList();
            setCachedTurnkeyTemplates(templates);
          }
        } catch (e) {
          debugPrint('[AccountSyncWorker] Turnkey catalog sync skipped: $e');
        }
      }

      // 3. If signed in, sync per-bot ad minutes / runtime balances
      if (client != null) {
        try {
          final apps = await AppManager().getAllApps();
          final botIds = apps
              .whereType<Map>()
              .map((raw) => (raw['id'] ?? '').toString().trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false);

          for (final botId in botIds) {
            try {
              final runtime = await client.getBotRuntime(botId);
              final rawMinutes =
                  runtime['free_minutes_balance'] ??
                  runtime['freeMinutesBalance'];
              final minutes = (rawMinutes as num?)?.toInt() ?? 0;
              final currentApp = await AppManager().getApp(botId);
              if (currentApp.isNotEmpty) {
                final updated = Map<String, dynamic>.from(currentApp);
                updated['free_minutes'] = minutes;
                await AppManager().saveApp(botId, updated);
              }
            } catch (_) {}
          }
        } catch (e) {
          debugPrint('[AccountSyncWorker] Per-bot ad minutes sync skipped: $e');
        }
      }
    } catch (e) {
      debugPrint('[AccountSyncWorker] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }
}
