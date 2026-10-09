// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/engine/bot_engine_callbacks.dart';
import 'package:bot_creator_shared/engine/presence_manager.dart';
import 'package:bot_creator_shared/engine/event_dispatcher.dart';
import 'package:bot_creator_shared/engine/command_executor.dart';
import 'package:bot_creator_shared/engine/workflow_executor.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:bot_creator_shared/services/lavalink_probe.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:bot_creator_shared/utils/interaction_listener_registry.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/discord_auth_errors.dart';
import 'package:bot_creator_shared/utils/global.dart';

/// Represents an active bot session with its gateway connection and managers.
class BotSession {
  BotSession({
    required this.botId,
    required String token,
    required this.store,
    required this.callbacks,
    LavalinkConfig? lavalinkConfig,
    LavalinkProbe? lavalinkProbe,
    LavalinkConnectionTester? lavalinkConnectionTester,
    this.lavalinkSelectionTimeout = const Duration(seconds: 4),
  }) : _token = token,
       _lavalinkConfig = lavalinkConfig,
       lavalinkConnectionTester =
           lavalinkConnectionTester ?? LavalinkService.testConnection,
       _probe = lavalinkProbe {
    _workflowExecutor = WorkflowExecutor(store: store, callbacks: callbacks);
    _commandExecutor = CommandExecutor(
      store: store,
      callbacks: callbacks,
      workflowExecutor: _workflowExecutor,
      sessionVariableInjector: injectVariables,
    );
    _eventDispatcher = EventDispatcher(
      store: store,
      callbacks: callbacks,
      commandExecutor: _commandExecutor,
      workflowExecutor: _workflowExecutor,
      sessionVariableInjector: injectVariables,
    );
  }

  final String botId;
  final BotDataStore store;
  final BotEngineCallbacks callbacks;

  /// Budget TOTAL de la phase Lavalink qui précède la connexion Discord.
  ///
  /// C'est une borne dure : dépassée, la sélection est abandonnée et le bot se
  /// connecte sans musique. Jamais de démarrage suspendu à Lavalink.
  final Duration lavalinkSelectionTimeout;

  /// Test de connexion utilisé pour revérifier un serveur issu du cache.
  /// Injectable pour les tests (aucun appel réseau).
  final LavalinkConnectionTester lavalinkConnectionTester;

  String _token;
  LavalinkConfig? _lavalinkConfig;

  /// Sondeur partagé par les démarrages successifs du même bot : son classement
  /// (cache ~10 min) évite de re-sonder à chaque redémarrage.
  LavalinkProbe? _probe;

  /// Dernier selected server par la sélection automatique (diagnostic).
  LavalinkProbeTarget? _selectedServer;

  LavalinkProbeTarget? get selectedServer => _selectedServer;

  Map<String, bool> _intentsMap = const {};

  String get token => _token;
  LavalinkConfig? get lavalinkConfig => _lavalinkConfig;

  late final WorkflowExecutor _workflowExecutor;
  late final CommandExecutor _commandExecutor;
  late final EventDispatcher _eventDispatcher;

  WorkflowExecutor get workflowExecutor => _workflowExecutor;
  NyxxGateway? get gateway => _gateway;
  LavalinkService? get lavalinkService => _lavalinkService;
  String get ownerId => _ownerId;
  int get commandCount => _commandCount;

  NyxxGateway? _gateway;
  LavalinkService? _lavalinkService;
  PresenceManager? _presenceManager;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  DateTime? _startedAt;
  Timer? _metricsTimer;
  Timer? _initialMetricsTimer;

  String _ownerId = '';
  int _commandCount = 0;

  bool get isActive => _gateway != null;

  static const Duration _portalIntentTimeout = Duration(seconds: 15);

  Future<Map<String, bool>> _resolveEffectiveIntents(
    BotConfig config, {
    List<String>? warnings,
  }) async {
    try {
      return await _fetchPortalEffectiveIntents(
        config,
        warnings: warnings,
      ).timeout(_portalIntentTimeout);
    } on TimeoutException {
      warnings?.add(
        'Portal intent sync timed out — using safe fallback intents',
      );
      return buildSafeFallbackIntentsMap(config: config, warnings: warnings);
    } catch (error) {
      if (isDiscordTokenUnauthorized(error)) {
        throw DiscordTokenUnauthorizedException(
          'Discord bot token is invalid or unauthorized while resolving intents',
          cause: error,
        );
      }
      return buildSafeFallbackIntentsMap(config: config, warnings: warnings);
    }
  }

