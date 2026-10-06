import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import 'home_ui.dart';

/// Temps restant qui s'écoule à la seconde : mois (30 j) · jours · heures · min ·
/// s, à partir de la plus grande unité non nulle (« 00 mois 00 jours » n'apprend
/// rien ; minutes et secondes restent toujours affichées).
///
/// Les chiffres sont tabulaires pour ne pas bouger d'un tick à l'autre. Un
/// lecteur d'écran lit [summary] une fois, pas chaque seconde. Passé [deadline],
/// le décompte devient [expiredLabel].
class HostingCountdown extends StatefulWidget {
  const HostingCountdown({
    super.key,
    required this.deadline,
    required this.expiredLabel,
    required this.summary,
    this.now,
  });

  final DateTime deadline;
  final String expiredLabel;
  final String summary;

  /// Horloge injectable (tests) ; par défaut `DateTime.now`.
  final DateTime Function()? now;

  @override
  State<HostingCountdown> createState() => _HostingCountdownState();
}

class _HostingCountdownState extends State<HostingCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;
    final left = widget.deadline.difference((widget.now ?? DateTime.now)());
    if (left.isNegative) {
      return Text(
        widget.expiredLabel,
        style: homeDisplayStyle(
          15,
          weight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      );
    }
    final tr = context.tr;
    final days = left.inDays;
    final cells = <(int, String)>[
      (days ~/ 30, tr.unit_short_month),
      (days % 30, tr.unit_short_day),
      (left.inHours % 24, tr.unit_short_hour),
      (left.inMinutes % 60, tr.unit_short_minute),
      (left.inSeconds % 60, tr.unit_short_second),
    ];
    var first = cells.indexWhere((c) => c.$1 > 0);
    if (first < 0 || first > 3) first = 3;
    return Semantics(
      label: widget.summary,
      excludeSemantics: true,
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          for (var i = first; i < cells.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cells[i].$1.toString().padLeft(2, '0'),
                  style:
                      homeDisplayStyle(
                        20,
                        weight: FontWeight.w700,
                        color: scheme.onSurface,
                      ).copyWith(
                        height: 1.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
                Text(
                  cells[i].$2.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: muted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
