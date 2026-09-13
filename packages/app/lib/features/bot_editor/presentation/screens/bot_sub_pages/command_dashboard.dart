import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bot_creator/core/storage/database.dart';

import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/core/utils/responsive.dart';

enum _DashboardStatsSource { local, manager, runner }

final AppManager _appManager = AppManager();

class CommandDashboardPage extends StatefulWidget {
  const CommandDashboardPage({super.key, required this.botId});

  final String botId;

  @override
  State<CommandDashboardPage> createState() => _CommandDashboardPageState();
}

class _CommandDashboardPageState extends State<CommandDashboardPage> {
  RemoteRuntimeClient? _client;
  bool _loading = true;
  bool _refreshingSources = false;
  String? _error;
  _DashboardStatsSource _source = _DashboardStatsSource.local;

  late DateTime _startDate;
  late DateTime _endDate;

  int _totalAllTime = 0;
  List<_CommandCount> _commands = const [];
  List<_TimelineEntry> _timeline = const [];
  List<_LocaleCount> _locales = const [];
  int _failedInPeriod = 0;
  double _errorRatePct = 0;
  int _p50LatencyMs = 0;
  int _p95LatencyMs = 0;

  List<RunnerConnectionConfig> _runners = const [];
  String? _activeRunnerId;
  bool _hasManagerSource = false;
  String? _managerUnavailableReason;