  Future<Map<String, bool>> _fetchPortalEffectiveIntents(
    BotConfig config, {
    List<String>? warnings,
  }) async {
    final portalEnabled = await readPortalEnabledPrivilegedIntents(_token);
    return buildEffectiveIntentsMap(
      config: config,
      portalEnabledPrivileged: portalEnabled,
      warnings: warnings,
    );
  }

  /// Plugins confiés à la passerelle Discord.
  ///
  /// Le plugin Lavalink n'y figure QUE si un serveur a été retenu : la
  /// passerelle se connecte donc toujours, musique ou pas.
  static List<NyxxPlugin> buildGatewayPlugins({
    LavalinkPlugin? lavalinkPlugin,
  }) {
    return <NyxxPlugin>[logging, cliIntegration, ?lavalinkPlugin];
  }

  /// Demande au sondeur le serveur à utiliser, puis construit le plugin.
  ///
  /// Contrat (c'est ce qui protège la passerelle Discord) :
  /// - jamais d'exception : l'échec rend `null` (musique indisponible) ;
  /// - jamais au-delà de [lavalinkSelectionTimeout] : la sélection est COUPÉE,
  ///   pas attendue ; le sondage se termine en tâche de fond et alimente le
  ///   cache du prochain démarrage ;
  /// - un serveur issu du classement vient d'être testé par le sondeur, il
  ///   n'est pas retesté ; un serveur de repli, ou un classement servi depuis
  ///   le cache (~10 min), est revérifié en REST avec le temps restant.
  ///
  /// Publique pour être prouvée par les tests sans ouvrir de session Discord.
  Future<LavalinkPlugin?> prepareLavalinkPlugin(LavalinkConfig? config) async {
    _selectedServer = null;
    if (config == null || !config.enabled) return null;

    final stopwatch = Stopwatch()..start();
    final probe = _probe ??= LavalinkProbe(
      onLog: (message) => callbacks.onLog?.call(message, botId: botId),
    );
    final customServers = LavalinkProbeTarget.customServersFromJson(
      config.customServersJson,
    );

    // Le classement déjà connu (cache) est signalé : il faudra le revérifier.
    final rankedFromCache = probe.hasFreshCache;

    final Future<LavalinkProbeTarget?> selection;
    try {
      selection = probe.findBestServer(customServers: customServers);
    } catch (error) {
      return _lavalinkUnavailable('selection failed ($error)');
    }

    LavalinkProbeTarget? retained;
    try {
      retained = await selection
          .timeout(lavalinkSelectionTimeout, onTimeout: () => null)
          // Une erreur tardive du sondage ne doit jamais remonter jusqu'ici.
          .catchError((Object _) => null);
    } catch (error) {
      return _lavalinkUnavailable('selection failed ($error)');
    }

    if (retained == null) {
      return _lavalinkUnavailable(
        'no server responded within ${stopwatch.elapsedMilliseconds} ms',
      );
    }

    final justVerified =
        !rankedFromCache &&
        probe.cachedResults.any(
          (result) => result.target.sameEndpointAs(retained!),
        );

    if (!justVerified) {
      final remaining = lavalinkSelectionTimeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        return _lavalinkUnavailable('selection budget exhausted');
      }
      final error = await _testLavalinkConnection(
        retained,
      ).timeout(remaining, onTimeout: () => 'budget exhausted');
      if (error != null) {
        _selectedServer = null;
        callbacks.onLog?.call(
          'Lavalink: ${retained.endpoint} is not responding ($error) — '
          'music unavailable',
          botId: botId,
        );
        return null;
      }
    }

