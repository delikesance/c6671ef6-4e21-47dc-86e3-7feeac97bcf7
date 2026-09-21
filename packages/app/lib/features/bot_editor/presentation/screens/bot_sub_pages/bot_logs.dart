import 'dart:async';
import 'package:bot_creator/core/platform/run_platform.dart';

import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';

import 'package:bot_creator/core/network/poll_cadence.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class BotLogsPage extends StatefulWidget {
  const BotLogsPage({super.key, this.botId});

  final String? botId;

  @override
  State<BotLogsPage> createState() => _BotLogsPageState();
}

class _BotLogsPageState extends State<BotLogsPage> {
  late bool _debugEnabled;
  String? _selectedBotId;
  Map<String, String> _botNamesById = const <String, String>{};
  final Set<String> _expandedLogs = <String>{};
  final Set<String> _expandedRawLogs = <String>{};
  final ScrollController _scrollController = ScrollController();
  bool _showNewestFirst = true;
  int _visibleLimit = 200;
  bool _rawMode = false;
  double _rawFontSize = 11.0;
  double _rawFontSizeAtScaleStart = 11.0;

  static const double _rawFontSizeMin = 7.0;
  static const double _rawFontSizeMax = 22.0;
  static const int _collapseThreshold = 240;

  // Runner log polling
  Timer? _runnerPollTimer;
  List<String> _lastKnownRemoteLogs = const [];

  /// Cadence du sondage des logs : un écran laissé ouvert sur un bot calme ne doit
  /// pas générer 48 requêtes par minute (deux endpoints par tick).
  final PollCadence _logsCadence = PollCadence(
    nominal: const Duration(milliseconds: 2500),
  );

  /// Numéro du tick courant, pour n'interroger les métriques qu'un tick sur quatre.
  int _metricsTick = 0;

  /// Dernières métriques affichées, comparées en mémoire (aucune requête
  /// supplémentaire) pour savoir si le tick courant apporte du neuf.
  _MetricsSnapshot? _lastMetricsSnapshot;

  RemoteRuntimeClient? _runtimeClient;
  RemoteRuntimeSource _runtimeSource = RemoteRuntimeSource.local;
  String? _runtimeLabel;
  String? _runtimeUnavailableReason;

  // Une seule règle dans toute l'application : le serveur pilote depuis n'importe
  // quelle plateforme, poste de travail compris (voir `run_platform.dart`).
  bool get _supportsManagerRuntime => supportsManagerRuntime;

  bool get _usingRemoteSource => _runtimeSource != RemoteRuntimeSource.local;

  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  String _runtimeSourceLabel() {
    return switch (_runtimeSource) {
      RemoteRuntimeSource.manager => _uiCopy(
        fr: 'Serveurs Bot Creator',
        en: 'Bot Creator servers',
      ),
      RemoteRuntimeSource.runner =>
        (_runtimeLabel?.trim().isNotEmpty ?? false)
            ? context.tr.logs_runner_source(_runtimeLabel!)
            : context.tr.bot_stats_source_runner_api,
      RemoteRuntimeSource.local => _uiCopy(
        fr: 'Local sur cet appareil',
        en: 'Local on this device',
      ),
    };
  }

  @override
  void initState() {
    super.initState();
    _debugEnabled = isBotDebugLogsEnabled;
    _selectedBotId = widget.botId;
    unawaited(_loadBotNamesById());
    _initRunnerPolling();
  }

