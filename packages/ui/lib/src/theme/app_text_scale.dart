import 'package:flutter/material.dart';

import 'app_appearance.dart';

/// Wraps the navigator so pages, dialogs and overlays share the adjustment.
class AppTextScale extends StatelessWidget {
  const AppTextScale({super.key, required this.factor, required this.child});

  final double? factor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final data = MediaQuery.of(context);
    final adjustment = AppAppearanceConfig.normalizeTextScale(factor);
    return MediaQuery(
      data: data.copyWith(
        textScaler: adjustment == 1.0
            ? data.textScaler
            : _AdjustedTextScaler(data.textScaler, adjustment),
      ),
      child: child,
    );
  }
}

/// Retains the system's nonlinear scaling curve instead of flattening it to a
/// single legacy textScaleFactor. The app preference multiplies its output.
class _AdjustedTextScaler extends TextScaler {
  const _AdjustedTextScaler(this.system, this.factor);

  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _AdjustedTextScaler &&
      other.system == system &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
