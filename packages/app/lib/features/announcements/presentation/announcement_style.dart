// Habillage partagé de la bannière et du dialogue d'annonce.
//
// Aucune couleur en dur : la teinte vient des rôles du thème (le même jeu que
// les cartes de l'app), et l'icône ne dépend que de la gravité. Aucun littéral
// d'UI non plus — tout passe par les 6 locales.
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';

/// Ouvre un lien externe. Injectable pour que les tests n'appellent jamais le
/// lanceur de la plateforme.
typedef AnnouncementLinkOpener = Future<bool> Function(Uri uri);

/// Palette d'une gravité d'annonce, prise dans le thème courant.
class AnnouncementPalette {
  const AnnouncementPalette({
    required this.container,
    required this.onContainer,
    required this.icon,
  });

  final Color container;
  final Color onContainer;
  final IconData icon;

  static AnnouncementPalette of(
    BuildContext context,
    AnnouncementSeverity severity,
  ) {
    final scheme = Theme.of(context).colorScheme;
    switch (severity) {
      case AnnouncementSeverity.info:
        return AnnouncementPalette(
          container: scheme.surfaceContainerHigh,
          onContainer: scheme.onSurface,
          icon: Icons.info_outline,
        );
      case AnnouncementSeverity.important:
        return AnnouncementPalette(
          container: scheme.tertiaryContainer,
          onContainer: scheme.onTertiaryContainer,
          icon: Icons.warning_amber_rounded,
        );
      case AnnouncementSeverity.critical:
        return AnnouncementPalette(
          container: scheme.errorContainer,
          onContainer: scheme.onErrorContainer,
          icon: Icons.error_outline,
        );
    }
  }
}

/// Ouvre [uri] hors de l'app. Un échec ne casse rien : il devient une
/// notification discrète, jamais une exception.
///
/// Si aucun `ScaffoldMessenger` n'est disponible (arbre détaché), l'échec est
/// JOURNALISÉ plutôt qu'avalé : c'est la seule trace qui reste.
Future<void> openAnnouncementLink(
  BuildContext context,
  Uri uri, {
  AnnouncementLinkOpener? openLink,
}) async {
  final opened = await (openLink?.call(uri) ?? openExternalUrl(uri));
  if (opened || !context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final message = context.tr.announcement_link_open_failed;
  if (messenger == null) {
    unawaited(
      AppDiagnostics.logInfo(
        'Announcements: link failure not shown (no ScaffoldMessenger)',
      ),
    );
    return;
  }
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