  @override
  void dispose() {
    _runnerPollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initRunnerPolling() async {
    debugPrint(
      '[BotLogs] Starting _initRunnerPolling for botId: $_selectedBotId',
    );

    ResolvedRemoteRuntime runtime;
    try {
      runtime = await resolveRemoteRuntime(
        supportsManagerRuntime: _supportsManagerRuntime,
        botId: _selectedBotId,
        getTimeout: const Duration(seconds: 5),
        postTimeout: const Duration(seconds: 10),
      ).timeout(const Duration(seconds: 8));
      debugPrint(
        '[BotLogs] Runtime resolved: source=${runtime.source}, hasClient=${runtime.client != null}',
      );
    } catch (e) {
      debugPrint('[BotLogs] Runtime resolution failed/timed out: $e');
      runtime = const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
    }

    final botId = _selectedBotId;
    if (runtime.client == null &&
        runtime.source == RemoteRuntimeSource.manager &&
        botId != null) {
      debugPrint(
        '[BotLogs] Manager client missing; attempting session restore for botId: $botId',
      );
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isNotEmpty) {
        final helper = MainApiOwnerSyncHelper(
          resolveRuntime:
              ({
                getTimeout = const Duration(seconds: 5),
                postTimeout = const Duration(seconds: 10),
              }) => resolveRemoteRuntime(
                supportsManagerRuntime: _supportsManagerRuntime,
                botId: botId,
                getTimeout: getTimeout,
                postTimeout: postTimeout,
              ),
          loadLocalBotById: (id) async => await appManager.getApp(id),
          log: (msg) => debugPrint('[BotLogs.Sync] $msg'),
        );

        final restored = await helper
            .restoreMainApiSessionWithBotToken(botId: botId, botToken: token)
            .timeout(const Duration(seconds: 8), onTimeout: () => false);
        debugPrint('[BotLogs] Session restore result: $restored');

        if (restored) {
          runtime = await resolveRemoteRuntime(
            supportsManagerRuntime: _supportsManagerRuntime,
            botId: _selectedBotId,
            getTimeout: const Duration(seconds: 5),
            postTimeout: const Duration(seconds: 10),
          );
          debugPrint(
            '[BotLogs] Runtime re-resolved: source=${runtime.source}, hasClient=${runtime.client != null}',
          );
        }
      }
    }

    _runtimeClient = runtime.client;
    _runtimeSource = runtime.source;
    if (botId != null &&
        _supportsManagerRuntime == false &&
        (runtime.client == null ||
            runtime.source == RemoteRuntimeSource.local)) {
      final hydrated = await RunnerSettings.resolveConfigForBot(botId);
      if (hydrated != null) {
        _runtimeClient = hydrated.createClient(
          getTimeout: const Duration(seconds: 5),
          postTimeout: const Duration(seconds: 10),
        );
        _runtimeSource = RemoteRuntimeSource.runner;
        _runtimeLabel = hydrated.name ?? hydrated.url;
        if (kDebugMode) {
          debugPrint(
            '[BotLogs] Using hydrated runner client at ${hydrated.url}',
          );
        }
      }
    }
    // Le panneau console intégré de la home lit le même bucket que cette page :
    // on enregistre la source résolue pour ce bot avant tout retour anticipé.
    setBotLogsSourceForBot(_selectedBotId, _runtimeSource);
    if (!mounted) return;

    setState(() {
      _runtimeLabel = runtime.detailLabel;
      _runtimeUnavailableReason = runtime.unavailableReason;
    });

    final client = _runtimeClient;
    if (client == null) {
      debugPrint(
        '[BotLogs] No runtime client available; polling will not start.',
      );
      return;
    }

    debugPrint('[BotLogs] Starting poll loop...');
    await _pollRunnerData(client);
    // Le premier poll est asynchrone : si la page a été démontée entre-temps,
    // ne pas armer le timer (sinon « A Timer is still pending even after the
    // widget tree was disposed »).
    if (!mounted) {
      debugPrint(
        '[BotLogs] Widget disposed during initial poll; no timer started.',
      );
      return;
    }
    // Plus de `Timer.periodic` fixe : le tick initial ci-dessus a déjà réarmé la
    // cadence adaptative (voir `_pollRunnerData` / `_reschedulePolling`), qui s'espace
    // tant que rien ne change au lieu de sonder toutes les 2,5 s pour rien.
  }

  Future<void> _restartPolling() async {
    _runnerPollTimer?.cancel();
    _runnerPollTimer = null;
    _lastKnownRemoteLogs = const [];
    // Nouveau bot : on repart au rythme nominal et on réinterroge les métriques tout
    // de suite, sinon le nouvel écran hériterait de l'espacement du précédent.
    _logsCadence.reset();
    _metricsTick = 0;
    _lastMetricsSnapshot = null;
    await _initRunnerPolling();
  }

  /// Les métriques bougent lentement (RSS, CPU, stockage) : les interroger à chaque
  /// tick doublerait le coût sans rien apporter, un tick sur quatre suffit (~10 s).
  static const int _metricsEveryNTicks = 4;

  /// Un mébioctet : la précision à laquelle on compare les mesures de taille.
  static const int _bytesPerMebibyte = 1024 * 1024;

