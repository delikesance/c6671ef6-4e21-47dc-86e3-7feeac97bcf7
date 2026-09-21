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
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.buttonBackground,
    required this.buttonForeground,
  });

  final Color container;
  final Color onContainer;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final Color buttonBackground;
  final Color buttonForeground;

  static AnnouncementPalette of(
    BuildContext context,
    AnnouncementSeverity severity,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    switch (severity) {
      case AnnouncementSeverity.info:
        return AnnouncementPalette(
          container: isDark ? const Color(0xFF162032) : const Color(0xFFEFF6FF),
          onContainer: isDark
              ? const Color(0xFF93C5FD)
              : const Color(0xFF1E40AF),
          border: isDark
              ? const Color(0xFF2563EB).withValues(alpha: 0.35)
              : const Color(0xFFBFDBFE),
          icon: Icons.info_outline,
          iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
          buttonBackground: isDark
              ? const Color(0xFF3B82F6)
              : const Color(0xFF2563EB),
          buttonForeground: Colors.white,
        );
      case AnnouncementSeverity.important:
        return AnnouncementPalette(
          container: isDark ? const Color(0xFF2A2012) : const Color(0xFFFFFBEB),
          onContainer: isDark
              ? const Color(0xFFFDE68A)
              : const Color(0xFF92400E),
          border: isDark
              ? const Color(0xFFD97706).withValues(alpha: 0.35)
              : const Color(0xFFFDE68A),
          icon: Icons.warning_amber_rounded,
          iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
          buttonBackground: isDark
              ? const Color(0xFFF59E0B)
              : const Color(0xFFD97706),
          buttonForeground: isDark ? Colors.black : Colors.white,
        );
      case AnnouncementSeverity.critical:
        return AnnouncementPalette(
          container: isDark ? const Color(0xFF2A1517) : const Color(0xFFFEF2F2),
          onContainer: isDark
              ? const Color(0xFFFECACA)
              : const Color(0xFF991B1B),
          border: isDark
              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
              : const Color(0xFFFECACA),
          icon: Icons.error_outline,
          iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
          buttonBackground: isDark
              ? const Color(0xFFEF4444)
              : const Color(0xFFDC2626),
          buttonForeground: Colors.white,
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
