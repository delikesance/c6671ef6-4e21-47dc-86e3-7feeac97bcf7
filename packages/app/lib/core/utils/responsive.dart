import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:flutter/material.dart';

export 'package:bot_creator_ui/src/widgets/responsive.dart';

extension ScaffoldParentExtension on BuildContext {
  /// Open the parent Scaffold's drawer if it exists.
  ///
  /// Le repli explicite vise le `Scaffold` le PLUS PROCHE (`Scaffold.maybeOf`,
  /// dont le fournisseur est un ancêtre de ce contexte — le lookup est donc
  /// légitime). Quand il n'y en a aucun, on le JOURNALISE : un bouton qui ne
  /// répond pas et ne laisse aucune trace est indiagnosticable.
  void openParentDrawer() {
    ScaffoldState? parent;
    int count = 0;
    visitAncestorElements((element) {
      if (element is StatefulElement && element.state is ScaffoldState) {
        count++;
        if (count > 1) {
          // Skip the first (nested) Scaffold
          parent = element.state as ScaffoldState;
          return false; // stop traversing
        }
      }
      return true; // continue traversing
    });
    final target = parent ?? Scaffold.maybeOf(this);
    if (target == null) {
      unawaited(
        AppDiagnostics.logInfo('Responsive: no Scaffold to open a drawer on'),
      );
      return;
    }
    target.openDrawer();
  }
}