  Future<void> _pollRunnerData(RemoteRuntimeClient client) async {
    final outcome = await _pollRunnerLogs(client);
    final withMetrics = _metricsTick % _metricsEveryNTicks == 0;
    _metricsTick++;
    if (withMetrics) {
      final metricsOutcome = await _pollRunnerMetrics(client);
      // Des métriques fraîches comptent comme un changement : l'utilisateur regarde
      // l'écran, on ne veut pas ralentir juste parce que les lignes de log n'ont pas
      // bougé.
      if (metricsOutcome == TickOutcome.changed) {
        _logsCadence.reset();
      }
    }
    _logsCadence.consume(outcome);
    // Réarmer un timer alors que la page est démontée laisse « A Timer is still
    // pending even after the widget tree was disposed ».
    if (!mounted) {
      return;
    }
    _reschedulePolling();
  }

  /// Réarme le prochain tick selon la cadence courante : c'est ce réarmement, et non
  /// un `Timer.periodic`, qui permet d'espacer les requêtes quand rien ne change.
  void _reschedulePolling() {
    _runnerPollTimer?.cancel();
    _runnerPollTimer = Timer(_logsCadence.current, () {
      final client = _runtimeClient;
      if (!mounted || client == null) {
        return;
      }
      unawaited(_pollRunnerData(client));
    });
  }

  Future<TickOutcome> _pollRunnerLogs(RemoteRuntimeClient client) async {
    try {
      debugPrint('[BotLogs] Polling logs for botId: $_selectedBotId');
      final lines = await client.getLogs(botId: _selectedBotId, limit: 500);
      debugPrint('[BotLogs] Received ${lines.length} log lines');

      // Comparaison faite sur la charge utile déjà en mémoire : le changement se
      // détecte sans requête supplémentaire (et avant d'écraser la référence).
      final changed = _remoteLogsChanged(lines);
      if (lines.isEmpty) {
        _lastKnownRemoteLogs = const [];
        return changed ? TickOutcome.changed : TickOutcome.unchanged;
      }

      final overlap = _computeOverlap(_lastKnownRemoteLogs, lines);
      if (overlap < lines.length) {
        final newLines = lines.sublist(overlap);
        for (final line in newLines) {
          appendBotLog(line, botId: _selectedBotId, source: _runtimeSource);
        }
      }
      _lastKnownRemoteLogs = List<String>.from(lines);
      return changed ? TickOutcome.changed : TickOutcome.unchanged;
    } catch (e) {
      debugPrint('[BotLogs] Error polling logs: $e');
      // Un endpoint en échec ne doit pas être martelé : le compter comme inchangé
      // espace le sondage, ce qui sert de repli progressif jusqu'au rétablissement.
      return TickOutcome.unchanged;
    }
  }

  /// Un changement de logs se lit au nombre de lignes et à la dernière ligne :
  /// comparer tout le tampon coûterait aussi cher que la requête qu'on économise.
  bool _remoteLogsChanged(List<String> lines) {
    final previous = _lastKnownRemoteLogs;
    if (previous.length != lines.length) {
      return true;
    }
    if (lines.isEmpty) {
      return false;
    }
    return previous.last != lines.last;
  }

  Future<TickOutcome> _pollRunnerMetrics(RemoteRuntimeClient client) async {
    try {
      final metrics = await client.getMetrics(botId: _selectedBotId);
      final runtimeBotId = _selectedBotId ?? metrics.activeBotId;
      final isRunningForSelectedBot = runtimeBotId == null
          ? metrics.running
          : metrics.bots.any(
              (bot) => bot.botId == runtimeBotId && bot.isRunning,
            );
      // On compare ce que l'écran affiche réellement : l'état du bot, le RSS, le RSS
      // estimé, le CPU et le stockage. Comparer ces valeurs telles quelles ne marche
      // pas — un RSS au byte près et un CPU flottant changent à chaque mesure, ce qui
      // remettrait la cadence au nominal à chaque tick et annulerait l'espacement.
      final snapshot = (
        running: isRunningForSelectedBot,
        rssMb: _mebibytes(metrics.rssBytes),
        estimatedRssMb: _mebibytes(metrics.botEstimatedRssBytes),
        cpuBucket: _cpuBucket(metrics.cpuPercent),
        storageMb: _mebibytes(metrics.storageBytes),
      );
      final changed = snapshot != _lastMetricsSnapshot;
      _lastMetricsSnapshot = snapshot;
      updateBotRuntimeMetricsFromRemote(
        running: isRunningForSelectedBot,
        botId: runtimeBotId,
        source: _runtimeSource,
        rssBytes: metrics.rssBytes,
        estimatedRssBytes: metrics.botEstimatedRssBytes,
        cpuPercent: metrics.cpuPercent,
        storageBytes: metrics.storageBytes,
      );
      return changed ? TickOutcome.changed : TickOutcome.unchanged;
    } catch (e) {
      debugPrint('[BotLogs] Error polling metrics: $e');
      // Même repli que pour les logs : on espace au lieu de réessayer en boucle.
      return TickOutcome.unchanged;
    }
  }

