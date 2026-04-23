import 'dart:async';
import 'dart:io';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/routes/app.dart';
import 'package:bot_creator/routes/app/bot_logs.dart';
import 'package:bot_creator/utils/analytics.dart';
import 'package:bot_creator/utils/bot.dart';
import 'package:bot_creator/utils/bot_payload_builder.dart';
import 'package:bot_creator/utils/discord_rpc_service.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/ad_reward_service.dart';
import 'package:bot_creator/utils/ads_placement_policy.dart';
import 'package:bot_creator/utils/ad_consent_service.dart';
import 'package:bot_creator/utils/global.dart';
import 'package:bot_creator/utils/app_theme.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/remote_runtime.dart';
import 'package:bot_creator/utils/subscription_service.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/widgets/native_ad_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nyxx/nyxx.dart' hide Locale, Logger;
import 'dart:developer' as developer;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// IDs des bots en cours d'exécution.
  Set<String> _runningBotIds = <String>{};
  RemoteRuntimeSource _runtimeSource = RemoteRuntimeSource.local;
  String? _runtimeDetailLabel;

  /// ID du bot en cours d'action (démarrage/arrêt/ajout de temps).
  String? _botIdInAction;

  /// Un AnimationController par carte (clé = bot id) pour l'effet pulse.
  final Map<String, AnimationController> _pulseControllers = {};
  Map<String, int> _freeMinutesByBotId = <String, int>{};

  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  bool get _supportsManagerRuntime => !kIsWeb;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppAnalytics.logScreenView(screenName: 'HomePage', screenClass: 'HomePage');
    AppAnalytics.logEvent(name: 'home_page_opened');
    _initRunningState();
    unawaited(syncAllBotsFromManager(silent: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final ctrl in _pulseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncAllBotsFromManager(silent: true);
    }
  }

  // ── Initialisation de l'état running ───────────────────────────────────────

  Future<void> _initRunningState() async {
    final runningIds = <String>{};
    final remoteClient = await _resolveGlobalMainApiClient();
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 30),
      postTimeout: const Duration(seconds: 90),
    );

    unawaited(
      SubscriptionService.resolveEffectivePremiumStatus(
        client: remoteClient,
        forceRefresh: true,
      ),
    );

    if (remoteClient != null) {
      try {
        final status = await remoteClient.getStatus();
        for (final bot in status.bots) {
          if (bot.isRunning) {
            runningIds.add(bot.botId);
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _runningBotIds = runningIds;
        _runtimeSource = remoteRuntime.source;
        _runtimeDetailLabel = remoteRuntime.detailLabel;
      });
      _syncPulse(runningIds);
      await _syncDiscordRpcPresence(runningIds);
      unawaited(_refreshBotRuntimeBalances());
      return;
    }

    if (remoteRuntime.blocksLocalFallback) {
      if (!mounted) return;
      setState(() {
        _runningBotIds = runningIds;
        _runtimeSource = remoteRuntime.source;
        _runtimeDetailLabel = remoteRuntime.detailLabel;
      });
      _syncPulse(runningIds);
      await _syncDiscordRpcPresence(runningIds);
      unawaited(_refreshBotRuntimeBalances());
      return;
    }

    if (_supportsForegroundTask) {
      try {
        final running = await FlutterForegroundTask.isRunningService;
        if (running) {
          final configuredIds = await getConfiguredMobileBotIds();
          if (configuredIds.isNotEmpty) {
            runningIds.addAll(configuredIds);
            for (final botId in configuredIds) {
              addMobileRunningBotId(botId);
            }
          } else {
            final fallbackId =
                mobileRunningBotId ??
                await FlutterForegroundTask.getData<String>(
                  key: 'running_bot_id',
                );
            if (fallbackId != null && fallbackId.isNotEmpty) {
              runningIds.add(fallbackId);
              addMobileRunningBotId(fallbackId);
            }
          }
        }
      } on MissingPluginException {
        // Plateforme non supportée.
      }
    } else {
      runningIds.addAll(desktopRunningBotIds);
    }
    if (!mounted) return;
    setState(() {
      _runningBotIds = runningIds;
      _runtimeSource = RemoteRuntimeSource.local;
      _runtimeDetailLabel = null;
    });
    _syncPulse(runningIds);
    await _syncDiscordRpcPresence(runningIds);
    unawaited(_refreshBotRuntimeBalances());
  }

  int _extractFreeMinutes(dynamic raw) {
    if (raw == null) {
      return 0;
    }
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw.toString()) ?? 0;
  }

  bool _hasFreeRuntimeAvailable(Map<String, dynamic> runtime, int balance) {
    final fundingMode =
        (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final sessionActiveRaw =
        runtime['session_active'] ?? runtime['sessionActive'];
    final sessionActive =
        sessionActiveRaw == true ||
        sessionActiveRaw?.toString().toLowerCase() == 'true';
    return balance > 0 || fundingMode == 'free' || sessionActive;
  }

  Future<void> _refreshBotRuntimeBalances({Iterable<String>? botIds}) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      if (mounted && _freeMinutesByBotId.isNotEmpty) {
        setState(() => _freeMinutesByBotId = <String, int>{});
      }
      return;
    }

    final ids = <String>{...?(botIds?.where((id) => id.trim().isNotEmpty))};
    if (ids.isEmpty) {
      final names = await _loadBotNamesById();
      ids.addAll(names.keys.where((id) => id.trim().isNotEmpty));
    }
    if (ids.isEmpty) {
      return;
    }

    final updated = <String, int>{..._freeMinutesByBotId};
    for (final botId in ids) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final minutes = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );
        updated[botId] = minutes;
      } catch (_) {
        // Best-effort refresh only.
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _freeMinutesByBotId = updated;
    });
  }

  Future<void> syncAllBotsFromManager({bool silent = false}) async {
    final remoteClient = await _resolveGlobalMainApiClient();
    if (remoteClient == null) {
      return;
    }

    try {
      final bots = await remoteClient.listBots();
      for (final bot in bots) {
        try {
          final botId = bot['bot_id']?.toString() ?? '';
          if (botId.isEmpty) continue;

          final botName = bot['bot_name']?.toString() ?? 'Unnamed Bot';
          final config = bot['config'] as Map<String, dynamic>? ?? {};

          // Prefer manager token if available, otherwise use local token
          String token = bot['bot_token']?.toString() ?? '';
          if (token.isEmpty) {
            final existing = await appManager.getApp(botId);
            token = (existing['token'] ?? '').toString();
          }

          await appManager.createOrUpdateApp(
            id: Snowflake.parse(botId),
            username: botName,
            avatarHash:
                bot['avatar_hash']?.toString() ?? bot['avatar']?.toString(),
            discriminator: bot['discriminator']?.toString(),
            token: token,
            intents: (config['intents'] as Map?)?.cast<String, bool>(),
            prefix: config['prefix']?.toString(),
          );
        } catch (e) {
          developer.log('Failed to sync bot ${bot['bot_id']}: $e');
        }
      }

      if (mounted) {
        await _initRunningState();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    }
  }

  // ── Gestion des animations pulse ───────────────────────────────────────────

  AnimationController _getOrCreatePulseController(String botId) {
    return _pulseControllers.putIfAbsent(
      botId,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _syncPulse(Set<String> runningIds) {
    for (final entry in _pulseControllers.entries) {
      if (runningIds.contains(entry.key)) {
        if (!entry.value.isAnimating) {
          entry.value.repeat(reverse: true);
        }
      } else {
        entry.value
          ..stop()
          ..value = 0;
      }
    }
  }

  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  String? _runtimeBadgeLabel() {
    return switch (_runtimeSource) {
      RemoteRuntimeSource.manager => _uiCopy(
        fr: 'Serveurs Bot Creator',
        en: 'Bot Creator servers',
      ),
      RemoteRuntimeSource.runner =>
        (_runtimeDetailLabel?.trim().isNotEmpty ?? false)
            ? context.tr.runner_source_label(_runtimeDetailLabel!)
            : _uiCopy(fr: 'Runner', en: 'Runner'),
      RemoteRuntimeSource.local => null,
    };
  }

  Future<Map<String, String>> _loadBotNamesById() async {
    final apps = await appManager.getAllApps();
    final namesById = <String, String>{};
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp);
      final botId = (app['id'] ?? '').toString();
      if (botId.isEmpty) {
        continue;
      }
      namesById[botId] = (app['name'] ?? botId).toString();
    }
    return namesById;
  }

  Future<void> _syncDiscordRpcPresence(
    Set<String> runningBotIds, {
    String? preferredBotId,
    String? preferredBotName,
  }) async {
    try {
      final botNamesById = await _loadBotNamesById();
      await DiscordRpcService.instance.syncBotRuntimeState(
        runningBotIds: runningBotIds,
        botNamesById: botNamesById,
        runtimeSource: _runtimeSource,
        preferredBotId: preferredBotId,
        preferredBotName: preferredBotName,
        activeSourceLabel: _runtimeDetailLabel,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to sync Discord RPC presence: $error',
        name: 'HomePage',
        stackTrace: stackTrace,
      );
    }
  }

  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 90),
  }) async {
    return resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  Future<DiscordApplicationOwnerMetadata?>
  _resolveDiscordOwnerMetadataForBotStart({
    required String botId,
    required String? token,
  }) async {
    final trimmedToken = token?.trim() ?? '';
    if (trimmedToken.isEmpty) {
      appendBotDebugLog(
        'Unable to resolve Discord owner for $botId: bot token is missing.',
      );
      return null;
    }

    try {
      final metadata = await getDiscordApplicationOwnerMetadata(trimmedToken);
      if (metadata == null || metadata.ownerCandidateIds.isEmpty) {
        appendBotDebugLog(
          'Discord owner lookup via /applications/@me returned empty for $botId.',
        );
        return null;
      }

      appendBotDebugLog(
        'Discord owner metadata resolved via /applications/@me for $botId: ${metadata.candidatesLabel}',
      );
      return metadata;
    } catch (error) {
      appendBotDebugLog(
        'Discord owner lookup via /applications/@me failed for $botId: $error',
      );
      return null;
    }
  }

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
    String? preferredOwnerId,
    Iterable<String> acceptableOwnerIds = const <String>[],
  }) async {
    final trimmedToken = botToken?.trim() ?? '';
    if (trimmedToken.isEmpty) {
      appendBotDebugLog(
        'Manager session restore skipped for $botId: bot token is missing.',
      );
      return false;
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      if (!config.isConfigured) {
        appendBotDebugLog(
          'Manager session restore skipped for $botId: manager base URL is not configured.',
        );
        return false;
      }

      final client = MainApiClient(baseUrl: config.baseUrl);
      final normalizedPreferredOwner = preferredOwnerId?.trim() ?? '';
      final session = await client.exchangeDiscordBotToken(
        botToken: trimmedToken,
        preferredOwnerId:
            normalizedPreferredOwner.isEmpty ? null : normalizedPreferredOwner,
      );

      final normalizedSessionOwner = session.userId?.trim() ?? '';
      final normalizedAcceptableOwners =
          acceptableOwnerIds
              .map((ownerId) => ownerId.trim())
              .where((ownerId) => ownerId.isNotEmpty)
              .toSet();
      if (normalizedAcceptableOwners.isNotEmpty &&
          normalizedSessionOwner.isNotEmpty &&
          !normalizedAcceptableOwners.contains(normalizedSessionOwner)) {
        appendBotDebugLog(
          'Manager session restore rejected for $botId: owner mismatch expected=${normalizedAcceptableOwners.join(',')} actual=$normalizedSessionOwner.',
        );
        return false;
      }

      await MainApiSettingsStore.saveSession(session);
      appendBotDebugLog(
        "Manager session restored from bot token for $botId (owner=${normalizedSessionOwner.isEmpty ? 'unknown' : normalizedSessionOwner}).",
      );
      return true;
    } catch (error) {
      appendBotDebugLog('Manager session restore failed for $botId: $error');
      return false;
    }
  }

  Future<MainApiClient?> _resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    var runtime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    var resolvedToken = botToken?.trim() ?? '';
    if (resolvedToken.isEmpty) {
      final app = await appManager.getApp(botId);
      resolvedToken = (app['token'] ?? '').toString().trim();
    }
    final ownerMetadata =
        resolvedToken.isEmpty
            ? null
            : await _resolveDiscordOwnerMetadataForBotStart(
              botId: botId,
              token: resolvedToken,
            );
    final ownerCandidates =
        ownerMetadata?.ownerCandidateIds ?? const <String>[];
    final session = await MainApiSettingsStore.loadSession();
    final sessionOwnerId = session?.userId?.trim() ?? '';
    final directClient = runtime.client;
    final hasMatchingManagerSession =
        directClient is MainApiClient &&
        session != null &&
        !session.isExpired &&
        (ownerCandidates.isEmpty ||
            ownerMetadata!.matchesOwnerId(sessionOwnerId));
    if (hasMatchingManagerSession) {
      return directClient;
    }

    if (!attemptSessionRestore || resolvedToken.isEmpty) {
      return ownerCandidates.isEmpty && directClient is MainApiClient
          ? directClient
          : null;
    }

    if (ownerCandidates.isNotEmpty &&
        sessionOwnerId.isNotEmpty &&
        !ownerMetadata!.matchesOwnerId(sessionOwnerId)) {
      appendBotDebugLog(
        'Manager session owner mismatch for $botId: expected one of ${ownerCandidates.join(',')} actual=$sessionOwnerId. Restoring from bot token.',
      );
    }

    final restored = await _restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: resolvedToken,
      preferredOwnerId: ownerMetadata?.resolveOwnerId(
        preferredOwnerId: sessionOwnerId,
      ),
      acceptableOwnerIds: ownerCandidates,
    );
    if (!restored) {
      return null;
    }

    runtime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final refreshedClient = runtime.client;
    return refreshedClient is MainApiClient ? refreshedClient : null;
  }

  Future<MainApiClient?> _resolveGlobalMainApiClient({
    bool attemptRestore = true,
  }) async {
    var runtime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 15),
      postTimeout: const Duration(seconds: 30),
    );

    if (runtime.source == RemoteRuntimeSource.manager &&
        runtime.client == null &&
        attemptRestore) {
      final apps = await appManager.getAllApps();
      for (final rawApp in apps) {
        if (rawApp is! Map) continue;
        final botId = (rawApp['id'] ?? '').toString();
        final token = (rawApp['token'] ?? '').toString();
        if (botId.isNotEmpty && token.isNotEmpty) {
          final client = await _resolveMainApiClientForBot(
            botId: botId,
            botToken: token,
            attemptSessionRestore: true,
          );
          if (client != null) {
            return client;
          }
        }
      }
    }

    final client = runtime.client;
    return client is MainApiClient ? client : null;
  }

  // ── Démarrage / Arrêt du bot ───────────────────────────────────────────────

  Future<void> _toggleBot({
    required String botId,
    required String botName,
  }) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    try {
      final isRunning = _runningBotIds.contains(botId);

      if (isRunning) {
        final shouldStop = await AppTheme.showConfirmDialog(
          context,
          title: _uiCopy(fr: 'Arrêter le bot ?', en: 'Stop this bot?'),
          content: _uiCopy(
            fr:
                'Si une session gratuite est en cours, le temps restant peut être perdu. Continuer ?',
            en:
                'If a free runtime session is active, remaining time may be lost. Continue?',
          ),
          confirmLabel: _uiCopy(fr: 'Arrêter', en: 'Stop'),
          icon: Icons.warning_amber_rounded,
        );
        if (!shouldStop || !mounted) {
          return;
        }
      }

      var runtime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );

      if (!isRunning && _runningBotIds.length >= 5) {
        throw Exception(
          context.tr.error_with_details('Maximum active bots reached (5)'),
        );
      }

      // ── Fetch + validate token before anything else (only when starting) ──
      String? token;
      if (!isRunning) {
        var usingRunner = runtime.client != null || runtime.blocksLocalFallback;

        if (runtime.blocksLocalFallback) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();
          final ownerMetadata = await _resolveDiscordOwnerMetadataForBotStart(
            botId: botId,
            token: token,
          );
          final session = await MainApiSettingsStore.loadSession();
          final preferredOwnerId = ownerMetadata?.resolveOwnerId(
            preferredOwnerId: session?.userId,
          );

          final sessionRestored = await _restoreMainApiSessionWithBotToken(
            botId: botId,
            botToken: token,
            preferredOwnerId: preferredOwnerId,
            acceptableOwnerIds:
                ownerMetadata?.ownerCandidateIds ?? const <String>[],
          );
          if (sessionRestored) {
            runtime = await _resolveRemoteRuntime(
              getTimeout: const Duration(seconds: 30),
              postTimeout: const Duration(seconds: 90),
            );
            usingRunner = runtime.client != null || runtime.blocksLocalFallback;
          }

          if (!sessionRestored || runtime.blocksLocalFallback) {
            final baseMessage =
                runtime.unavailableReason ??
                _uiCopy(
                  fr:
                      'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en:
                      'Sign in to Bot Creator in Settings before starting this bot.',
                );

            final message =
                ownerMetadata == null || ownerMetadata.ownerCandidateIds.isEmpty
                    ? baseMessage
                    : '$baseMessage\nDiscord owners: ${ownerMetadata.candidatesLabel}';
            throw Exception(message);
          }
        }

        if (!usingRunner) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();
          if (token == null || token.trim().isEmpty) {
            throw Exception(context.tr.home_token_missing(botName));
          }

          // Token check against Discord before showing ads
          try {
            await getDiscordUser(token);
          } catch (_) {
            if (!mounted) return;
            final proceed = await AppTheme.showConfirmDialog(
              context,
              title: context.tr.bot_home_token_invalid_title,
              content: context.tr.bot_home_token_invalid_content,
              confirmLabel: context.tr.bot_home_start,
            );
            if (!proceed || !mounted) return;
          }
        }

        final adUnlocked = await _maybeOfferRewardedAd(
          botId: botId,
          botToken: token,
        );
        if (!adUnlocked) {
          return;
        }
        if (!mounted) return;
      }

      // ── Runner API (API only) ─────────────────────────────────────────────
      runtime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );
      final client = runtime.client;
      if (client != null) {
        try {
          if (isRunning) {
            appendBotLog(
              'Bot stop requested',
              botId: botId,
              source: runtime.source,
            );
            final stopResult = await client.stopBot(botId);

            // Show warning if free time was lost
            if (stopResult['free_time_lost'] == true && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    stopResult['warning'] as String? ??
                        context.tr.error_with_details(
                          'Accumulated free runtime was discarded',
                        ),
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
            }

            endBotLogSession(botId: botId, source: runtime.source);
            unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds}..remove(botId);
              });
            }
            setBotRuntimeActive(_runningBotIds.isNotEmpty);
          } else {
            startBotLogSession(botId: botId, source: runtime.source);
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: runtime.source,
            );
            final payload = await buildBotPayload(botId);
            if (client is MainApiClient) {
              final app = await appManager.getApp(botId);
              final botToken = (app['token'] ?? '').toString().trim();
              if (botToken.isNotEmpty) {
                try {
                  await client.saveDiscordBotSnapshot(
                    botToken: botToken,
                    config: payload,
                  );
                } catch (_) {
                  // Best-effort only: do not block start if save route fails.
                }
              }
            }
            await client.syncBot(botId, botName, payload);
            if (client is MainApiClient) {
              await startManagerBotWithCreditRetry(
                client: client,
                botId: botId,
                botName: botName,
              );
            } else {
              await client.startBot(botId, botName: botName);
            }
            setBotRuntimeActive(true);
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds, botId};
                _runtimeSource = runtime.source;
                _runtimeDetailLabel = runtime.detailLabel;
              });
            }
          }
        } catch (error) {
          if (client is MainApiClient) {
            throw Exception(await describeManagerRuntimeFailure(client, error));
          }
          rethrow;
        }
        _syncPulse(_runningBotIds);
        await _syncDiscordRpcPresence(
          _runningBotIds,
          preferredBotId: _runningBotIds.contains(botId) ? botId : null,
          preferredBotName: _runningBotIds.contains(botId) ? botName : null,
        );
        return;
      }

      // ── Local engine ──────────────────────────────────────────────────────
      // Token already fetched and validated above; re-read if needed (stop path)
      if (token == null) {
        final app = await appManager.getApp(botId);
        token = app['token']?.toString();
      }
      if (token == null || token.trim().isEmpty) {
        throw Exception(context.tr.home_token_missing(botName));
      }

      if (!isRunning) {
        clearBotBaselineRss();
        startBotLogSession(botId: botId);
        appendBotLog('Bot start requested', botId: botId);
      }

      if (_supportsForegroundTask) {
        // ── Mobile (Android / iOS) ─────────────────────────────────────────
        if (isRunning) {
          appendBotLog('Bot stop requested', botId: botId);
          await stopMobileBotSession(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
          setBotRuntimeActive(_runningBotIds.isNotEmpty);
        } else {
          // Vérifier / demander la permission de notification.
          try {
            var perm =
                await FlutterForegroundTask.checkNotificationPermission();
            if (perm != NotificationPermission.granted) {
              await FlutterForegroundTask.requestNotificationPermission();
            }
          } on MissingPluginException {
            // Continuer sans vérification sur les plateformes non supportées.
          }

          await initForegroundService(eventIntervalMs: 5000);
          await startMobileBotSession(botId: botId, token: token);

          try {
            final running = await FlutterForegroundTask.isRunningService;
            if (!running) {
              throw Exception(context.tr.home_foreground_service_not_started);
            }
          } on MissingPluginException {
            // Accepter sur les plateformes de dev.
          }

          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
        }
      } else {
        // ── Desktop (Linux / Windows / macOS) ─────────────────────────────
        if (isRunning) {
          appendBotLog(
            context.tr.home_log_desktop_stop_requested,
            botId: botId,
          );
          await stopDesktopBot(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          setBotRuntimeActive(
            isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
          );
          clearBotBaselineRss();
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
        } else {
          await startDesktopBot(token);
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
        }
      }

      _syncPulse(_runningBotIds);
      await _syncDiscordRpcPresence(
        _runningBotIds,
        preferredBotId: _runningBotIds.contains(botId) ? botId : null,
        preferredBotName: _runningBotIds.contains(botId) ? botName : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.error_with_details(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _botIdInAction = null);
    }
  }

  Future<int?> _fetchMainApiRuntimeBalance(String botId) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return null;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      return _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _waitForMainApiRewardCredit({
    required String botId,
    required int? previousBalance,
  }) async {
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
          setState(() {
            _freeMinutesByBotId = <String, int>{
              ..._freeMinutesByBotId,
              botId: balance,
            };
          });
        }

        if (previousBalance == null ||
            balance > previousBalance ||
            _hasFreeRuntimeAvailable(runtime, balance)) {
          return true;
        }
      } catch (_) {
        // Keep polling until timeout.
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<bool> _ensureMainApiBotSnapshotForAd(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) {
      return false;
    }

    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    if (remoteClient == null) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager client unavailable before snapshot sync.',
      );
      return false;
    }

    final payload = await buildBotPayload(botId);
    try {
      await remoteClient.saveDiscordBotSnapshot(
        botToken: botToken,
        config: payload,
      );
      return true;
    } catch (error) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager snapshot sync failed: $error',
      );
      return false;
    }
  }

  Future<AdRewardSsvContext?> _buildMainApiAdSsvContext(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) {
      return null;
    }

    final session = await MainApiSettingsStore.loadSession();
    final ownerIdFromSession = (session?.userId ?? '').trim();
    final ownerMetadata = await getDiscordApplicationOwnerMetadata(botToken);
    final ownerIdFromDiscord = ownerMetadata?.resolveOwnerId() ?? '';

    if (ownerMetadata != null &&
        ownerMetadata.matchesOwnerId(ownerIdFromSession)) {
      if (ownerIdFromSession.isNotEmpty &&
          ownerIdFromSession != ownerIdFromDiscord) {
        appendBotDebugLog(
          'Owner reconciliation for $botId: keeping manager session owner $ownerIdFromSession because it is a valid Discord team owner/member.',
        );
      }
    } else if (ownerIdFromSession.isNotEmpty &&
        ownerIdFromDiscord.isNotEmpty &&
        ownerIdFromSession != ownerIdFromDiscord) {
      appendBotDebugLog(
        'Owner mismatch for $botId: using discord application owner $ownerIdFromDiscord instead of manager session owner $ownerIdFromSession for ad mapping.',
      );
    }

    final ownerId =
        ownerMetadata?.resolveOwnerId(preferredOwnerId: ownerIdFromSession) ??
        ownerIdFromSession;
    if (ownerId.isEmpty) {
      return null;
    }

    return AdRewardSsvContext(
      userId: ownerId,
      customData:
          Uri(
            queryParameters: <String, String>{
              'owner_id': ownerId,
              'bot_id': botId,
              'placement': 'admob_rewarded',
              if (ownerIdFromDiscord.isNotEmpty)
                'discord_owner_id': ownerIdFromDiscord,
            },
          ).query,
    );
  }

  Future<void> _addHostingTime(String botId) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    try {
      final app = await appManager.getApp(botId);
      final botToken = (app['token'] ?? '').toString().trim();
      final name = (app['name'] ?? '').toString().trim();

      final rewarded = await _maybeOfferRewardedAd(
        botId: botId,
        botToken: botToken.isNotEmpty ? botToken : null,
      );
      if (rewarded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Time added for $name')),
        );
        unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
      }
    } finally {
      if (mounted) {
        setState(() => _botIdInAction = null);
      }
    }
  }

  Future<bool> _isMainApiPremiumUser({
    required String botId,
    String? botToken,
  }) async {
    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    return SubscriptionService.canSkipRewardedAds(
      client: remoteClient is MainApiClient ? remoteClient : null,
      forceRefresh: true,
      allowStoredManagerSession: false,
    );
  }

  Future<bool> _maybeOfferRewardedAd({
    required String botId,
    String? botToken,
  }) async {
    if (!_supportsForegroundTask || !mounted) {
      return true;
    }

    if (await _isMainApiPremiumUser(botId: botId, botToken: botToken)) {
      return true;
    }

    if (!AdRewardService.hasReadyRewardedAd) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                'A reward ad is required before starting this bot.',
              ),
            ),
          ),
        );
      }
      return false;
    }

    final snapshotReady = await _ensureMainApiBotSnapshotForAd(botId);
    if (!snapshotReady) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to sync bot snapshot (/applications/@me).',
      );
      return false;
    }

    final ssvContext = await _buildMainApiAdSsvContext(botId);
    if (ssvContext == null) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to resolve Discord owner via /applications/@me.',
      );
      return false;
    }

    if (!await AdRewardService.shouldOfferRewardedAd(
      checkPremiumCapability: false,
    )) {
      return false;
    }

    final consentGranted = await _ensureAdsConsent();
    if (!consentGranted || !mounted) {
      return false;
    }

    final previousBalance = await _fetchMainApiRuntimeBalance(botId);

    var rewardEarned = false;
    final adShown = await AdRewardService.showRewardedAd(
      ssvContext: ssvContext,
      onRewardEarned: () async {
        rewardEarned = true;
      },
    );
    if (!adShown || !rewardEarned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                'You must complete the rewarded ad to start this bot.',
              ),
            ),
          ),
        );
      }
      return false;
    }

    unawaited(() async {
      final rewardCredited = await _waitForMainApiRewardCredit(
        botId: botId,
        previousBalance: previousBalance,
      );
      if (!rewardCredited) {
        appendBotDebugLog(
          'Reward credit still pending for $botId after ad completion; start flow continues with automatic manager retry.',
        );
        return;
      }
      await _refreshBotRuntimeBalances(botIds: <String>[botId]);
    }());

    await SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true);
    if (!mounted) {
      return false;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.rewarded_start_thanks)));
    return true;
  }

  Future<bool> _ensureAdsConsent() async {
    final consentGranted = await AdConsentService.ensureCanRequestAds();
    if (!consentGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.ads_consent_refused_info)),
      );
    }
    return consentGranted;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double horizontalPadding;

        // Responsive grid based on screen width
        if (width < 420) {
          // Small phone - single column
          crossAxisCount = 1;
          horizontalPadding = 12.0;
        } else if (width < 600) {
          // Mobile - 2 columns
          crossAxisCount = 2;
          horizontalPadding = 12.0;
        } else if (width >= 1500) {
          // Extra large desktop - 5 columns
          crossAxisCount = 5;
          horizontalPadding = 24.0;
        } else if (width >= 1200) {
          // Large desktop - 4 columns
          crossAxisCount = 4;
          horizontalPadding = 24.0;
        } else if (width >= 900) {
          // Tablet - 3 columns
          crossAxisCount = 3;
          horizontalPadding = 20.0;
        } else if (width >= 760) {
          // Medium tablet - 3 columns
          crossAxisCount = 3;
          horizontalPadding = 16.0;
        } else {
          // Small tablet - 2 columns
          crossAxisCount = 2;
          horizontalPadding = 16.0;
        }

        final cardWidth =
            (width - (horizontalPadding * 2) - ((crossAxisCount - 1) * 12)) /
            crossAxisCount;

        return Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: StreamBuilder<List<dynamic>>(
            stream: appManager.getAppStream(),
            initialData: const <dynamic>[],
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                developer.log(
                  'Error loading data: ${snapshot.error}',
                  name: 'HomePage',
                );
                return Center(child: Text(context.tr.app_loading_error));
              }

              final apps = snapshot.data;
              if (apps == null || apps.isEmpty) {
                return const _EmptyStateWithSupport();
              }

              return Column(
                children: [
                  if (AdsPlacementPolicy.isPlacementEnabled(
                        NativeAdPlacement.homeBots,
                      ) &&
                      apps.length >= AdsPlacementPolicy.listInterval)
                    const NativeAdSlot(
                      placement: NativeAdPlacement.homeBots,
                      height: 118,
                      margin: EdgeInsets.only(bottom: 12),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => syncAllBotsFromManager(silent: false),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          bottom: 80,
                          left: 14,
                          right: 14,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: apps.map((app) {
                              final name =
                                  app['name']?.toString() ??
                                  context.tr.home_unknown_app;
                              final id = app['id']?.toString() ?? '';
                              final avatar = app['avatar']?.toString();
                              final guildCount = switch (app['guild_count']) {
                                final int value => value,
                                final String s => int.tryParse(s) ?? 0,
                                _ => 0,
                              };

                              final isRunning = _runningBotIds.contains(id);

                              const runtimeToggleAllowed = true;

                              final canToggle =
                                  runtimeToggleAllowed &&
                                  _botIdInAction == null;

                              final pulseCtrl = _getOrCreatePulseController(id);

                              return SizedBox(
                                width: cardWidth,
                                child: _BotCard(
                                  name: name,
                                  id: id,
                                  avatar: avatar,
                                  guildCount: guildCount,
                                  compact: width < 760,
                                  isRunning: isRunning,
                                  canToggle: canToggle,
                                  isTogglingThisBot: _botIdInAction == id,
                                  runtimeBadgeLabel:
                                      isRunning ? _runtimeBadgeLabel() : null,
                                  freeMinutes: _freeMinutesByBotId[id],
                                  pulseController: pulseCtrl,
                                  onManage:
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => AppEditPage(
                                                appName: name,
                                                id: int.tryParse(id) ?? 0,
                                              ),
                                        ),
                                      ).then((_) => _initRunningState()),
                                  onToggle:
                                      () => _toggleBot(
                                        botId: id,
                                        botName: name,
                                      ),
                                  onAddTime: () => _addHostingTime(id),
                                  onLogs:
                                      isRunning
                                          ? () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      BotLogsPage(botId: id),
                                            ),
                                          )
                                          : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Widget carte ─────────────────────────────────────────────────────────────

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.name,
    required this.id,
    required this.avatar,
    required this.guildCount,
    required this.compact,
    required this.isRunning,
    required this.canToggle,
    required this.isTogglingThisBot,
    required this.pulseController,
    required this.onManage,
    required this.onToggle,
    required this.onAddTime,
    required this.onLogs,
    this.runtimeBadgeLabel,
    this.freeMinutes,
  });

  final String name;
  final String id;
  final String? avatar;
  final int? guildCount;
  final bool compact;
  final bool isRunning;
  final bool canToggle;
  final bool isTogglingThisBot;
  final String? runtimeBadgeLabel;
  final int? freeMinutes;
  final AnimationController pulseController;
  final VoidCallback onManage;
  final VoidCallback onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onLogs;

  static const _onlineGradient = AppTheme.botCardOnlineGradient;
  static const _offlineGradient = AppTheme.botCardOfflineGradient;

  String _serverCountLabel() {
    final count = guildCount ?? 0;
    final key = count > 1 ? 'home_server_count_other' : 'home_server_count_one';
    return AppStrings.tr(key, params: {'count': count.toString()});
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 24.0 : 34.0;
    final avatarFallbackSize = compact ? 48.0 : 68.0;
    final titleFontSize = compact ? 13.0 : 16.0;
    final buttonVerticalPadding = compact ? 4.0 : 10.0;

    final gradientColors = isRunning ? _onlineGradient : _offlineGradient;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      elevation: isRunning ? 8 : 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10.0 : 14.0),
          child: Column(
            children: [
              // ── Status badge pill ──────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: AnimatedBuilder(
                  animation: pulseController,
                  builder: (_, _) {
                    final opacity =
                        isRunning ? 0.5 + 0.5 * pulseController.value : 1.0;
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isRunning
                                        ? AppTheme.successAccent
                                        : AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isRunning
                                  ? context.tr.home_status_online
                                  : context.tr.home_status_offline,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Avatar + Identity ──────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: compact ? 8 : 12),
                    // Avatar with glow ring when running
                    Container(
                      decoration:
                          isRunning
                              ? BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.successAccent.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              )
                              : null,
                      child:
                          avatar != null && avatar!.isNotEmpty
                              ? CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    avatar!,
                                    width: avatarRadius * 2,
                                    height: avatarRadius * 2,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, _, _) => Icon(
                                          Icons.smart_toy_rounded,
                                          size: avatarFallbackSize * 0.6,
                                          color: Colors.white70,
                                        ),
                                  ),
                                ),
                              )
                              : CircleAvatar(
                                radius: avatarRadius,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                child: Icon(
                                  Icons.smart_toy_rounded,
                                  size: avatarFallbackSize * 0.6,
                                  color: Colors.white70,
                                ),
                              ),
                    ),

                    SizedBox(height: compact ? 4 : 10),

                    // Name
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Server count + runner label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _serverCountLabel(),
                          style: TextStyle(
                            fontSize: compact ? 10.5 : 11.0,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),

                    // Runner badge (hidden in compact to save space)
                    if (runtimeBadgeLabel != null && !compact) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.dns_outlined,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                runtimeBadgeLabel!,
                                style: TextStyle(
                                  fontSize: compact ? 9.0 : 9.5,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (freeMinutes != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.tr('home_hosting_time_left', params: {'minutes': freeMinutes!.toString()}),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: compact ? 10 : 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                ],
              ),

              // ── Action buttons ─────────────────────────────────────────────
              SizedBox(height: compact ? 2 : 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canToggle ? onToggle : null,
                  icon:
                      isTogglingThisBot
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 16,
                          ),
                  label: Text(
                    isRunning
                        ? context.tr.home_stop
                        : (SubscriptionService.isSubscribed
                            ? AppStrings.tr('home_start_premium')
                            : AppStrings.tr('home_start_ads')),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isRunning
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.1,
                    ),
                    disabledForegroundColor: Colors.white38,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: EdgeInsets.symmetric(
                      vertical: buttonVerticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),

              if (isRunning && !SubscriptionService.isSubscribed) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canToggle ? onAddTime : null,
                    icon:
                        isTogglingThisBot
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.more_time_rounded, size: 16),
                    label: Text(AppStrings.tr('home_add_time')),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: EdgeInsets.symmetric(
                        vertical: buttonVerticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: compact ? 4 : 6),

              // Manage + Logs row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onManage,
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: Text(context.tr.home_manage),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onLogs,
                    icon: const Icon(Icons.article_outlined, size: 18),
                    tooltip: context.tr.home_logs_tooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor:
                          onLogs != null
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state avec CTA support ──────────────────────────────────────────

class _EmptyStateWithSupport extends StatelessWidget {
  const _EmptyStateWithSupport();

  static const _discordUrl = 'https://discord.gg/gyEGNBUZdA';
  static const _discordColor = AppTheme.discord;

  Future<void> _openDiscord() async {
    final uri = Uri.parse(_discordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.app_no_apps,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              context.tr.home_empty_support_hint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openDiscord,
              icon: const Icon(Icons.forum_rounded, size: 18),
              label: Text(context.tr.home_empty_support_btn),
              style: FilledButton.styleFrom(
                backgroundColor: _discordColor,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
