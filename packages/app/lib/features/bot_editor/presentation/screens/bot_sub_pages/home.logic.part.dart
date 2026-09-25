part of 'home.dart';

extension _AppHomePageLogic on _AppHomePageState {
  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  // Une seule règle dans toute l'application (voir `run_platform.dart`).
  bool get _supportsManagerRuntime => supportsManagerRuntime;

  /// Source d'exécution VIVANTE du bot affiché par cette page.
  ///
  /// `null` hors poste de travail : le mobile garde son affichage historique
  /// (`_botLaunched` + hébergement), décision produit verrouillée par des tests.
  /// Sur un poste, la décision vient de `bot_run_source.dart` — la MÊME brique
  /// que la carte d'accueil, donc les deux écrans ne peuvent plus annoncer deux
  /// sources différentes pour le même bot.
  BotRunOrigin? get _runOrigin => desktopBotRunOrigin(
    botId: widget.client.user.id.toString(),
    serverReportsRunning: _botLaunched,
  );

  Future<bool> _requestPermissions() async {
    if (!_supportsForegroundTask) {
      return true;
    }

    try {
      var notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
        notificationPermission =
            await FlutterForegroundTask.checkNotificationPermission();
      }

      if (notificationPermission != NotificationPermission.granted) {
        return false;
      }

      if (Platform.isAndroid) {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      }
    } on MissingPluginException {
      return true;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        debugPrint('Foreground permission channel unavailable; skipping.');
        return true;
      }
      rethrow;
    }

    return true;
  }

  Future<void> _initService() async {
    if (!_supportsForegroundTask) {
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> _init() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog('[AppHome._init] Starting init for botId=$botId.');
    final app = await appManager.getApp(botId);
    var isRunning = false;

    final token = (app['token'] ?? '').toString().trim();
    if (token.isNotEmpty) {
      unawaited(() async {
        try {
          final meta = await getDiscordApplicationOwnerMetadata(token);
          if (mounted) {
            _setState(() {
              _ownerMetadata = meta;
            });
          }
        } catch (_) {}
      }());
    }

    var remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 5),
      postTimeout: const Duration(seconds: 10),
    );
    var remoteClient = remoteRuntime.client;

    if (remoteClient == null &&
        remoteRuntime.source == RemoteRuntimeSource.manager) {
      final token = (app['token'] ?? '').toString().trim();
      if (token.isNotEmpty) {
        appendBotDebugLog(
          '[AppHome._init] Manager client missing; restoring session directly via bot token.',
        );
        final restored = await _ownerSyncHelper
            .restoreMainApiSessionWithBotToken(botId: botId, botToken: token)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                appendBotDebugLog(
                  '[AppHome._init] Session restore timed out (8s); continuing without manager.',
                );
                return false;
              },
            );
        if (restored) {
          appendBotDebugLog(
            '[AppHome._init] Manager session restored successfully via bot token.',
          );
          remoteRuntime = await _resolveRemoteRuntime(
            getTimeout: const Duration(seconds: 5),
            postTimeout: const Duration(seconds: 10),
          );
          remoteClient = remoteRuntime.client;
        } else {
          appendBotDebugLog('[AppHome._init] Manager session restore failed.');
        }
      }
    }

    appendBotDebugLog(
      '[AppHome._init] Runtime resolved: source=${remoteRuntime.source}, hasClient=${remoteClient != null}, blocksLocalFallback=${remoteRuntime.blocksLocalFallback}, detail=${remoteRuntime.detailLabel ?? 'none'}.',
    );
    unawaited(
      SubscriptionService.resolveEffectivePremiumStatus(
        client: remoteClient is MainApiClient ? remoteClient : null,
        forceRefresh: true,
      ),
    );
    if (remoteClient != null) {
      try {
        appendBotDebugLog(
          '[AppHome._init] Fetching per-bot status via ${remoteClient.runtimeType} for botId=$botId.',
        );
        final status = await remoteClient.getStatus(botId: botId);
        appendBotDebugLog(
          '[AppHome._init] Status fetched: running=${status.running}, activeBotId=${status.activeBotId ?? 'none'}, botEntries=${status.bots.length}.',
        );
        isRunning = status.isBotRunning(botId);
        appendBotDebugLog(
          '[AppHome._init] Bot running evaluation from remote status: botId=$botId, isRunning=$isRunning.',
        );
      } catch (_) {
        appendBotDebugLog(
          '[AppHome._init] Failed to fetch remote status; defaulting isRunning=false.',
        );
        isRunning = false;
      }
    } else if (remoteRuntime.blocksLocalFallback) {
      appendBotDebugLog(
        '[AppHome._init] Local fallback blocked and no remote client available; forcing isRunning=false.',
      );
      isRunning = false;
    } else {
      if (_supportsForegroundTask) {
        try {
          appendBotDebugLog(
            '[AppHome._init] Using foreground-task fallback for botId=$botId.',
          );
          final readyIds = await getReadyMobileBotIds();
          appendBotDebugLog(
            '[AppHome._init] Ready mobile ids=${readyIds.join(',')}.',
          );
          if (readyIds.contains(botId) || isMobileBotRunning(botId)) {
            isRunning = true;
            appendBotDebugLog(
              '[AppHome._init] Marked running from readyIds/isMobileBotRunning.',
            );
          } else {
            final configuredIds = await getConfiguredMobileBotIds();
            final serviceRunning = await FlutterForegroundTask.isRunningService;
            isRunning = serviceRunning && configuredIds.contains(botId);
            appendBotDebugLog(
              '[AppHome._init] Foreground fallback computed isRunning=$isRunning (serviceRunning=$serviceRunning, configuredIds=${configuredIds.join(',')}).',
            );
          }
        } on MissingPluginException {
          appendBotDebugLog(
            '[AppHome._init] Foreground plugin unavailable; forcing isRunning=false.',
          );
          isRunning = false;
        } on PlatformException catch (error) {
          if (_isDeadChannelError(error)) {
            appendBotDebugLog(
              '[AppHome._init] Dead channel during foreground lookup; forcing isRunning=false. error=$error',
            );
            isRunning = false;
          } else {
            rethrow;
          }
        } catch (_) {
          appendBotDebugLog(
            '[AppHome._init] Unexpected foreground fallback error; forcing isRunning=false.',
          );
          isRunning = false;
        }
      } else {
        isRunning = isDesktopBotRunningId(botId);
        appendBotDebugLog(
          '[AppHome._init] Desktop fallback isRunning=$isRunning for botId=$botId.',
        );
      }
    }

    appendBotDebugLog(
      '[AppHome._init] Final running decision for botId=$botId isRunning=$isRunning.',
    );

    await AppAnalytics.logScreenView(
      screenName: "AppHomePage",
      screenClass: "AppHomePage",
      parameters: {
        "app_name": app["name"] ?? "unknown",
        "app_id": botId,
        "is_running": isRunning ? "true" : "false",
      },
    );
    final capabilities = await getBotRuntimeCapabilities(botId);
    if (mounted) {
      var resolvedName = (app["name"] ?? '').toString();
      final idStr = botId.trim();
      final needsNameResolution =
          resolvedName.isEmpty ||
          resolvedName == idStr ||
          resolvedName == 'Unnamed Bot' ||
          (resolvedName.length >= 15 && BigInt.tryParse(resolvedName) != null);
      if (needsNameResolution) {
        unawaited(() async {
          try {
            final user = await widget.client.user.get().timeout(
              const Duration(seconds: 5),
            );
            final fetchedUsername = user.username.trim();
            if (fetchedUsername.isNotEmpty && mounted) {
              _setState(() {
                _appName = fetchedUsername;
              });
              if (token.isNotEmpty) {
                await appManager.createOrUpdateApp(
                  id: widget.client.user.id,
                  username: fetchedUsername,
                  token: token,
                );
              }
            }
          } catch (_) {}
        }());
      }
      _setState(() {
        _botLaunched = isRunning;
        _botStarting = false;
        // `app["name"]` is dynamic and a legacy/hand-edited entry can be null;
        // `_appName` is a non-nullable String, so a bare assignment threw
        // "type 'Null' is not a subtype of type 'String'" (issue 51fdaaea).
        _appName = resolvedName;
        avatar = app["avatar"] ?? "";
        _runtimeCapabilities = capabilities;
      });
    }
    appendBotDebugLog(
      '[AppHome._init] State updated: botLaunched=$_botLaunched, appName=$_appName.',
    );

    unawaited(_refreshFreeRuntimeBalance());
    unawaited(_reconcileOnLaunch());
    appendBotDebugLog('[AppHome._init] Init completed for botId=$botId.');
  }

  bool _isDeadChannelError(Object error) {
    if (error is! PlatformException) return false;
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();
    return code.contains('channel') ||
        message.contains('dead channel') ||
        message.contains('unable to establish connection on channel') ||
        details.contains('dead channel') ||
        details.contains('unable to establish connection on channel');
  }

  Future<void> _toggleBotLaunchState() async {
    if (_botStarting) return;
    // The same entry point stops a running bot: the catch has to know whether
    // this attempt was a start to report an outcome.
    final wasStarting = !_botLaunched;
    _setState(() {
      _botStarting = true;
    });
    bool keepsStartingStateActive = false;
    try {
      final app = await appManager.getApp(widget.client.user.id.toString());
      final token = app["token"]?.toString();
      if (token == null || token.trim().isEmpty) {
        throw Exception("Token not found");
      }

      final botId = widget.client.user.id.toString();

      var remoteRuntime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 25),
      );

      if (!_botLaunched && remoteRuntime.blocksLocalFallback) {
        final sessionRestored = await _restoreMainApiSessionWithBotToken(
          botId: botId,
          botToken: token,
        );

        if (sessionRestored) {
          remoteRuntime = await _resolveRemoteRuntime(
            getTimeout: const Duration(seconds: 30),
            postTimeout: const Duration(seconds: 25),
          );
        }

        if (remoteRuntime.blocksLocalFallback) {
          final message =
              remoteRuntime.unavailableReason ??
              context.tr.bot_start_sign_in_required;

          throw Exception(message);
        }
      }

      if (!_botLaunched) {
        if (remoteRuntime.client == null) {
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
        if (SubscriptionService.isSubscribed) {
          await SubscriptionService.syncStatusWithBackend(force: true);
        }

        final adUnlocked = await _maybeOfferRewardedAd(
          botId: botId,
          botToken: token,
        );
        if (!adUnlocked) {
          return;
        }
      }

      final remoteClient = remoteRuntime.client;

      if (remoteClient != null) {
        try {
          if (_botLaunched) {
            appendBotLog(
              'Bot stop requested',
              botId: botId,
              source: remoteRuntime.source,
            );
            await remoteClient.stopBot(botId);
            endBotLogSession(botId: botId, source: remoteRuntime.source);
            setBotRuntimeActive(false);
            _setState(() => _botLaunched = false);
          } else {
            startBotLogSession(botId: botId, source: remoteRuntime.source);
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: remoteRuntime.source,
            );
            if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
              await validateJsBotPayloadOrThrow(botId);
            }
            final payload = await buildRemotePayload(botId);
            if (remoteClient is MainApiClient) {
              final botToken = token.trim();
              if (botToken.isNotEmpty) {
                try {
                  await remoteClient.saveDiscordBotSnapshot(
                    botId: botId,
                    botToken: botToken,
                    config: payload,
                  );
                } catch (_) {}
              }
              // La poussée de DÉMARRAGE passe par la MÊME orchestration que la
              // poussée canonique : un `409 bot_config_overshrink` — suppression
              // massive, peut-être volontaire — n'est pas une panne mais une
              // QUESTION, et on la POSE au lieu d'afficher un simple message qui
              // obligerait l'utilisateur à relancer son geste pour confirmer.
              // Sans accord, rien n'est envoyé, le local reste intact, et le
              // démarrage s'arrête ici : lancer le bot sur la configuration que
              // le serveur vient de refuser serait un mensonge sur ce qui a été
              // appliqué.
              final pushOutcome = await pushStartBotConfigToleratingOvershrink(
                client: remoteClient,
                botId: botId,
                botName: _appName,
                config: payload,
                askConfirmation: _askOvershrinkConfirmation,
              );
              if (pushOutcome != BotConfigPushOutcome.sent) {
                _reportOvershrinkNothingSent();
                return;
              }
              await startManagerBotWithCreditRetry(
                client: remoteClient,
                botId: botId,
                botName: _appName,
              );
              RunnerSettings.associateBotWithRunner(botId, 'manager');
            } else {
              await remoteClient.syncBot(botId, _appName, payload);
              await remoteClient.startBot(botId, botName: _appName);
              final runnerConfig = await RunnerSettings.resolveConfigForBot(
                botId,
              );
              if (runnerConfig != null) {
                RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
              }
            }
            setBotRuntimeActive(true);
            _setState(() => _botLaunched = true);
            // The runtime confirmed the start: the funnel's success point.
            unawaited(ActivationFunnel.botStart());
          }
        } catch (error) {
          // Refus de la garde anti-config-vide : il a eu lieu AVANT tout appel
          // réseau. Le passer par `describeManagerRuntimeFailure` le présenterait
          // comme une panne des serveurs Bot Creator alors que rien n'a été
          // envoyé — on le laisse donc remonter tel quel vers le message dédié.
          // Même traitement pour le refus SERVEUR de sur-réduction
          // (`409 bot_config_overshrink`) : c'est une question posée au
          // propriétaire, pas un serveur qui serait « pas encore prêt ».
          if (isBotPayloadRefusal(error) ||
              isBotConfigOvershrinkRefusal(error)) {
            rethrow;
          }
          if (remoteClient is MainApiClient) {
            throw Exception(
              await describeManagerRuntimeFailure(remoteClient, error),
            );
          }
          rethrow;
        }
        return;
      }

      if (!_botLaunched) {
        clearBotBaselineRss();
        final engine = await getBotRuntimeEngine(botId);
        final isJsDesktop =
            !_supportsForegroundTask && engine == runtimeEngineJavascript;
        if (!isJsDesktop) {
          startBotLogSession(botId: botId);
          appendBotLog('Bot start requested', botId: botId);
        }
      }

      if (_supportsForegroundTask) {
        if (_botLaunched) {
          appendBotLog('Bot stop requested', botId: botId);
          await stopMobileBotSession(botId: botId);
          endBotLogSession(botId: botId);
          setBotRuntimeActive(
            isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
          );
          _setState(() {
            _botLaunched = false;
            _botStarting = false;
          });
          return;
        }

        final permissionGranted = await _requestPermissions();
        if (!permissionGranted) {
          throw Exception(context.tr.bot_home_notif_required);
        }
        await _initService();

        await startMobileBotSession(botId: botId, token: token);
        developer.log(
          'Token saved, starting foreground service',
          name: 'AppHomePage',
        );

        final running = await FlutterForegroundTask.isRunningService;
        if (!running) {
          throw Exception(context.tr.bot_home_service_not_started);
        }

        _setState(() {
          _botLaunched = false;
          _botStarting = true;
        });
        keepsStartingStateActive = true;
        // The foreground service reported itself running: the mobile start
        // succeeded, even though the bot is not "launched" locally yet.
        unawaited(ActivationFunnel.botStart());
      } else {
        if (_botLaunched) {
          appendBotLog(context.tr.bot_home_log_desktop_stop, botId: botId);
          await stopDesktopBot(botId: botId);
          endBotLogSession(botId: botId);
          setBotRuntimeActive(
            isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
          );
          clearBotBaselineRss();
          _setState(() {
            _botLaunched = false;
            _botStarting = false;
          });
          return;
        }

        if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
          final runnerConfig = await RunnerSettings.resolveConfigForBot(botId);
          if (runnerConfig == null) {
            final startupDetail =
                await RunnerSettings.embeddedRunnerStartupFailureDetail();
            final detailSuffix = startupDetail == null || startupDetail.isEmpty
                ? ''
                : ' ($startupDetail)';
            throw Exception(
              context.tr.bot_start_embedded_runner_failed(detailSuffix),
            );
          }

          final client = runnerConfig.createClient();
          startBotLogSession(botId: botId, source: RemoteRuntimeSource.runner);
          clearBotBaselineRss();
          appendBotLog(
            'Bot start requested',
            botId: botId,
            source: RemoteRuntimeSource.runner,
          );
          await validateJsBotPayloadOrThrow(botId);
          final payload = await buildRemotePayload(botId);
          await client.syncBot(botId, _appName, payload);
          await client.startBot(botId, botName: _appName);
          RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
          setBotRuntimeActive(true);
          _setState(() => _botLaunched = true);
          // The runner accepted the start: the funnel's success point.
          unawaited(ActivationFunnel.botStart());
          return;
        }

        await startDesktopBot(token);
        // The local engine is running the bot: the funnel's success point.
        unawaited(ActivationFunnel.botStart());
      }

      _setState(() {
        _botLaunched = !_supportsForegroundTask;
        _botStarting = false;
      });
    } on PlatformException catch (error) {
      if (wasStarting) {
        unawaited(ActivationFunnel.botStartFailed(error));
      }
      _setState(() {
        _botStarting = false;
      });
      final deadChannel = _isDeadChannelError(error);
      final display = deadChannel
          ? 'Foreground service channel unavailable. Please reopen the app and try again.'
          : error.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_start_error(display))),
        );
      }
    } catch (e) {
      if (wasStarting) {
        unawaited(ActivationFunnel.botStartFailed(e));
      }
      _setState(() {
        _botStarting = false;
      });
      if (mounted) {
        // La poussée refusée par la garde anti-config-vide a son propre message :
        // il dit les deux choses que l'utilisateur ignore — rien n'est parti, et
        // rien n'a été effacé en local. Sinon, le message d'échec habituel. Le
        // refus SERVEUR de sur-réduction reçoit la même phrase (une seule version
        // des faits), sans passer pour une panne.
        final refusal =
            localizedBotPayloadRefusalMessage(context.tr, e) ??
            localizedBotConfigOvershrinkNothingSent(context.tr, e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              refusal ?? context.tr.bot_home_start_error(e.toString()),
            ),
            backgroundColor: refusal == null ? null : AppTheme.error,
          ),
        );
      }
    } finally {
      if (!keepsStartingStateActive) {
        _setState(() {
          _botStarting = false;
        });
      }
    }
  }

  Future<void> _restartBot() async {
    if (_botStarting) return;
    if (_botLaunched) {
      await _toggleBotLaunchState();
      if (!mounted || _botLaunched) return;
    }
    await _toggleBotLaunchState();
  }

  Future<void> _refreshOverview() async {
    await _init();
    if (!SubscriptionService.isSubscribed) {
      await _refreshFreeRuntimeBalance();
    }
  }
}