  /// Les tailles sont comparées au mébioctet : c'est la précision de l'affichage, et
  /// une variation plus fine n'apprend rien à l'utilisateur.
  static int? _mebibytes(int? bytes) =>
      bytes == null ? null : bytes ~/ _bytesPerMebibyte;

  /// Le CPU est comparé par paliers de 5 points : un pourcentage décimal bouge à
  /// chaque mesure, un écart de cet ordre reste franc à l'écran.
  static int? _cpuBucket(double? cpuPercent) =>
      cpuPercent == null ? null : (cpuPercent / 5).floor();

  Future<void> _loadBotNamesById() async {
    final namesById = await getKnownBotNamesById();
    if (!mounted) {
      return;
    }
    setState(() {
      _botNamesById = namesById;
    });
  }

  int _computeOverlap(List<String> previous, List<String> current) {
    if (previous.isEmpty || current.isEmpty) {
      return 0;
    }

    final maxOverlap = previous.length < current.length
        ? previous.length
        : current.length;
    for (var overlap = maxOverlap; overlap > 0; overlap--) {
      var same = true;
      for (var index = 0; index < overlap; index++) {
        final prevValue = previous[previous.length - overlap + index];
        final currentValue = current[index];
        if (prevValue != currentValue) {
          same = false;
          break;
        }
      }
      if (same) {
        return overlap;
      }
    }
    return 0;
  }