    _selectedServer = retained;
    callbacks.onLog?.call(
      'Lavalink: selected server ${retained.endpoint}'
      '${retained.isCustom ? ' (custom server)' : ''} '
      'in ${stopwatch.elapsedMilliseconds} ms — plugin ready',
      botId: botId,
    );
    return LavalinkService.createPluginForServer(
      host: retained.host,
      port: retained.port,
      password: retained.password,
      useSsl: retained.useSsl,
    );
  }

  Future<String?> _testLavalinkConnection(LavalinkProbeTarget target) {
    return lavalinkConnectionTester(
      host: target.host,
      port: target.port,
      password: target.password,
      useSsl: target.useSsl,
    );
  }

  LavalinkPlugin? _lavalinkUnavailable(String reason) {
    _selectedServer = null;
    callbacks.onLog?.call(
      'Lavalink: $reason — music unavailable, the Discord gateway '
      'continues without waiting',
      botId: botId,
    );
    return null;
  }

  /// Starts the bot gateway connection and initializes all managers.
  Future<void> start() async {
    if (isActive) return;

    final appData = await store.getApp(botId);
    final config = BotConfig.fromJson(appData);

    final intentWarnings = <String>[];
    final effectiveIntents = await _resolveEffectiveIntents(
      config,
      warnings: intentWarnings,
    );

    _intentsMap = effectiveIntents;

    for (final warning in intentWarnings) {
      callbacks.onLog?.call('Intent warning: $warning', botId: botId);
    }

    final intents = buildGatewayIntents(effectiveIntents);

    final enabledNames = enabledIntentNames(effectiveIntents);
    callbacks.onLog?.call(
      '[DiscordCache] Minimal cache enabled; intents: ${enabledNames.isEmpty ? 'Guilds only' : enabledNames.join(', ')}',
      botId: botId,
    );

    callbacks.onLog?.call('Starting bot gateway...', botId: botId);

    // ── Lavalink : phase bornée AVANT la connexion Discord ────────────────
    // Règle durement apprise : la passerelle Discord doit se connecter D'ABORD.
    // Le plugin Lavalink ouvre son WebSocket dans son `afterConnect`, sans
    // délai côté `nyxx_lavalink` : un serveur injoignable ferait patienter —
    // voire bloquerait — la connexion Discord entière. On prépare donc la
    // musique ici, sous budget borné, et l'échec n'a AUCUNE conséquence sur la
    // connexion Discord : pas de plugin, musique indisponible, bot en ligne.
    final lavalinkPlugin = await prepareLavalinkPlugin(lavalinkConfig);

    final plugins = buildGatewayPlugins(lavalinkPlugin: lavalinkPlugin);

    try {
      _gateway = await Nyxx.connectGateway(
        token,
        intents,
        options: GatewayClientOptions(plugins: plugins),
      );

      // ── Lavalink: wait for ready event now that the plugin is connected ──
      if (lavalinkPlugin != null) {
        _lavalinkService = LavalinkService(
          plugin: lavalinkPlugin,
          onLog: (msg) => callbacks.onLog?.call(msg, botId: botId),
        );

        // Fire and forget: wait for Lavalink WS handshake in background
        unawaited(
          _lavalinkService!
              .waitForReady()
              .then((_) {
                callbacks.onLog?.call(
                  'Lavalink ready — music features enabled',
                  botId: botId,
                );
                _workflowExecutor.lavalinkService = _lavalinkService;
                _lavalinkService!.monitorHealth();
              })
              .catchError((e) {
                callbacks.onLog?.call(
                  'Lavalink connection failed: $e — music disabled',
                  botId: botId,
                );
                _lavalinkService = null;
              }),
        );
      }

      // Debug voice events
      _gateway!.onVoiceStateUpdate.listen((event) {
        callbacks.onLog?.call(
          'DEBUG VOICE STATE: userId=${event.state.userId}, botId=${_gateway!.user.id}, guildId=${event.state.guildId}, channelId=${event.state.channelId}, sessionId=${event.state.sessionId}',
          botId: botId,
        );
      });
      _gateway!.onVoiceServerUpdate.listen((event) {
        final tokenSnippet = event.token.length > 5
            ? event.token.substring(0, 5)
            : event.token;
        callbacks.onLog?.call(
          'DEBUG VOICE SERVER: guildId=${event.guildId}, endpoint=${event.endpoint}, token=$tokenSnippet...',
          botId: botId,
        );
      });

      _startedAt = DateTime.now();
      botStartTimes[botId] = _startedAt!;

      // Listen for permanent disconnection (token invalidated, fatal close codes).
      // This detects Discord close codes 4004 (auth failed), 4010-4014, etc.
      // and automatically stops the session so the runner reports it as disconnected.
      final shardMessageSub = _gateway!.gateway.messages.listen((msg) {
        if (msg is Disconnecting) {
          final reason = formatGatewayDisconnectMessage(msg.reason);
          if (isDiscordGatewayDisallowedIntents(null, reason)) {
            callbacks.onLog?.call(
              'Disallowed intents (4014): $reason',
              botId: botId,
            );
          }
          callbacks.onDisconnected?.call(reason, botId: botId);
          stop();
        }
      });
      _subscriptions.add(shardMessageSub);

      // Cache metadata
      try {
        final app = await (_gateway! as NyxxRest).applications
            .fetchCurrentApplication();
        _ownerId = (app.team?.ownerId.toString() ?? app.owner?.id.toString())!;
      } catch (_) {}

      try {
        final commands = await store.listAppCommands(botId);
        _commandCount = commands.length;
      } catch (_) {}

      _presenceManager = PresenceManager(
        botId: botId,
        gateway: _gateway!,
        onLog: callbacks.onLog,
        onDebugLog: callbacks.onDebugLog,
        resolveTemplate: (input) {
          final vars = <String, String>{};
          injectAlwaysAvailableVariables(
            vars,
            botId: botId,
            guildCount: _gateway!.guilds.cache.length,
            uptimeMs: DateTime.now()
                .difference(_startedAt ?? DateTime.now())
                .inMilliseconds,
          );
          return resolveTemplatePlaceholders(input, vars);
        },
      );

      await reload();

      callbacks.onDebugLog?.call(
        'Registering event listeners...',
        botId: botId,
      );
      _subscriptions.addAll(
        _eventDispatcher.registerListeners(
          _gateway!,
          botId: botId,
          startedAt: _startedAt,
        ),
      );
      callbacks.onDebugLog?.call(
        '${_subscriptions.length} listeners registered.',
        botId: botId,
      );

      _startMetricsReporting();

      callbacks.onLifecycleChange?.call('started', botId: botId);
      callbacks.onLog?.call('Bot gateway connected.', botId: botId);
    } catch (error, stackTrace) {
      if (isDiscordTokenUnauthorized(error)) {
        callbacks.onLog?.call(
          'Failed to start bot: invalid Discord token ($error)',
          botId: botId,
        );
      } else {
        callbacks.onLog?.call('Failed to start bot: $error', botId: botId);
      }
      callbacks.onDebugLog?.call(
        'Start error stack: $stackTrace',
        botId: botId,
      );
      rethrow;
    }
  }

  /// Reloads the bot configuration (presence, commands, etc.) without reconnecting,
  /// unless token, intents, or lavalink presence changed.
  Future<void> reload() async {
    final appData = await store.getApp(botId);
    final config = BotConfig.fromJson(appData);

    final newToken = config.token;
    final newLavalinkConfig = config.lavalinkConfig;

    // « Avoir Lavalink » = la musique est ACTIVÉE : c'est l'interrupteur qui
    // décide si la passerelle doit être rebâtie avec un plugin de musique.
    final previousHasLavalink = _lavalinkConfig?.enabled == true;
    final newHasLavalink = newLavalinkConfig?.enabled == true;

    final newEffectiveIntents = await _resolveEffectiveIntents(config);
    final bool intentsChanged =
        !_sameIntents(_intentsMap, newEffectiveIntents) ||
        (previousHasLavalink != newHasLavalink);

    if (_token != newToken || intentsChanged) {
      callbacks.onLog?.call(
        'Lavalink/Intents/Token changed, reconnecting gateway...',
        botId: botId,
      );
      _token = newToken;
      _lavalinkConfig = newLavalinkConfig;
      _intentsMap = newEffectiveIntents;

      await stop();
      await start();
      return;
    }

    // If no gateway reconnect is needed, check if the Lavalink settings changed
    if (newHasLavalink && previousHasLavalink) {
      final current = _lavalinkConfig;
      if (current != null &&
          newLavalinkConfig != null &&
          !current.sameSettingsAs(newLavalinkConfig)) {
        callbacks.onLog?.call(
          'Lavalink config details changed, updating service...',
          botId: botId,
        );
        _lavalinkConfig = newLavalinkConfig;
        await _reloadLavalinkService();
      }
    } else if (!newHasLavalink && previousHasLavalink) {
      _lavalinkConfig = null;
      await _disposeLavalink();
    }

    _presenceManager?.start(
      statuses: config.statuses,
      presenceStatus: config.presenceStatus,
    );

    // Refresh command count
    try {
      final commands = await store.listAppCommands(botId);
      _commandCount = commands.length;
    } catch (_) {}
  }

  /// Stops the bot session and cleans up resources.
  Future<void> stop() async {
    botStartTimes.remove(botId);
    _metricsTimer?.cancel();
    _metricsTimer = null;
    _initialMetricsTimer?.cancel();
    _initialMetricsTimer = null;

    _presenceManager?.stop();
    _presenceManager = null;

    // Clear any registered interaction listeners for this bot
    InteractionListenerRegistry.instance.removeAllForBot(botId);

    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();

    await _disposeLavalink();

    if (_gateway != null) {
      await _gateway!.close();
      _gateway = null;
    }

    callbacks.onLifecycleChange?.call('stopped', botId: botId);
  }

  /// Injects session-specific variables.
  void injectVariables(Map<String, String> variables) {
    variables['bot.ownerId'] = _ownerId;
    variables['bot.commands'] = _commandCount.toString();
    variables['bot.commandsCount'] = _commandCount.toString();
    variables['bot.slashCommandsCount'] = _commandCount.toString();
    if (_startedAt != null) {
      variables['bot.uptime'] = DateTime.now()
          .difference(_startedAt!)
          .inMilliseconds
          .toString();
    }
  }

  void _startMetricsReporting() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _reportMetrics();
    });
    // Initial report
    _initialMetricsTimer?.cancel();
    _initialMetricsTimer = Timer(
      const Duration(seconds: 5),
      () => _reportMetrics(),
    );
  }

  void _reportMetrics() {
    final gateway = _gateway;
    if (gateway == null) return;

    BotRuntimeMetrics metrics = const BotRuntimeMetrics(
      guildCount: 0,
      shardsCount: 0,
      latencyMs: 0,
      uptimeSeconds: 0,
      memoryUsageBytes: 0,
      cpuUsagePercent: 0.0,
    );
    try {
      final gatewayManager = gateway.gateway;
      // In Nyxx 6.x, Gateway is the interface for the gateway manager.
      // We can access shards if we cast to the implementation or if the interface exposes it.
      // To be safe and avoid dynamic, we try to use the common shards property if it exists on the interface.
      final shards = (gatewayManager as dynamic).shards as List?;
      metrics = BotRuntimeMetrics(
        guildCount: gateway.guilds.cache.length,
        shardsCount: shards?.length ?? 1,
        latencyMs: (shards != null && shards.isNotEmpty)
            ? ((shards.first as dynamic).latency as Duration?)
                      ?.inMilliseconds ??
                  0
            : 0,
        uptimeSeconds: _startedAt != null
            ? DateTime.now().difference(_startedAt!).inSeconds
            : 0,
        memoryUsageBytes: 0,
        cpuUsagePercent: 0.0,
      );
    } catch (_) {
      metrics = BotRuntimeMetrics(
        guildCount: gateway.guilds.cache.length,
        shardsCount: 1,
        latencyMs: 0,
        uptimeSeconds: _startedAt != null
            ? DateTime.now().difference(_startedAt!).inSeconds
            : 0,
        memoryUsageBytes: 0,
        cpuUsagePercent: 0.0,
      );
    }

    callbacks.onMetrics?.call(metrics, botId: botId);
  }

  bool _sameIntents(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if ((b[entry.key] ?? false) != entry.value) return false;
    }
    return true;
  }

  Future<void> _reloadLavalinkService() async {
    // LavalinkPlugin must be registered at gateway connection time.
    // Since the gateway is already running, we must do a full restart
    // to include the new plugin in GatewayClientOptions.
    callbacks.onLog?.call(
      'Lavalink config changed — restarting bot to apply new Lavalink settings...',
      botId: botId,
    );
    await stop();
    await start();
  }

  Future<void> _disposeLavalink() async {
    if (_lavalinkService != null) {
      callbacks.onLog?.call(
        'Lavalink: disposing existing service...',
        botId: botId,
      );
      try {
        await _lavalinkService!.dispose();
      } catch (e) {
        callbacks.onLog?.call(
          'Lavalink: error disposing service: $e',
          botId: botId,
        );
      }
      _lavalinkService = null;
      _workflowExecutor.lavalinkService = null;
    }
  }
}
