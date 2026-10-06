import 'package:flutter/material.dart';

/// Largeur à partir de laquelle le Studio affiche le rail latéral (comme
/// `desktopBreakpoint` de l'app). En dessous : barre de navigation en bas.
const double compactBreakpoint = 720;

/// `true` sur un écran de téléphone (ou une fenêtre étroite). La décision se
/// prend sur la largeur de la FENÊTRE, pas sur celle du contenu : le rail ne
/// doit pas apparaître et disparaître selon le contenu.
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < compactBreakpoint;

/// Marge horizontale des pages : 16 sur téléphone, 24 sur grand écran.
double pagePadding(BuildContext context) => isCompact(context) ? 16 : 24;

/// Marges d'une page défilante.
EdgeInsets pageInsets(BuildContext context, {double top = 12}) {
  final h = pagePadding(context);
  return EdgeInsets.fromLTRB(h, top, h, 40);
}