  bool get _supportsManagerRuntime =>
      !kIsWeb &&
      defaultTargetPlatform != TargetPlatform.windows &&
      defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(hours: 24));
    _endDate = DateTime.now();
    unawaited(_init());
  }

  Future<void> _init() async {
    await _refreshSources(refetchStats: false, preserveSelection: false);
    await _fetchStats();
  }

  String _managerSourceLabel() {
    return context.tr.runner_source_manager;
  }

  String _managerUnavailableMessage() {
    return _managerUnavailableReason ??
        context.tr.runner_source_manager_unavailable;
  }

  Future<void> _refreshSources({
    bool refetchStats = true,
    bool preserveSelection = true,
  }) async {
    setState(() {
      _refreshingSources = true;
    });

    final runners = await RunnerSettings.getRunners();
    final config = await RunnerSettings.getConfig();
    final runtime = await resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: widget.botId,
    );
    if (!mounted) return;

    final hasManagerSource = runtime.source == RemoteRuntimeSource.manager;
    var nextSource = preserveSelection
        ? _source
        : switch (runtime.source) {
            RemoteRuntimeSource.manager => _DashboardStatsSource.manager,
            RemoteRuntimeSource.runner => _DashboardStatsSource.runner,
            RemoteRuntimeSource.local => _DashboardStatsSource.local,
          };
    var nextActiveRunnerId = preserveSelection ? _activeRunnerId : config?.id;

    if (nextSource == _DashboardStatsSource.manager && !hasManagerSource) {
      nextSource = config == null
          ? _DashboardStatsSource.local
          : _DashboardStatsSource.runner;
      nextActiveRunnerId = config?.id;
    }

    if (nextSource == _DashboardStatsSource.runner) {
      final selectedRunner = runners
          .where((runner) => runner.id == nextActiveRunnerId)
          .firstOrNull;
      if (selectedRunner == null) {
        if (config != null && runners.any((runner) => runner.id == config.id)) {
          nextActiveRunnerId = config.id;
        } else if (hasManagerSource) {
          nextSource = _DashboardStatsSource.manager;
          nextActiveRunnerId = null;
        } else {
          nextSource = _DashboardStatsSource.local;
          nextActiveRunnerId = null;
        }
      }
    }

    RemoteRuntimeClient? nextClient;
    switch (nextSource) {
      case _DashboardStatsSource.local:
        nextClient = null;
        break;
      case _DashboardStatsSource.manager:
        nextClient = runtime.source == RemoteRuntimeSource.manager
            ? runtime.client
            : null;
        break;
      case _DashboardStatsSource.runner:
        final runner =
            runners
                .where((candidate) => candidate.id == nextActiveRunnerId)
                .firstOrNull ??
            (config != null &&
                    runners.any((candidate) => candidate.id == config.id)
                ? config
                : null);
        if (runner == null) {
          nextSource = hasManagerSource
              ? _DashboardStatsSource.manager
              : _DashboardStatsSource.local;
          nextActiveRunnerId = null;
          nextClient = nextSource == _DashboardStatsSource.manager
              ? runtime.client
              : null;
        } else {
          nextActiveRunnerId = runner.id;
          nextClient = runner.createClient();
        }
        break;
    }

    setState(() {
      _runners = runners;
      _activeRunnerId = nextActiveRunnerId;
      _source = nextSource;
      _hasManagerSource = hasManagerSource;
      _managerUnavailableReason = hasManagerSource
          ? runtime.unavailableReason
          : null;
      _refreshingSources = false;
    });
    _client = nextClient;

    if (refetchStats) {
      await _fetchStats();
    }
  }

  Future<void> _switchSource(String sourceId) async {
    if (sourceId == 'local') {
      setState(() {
        _source = _DashboardStatsSource.local;
        _loading = true;
        _error = null;
      });
      await _refreshSources();
      return;
    }

    if (sourceId == 'manager') {
      setState(() {
        _source = _DashboardStatsSource.manager;
        _activeRunnerId = null;
        _loading = true;
        _error = null;
      });
      await _refreshSources();
      return;
    }

    final runnerId = sourceId;
    final runner = _runners.where((r) => r.id == runnerId).firstOrNull;
    if (runner == null) return;
    setState(() {
      _source = _DashboardStatsSource.runner;
      _activeRunnerId = runnerId;
      _loading = true;
      _error = null;
    });
    _client = runner.createClient();
    await _refreshSources();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> json;
      if (_source == _DashboardStatsSource.local) {
        json = await _appManager.getLocalCommandStats(
          widget.botId,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else {
        final client = _client;
        if (client == null) {
          throw StateError(
            _source == _DashboardStatsSource.manager
                ? _managerUnavailableMessage()
                : 'Runner source selected but no active runner client.',
          );
        }
        // Always fetch the maximum 30-day window so we can filter locally.
        // This lets the date-range picker work correctly without needing the
        // runner/manager API to support arbitrary start/end timestamps.
        json = await client.getCommandStats(widget.botId, hours: 720);
      }
      if (!mounted) return;
      final rawCommands = json['commands'] as List? ?? [];
      final rawTimeline = json['timeline'] as List? ?? [];
      final rawLocales = json['locales'] as List? ?? [];
      final health = Map<String, dynamic>.from(
        (json['health'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

      // ── Local filtering of the remote timeline ─────────────────────────────
      // The runner/manager returns pre-aggregated command counts for the full
      // 30-day window (no per-command timestamps), so we can't re-filter those.
      // But the timeline entries carry epoch-hour buckets, so we CAN filter them
      // to the selected [_startDate, _endDate] range right here in the client.
      final sinceMs = _startDate.toUtc().millisecondsSinceEpoch;
      final untilMs = _endDate.toUtc().millisecondsSinceEpoch;

      setState(() {
        _totalAllTime = (json['totalAllTime'] as num?)?.toInt() ?? 0;
        _commands =
            rawCommands
                .map(
                  (e) => _CommandCount(
                    name: e['command'] as String? ?? '?',
                    count: (e['count'] as num?)?.toInt() ?? 0,
                  ),
                )
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count));

        // Build a dense hour-by-hour series for the selected period.
        // Only include timeline buckets that fall within [sinceMs, untilMs].
        final sparseMap = <int, int>{};
        for (final e in rawTimeline) {
          final bucket = int.tryParse((e['hour'] ?? '').toString());
          if (bucket == null) continue;
          final bucketMs = bucket * 3600000;
          // Filter to the selected date range
          if (bucketMs < sinceMs || bucketMs > untilMs) continue;
          sparseMap[bucket] = (e['count'] as num?)?.toInt() ?? 0;
        }
        final startBucket = sinceMs ~/ 3600000;
        final endBucket = untilMs ~/ 3600000;
        final totalHours = (endBucket - startBucket).clamp(1, 720);
        // Downsample to at most 48 buckets so the chart stays readable.
        final step = (totalHours / 48).ceil().clamp(1, 24);
        final dense = <_TimelineEntry>[];
        for (int b = startBucket; b <= endBucket; b += step) {
          int count = 0;
          for (int s = b; s < b + step; s++) {
            count += sparseMap[s] ?? 0;
          }
          dense.add(_TimelineEntry(hour: b.toString(), count: count));
        }
        _timeline = dense;
        _locales =
            rawLocales
                .map(
                  (e) => _LocaleCount(
                    locale: (e['locale'] ?? '').toString(),
                    count: (e['count'] as num?)?.toInt() ?? 0,
                  ),
                )
                .where((entry) => entry.locale.isNotEmpty)
                .toList()
              ..sort((a, b) => b.count.compareTo(a.count));
        _failedInPeriod = (health['failed'] as num?)?.toInt() ?? 0;
        _errorRatePct = (health['errorRatePct'] as num?)?.toDouble() ?? 0;
        _p50LatencyMs = (health['p50LatencyMs'] as num?)?.toInt() ?? 0;
        _p95LatencyMs = (health['p95LatencyMs'] as num?)?.toInt() ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDateRangeLabel() {
    final locale = Localizations.localeOf(context).languageCode;
    String format(DateTime date) {
      final months = switch (locale) {
        'fr' => const [
          'janv.',
          'févr.',
          'mars',
          'avril',
          'mai',
          'juin',
          'juil.',
          'août',
          'sept.',
          'oct.',
          'nov.',
          'déc.',
        ],
        'de' => const [
          'Jan.',
          'Feb.',
          'März',
          'Apr.',
          'Mai',
          'Juni',
          'Juli',
          'Aug.',
          'Sept.',
          'Okt.',
          'Nov.',
          'Dez.',
        ],
        'pt' => const [
          'jan.',
          'fev.',
          'mar.',
          'abr.',
          'mai.',
          'jun.',
          'jul.',
          'ago.',
          'set.',
          'out.',
          'nov.',
          'dez.',
        ],
        'tr' => const [
          'Oca',
          'Şub',
          'Mar',
          'Nis',
          'May',
          'Haz',
          'Tem',
          'Ağu',
          'Eyl',
          'Eki',
          'Kas',
          'Ara',
        ],
        _ => const [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ],
      };

      if (locale == 'fr') {
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      } else if (locale == 'de') {
        return '${date.day}. ${months[date.month - 1]} ${date.year}';
      } else if (locale == 'pt') {
        return '${date.day} de ${months[date.month - 1]} de ${date.year}';
      } else if (locale == 'tr') {
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      } else {
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    }

    return '${format(_startDate)} - ${format(_endDate)}';
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      locale: Localizations.localeOf(context),
      builder: (context, child) {
        return Theme(
          // The picker inherits the ambient scheme (single accent) instead of
          // re-injecting the brand purple locally.
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _loading = true;
      });
      await _fetchStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget body;
    if (_loading) {
      body = _CenteredMessage(
        icon: Icons.hourglass_empty,
        text: context.tr.dashboard_loading,
      );
    } else if (_error != null) {
      body = _CenteredMessage(
        icon: Icons.error_outline,
        text: '${context.tr.dashboard_error}\n$_error',
      );
    } else {
      final periodTotal = _commands.fold<int>(0, (sum, c) => sum + c.count);
      final hasExpandedAnalytics = PremiumCapabilities.hasCapability(
        PremiumCapability.analyticsExpanded,
      );

      body = Center(
        // `PageContent` porte la largeur maximale et les marges communes
        // (`AppPageLayout`) : la page ne code plus ses propres bornes.
        child: PageContent(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              // ── Runner source ──
              _StatsSourceBanner(
                hasManagerSource: _hasManagerSource,
                managerLabel: _managerSourceLabel(),
                runners: _runners,
                source: _source,
                activeRunnerId: _activeRunnerId,
                onSourceChanged: _switchSource,
                onRefreshSources: _refreshingSources ? null : _refreshSources,
              ),
              // ── Date Selector ──
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr.dashboard_analysis_period,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDateRangeLabel(),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.edit_calendar_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Total card ──
              _StatCard(
                icon: Icons.functions,
                label: context.tr.dashboard_total,
                value: _totalAllTime.toString(),
                subtitle: context.tr.dashboard_selected_period_total(
                  periodTotal,
                ),
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 16),
              if (hasExpandedAnalytics) ...[
                Text(
                  context.tr.dashboard_execution_health_title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      label: context.tr.dashboard_failed_commands,
                      value: _failedInPeriod.toString(),
                    ),
                    _MetricChip(
                      label: context.tr.dashboard_error_rate,
                      value: '${_errorRatePct.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: context.tr.dashboard_p50_latency,
                      value: '$_p50LatencyMs ms',
                    ),
                    _MetricChip(
                      label: context.tr.dashboard_p95_latency,
                      value: '$_p95LatencyMs ms',
                    ),
                  ],
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.dashboard_premium_analytics_title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(context.tr.dashboard_premium_analytics_desc),
                        if (PremiumCapabilities.canShowPurchaseUI) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: FilledButton.icon(
                              onPressed: () => SubscriptionPage.show(context),
                              icon: const Icon(Icons.workspace_premium_rounded),
                              label: Text(context.tr.premium_card_button),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (hasExpandedAnalytics && _locales.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  context.tr.dashboard_top_locales,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _locales
                      .take(8)
                      .map(
                        (entry) => Chip(
                          label: Text('${entry.locale} (${entry.count})'),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 16),

              // ── Top commands ──
              Text(
                context.tr.dashboard_top_commands,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_commands.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      context.tr.dashboard_no_data,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._commands.map(
                  (cmd) => _CommandRow(
                    command: cmd,
                    maxCount: _commands.first.count,
                    colorScheme: colorScheme,
                  ),
                ),
              const SizedBox(height: 24),

              // ── Timeline ──
              Text(
                context.tr.dashboard_timeline,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (_timeline.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      context.tr.dashboard_no_data,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.2),
                    ),
                  ),
                  child: _InteractiveTimelineChart(
                    entries: _timeline,
                    color: Theme.of(context).colorScheme.primary,
                    executionsLabel: context.tr.dashboard_executions,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (!ResponsiveHelper.isDesktopPlatform()) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          // Width-driven leading (partage avec les autres sous-pages) : null
          // quand la sidebar du shell est permanente, bouton tiroir en layout
          // compact, bouton retour sur une route poussée. L'ancien garde
          // `isDesktopPlatform()` laissait un burger mort en desktop large.
          leading: editorSubPageLeading(context),
          title: Text(context.tr.dashboard_title),
          centerTitle: true,
        ),
        body: SafeArea(child: body),
      );
    }
    return SafeArea(child: body);
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _CommandCount {
  const _CommandCount({required this.name, required this.count});
  final String name;
  final int count;
}

class _TimelineEntry {
  const _TimelineEntry({required this.hour, required this.count});
  final String hour;
  final int count;

  String label() {
    final bucket = int.tryParse(hour);
    if (bucket == null) {
      return hour;
    }
    final date = DateTime.fromMillisecondsSinceEpoch(
      bucket * 3600000,
      isUtc: true,
    ).toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)} ${two(date.hour)}:00';
  }
}

class _LocaleCount {
  const _LocaleCount({required this.locale, required this.count});

  final String locale;
  final int count;
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandRow extends StatelessWidget {
  const _CommandRow({
    required this.command,
    required this.maxCount,
    required this.colorScheme,
  });

  final _CommandCount command;
  final int maxCount;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCount > 0 ? command.count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '/${command.name}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 18,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              command.count.toString(),
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Interactive timeline chart (same engine as bot_stats.dart) ────────────────

class _InteractiveTimelineChart extends StatefulWidget {
  const _InteractiveTimelineChart({
    required this.entries,
    required this.color,
    required this.executionsLabel,
  });

  final List<_TimelineEntry> entries;
  final Color color;

  /// Localised formatter: called like `executionsLabel(count)` → "3 executions"
  final String Function(int) executionsLabel;

  @override
  State<_InteractiveTimelineChart> createState() =>
      _InteractiveTimelineChartState();
}

class _InteractiveTimelineChartState extends State<_InteractiveTimelineChart>
    with SingleTickerProviderStateMixin {
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

  void _updateTouch(Offset pos, double width) {
    final entries = widget.entries;
    if (entries.isEmpty) return;
    final pct = (pos.dx / width).clamp(0.0, 1.0);
    final idx = (pct * (entries.length - 1)).round().clamp(
      0,
      entries.length - 1,
    );
    setState(() => _selectedIndex = idx);
  }

  void _clearTouch() => setState(() => _selectedIndex = null);

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    if (entries.length < 2) {
      return Center(
        child: Text(
          context.tr.dashboard_no_data,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }
    final values = entries.map((e) => e.count.toDouble()).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragStart: (d) =>
              _updateTouch(d.localPosition, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _updateTouch(d.localPosition, constraints.maxWidth),
          onHorizontalDragEnd: (_) => _clearTouch(),
          onTapDown: (d) => _updateTouch(d.localPosition, constraints.maxWidth),
          onTapUp: (_) => _clearTouch(),
          onTapCancel: _clearTouch,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return CustomPaint(
                painter: _TimelineChartPainter(
                  values: values,
                  labels: entries.map((e) => e.label()).toList(),
                  color: widget.color,
                  selectedIndex: _selectedIndex,
                  pulseProgress: _pulseController.value,
                  tooltipFormatter: (i) =>
                      '${entries[i].label()}\n${widget.executionsLabel(entries[i].count)}',
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      },
    );
  }
}

class _TimelineChartPainter extends CustomPainter {
  _TimelineChartPainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.selectedIndex,
    required this.pulseProgress,
    required this.tooltipFormatter,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final int? selectedIndex;
  final double pulseProgress;
  final String Function(int index) tooltipFormatter;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 0.0001 ? 1.0 : (maxV - minV);

    const double gridPadding = 6.0;
    final double graphHeight = size.height - gridPadding * 2;

    // Dashed gridlines
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (int i = 1; i <= 3; i++) {
      final y = gridPadding + graphHeight * (i / 4.0);
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
        4.0,
        4.0,
      );
    }

    // Compute pixel positions
    final points = <Offset>[
      for (int i = 0; i < values.length; i++)
        Offset(
          (i / (values.length - 1)) * size.width,
          size.height -
              gridPadding -
              ((values[i] - minV) / range) * graphHeight,
        ),
    ];

    // Gradient fill
    final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(0, size.height), [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.0),
        ])
        ..style = PaintingStyle.fill,
    );

    // Stroke line
    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      strokePath.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      strokePath,
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), [
          color,
          color.withValues(alpha: 0.7),
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (selectedIndex != null && selectedIndex! < points.length) {
      final pt = points[selectedIndex!];

      // Dashed vertical cursor
      _drawDashedLine(
        canvas,
        Offset(pt.dx, 0),
        Offset(pt.dx, size.height),
        Paint()
          ..color = color.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
        3.0,
        3.0,
      );

      // Halo + dot
      canvas.drawCircle(
        pt,
        8.0,
        Paint()..color = color.withValues(alpha: 0.25),
      );
      canvas.drawCircle(pt, 4.0, Paint()..color = color);
      canvas.drawCircle(
        pt,
        4.0,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Tooltip
      final tooltip = tooltipFormatter(selectedIndex!);
      final tp = TextPainter(
        text: TextSpan(
          text: tooltip,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 140);

      final double tw = tp.width + 16;
      final double th = tp.height + 8;
      final double tx = (pt.dx - tw / 2).clamp(4.0, size.width - tw - 4.0);
      final double ty = (pt.dy - th - 10).clamp(2.0, size.height - th - 2.0);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(tx, ty, tw, th),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        rrect.shift(const Offset(0, 1.5)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRRect(rrect, Paint()..color = const Color(0xFF1E1E2C));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      tp.paint(canvas, Offset(tx + 8, ty + 4));
    } else {
      // Pulsing dot on last point
      final last = points.last;
      canvas.drawCircle(
        last,
        3.5 + pulseProgress * 6.5,
        Paint()..color = color.withValues(alpha: 0.4 * (1.0 - pulseProgress)),
      );
      canvas.drawCircle(last, 3.5, Paint()..color = color);
      canvas.drawCircle(
        last,
        3.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    double dashLen,
    double gapLen,
  ) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final dir = Offset(dx / len, dy / len);
    double cur = 0;
    while (cur < len) {
      final s = start + dir * cur;
      final e = start + dir * math.min(cur + dashLen, len);
      canvas.drawLine(s, e, paint);
      cur += dashLen + gapLen;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelineChartPainter old) =>
      old.values != values ||
      old.color != color ||
      old.selectedIndex != selectedIndex ||
      old.pulseProgress != pulseProgress;
}

class _StatsSourceBanner extends StatelessWidget {
  const _StatsSourceBanner({
    required this.hasManagerSource,
    required this.managerLabel,
    required this.runners,
    required this.source,
    required this.activeRunnerId,
    required this.onSourceChanged,
    required this.onRefreshSources,
  });

  final bool hasManagerSource;
  final String managerLabel;
  final List<RunnerConnectionConfig> runners;
  final _DashboardStatsSource source;
  final String? activeRunnerId;
  final ValueChanged<String> onSourceChanged;
  final Future<void> Function()? onRefreshSources;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeRunner = runners
        .where((r) => r.id == activeRunnerId)
        .firstOrNull;
    final localLabel = context.tr.runner_source_local;
    final activeRunnerLabel = activeRunner == null
        ? '?'
        : context.tr.runner_source_label(activeRunner.name ?? activeRunner.url);
    final selectedValue = switch (source) {
      _DashboardStatsSource.local => 'local',
      _DashboardStatsSource.manager => 'manager',
      _DashboardStatsSource.runner => activeRunnerId ?? 'local',
    };
    final sourceLabel = switch (source) {
      _DashboardStatsSource.local => localLabel,
      _DashboardStatsSource.manager => managerLabel,
      _DashboardStatsSource.runner => activeRunnerLabel,
    };
    final hasMultipleChoices = hasManagerSource || runners.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Neutral bar: the active source is already named by the dropdown
        // label — no brand-tinted container is needed.
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(
            Icons.dns_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: hasMultipleChoices
                ? DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedValue,
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'local',
                          child: Text(
                            localLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasManagerSource)
                          DropdownMenuItem(
                            value: 'manager',
                            child: Text(
                              managerLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        for (final r in runners)
                          DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              context.tr.runner_source_label(r.name ?? r.url),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) onSourceChanged(v);
                      },
                    ),
                  )
                : Text(
                    sourceLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
          ),
          IconButton(
            tooltip: context.tr.dashboard_refresh_sources_tooltip,
            onPressed: onRefreshSources == null
                ? null
                : () {
                    unawaited(onRefreshSources!());
                  },
            icon: const Icon(Icons.refresh, size: 18),
          ),
        ],
      ),
    );
  }
}
