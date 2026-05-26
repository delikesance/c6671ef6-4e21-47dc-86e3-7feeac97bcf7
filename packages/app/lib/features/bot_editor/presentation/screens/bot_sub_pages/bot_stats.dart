import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bot_creator/features/bot_editor/logic/bot.dart';

import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class BotStatsPage extends StatefulWidget {
  const BotStatsPage({super.key, this.botId});

  final String? botId;

  @override
  State<BotStatsPage> createState() => _BotStatsPageState();
}

class _BotStatsPageState extends State<BotStatsPage> {
  static const int _maxPoints = 40;
  String? _selectedBotId;
  Map<String, String> _botNamesById = const <String, String>{};

  final List<double> _ramHistory = <double>[];
  final List<double> _ramEstimatedHistory = <double>[];
  final List<double> _cpuHistory = <double>[];
  final List<double> _storageHistory = <double>[];

  StreamSubscription<int?>? _rssSub;
  StreamSubscription<int?>? _rssEstimatedSub;
  StreamSubscription<double?>? _cpuSub;
  StreamSubscription<int?>? _storageSub;
  Timer? _statsPollTimer;

  RemoteRuntimeClient? _runtimeClient;
  RemoteRuntimeSource _runtimeSource = RemoteRuntimeSource.local;
  bool _syncInFlight = false;
  String? _runtimeLabel;
  String? _runtimeUnavailableReason;

  int? _rssBytes;
  int? _rssEstimatedBytes;
  double? _cpuPercent;
  int? _storageBytes;

  bool get _supportsManagerRuntime =>
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.macOS;

