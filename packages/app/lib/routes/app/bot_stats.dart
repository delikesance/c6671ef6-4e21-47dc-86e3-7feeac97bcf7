import 'dart:io';
import 'dart:async';

import 'package:bot_creator/utils/bot.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/remote_runtime.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/utils/app_theme.dart';

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

  bool get _supportsManagerRuntime => Platform.isAndroid || Platform.isIOS;

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

  Future<void> _syncMetricsTick() async {
    if (_syncInFlight) {
      return;
    }
    _syncInFlight = true;

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
      _syncInFlight = false;
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
      appBar: AppBar(title: Text(context.tr.bot_stats_title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (canSelectBot)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedBotId,
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
            _MetricCard(
              title: context.tr.bot_stats_ram_process,
              value: _formatBytes(_rssBytes),
              icon: Icons.memory,
              history: _ramHistory,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: context.tr.bot_stats_ram_estimated,
              value: _formatBytes(_rssEstimatedBytes),
              icon: Icons.auto_graph,
              history: _ramEstimatedHistory,
              subtitle: _formatBaselineText(),
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: context.tr.bot_stats_cpu,
              value: _formatCpu(_cpuPercent),
              icon: Icons.speed,
              history: _cpuHistory,
            ),
            const SizedBox(height: 12),
            _MetricCard(
              title: context.tr.bot_stats_storage,
              value: _formatBytes(_storageBytes),
              icon: Icons.storage,
              history: _storageHistory,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color:
                    _usingRemoteMetrics
                        ? Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    _usingRemoteMetrics ? Icons.dns_outlined : Icons.lan,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _runtimeSourceLabel(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            _usingRemoteMetrics
                                ? Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer
                                : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_runtimeUnavailableReason?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
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
                      Icons.info_outline,
                      color: AppTheme.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _runtimeUnavailableReason!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              context.tr.bot_stats_notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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
    this.subtitle,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<double> history;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(height: 40, child: _Sparkline(values: history)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return Container(
        alignment: Alignment.centerLeft,
        child: Text(
          context.tr.bot_stats_collecting,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final norm = (values[i] - minV) / range;
      final y = size.height - (norm * (size.height - 2)) - 1;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final area =
        Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

    final fillPaint =
        Paint()
          ..color = color.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill;
    canvas.drawPath(area, fillPaint);

    final stroke =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
