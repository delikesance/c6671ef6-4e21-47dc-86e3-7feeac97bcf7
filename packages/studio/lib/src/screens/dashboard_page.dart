import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/studio_session.dart';
import '../dashboard/command_stats.dart';
import '../premium/studio_feature.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';

/// Onglet « Tableau de bord » : usage des commandes sur 24 h, 7 j ou 30 j.
///
/// Comme dans l'app, le volume d'exécutions est gratuit ; le taux d'erreur,
/// les latences et la répartition par langue demandent un compte Premium.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.api,
    required this.bot,
    required this.plan,
  });

  final StudioApi api;
  final StudioBot bot;
  final StudioPlan plan;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _windows = {24: '24 h', 168: '7 jours', 720: '30 jours'};

  int _hours = 24;
  late Future<CommandStats> _future = _load();

  Future<CommandStats> _load() =>
      widget.api.commandStats(widget.bot.id, _hours);

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final premium = StudioFeature.analytics.isAvailableFor(widget.plan);
    return SingleChildScrollView(
      padding: pageInsets(context),
      child: PageContent(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Tableau de bord',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                for (final e in _windows.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _hours == e.key,
                    onSelected: (_) {
                      _hours = e.key;
                      _reload();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<CommandStats>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorNotice(
                    message: '${snapshot.error}',
                    onRetry: _reload,
                  );
                }
                return _Content(
                  stats: snapshot.data!,
                  hours: _hours,
                  premium: premium,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.stats,
    required this.hours,
    required this.premium,
  });

  final CommandStats stats;
  final int hours;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final health = stats.health;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(label: 'Exécutions', value: _n(health.total)),
            _Metric(label: 'Depuis le début', value: _n(stats.totalAllTime)),
            if (premium) ...[
              _Metric(
                label: "Taux d'erreur",
                value: health.total == 0
                    ? '—'
                    : '${health.errorRatePct.toStringAsFixed(1)} %',
              ),
              _Metric(
                label: 'Latence P50 / P95',
                value: health.hasLatency
                    ? '${health.p50LatencyMs} / ${health.p95LatencyMs} ms'
                    : '—',
              ),
            ],
          ],
        ),
        if (!premium) ...[const SizedBox(height: 12), const _AnalyticsLocked()],
        const SizedBox(height: 24),
        const Overline('Activité'),
        const SizedBox(height: 12),
        _Bars(
          bars: timelineBars(stats.timeline, hours, DateTime.now()),
          daily: hours > 48,
        ),
        const SizedBox(height: 24),
        const Overline('Commandes'),
        const SizedBox(height: 12),
        if (stats.commands.isEmpty)
          const Text(
            'Aucune exécution sur cette période.',
            style: TextStyle(color: StudioColors.muted),
          )
        else
          for (final c in stats.commands)
            _CommandRow(
              command: c,
              max: stats.commands.first.count,
              premium: premium,
            ),
        if (premium && stats.locales.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Overline('Langues'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in stats.locales)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StudioColors.selected,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${l.locale.isEmpty ? '?' : l.locale} · ${_n(l.count)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: StudioColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

String _n(int v) =>
    v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: StudioColors.card,
      border: Border.all(color: StudioColors.clusterBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Overline(label),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _AnalyticsLocked extends StatelessWidget {
  const _AnalyticsLocked();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: StudioColors.containerLowest,
      border: Border.all(color: StudioColors.cardBorder),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: StudioColors.premiumGold,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Analytics Premium',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Débloquez le taux d\'erreur, les percentiles de latence et les insights de localisation.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: StudioColors.muted,
          ),
        ),
        SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: StudioColors.muted,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Ton compte est en formule gratuite : l'abonnement s'active depuis l'application mobile (le Studio n'affiche ni publicité ni achat).",
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: StudioColors.muted,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Bars extends StatelessWidget {
  const _Bars({required this.bars, required this.daily});

  final List<int> bars;
  final bool daily;

  @override
  Widget build(BuildContext context) {
    final max = bars.fold<int>(0, (m, v) => v > m ? v : m);
    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: max == 0
          ? const Center(
              child: Text(
                'Aucune activité sur cette période.',
                style: TextStyle(color: StudioColors.muted),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < bars.length; i++)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${bars[i]} exécution${bars[i] > 1 ? 's' : ''} · '
                          '${daily ? 'il y a ${bars.length - 1 - i} j' : 'il y a ${bars.length - 1 - i} h'}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: FractionallySizedBox(
                          heightFactor: bars[i] == 0 ? 0.01 : bars[i] / max,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bars[i] == 0
                                  ? StudioColors.cardBorder
                                  : StudioColors.action,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
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
    required this.max,
    required this.premium,
  });

  final CommandCount command;
  final int max;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final c = command;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  c.command,
                  style: const TextStyle(
                    fontFamily: StudioTheme.monoFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _n(c.count),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: max == 0 ? 0 : c.count / max,
              minHeight: 6,
              color: StudioColors.action,
              backgroundColor: StudioColors.selected,
            ),
          ),
          if (premium) ...[
            const SizedBox(height: 8),
            Text(
              '${c.errorRatePct.toStringAsFixed(1)} % d\'erreurs'
              ' · ${c.hasLatency ? 'P50 ${c.p50LatencyMs} ms · P95 ${c.p95LatencyMs} ms' : 'latence —'}',
              style: const TextStyle(fontSize: 12, color: StudioColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