  void _jumpToEdge() {
    if (!_scrollController.hasClients) {
      return;
    }

    final target = _showNewestFirst
        ? _scrollController.position.minScrollExtent
        : _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final knownBotIds = getKnownBotLogIds().toList(growable: false)..sort();
    final canSelectBot = knownBotIds.length > 1;
    final selectedBotId = _selectedBotId;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.bot_logs_title),
        actions: [
          IconButton(
            tooltip: _rawMode
                ? context.tr.bot_logs_rich_mode
                : context.tr.bot_logs_raw_mode,
            icon: Icon(_rawMode ? Icons.view_agenda_outlined : Icons.terminal),
            onPressed: () {
              setState(() {
                _rawMode = !_rawMode;
              });
            },
          ),
          IconButton(
            tooltip: _debugEnabled
                ? context.tr.bot_logs_disable_debug
                : context.tr.bot_logs_enable_debug,
            icon: Icon(
              _debugEnabled ? Icons.bug_report : Icons.bug_report_outlined,
            ),
            onPressed: () {
              setState(() {
                _debugEnabled = !_debugEnabled;
                setBotDebugLogsEnabled(_debugEnabled);
              });
            },
          ),
          IconButton(
            tooltip: context.tr.copy,
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final logs = getBotLogsSnapshotForBotFromSource(
                _selectedBotId,
                source: _runtimeSource,
              );
              await Clipboard.setData(ClipboardData(text: logs.join('\n')));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr.bot_logs_copied)),
                );
              }
            },
          ),
          IconButton(
            tooltip: _showNewestFirst
                ? context.tr.bot_logs_oldest_first
                : context.tr.bot_logs_newest_first,
            icon: Icon(
              _showNewestFirst
                  ? Icons.vertical_align_top
                  : Icons.vertical_align_bottom,
            ),
            onPressed: () {
              setState(() {
                _showNewestFirst = !_showNewestFirst;
              });
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _jumpToEdge();
              });
            },
          ),
          PopupMenuButton<int>(
            tooltip: context.tr.bot_logs_filter_count,
            icon: const Icon(Icons.filter_list),
            initialValue: _visibleLimit,
            onSelected: (value) {
              setState(() {
                _visibleLimit = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 100,
                child: Text(context.tr.bot_logs_show_n(100)),
              ),
              PopupMenuItem(
                value: 200,
                child: Text(context.tr.bot_logs_show_n(200)),
              ),
              PopupMenuItem(
                value: 500,
                child: Text(context.tr.bot_logs_show_n(500)),
              ),
              PopupMenuItem(
                value: 0,
                child: Text(context.tr.bot_logs_show_all),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<int?>(
          stream: getBotProcessRssStreamForBotFromSource(
            selectedBotId,
            source: _runtimeSource,
          ),
          initialData: getBotProcessRssBytesForBotFromSource(
            selectedBotId,
            source: _runtimeSource,
          ),
          builder: (context, metricsSnapshot) {
            return StreamBuilder<int?>(
              stream: getBotEstimatedRssStreamForBotFromSource(
                selectedBotId,
                source: _runtimeSource,
              ),
              initialData: getBotEstimatedRssBytesForBotFromSource(
                selectedBotId,
                source: _runtimeSource,
              ),
              builder: (context, estimatedSnapshot) {
                return PageContent(
                  child: Column(
                    children: [
                      if (canSelectBot)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedBotId,
                            decoration: InputDecoration(
                              labelText: context.tr.common_bot,
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: [
                              for (final botId in knownBotIds)
                                DropdownMenuItem<String>(
                                  value: botId,
                                  child: Text(_botNamesById[botId] ?? botId),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null || value == _selectedBotId) {
                                return;
                              }
                              setState(() {
                                _selectedBotId = value;
                                _expandedLogs.clear();
                              });
                              unawaited(_restartPolling());
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _usingRemoteSource
                                ? Theme.of(context).colorScheme.primaryContainer
                                      .withValues(alpha: 0.4)
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _usingRemoteSource
                                    ? Icons.dns_outlined
                                    : Icons.lan,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _runtimeSourceLabel(),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: _usingRemoteSource
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer
                                            : null,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_runtimeUnavailableReason?.trim().isNotEmpty ?? false)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.warning,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _runtimeUnavailableReason!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: StreamBuilder<List<String>>(
                          initialData: getBotLogsSnapshotForBotFromSource(
                            selectedBotId,
                            source: _runtimeSource,
                          ),
                          stream: getBotLogsStreamForBotFromSource(
                            selectedBotId,
                            source: _runtimeSource,
                          ),
                          builder: (context, snapshot) {
                            final allLogs = snapshot.data ?? const <String>[];
                            if (allLogs.isEmpty) {
                              return Center(
                                child: Text(context.tr.bot_logs_empty),
                              );
                            }

                            final sourceLogs =
                                (_visibleLimit > 0 &&
                                    allLogs.length > _visibleLimit)
                                ? allLogs.sublist(
                                    allLogs.length - _visibleLimit,
                                  )
                                : allLogs;

                            final logs = _showNewestFirst
                                ? sourceLogs.reversed.toList(growable: false)
                                : sourceLogs;

                            final textTheme = Theme.of(context).textTheme;
                            final bottomInset = MediaQuery.of(
                              context,
                            ).padding.bottom;

                            if (_rawMode) {
                              final isCompactScreen =
                                  MediaQuery.of(context).size.width < 420;
                              final compactRawFontSize = _rawFontSize < 10
                                  ? 10.0
                                  : _rawFontSize;
                              final itemH = (_rawFontSize * 1.6)
                                  .roundToDouble();
                              return GestureDetector(
                                onScaleStart: (_) {
                                  _rawFontSizeAtScaleStart = _rawFontSize;
                                },
                                onScaleUpdate: (details) {
                                  setState(() {
                                    _rawFontSize =
                                        (_rawFontSizeAtScaleStart *
                                                details.scale)
                                            .clamp(
                                              _rawFontSizeMin,
                                              _rawFontSizeMax,
                                            );
                                  });
                                },
                                child: isCompactScreen
                                    ? ListView.separated(
                                        controller: _scrollController,
                                        padding: EdgeInsets.only(
                                          top: 12,
                                          bottom: 16 + bottomInset + 64,
                                        ),
                                        itemCount: logs.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 6),
                                        itemBuilder: (context, index) {
                                          final raw = logs[index];
                                          final parsed = _parseLog(raw);
                                          final line =
                                              '${parsed.time} [${parsed.level}] ${parsed.message}';
                                          final expanded = _expandedRawLogs
                                              .contains(raw);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusMd,
                                                  ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SelectableText(
                                                  line,
                                                  maxLines: expanded ? null : 3,
                                                  style: textTheme.bodySmall
                                                      ?.copyWith(
                                                        fontFamily: 'monospace',
                                                        fontSize:
                                                            compactRawFontSize,
                                                        height: 1.35,
                                                        color: _rawLevelColor(
                                                          context,
                                                          parsed.level,
                                                          parsed.isDebug,
                                                        ),
                                                      ),
                                                ),
                                                if (!expanded &&
                                                    line.length > 140)
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _expandedRawLogs.add(
                                                            raw,
                                                          );
                                                        });
                                                      },
                                                      child: Text(
                                                        context
                                                            .tr
                                                            .bot_logs_show_more,
                                                      ),
                                                    ),
                                                  )
                                                else if (expanded)
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          _expandedRawLogs
                                                              .remove(raw);
                                                        });
                                                      },
                                                      child: Text(
                                                        context
                                                            .tr
                                                            .bot_logs_show_less,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : ListView.builder(
                                        controller: _scrollController,
                                        padding: EdgeInsets.only(
                                          top: 12,
                                          bottom: 16 + bottomInset + 64,
                                        ),
                                        itemCount: logs.length,
                                        itemExtent: itemH,
                                        itemBuilder: (context, index) {
                                          final raw = logs[index];
                                          final parsed = _parseLog(raw);
                                          return Text(
                                            '${parsed.time} [${parsed.level}] ${parsed.message}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  fontFamily: 'monospace',
                                                  fontSize: _rawFontSize,
                                                  height: 1.3,
                                                  color: _rawLevelColor(
                                                    context,
                                                    parsed.level,
                                                    parsed.isDebug,
                                                  ),
                                                ),
                                          );
                                        },
                                      ),
                              );
                            }

                            return ListView.separated(
                              controller: _scrollController,
                              padding: EdgeInsets.only(
                                top: 12,
                                bottom: 16 + bottomInset + 64,
                              ),
                              itemCount: logs.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final raw = logs[index];
                                final parsed = _parseLog(raw);
                                final displayMessage = _formatMessageForDisplay(
                                  parsed.message,
                                );
                                final isExpanded = _expandedLogs.contains(raw);
                                final shouldCollapse =
                                    displayMessage.length > _collapseThreshold;
                                final visibleMessage =
                                    shouldCollapse && !isExpanded
                                    ? '${displayMessage.substring(0, _collapseThreshold)}…'
                                    : displayMessage;

                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          _Badge(
                                            text: parsed.time,
                                            background: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            foreground: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          _Badge(
                                            text: parsed.level,
                                            background: _levelBackground(
                                              context,
                                              parsed.level,
                                              parsed.isDebug,
                                            ),
                                            foreground: _levelForeground(
                                              context,
                                              parsed.level,
                                              parsed.isDebug,
                                            ),
                                          ),
                                          if (parsed.logger.isNotEmpty) ...[
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                parsed.logger,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: textTheme.labelMedium,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      SelectableText(
                                        visibleMessage,
                                        style: textTheme.bodyMedium?.copyWith(
                                          fontFamily: 'monospace',
                                          height: 1.35,
                                        ),
                                      ),
                                      if (shouldCollapse)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                if (isExpanded) {
                                                  _expandedLogs.remove(raw);
                                                } else {
                                                  _expandedLogs.add(raw);
                                                }
                                              });
                                            },
                                            icon: Icon(
                                              isExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                            ),
                                            label: Text(
                                              isExpanded
                                                  ? context
                                                        .tr
                                                        .bot_logs_show_less
                                                  : context
                                                        .tr
                                                        .bot_logs_show_more,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        heroTag: null,
        tooltip: _showNewestFirst
            ? context.tr.bot_logs_go_to_latest
            : context.tr.bot_logs_go_to_bottom,
        onPressed: _jumpToEdge,
        child: Icon(
          _showNewestFirst
              ? Icons.vertical_align_top
              : Icons.vertical_align_bottom,
        ),
      ),
    );
  }

  _ParsedLog _parseLog(String raw) {
    final source = _stripAnsi(raw).trimLeft();
    final runnerIsoMatch = RegExp(
      r'^\[(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z)\]\s*\[([^\]]+)\]\s*([^:]+):\s*(.*)$',
    ).firstMatch(source);
    if (runnerIsoMatch != null) {
      final isoRaw = runnerIsoMatch.group(1) ?? '';
      final level = (runnerIsoMatch.group(2) ?? 'LOG').trim();
      final logger = (runnerIsoMatch.group(3) ?? '').trim();
      final message = (runnerIsoMatch.group(4) ?? '').trimLeft();
      final parsedIso = DateTime.tryParse(isoRaw)?.toLocal();
      final time = parsedIso == null
          ? '--:--:--'
          : '${parsedIso.hour.toString().padLeft(2, '0')}:${parsedIso.minute.toString().padLeft(2, '0')}:${parsedIso.second.toString().padLeft(2, '0')}';
      return _ParsedLog(
        time: time,
        level: level,
        logger: logger,
        message: message,
        isDebug: level.toUpperCase() == 'DEBUG',
      );
    }

    final timeMatch = RegExp(
      r'\[\s*(\d{1,2})\s*:\s*(\d{2})\s*:\s*(\d{2})(?:\s*\.\s*\d+)?\s*\]',
    ).firstMatch(source);
    if (timeMatch == null) {
      return _ParsedLog(
        time: '--:--:--',
        level: 'LOG',
        logger: '',
        message: source,
        isDebug: false,
      );
    }

    final hours = (timeMatch.group(1) ?? '--').padLeft(2, '0');
    final minutes = timeMatch.group(2) ?? '--';
    final seconds = timeMatch.group(3) ?? '--';
    final time = '$hours:$minutes:$seconds';
    var rest = source.substring(timeMatch.end).trimLeft();

    final isDebug = RegExp(r'^DEBUG\s*:', caseSensitive: false).hasMatch(rest);
    if (isDebug) {
      rest = rest.replaceFirst(RegExp(r'^DEBUG\s*:', caseSensitive: false), '');
      rest = rest.trimLeft();
    }

    var cursor = 0;
    while (cursor < rest.length && rest[cursor] == ' ') {
      cursor++;
    }

    final levelToken = _readBracketToken(rest, cursor);
    if (levelToken != null) {
      cursor = levelToken.end;
      while (cursor < rest.length && rest[cursor] == ' ') {
        cursor++;
      }

      final loggerToken = _readBracketToken(rest, cursor);
      if (loggerToken != null) {
        cursor = loggerToken.end;
        while (cursor < rest.length && rest[cursor] == ' ') {
          cursor++;
        }

        return _ParsedLog(
          time: time,
          level: levelToken.value.trim(),
          logger: loggerToken.value.trim(),
          message: rest.substring(cursor),
          isDebug: isDebug,
        );
      }

      return _ParsedLog(
        time: time,
        level: levelToken.value.trim(),
        logger: '',
        message: rest.substring(cursor).trimLeft(),
        isDebug: isDebug,
      );
    }

    return _ParsedLog(
      time: time,
      level: isDebug ? 'DEBUG' : 'LOG',
      logger: '',
      message: rest,
      isDebug: isDebug,
    );
  }

  String _stripAnsi(String input) {
    return input.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');
  }

  _BracketToken? _readBracketToken(String source, int start) {
    if (start < 0 || start >= source.length || source[start] != '[') {
      return null;
    }

    final token = StringBuffer();
    var depth = 0;

    for (var index = start; index < source.length; index++) {
      final char = source[index];

      if (char == '[') {
        if (depth > 0) {
          token.write(char);
        }
        depth++;
        continue;
      }

      if (char == ']') {
        depth--;
        if (depth == 0) {
          return _BracketToken(value: token.toString(), end: index + 1);
        }
        if (depth < 0) {
          return null;
        }
        token.write(char);
        continue;
      }

      if (depth > 0) {
        token.write(char);
      }
    }

    return null;
  }

  String _formatMessageForDisplay(String message) {
    if (message.length < 40) {
      return message;
    }

    final firstOpenBrace = message.indexOf('{');
    final lastCloseBrace = message.lastIndexOf('}');
    if (firstOpenBrace == -1 ||
        lastCloseBrace == -1 ||
        lastCloseBrace <= firstOpenBrace) {
      return message;
    }

    final prefix = message.substring(0, firstOpenBrace).trimRight();
    final structured = message.substring(firstOpenBrace, lastCloseBrace + 1);
    final suffix = message.substring(lastCloseBrace + 1).trimLeft();

    final prettyStructured = _prettyStructuredText(structured);
    final parts = <String>[];
    if (prefix.isNotEmpty) {
      parts.add(prefix);
    }
    parts.add(prettyStructured);
    if (suffix.isNotEmpty) {
      parts.add(suffix);
    }

    return parts.join('\n');
  }

  String _prettyStructuredText(String input) {
    final out = StringBuffer();
    var indent = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var escaping = false;

    void writeIndent() {
      out.write('  ' * indent);
    }

    for (var index = 0; index < input.length; index++) {
      final char = input[index];

      if (escaping) {
        out.write(char);
        escaping = false;
        continue;
      }

      if (char == r'\') {
        out.write(char);
        escaping = true;
        continue;
      }

      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        out.write(char);
        continue;
      }

      if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        out.write(char);
        continue;
      }

      if (inSingleQuote || inDoubleQuote) {
        out.write(char);
        continue;
      }

      if (char == '{' || char == '[') {
        out.write(char);
        indent++;
        out.write('\n');
        writeIndent();
        continue;
      }

      if (char == '}' || char == ']') {
        if (indent > 0) {
          indent--;
        }

        final current = out.toString();
        if (!current.endsWith('\n')) {
          out.write('\n');
        }
        writeIndent();
        out.write(char);
        continue;
      }

      if (char == ',') {
        out.write(char);
        out.write('\n');
        writeIndent();
        continue;
      }

      out.write(char);
    }

    return out.toString().replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  Color _rawLevelColor(BuildContext context, String level, bool isDebug) {
    final scheme = Theme.of(context).colorScheme;
    final upper = level.toUpperCase();
    if (upper == 'SEVERE' || upper == 'ERROR') {
      return scheme.error;
    }
    if (upper == 'WARNING' || upper == 'WARN') {
      return scheme.tertiary;
    }
    if (isDebug || upper == 'FINE' || upper == 'FINER' || upper == 'FINEST') {
      return scheme.onSurface.withValues(alpha: 0.55);
    }
    return scheme.onSurface.withValues(alpha: 0.85);
  }

  Color _levelBackground(BuildContext context, String level, bool isDebug) {
    final scheme = Theme.of(context).colorScheme;
    final upper = level.toUpperCase();
    if (upper == 'SEVERE' || upper == 'ERROR') {
      return scheme.errorContainer;
    }
    if (upper == 'WARNING' || upper == 'WARN') {
      return scheme.tertiaryContainer;
    }
    if (upper == 'INFO') {
      return scheme.primaryContainer;
    }
    if (isDebug || upper == 'FINE' || upper == 'FINER' || upper == 'FINEST') {
      return scheme.secondaryContainer;
    }
    return scheme.surfaceContainerHighest;
  }

  Color _levelForeground(BuildContext context, String level, bool isDebug) {
    final scheme = Theme.of(context).colorScheme;
    final upper = level.toUpperCase();
    if (upper == 'SEVERE' || upper == 'ERROR') {
      return scheme.onErrorContainer;
    }
    if (upper == 'WARNING' || upper == 'WARN') {
      return scheme.onTertiaryContainer;
    }
    if (upper == 'INFO') {
      return scheme.onPrimaryContainer;
    }
    if (isDebug || upper == 'FINE' || upper == 'FINER' || upper == 'FINEST') {
      return scheme.onSecondaryContainer;
    }
    return scheme.onSurfaceVariant;
  }
}

/// Métriques mémorisées d'un tick à l'autre, réduites à la précision affichée :
/// l'égalité structurelle des « records » suffit à détecter un changement, sans
/// requête supplémentaire ni comparaison champ par champ.
typedef _MetricsSnapshot = ({
  bool running,
  int? rssMb,
  int? estimatedRssMb,
  int? cpuBucket,
  int? storageMb,
});

class _ParsedLog {
  const _ParsedLog({
    required this.time,
    required this.level,
    required this.logger,
    required this.message,
    required this.isDebug,
  });

  final String time;
  final String level;
  final String logger;
  final String message;
  final bool isDebug;
}

class _BracketToken {
  const _BracketToken({required this.value, required this.end});

  final String value;
  final int end;
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
