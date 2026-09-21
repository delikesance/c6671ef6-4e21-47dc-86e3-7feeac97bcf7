// PRÉSENTATION des annonces in-app : montage de la bannière dans l'overlay,
// dialogue modal, mémoire « déjà vue » et traces d'échec d'affichage.
//
// Extrait de `AnnouncementService` par RESPONSABILITÉ : le service garde la
// décision et le réseau, ce fichier ne fait que MONTRER ce qui a été décidé.
// Il est le SEUL propriétaire de l'état de présentation (emplacement occupé,
// marques « vue ») : le service lui délègue, il ne duplique aucun état.
//
// Règles non négociables portées ici :
//   * la marque « vue » est écrite AVANT l'affichage — c'est elle seule qui
//     garantit « jamais deux fois » ;
//   * quand la présentation n'a PAS pu être montée, le montage rend `false` :
//     c'est le signal, pour l'appelant, d'ANNULER la marque. « Jamais deux
//     fois » protège ce qui a été VU, pas ce qui a échoué à s'afficher ;
//   * aucun échec muet : tout part dans AppDiagnostics (le journal visible de
//     l'app) et dans `lastDisplayFailure`, que les tests peuvent lire sans
//     initialiser le stockage de la plateforme.
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_dialog.dart';

/// [ValueNotifier] spécialisé permettant de vérifier [hasListeners]
/// sans enfreindre la visibilité protégée dans les analyseurs statiques.
class AnnouncementBannerNotifier extends ValueNotifier<Announcement?> {
  AnnouncementBannerNotifier(super.value);

  /// Indique si un écouteur actif est enregistré.
  bool get hasActiveListeners => hasListeners;
}

/// Monte les annonces à l'écran et tient la mémoire « déjà vue ».
class AnnouncementPresenter {
  AnnouncementPresenter._();

  static OverlayEntry? _bannerEntry;
  static bool _modalVisible = false;
  static VoidCallback? _onBannerDismissed;

  /// Annonce actuellement affichée sous forme de bannière.
  /// Écoutée par [HomePage] pour un affichage directement dans la page
  /// au-dessus du bouton « Créer un bot » au lieu d'un overlay flottant.
  static final AnnouncementBannerNotifier bannerNotifier =
      AnnouncementBannerNotifier(null);

  /// Indique si un hôte en ligne (comme la HomePage) est actuellement à l'écoute.
  static bool get hasInlineHost => bannerNotifier.hasActiveListeners;

  /// Dernier échec de présentation (« la bannière ou le dialogue n'a pas pu
  /// être monté, donc l'annonce n'a pas été consommée »).
  static String? lastDisplayFailure;

  /// Un emplacement est-il déjà occupé ? UNE SEULE annonce à la fois.
  static bool get isOccupied =>
      _bannerEntry != null || bannerNotifier.value != null || _modalVisible;

  /// Remet l'état de présentation à zéro (entre deux tests).
  ///
  /// La bannière encore à l'écran n'est pas retirée de son overlay : l'arbre
  /// du test précédent est déjà détruit, et toucher une entrée orpheline
  /// ferait échouer la remise à zéro. On oublie simplement le pointeur.
  static void reset() {
    lastDisplayFailure = null;
    _modalVisible = false;
    _onBannerDismissed = null;
    _bannerEntry = null;
    bannerNotifier.value = null;
    _sessionDismissedIds.clear();
  }

  // ── Mémoire de session (« ignorée pour la session après clic sur Compris ») ──

  static final Set<String> _sessionDismissedIds = <String>{};

  /// Identifiants ignorés pour la session en cours.
  static Set<String> get sessionDismissedIds =>
      Set<String>.unmodifiable(_sessionDismissedIds);

  /// Identifiants acquittés pour la session courante.
  ///
  /// Règle : tant que l'annonce est disponible côté serveur, elle ne doit
  /// jamais être cachée après un redémarrage. Elle n'est masquée QUE durant la
  /// session en cours après clic sur « Got it » / « Compris ».
  static Future<Set<String>> seenIds() async =>
      Set<String>.unmodifiable(_sessionDismissedIds);

  /// Ignore l'annonce pour la durée de la session courante (clic sur « Got it » / « Compris »).
  static void dismissForSession(String id) {
    _sessionDismissedIds.add(id);
  }

  /// Acquitte une annonce pour la session courante.
  static Future<void> markSeen(String id) async {
    dismissForSession(id);
  }

  /// Annule l'acquittement d'une annonce dans la session courante.
  static Future<void> unmarkSeen(String id) async {
    _sessionDismissedIds.remove(id);
  }

  /// Déclenche la fermeture d'une bannière affichée (en ligne ou overlay)
  /// suite au clic sur « Got it » / « Compris ».
  static void dismissBanner() {
    final current = bannerNotifier.value;
    if (current != null) {
      dismissForSession(current.id);
    }
    final callback = _onBannerDismissed;
    _onBannerDismissed = null;
    removeBanner();
    callback?.call();
  }

  /// Transfère un éventuel overlay flottant vers le composant en ligne lorsque l'accueil se monte.
  static void absorbOverlayIntoInline() {
    final entry = _bannerEntry;
    _bannerEntry = null;
    if (entry != null) {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }
  }

