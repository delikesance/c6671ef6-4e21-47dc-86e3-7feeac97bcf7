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
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_dialog.dart';

/// Monte les annonces à l'écran et tient la mémoire « déjà vue ».
class AnnouncementPresenter {
  AnnouncementPresenter._();

  static OverlayEntry? _bannerEntry;
  static bool _modalVisible = false;

  /// Dernier échec de présentation (« la bannière ou le dialogue n'a pas pu
  /// être monté, donc l'annonce n'a pas été consommée »).
  static String? lastDisplayFailure;

  /// Un emplacement est-il déjà occupé ? UNE SEULE annonce à la fois.
  static bool get isOccupied => _bannerEntry != null || _modalVisible;

  /// Remet l'état de présentation à zéro (entre deux tests).
  ///
  /// La bannière encore à l'écran n'est pas retirée de son overlay : l'arbre
  /// du test précédent est déjà détruit, et toucher une entrée orpheline
  /// ferait échouer la remise à zéro. On oublie simplement le pointeur.
  static void reset() {
    lastDisplayFailure = null;
    _modalVisible = false;
    _bannerEntry = null;
  }

  // ── Mémoire « déjà vue » ─────────────────────────────────────────────────

  /// Identifiants déjà vus, relus des préférences (vide si indisponibles).
  static Future<Set<String>> seenIds() async {
    final prefs = await _preferences();
    if (prefs == null) return const <String>{};
    return AnnouncementSeenStore.idsFromKeys(prefs.getKeys());
  }

  /// Écrit la marque « vue » AVANT l'affichage : une app tuée pendant que
  /// l'annonce est à l'écran ne la remontre pas au lancement suivant.
  static Future<void> markSeen(String id) async {
    final prefs = await _preferences();
    if (prefs == null) return;
    try {
      await prefs.setInt(
        AnnouncementSeenStore.keyFor(id),
        DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      // Mémoire bornée : sans cela, une clé par annonce vue pour toujours
      // ferait grossir `SharedPreferences` indéfiniment.
      final seenAt = <String, int>{};
      for (final key in prefs.getKeys()) {
        if (!key.startsWith(AnnouncementSeenStore.keyPrefix)) continue;
        seenAt[key] = prefs.getInt(key) ?? 0;
      }
      for (final key in AnnouncementSeenStore.keysToEvict(seenAt)) {
        await prefs.remove(key);
      }
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Announcements: could not persist the seen marker',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  /// Annule la marque « vue » : l'annonce n'a pas été montrée, elle doit donc
  /// pouvoir se représenter (cadence nominale, ou retour au premier plan).
  ///
  /// C'est le pendant de [markSeen] : « jamais deux fois » ne vaut que pour ce
  /// qui a réellement été affiché.
  static Future<void> unmarkSeen(String id) async {
    final prefs = await _preferences();
    if (prefs == null) return;
    try {
      await prefs.remove(AnnouncementSeenStore.keyFor(id));
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Announcements: could not clear the seen marker',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  // ── Bannière ─────────────────────────────────────────────────────────────

  /// Monte la bannière dans [host], ou rend `false` si l'emplacement est
  /// indisponible — auquel cas l'appelant annule la marque « vue ».
  static bool showBanner({
    required OverlayState? host,
    required Announcement announcement,
    required VoidCallback onDismissed,
  }) {
    if (host == null) {
      recordFailure(announcement, 'aucun overlay disponible');
      return false;
    }

    final entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        // En haut de l'écran, sous la barre d'état : l'accueil reste utilisable
        // sous la bannière, qui n'intercepte pas les taps hors d'elle-même.
        top: MediaQuery.paddingOf(overlayContext).top + 8,
        left: 12,
        right: 12,
        child: AnnouncementBanner(
          announcement: announcement,
          onDismiss: () {
            removeBanner();
            onDismissed();
          },
        ),
      ),
    );

    try {
      host.insert(entry);
    } catch (error, stack) {
      // Overlay détruit entre la résolution et l'insertion : on ne garde pas
      // l'entrée, sinon l'emplacement resterait occupé pour toujours et PLUS
      // AUCUNE annonce ne pourrait s'afficher.
      entry.dispose();
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
    unawaited(
      AppDiagnostics.logInfo(
        'Announcements: banner shown',
        data: <String, Object?>{'id': announcement.id},
      ),
    );
    return true;
  }

  /// Retire la bannière de son overlay, si elle y est encore.
  static void removeBanner() {
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
    unawaited(
      () async {
        try {
          await showAnnouncementDialog(context, announcement: announcement);
        } catch (error, stack) {
          unawaited(
            AppDiagnostics.logError(
              'Announcements: dialog failed',
              error,
              stack,
              fatal: false,
            ),
          );
          // Le dialogue n'a pas été vu : la marque « vue » est rendue, sinon
          // l'annonce critique serait perdue pour de bon.
          await unmarkSeen(announcement.id);
        } finally {
          _modalVisible = false;
          onClosed();
        }
      }(),
    );
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

  static Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Announcements: preferences unavailable',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }
  }
}
