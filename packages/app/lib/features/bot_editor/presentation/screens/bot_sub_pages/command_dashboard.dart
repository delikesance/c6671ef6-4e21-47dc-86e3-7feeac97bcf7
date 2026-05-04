import 'dart:async';

import 'package:bot_creator/core/storage/database.dart';

import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

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

  int _hours = 24;

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

  bool get _supportsManagerRuntime => !kIsWeb;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    await _refreshSources(refetchStats: false, preserveSelection: false);
    await _fetchStats();
  }

  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  String _managerSourceLabel() {
    return _uiCopy(fr: 'Serveurs Bot Creator', en: 'Bot Creator servers');
  }

  String _managerUnavailableMessage() {
    return _managerUnavailableReason ??
        _uiCopy(
          fr:
              'Connectez-vous a Bot Creator dans les parametres pour charger les stats depuis les serveurs Bot Creator.',
          en:
              'Sign in to Bot Creator in Settings to load stats from Bot Creator servers.',
        );
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
    );
    if (!mounted) return;

    final hasManagerSource = runtime.source == RemoteRuntimeSource.manager;
    var nextSource =
        preserveSelection
            ? _source
            : switch (runtime.source) {
              RemoteRuntimeSource.manager => _DashboardStatsSource.manager,
              RemoteRuntimeSource.runner => _DashboardStatsSource.runner,
              RemoteRuntimeSource.local => _DashboardStatsSource.local,
            };
    var nextActiveRunnerId = preserveSelection ? _activeRunnerId : config?.id;

    if (nextSource == _DashboardStatsSource.manager && !hasManagerSource) {
      nextSource =
          config == null
              ? _DashboardStatsSource.local
              : _DashboardStatsSource.runner;
      nextActiveRunnerId = config?.id;
    }

    if (nextSource == _DashboardStatsSource.runner) {
      final selectedRunner =
          runners
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
        nextClient =
            runtime.source == RemoteRuntimeSource.manager
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
          nextSource =
              hasManagerSource
                  ? _DashboardStatsSource.manager
                  : _DashboardStatsSource.local;
          nextActiveRunnerId = null;
          nextClient =
              nextSource == _DashboardStatsSource.manager
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
      _managerUnavailableReason =
          hasManagerSource ? runtime.unavailableReason : null;
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
          hours: _hours,
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
        json = await client.getCommandStats(widget.botId, hours: _hours);
      }
      if (!mounted) return;
      final rawCommands = json['commands'] as List? ?? [];
      final rawTimeline = json['timeline'] as List? ?? [];
      final rawLocales = json['locales'] as List? ?? [];
      final health = Map<String, dynamic>.from(
        (json['health'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
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
        _timeline =
            rawTimeline
                .map(
                  (e) => _TimelineEntry(
                    hour: e['hour'] as String? ?? '',
                    count: (e['count'] as num?)?.toInt() ?? 0,
                  ),
                )
                .toList();
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

  void _setPeriod(int hours) {
    if (hours == _hours) return;
    _hours = hours;
    unawaited(_fetchStats());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return _CenteredMessage(
        icon: Icons.hourglass_empty,
        text: context.tr.dashboard_loading,
      );
    }

    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        text: '${context.tr.dashboard_error}\n$_error',
      );
    }

    final periodTotal = _commands.fold<int>(0, (sum, c) => sum + c.count);
    final hasExpandedAnalytics = PremiumCapabilities.hasCapability(
      PremiumCapability.analyticsExpanded,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
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
        // ── Period selector ──
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [
              (24, 'dashboard_period_24h'),
              (168, 'dashboard_period_7d'),
              (720, 'dashboard_period_30d'),
            ])
              ChoiceChip(
                label: Text(entry.$2),
                selected: _hours == entry.$1,
                onSelected: (_) => _setPeriod(entry.$1),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Total card ──
        _StatCard(
          icon: Icons.functions,
          label: context.tr.dashboard_total,
          value: _totalAllTime.toString(),
          subtitle: context.tr.dashboard_selected_period_total(periodTotal),
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 16),
        if (hasExpandedAnalytics) ...[
          Text(
            context.tr.dashboard_execution_health_title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locales
                .take(8)
                .map(
                  (entry) =>
                      Chip(label: Text('${entry.locale} (${entry.count})')),
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
          SizedBox(height: 150, child: _TimelineChart(entries: _timeline)),
      ],
    );
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
    final date =
        DateTime.fromMillisecondsSinceEpoch(
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
          Icon(icon, color: colorScheme.primary),
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

class _TimelineChart extends StatelessWidget {
  const _TimelineChart({required this.entries});
  final List<_TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final maxCount = entries.fold<int>(0, (m, e) => e.count > m ? e.count : m);
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth =
            entries.isNotEmpty
                ? (constraints.maxWidth / entries.length).clamp(4.0, 24.0)
                : 8.0;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              entries.map((e) {
                final ratio = maxCount > 0 ? e.count / maxCount : 0.0;
                return Tooltip(
                  message:
                      '${e.label()}\n${context.tr.dashboard_executions(e.count)}',
                  child: Container(
                    width: barWidth - 1,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    height: (ratio * (constraints.maxHeight - 16)).clamp(
                      2.0,
                      constraints.maxHeight - 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: 0.3 + 0.7 * ratio,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
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
    final activeRunner =
        runners.where((r) => r.id == activeRunnerId).firstOrNull;
    final localLabel = context.tr.runner_source_local;
    final activeRunnerLabel =
        activeRunner == null
            ? '?'
            : context.tr.runner_source_label(
              activeRunner.name ?? activeRunner.url,
            );
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
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.dns_outlined, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child:
                hasMultipleChoices
                    ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedValue,
                        isDense: true,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onPrimaryContainer,
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
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
          ),
          IconButton(
            tooltip: context.tr.dashboard_refresh_sources_tooltip,
            onPressed:
                onRefreshSources == null
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