  /// Monte la bannière (en ligne dans la page d'accueil si disponible, ou dans l'overlay
  /// en repli), ou rend `false` si aucun emplacement n'est disponible — auquel cas
  /// l'appelant annule la marque « vue ».
  static bool showBanner({
    required OverlayState? host,
    required Announcement announcement,
    required VoidCallback onDismissed,
  }) {
    _onBannerDismissed = onDismissed;

    // Si la page d'accueil (ou un hôte en ligne) écoute déjà, la bannière s'affiche
    // directement au-dessus du bouton « Créer un bot » sans flotter par-dessus le contenu.
    if (hasInlineHost) {
      bannerNotifier.value = announcement;
      unawaited(
        AppDiagnostics.logInfo(
          'Announcements: banner shown inline',
          data: <String, Object?>{'id': announcement.id},
        ),
      );
      return true;
    }

    if (host == null) {
      bannerNotifier.value = null;
      recordFailure(announcement, 'aucun overlay disponible');
      return false;
    }

    final entry = OverlayEntry(
      builder: (overlayContext) {
        final mediaQuery = MediaQuery.maybeOf(overlayContext);
        final screenWidth = mediaQuery?.size.width ?? 800.0;
        final isDesktop = ResponsiveHelper.isDesktopPlatform();
        final isWide = screenWidth >= AppTheme.desktopBreakpoint;

        final banner = AnnouncementBanner(
          announcement: announcement,
          onDismiss: dismissBanner,
        );

        if (isDesktop || isWide) {
          // Sur poste de travail ou grand écran : affichage en notification
          // flottante en bas à droite. Ne masque plus la barre de titre desktop,
          // le bouton « Créer un bot » ni les actions d'en-tête de l'accueil.
          const maxToastWidth = 440.0;
          final availableWidth = screenWidth - 32;
          final toastWidth = availableWidth < maxToastWidth
              ? availableWidth
              : maxToastWidth;
          final bottomOffset = isWide
              ? 24.0
              : (FloatingGlassNavBar.contentClearanceOf(overlayContext) + 12.0);

          return Positioned(
            right: 16,
            bottom: bottomOffset,
            width: toastWidth,
            child: banner,
          );
        }

        // Sur mobile/écran étroit : en haut sous la barre d'état système.
        final topPadding = mediaQuery?.padding.top ?? 0.0;
        return Positioned(
          top: topPadding + 8,
          left: 12,
          right: 12,
          child: banner,
        );
      },
    );

    try {
      host.insert(entry);
    } catch (error, stack) {
      // Overlay détruit entre la résolution et l'insertion : on ne garde pas
      // l'entrée, sinon l'emplacement resterait occupé pour toujours et PLUS
      // AUCUNE annonce ne pourrait s'afficher.
      entry.dispose();
      bannerNotifier.value = null;
      recordFailure(announcement, 'overlay hors service');
      unawaited(
        AppDiagnostics.logError(
          'Announcements: banner insert failed',
          error,
          stack,
          fatal: false,
          reason: announcement.id,
        ),
      );
      return false;
    }

    _bannerEntry = entry;
    bannerNotifier.value = announcement;
    unawaited(
      AppDiagnostics.logInfo(
        'Announcements: banner shown',
        data: <String, Object?>{'id': announcement.id},
      ),
    );
    return true;
  }

  /// Retire la bannière de son overlay et désactive la bannière en ligne.
  static void removeBanner() {
    bannerNotifier.value = null;
    final entry = _bannerEntry;
    _bannerEntry = null;
    if (entry == null) return;
    if (entry.mounted) entry.remove();
    entry.dispose();
  }

  // ── Dialogue ─────────────────────────────────────────────────────────────

  /// Monte le dialogue modal, ou rend `false` s'il n'y a pas de Navigator
  /// vivant pour le porter.
  ///
  /// [navigatorAlive] est vérifié AVANT d'occuper l'emplacement : un dialogue
  /// qui ne se monte pas laisserait l'emplacement occupé pour toujours, et
  /// l'annonce consommée.
  static bool showModal({
    required BuildContext context,
    required Announcement announcement,
    required bool navigatorAlive,
    required VoidCallback onClosed,
  }) {
    if (!navigatorAlive) {
      recordFailure(announcement, 'aucun Navigator pour le dialogue');
      return false;
    }

    _modalVisible = true;
    unawaited(() async {
      try {
        await showAnnouncementDialog(context, announcement: announcement);
        dismissForSession(announcement.id);
      } catch (error, stack) {
        unawaited(
          AppDiagnostics.logError(
            'Announcements: dialog failed',
            error,
            stack,
            fatal: false,
          ),
        );
        await unmarkSeen(announcement.id);
      } finally {
        _modalVisible = false;
        onClosed();
      }
    }());
    return true;
  }

  // ── Échec de présentation ────────────────────────────────────────────────

  /// Signale une présentation qui n'a pas pu être montée.
  ///
  /// Jamais muet : la ligne part dans `AppDiagnostics` (visible dans le journal
  /// de l'app) et la marque « vue » est annulée par l'appelant.
  static void recordFailure(Announcement announcement, String reason) {
    lastDisplayFailure = '${announcement.id} — $reason';
    unawaited(
      AppDiagnostics.logError(
        'Announcements: presentation could not be mounted',
        StateError('annonce non affichée : $reason'),
        StackTrace.current,
        fatal: false,
        reason: announcement.id,
      ),
    );
  }
}
