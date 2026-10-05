import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

/// État d'un bot : seules couleurs de statut autorisées dans l'interface.
enum StatusPillVariant { online, stopped, warning, error }

/// Pastille d'état (point + libellé), 26 px de haut, rayon 13.
///
/// Le libellé doit être localisé par l'appelant.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.variant, required this.label});

  const StatusPill.online({super.key, required this.label})
    : variant = StatusPillVariant.online;
  const StatusPill.stopped({super.key, required this.label})
    : variant = StatusPillVariant.stopped;
  const StatusPill.warning({super.key, required this.label})
    : variant = StatusPillVariant.warning;
  const StatusPill.error({super.key, required this.label})
    : variant = StatusPillVariant.error;

  static const double height = 26;

  final StatusPillVariant variant;
  final String label;

  /// Couleur du point (statut) de la variante.
  static Color dotColorOf(StatusPillVariant v) => switch (v) {
    StatusPillVariant.online => AppTheme.statusOnline,
    StatusPillVariant.stopped => AppTheme.statusStopped,
    StatusPillVariant.warning => AppTheme.statusWarning,
    StatusPillVariant.error => AppTheme.statusError,
  };

  /// Couleur du texte (variante lisible ≥ 4.5:1).
  static Color textColorOf(StatusPillVariant v) => switch (v) {
    StatusPillVariant.error => AppTheme.statusErrorText,
    StatusPillVariant.stopped => AppTheme.homeMuted,
    _ => dotColorOf(v),
  };

  @override
  Widget build(BuildContext context) {
    final dot = dotColorOf(variant);
    return Semantics(
      label: label,
      container: true,
      child: ExcludeSemantics(
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: dot.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: dot.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: textColorOf(variant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