  bool get _usingRemoteMetrics => _runtimeSource != RemoteRuntimeSource.local;

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
            ? context.tr.runner_source_label(_runtimeLabel!)
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
    _selectedBotId = widget.botId;
    unawaited(_loadBotNamesById());
    captureBotBaselineRss(force: false);
    _rssBytes = getBotProcessRssBytesForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    );
    _rssEstimatedBytes = getBotEstimatedRssBytesForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    );
    _cpuPercent = getBotProcessCpuPercentForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    );
    _storageBytes = getBotProcessStorageBytesForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    );

    unawaited(_initializeStatsSync());

    _pushMetric(_ramHistory, _rssBytes?.toDouble());
    _pushMetric(_ramEstimatedHistory, _rssEstimatedBytes?.toDouble());
    _pushMetric(_cpuHistory, _cpuPercent);
    _pushMetric(_storageHistory, _storageBytes?.toDouble());

    _subscribeMetricStreams();
  }

  Future<void> _loadBotNamesById() async {
    final namesById = await getKnownBotNamesById();
    if (!mounted) {
      return;
    }
    setState(() {
      _botNamesById = namesById;
    });
  }

  Future<void> _initializeStatsSync() async {
    final runtime = await resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: _selectedBotId,
      getTimeout: const Duration(seconds: 30),
      postTimeout: const Duration(seconds: 90),
    );
    _runtimeClient = runtime.client;
    _runtimeSource = runtime.source;
    if (!mounted) {
      return;
    }

    setState(() {
      _runtimeLabel = runtime.detailLabel;
      _runtimeUnavailableReason = runtime.unavailableReason;
      _rssBytes = getBotProcessRssBytesForBotFromSource(
        _selectedBotId,
        source: _runtimeSource,
      );
      _rssEstimatedBytes = getBotEstimatedRssBytesForBotFromSource(
        _selectedBotId,
        source: _runtimeSource,
      );
      _cpuPercent = getBotProcessCpuPercentForBotFromSource(
        _selectedBotId,
        source: _runtimeSource,
      );
      _storageBytes = getBotProcessStorageBytesForBotFromSource(
        _selectedBotId,
        source: _runtimeSource,
      );
    });
    _subscribeMetricStreams();

    await _syncMetricsTick();
    _statsPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_syncMetricsTick());
    });
  }

  bool get _isCurrentBotRunning {
    final botId = _selectedBotId;
    if (botId == null || botId.trim().isEmpty) {
      return isBotRuntimeActive;
    }
    return isDesktopBotRunningId(botId) ||
        isMobileBotRunning(botId) ||
        (_usingRemoteMetrics && _rssBytes != null && _rssBytes! > 0);
  }

  Future<void> _syncMetricsTick() async {
    if (_syncInFlight) {
      return;
    }
    if (mounted) {
      setState(() {
        _syncInFlight = true;
      });
    } else {
      _syncInFlight = true;
    }

    try {
      final client = _runtimeClient;
      if (client != null) {
        try {
          final metrics = await client.getMetrics(botId: _selectedBotId);
          final runtimeBotId = _selectedBotId ?? metrics.activeBotId;
          final isRunningForSelectedBot =
              runtimeBotId == null
                  ? metrics.running
                  : metrics.bots.any(
                    (bot) => bot.botId == runtimeBotId && bot.isRunning,
                  );
          updateBotRuntimeMetricsFromRemote(
            running: isRunningForSelectedBot,
            botId: runtimeBotId,
            source: _runtimeSource,
            rssBytes: metrics.rssBytes,
            estimatedRssBytes: metrics.botEstimatedRssBytes,
            cpuPercent: metrics.cpuPercent,
            storageBytes: metrics.storageBytes,
          );
          return;
        } catch (_) {
          return;
        }
      }

      if (_runtimeSource == RemoteRuntimeSource.manager) {
        return;
      }

      await refreshBotStatsNow(botId: _selectedBotId, source: _runtimeSource);
    } finally {
      if (mounted) {
        setState(() {
          _syncInFlight = false;
        });
      } else {
        _syncInFlight = false;
      }
    }
  }

  @override
  void dispose() {
    _statsPollTimer?.cancel();
    _rssSub?.cancel();
    _rssEstimatedSub?.cancel();
    _cpuSub?.cancel();
    _storageSub?.cancel();
    super.dispose();
  }

  void _pushMetric(List<double> target, double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return;
    }
    target.add(value);
    if (target.length > _maxPoints) {
      target.removeAt(0);
    }
  }

  void _subscribeMetricStreams() {
    _rssSub?.cancel();
    _rssEstimatedSub?.cancel();
    _cpuSub?.cancel();
    _storageSub?.cancel();

    _rssSub = getBotProcessRssStreamForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    ).listen((value) {
      if (!mounted) return;
      setState(() {
        _rssBytes = value;
        _pushMetric(_ramHistory, value?.toDouble());
      });
    });

    _rssEstimatedSub = getBotEstimatedRssStreamForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    ).listen((value) {
      if (!mounted) return;
      setState(() {
        _rssEstimatedBytes = value;
        _pushMetric(_ramEstimatedHistory, value?.toDouble());
      });
    });

    _cpuSub = getBotProcessCpuStreamForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    ).listen((value) {
      if (!mounted) return;
      setState(() {
        _cpuPercent = value;
        _pushMetric(_cpuHistory, value);
      });
    });

    _storageSub = getBotProcessStorageStreamForBotFromSource(
      _selectedBotId,
      source: _runtimeSource,
    ).listen((value) {
      if (!mounted) return;
      setState(() {
        _storageBytes = value;
        _pushMetric(_storageHistory, value?.toDouble());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final knownBotIds = getKnownBotLogIds().toList(growable: false)..sort();
    final canSelectBot = knownBotIds.length > 1;

    return Scaffold(
      appBar: AppTheme.brandAppBar(
        title: context.tr.bot_stats_title,
        bottom: _syncInFlight
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (canSelectBot)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedBotId,
                          decoration: InputDecoration(
                            labelText: context.tr.common_bot,
                            prefixIcon: const Icon(Icons.smart_toy_outlined),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
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
                              _rssBytes = getBotProcessRssBytesForBotFromSource(
                                value,
                                source: _runtimeSource,
                              );
                              _rssEstimatedBytes =
                                  getBotEstimatedRssBytesForBotFromSource(
                                    value,
                                    source: _runtimeSource,
                                  );
                              _cpuPercent = getBotProcessCpuPercentForBotFromSource(
                                value,
                                source: _runtimeSource,
                              );
                              _storageBytes = getBotProcessStorageBytesForBotFromSource(
                                value,
                                source: _runtimeSource,
                              );
                              _ramHistory.clear();
                              _ramEstimatedHistory.clear();
                              _cpuHistory.clear();
                              _storageHistory.clear();
                              _pushMetric(_ramHistory, _rssBytes?.toDouble());
                              _pushMetric(
                                _ramEstimatedHistory,
                                _rssEstimatedBytes?.toDouble(),
                              );
                              _pushMetric(_cpuHistory, _cpuPercent);
                              _pushMetric(_storageHistory, _storageBytes?.toDouble());
                            });
                            _subscribeMetricStreams();
                            unawaited(_syncMetricsTick());
                          },
                        ),
                      ),
                    _buildHeaderCard(context),
                    _buildMetricsLayout(context, constraints),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _usingRemoteMetrics
                            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.12)
                            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: _usingRemoteMetrics
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _usingRemoteMetrics ? Icons.dns_outlined : Icons.lan,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _uiCopy(fr: 'Source des métriques', en: 'Metrics Source'),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _runtimeSourceLabel(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_runtimeUnavailableReason?.trim().isNotEmpty ?? false) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(
                            color: AppTheme.warning.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppTheme.warning,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _uiCopy(fr: 'Avertissement', en: 'Warning'),
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _runtimeUnavailableReason!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      context.tr.bot_stats_notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final isRunning = _isCurrentBotRunning;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String statusText = isRunning
        ? _uiCopy(fr: 'En ligne', en: 'Online')
        : _uiCopy(fr: 'Hors ligne', en: 'Offline');
    final Color statusColor = isRunning ? AppTheme.successLight : AppTheme.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: isRunning
            ? LinearGradient(
                colors: [
                  AppTheme.brandPrimary.withValues(alpha: isDark ? 0.15 : 0.08),
                  AppTheme.brandSecondary.withValues(alpha: isDark ? 0.05 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isRunning ? null : (isDark ? AppTheme.darkSurface : theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isRunning
              ? AppTheme.brandPrimary.withValues(alpha: 0.25)
              : theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          _PulsingStatusDot(color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedBotId != null
                      ? (_botNamesById[_selectedBotId] ?? _selectedBotId!)
                      : _uiCopy(fr: 'Aucun robot sélectionné', en: 'No bot selected'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      statusText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: TextStyle(color: theme.colorScheme.outline, fontSize: 8),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _runtimeSourceLabel(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            icon: Icon(
              Icons.refresh,
              color: theme.colorScheme.primary,
            ),
            onPressed: _syncInFlight ? null : () => unawaited(_syncMetricsTick()),
            tooltip: _uiCopy(fr: 'Rafraîchir maintenant', en: 'Refresh now'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsLayout(BuildContext context, BoxConstraints constraints) {
    final double width = constraints.maxWidth;

    final cards = [
      _MetricCard(
        title: context.tr.bot_stats_ram_process,
        value: _formatBytes(_rssBytes),
        icon: Icons.memory,
        history: _ramHistory,
        color: AppTheme.brandPrimary,
        valueFormatter: (v) => _formatBytes(v.toInt()),
      ),
      _MetricCard(
        title: context.tr.bot_stats_ram_estimated,
        value: _formatBytes(_rssEstimatedBytes),
        icon: Icons.auto_graph,
        history: _ramEstimatedHistory,
        color: AppTheme.brandSecondary,
        valueFormatter: (v) => _formatBytes(v.toInt()),
        subtitle: _formatBaselineText(),
      ),
      _MetricCard(
        title: context.tr.bot_stats_cpu,
        value: _formatCpu(_cpuPercent),
        icon: Icons.speed,
        history: _cpuHistory,
        color: AppTheme.syntaxCyan,
        valueFormatter: (v) => _formatCpu(v),
      ),
      _MetricCard(
        title: context.tr.bot_stats_storage,
        value: _formatBytes(_storageBytes),
        icon: Icons.storage,
        history: _storageHistory,
        color: AppTheme.warning,
        valueFormatter: (v) => _formatBytes(v.toInt()),
      ),
    ];

    if (width > 1000) {
      // 4 Columns for wide desktop monitors, all 4 cards sit on a single row!
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95, // Near square / slightly portrait proportions
        children: cards,
      );
    } else if (width > 600) {
      // 2 Columns for tablet/medium desktop viewports
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.4,
        children: cards,
      );
    } else {
      // 1 Column stacked list for narrow mobile viewports
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cards.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => cards[index],
      );
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes < 0) {
      return 'N/A';
    }

    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex++;
    }
    return '${value.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }

  String _formatCpu(double? cpu) {
    if (cpu == null || cpu.isNaN || cpu.isInfinite) {
      return 'N/A';
    }
    return '${cpu.toStringAsFixed(1)} %';
  }

  String? _formatBaselineText() {
    final baseline = getBotBaselineRssBytes();
    if (baseline == null) {
      return null;
    }
    final capturedAt = getBotBaselineCapturedAt();
    final time =
        capturedAt == null
            ? ''
            : ' • ${capturedAt.hour.toString().padLeft(2, '0')}:${capturedAt.minute.toString().padLeft(2, '0')}:${capturedAt.second.toString().padLeft(2, '0')}';
    return 'Baseline: ${_formatBytes(baseline)}$time';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.history,
    required this.color,
    required this.valueFormatter,
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<double> history;
  final Color color;
  final String Function(double) valueFormatter;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.4),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (history.isNotEmpty)
                _buildTrendChip(context, history, color) ?? const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 75,
            child: _InteractiveChart(
              values: history,
              color: color,
              valueFormatter: valueFormatter,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTrendChip(BuildContext context, List<double> history, Color accentColor) {
    if (history.length < 2) return null;
    final current = history.last;
    final previous = history[history.length - 2];
    if (previous == 0) return null;
    final change = ((current - previous) / previous) * 100;

    if (change.abs() < 0.05) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.trending_flat, size: 10, color: Colors.grey),
            const SizedBox(width: 2),
            Text(
              '0.0%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final isUp = change > 0;
    final isUpwardHeavy = title.contains('RAM') || title.contains('CPU');
    final isGood = isUpwardHeavy ? !isUp : isUp;
    
    final color = isGood ? AppTheme.successLight : AppTheme.errorLight;
    final bgColor = isGood ? AppTheme.successLight.withValues(alpha: 0.12) : AppTheme.errorLight.withValues(alpha: 0.12);
    final icon = isUp ? Icons.arrow_upward : Icons.arrow_downward;
    final sign = isUp ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '$sign${change.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveChart extends StatefulWidget {
  const _InteractiveChart({
    required this.values,
    required this.color,
    required this.valueFormatter,
  });

  final List<double> values;
  final Color color;
  final String Function(double) valueFormatter;

  @override
  State<_InteractiveChart> createState() => _InteractiveChartState();
}

class _InteractiveChartState extends State<_InteractiveChart> with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.values.length < 2) {
      return Container(
        alignment: Alignment.centerLeft,
        child: Text(
          context.tr.bot_stats_collecting,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (details) => _updateTouch(details.localPosition, constraints.maxWidth),
          onHorizontalDragUpdate: (details) => _updateTouch(details.localPosition, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _clearTouch(),
          onTapDown: (details) => _updateTouch(details.localPosition, constraints.maxWidth),
          onTapUp: (_) => _clearTouch(),
          onTapCancel: () => _clearTouch(),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ChartPainter(
                  values: widget.values,
                  color: widget.color,
                  selectedIndex: _selectedIndex,
                  pulseProgress: _pulseController.value,
                  valueFormatter: widget.valueFormatter,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      },
    );
  }

  void _updateTouch(Offset localPosition, double width) {
    final values = widget.values;
    if (values.isEmpty) return;

    final double xPercent = (localPosition.dx / width).clamp(0.0, 1.0);
    final int index = (xPercent * (values.length - 1)).round().clamp(0, values.length - 1);

    setState(() {
      _selectedIndex = index;
    });
  }

  void _clearTouch() {
    setState(() {
      _selectedIndex = null;
    });
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.color,
    required this.selectedIndex,
    required this.pulseProgress,
    required this.valueFormatter,
  });

  final List<double> values;
  final Color color;
  final int? selectedIndex;
  final double pulseProgress;
  final String Function(double) valueFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final double gridPadding = 6.0;
    final double graphHeight = size.height - (gridPadding * 2);

    for (int i = 1; i <= 3; i++) {
      final double y = gridPadding + (graphHeight * (i / 4.0));
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint, 4.0, 4.0);
    }

    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final norm = (values[i] - minV) / range;
      final y = size.height - gridPadding - (norm * graphHeight);
      points.add(Offset(x, y));
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      fillPath.lineTo(points[i].dx, points[i].dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [color.withValues(alpha: 0.20), color.withValues(alpha: 0.0)],
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePath = Path()
      ..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      strokePath.lineTo(points[i].dx, points[i].dy);
    }

    final strokePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(size.width, 0),
        [color, color.withValues(alpha: 0.7)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(strokePath, strokePaint);

    if (selectedIndex != null && selectedIndex! < points.length) {
      final activePoint = points[selectedIndex!];

      final trackingPaint = Paint()
        ..color = color.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      _drawDashedLine(canvas, Offset(activePoint.dx, 0), Offset(activePoint.dx, size.height), trackingPaint, 3.0, 3.0);

      final haloPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 8.0, haloPaint);

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(activePoint, 4.0, dotPaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(activePoint, 4.0, borderPaint);

      final String formattedVal = valueFormatter(values[selectedIndex!]);
      final tp = TextPainter(
        text: TextSpan(
          text: formattedVal,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final double tooltipW = tp.width + 16;
      final double tooltipH = tp.height + 8;
      
      double tooltipX = (activePoint.dx - tooltipW / 2).clamp(4.0, size.width - tooltipW - 4.0);
      double tooltipY = (activePoint.dy - tooltipH - 10).clamp(2.0, size.height - tooltipH - 2.0);

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tooltipX, tooltipY, tooltipW, tooltipH),
        const Radius.circular(6),
      );

      final tooltipShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRRect(rrect.shift(const Offset(0, 1.5)), tooltipShadowPaint);

      final tooltipPaint = Paint()
        ..color = const Color(0xFF1E1E2C)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rrect, tooltipPaint);

      final tooltipBorderPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRRect(rrect, tooltipBorderPaint);

      tp.paint(canvas, Offset(tooltipX + 8, tooltipY + 4));

    } else {
      final lastPoint = points.last;
      
      final pulsePaint = Paint()
        ..color = color.withValues(alpha: 0.4 * (1.0 - pulseProgress))
        ..style = PaintingStyle.fill;
      final double pulseRadius = 3.5 + (pulseProgress * 6.5);
      canvas.drawCircle(lastPoint, pulseRadius, pulsePaint);

      final corePaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 3.5, corePaint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(lastPoint, 3.5, borderPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, double dashLength, double gapLength) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final direction = Offset(dx / length, dy / length);
    
    double currentLength = 0;
    while (currentLength < length) {
      final dashStart = start + direction * currentLength;
      final nextLength = math.min(currentLength + dashLength, length);
      final dashEnd = start + direction * nextLength;
      canvas.drawLine(dashStart, dashEnd, paint);
      currentLength += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

class _PulsingStatusDot extends StatefulWidget {
  const _PulsingStatusDot({required this.color});
  final Color color;

  @override
  State<_PulsingStatusDot> createState() => _PulsingStatusDotState();
}

class _PulsingStatusDotState extends State<_PulsingStatusDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(20, 20),
          painter: _PulsingDotPainter(
            color: widget.color,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _PulsingDotPainter extends CustomPainter {
  _PulsingDotPainter({required this.color, required this.progress});
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paintPulse = Paint()
      ..color = color.withValues(alpha: 0.45 * (1.0 - progress))
      ..style = PaintingStyle.fill;
    final pulseRadius = 4.0 + (progress * 6.5);
    canvas.drawCircle(center, pulseRadius, paintPulse);

    final paintDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.0, paintDot);
  }

  @override
  bool shouldRepaint(covariant _PulsingDotPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.progress != progress;
  }
}
