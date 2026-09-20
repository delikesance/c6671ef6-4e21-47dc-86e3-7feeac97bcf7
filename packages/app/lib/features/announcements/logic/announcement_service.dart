// Service des annonces in-app : ici la décision rencontre l'affichage.
//
// Trois responsabilités, trois fichiers, un seul propriétaire par état :
//   * `announcement.dart` et `announcement_policy.dart` — les décisions pures
//     (quelle annonce, bannière ou dialogue, quelles clés « vue », cadence) ;
//   * `announcement_fetch.dart` — le transport : session, client, réseau et
//     lecture de la cadence autorisée ;
//   * `announcement_presenter.dart` — le montage à l'écran et la mémoire
//     « déjà vue » ;
// ce fichier les branche et garde LA garantie métier : la marque « vue » est
// écrite AVANT l'affichage, puis ANNULÉE si la présentation échoue. Une annonce
// réellement affichée ne se remontre jamais ; une annonce qui a échoué à
// s'afficher n'est pas consommée.
//
// Deux règles de robustesse, jamais négociées :
//   * réseau coupé, 4xx, JSON illisible, session absente → AUCUNE erreur
//     visible, aucun écran bloqué : tout part dans AppDiagnostics ;
//   * pas de nouveau `Timer` de sondage. La récupération est DEMANDÉE au
//     démarrage et à chaque retour au premier plan, et c'est `PollCadence`
//     (socle partagé de l'app) qui dit si une requête a le droit de partir.
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_fetch.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/logic/announcement_presenter.dart';

/// Suit le retour au premier plan : une annonce publiée pendant que l'app
/// était en arrière-plan doit pouvoir apparaître sans redémarrage.
class _AnnouncementLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(AnnouncementService.refresh());
  }
}

class AnnouncementService {
  AnnouncementService._();

  /// Racine de navigation, injectée par `main.dart` : le service monte la
  /// bannière dans l'overlay et le dialogue sans dépendre de la racine de
  /// l'app.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Délai avant de retenter quand le dernier essai a échoué pour une raison
  /// réseau (app hors ligne) : on ne requête pas, on attend.
  static const Duration offlineCooldown = Duration(minutes: 10);

  /// Intervalle nominal entre deux récupérations (`info`/`important`
  /// comprises) — passé à `PollCadence`, qui l'espace tant que rien ne change.
  static const Duration nominalInterval = Duration(minutes: 5);

  /// Plafond de l'espacement automatique.
  static const Duration ceilingInterval = Duration(minutes: 30);

  static final AnnouncementFetchPolicy _policy = AnnouncementFetchPolicy(
    nominal: nominalInterval,
    ceiling: ceilingInterval,
  );

  static bool _busy = false;
  static _AnnouncementLifecycleObserver? _observer;

  // ── Points d'injection pour les tests (jamais utilisés en production) ────

  /// Remplace la résolution du client authentifié (`null` = pas de client).
  @visibleForTesting
  static Future<MainApiClient?> Function()? debugClientResolver;

  /// Remplace l'appel réseau. Sert à simuler un appareil hors ligne ou un
  /// serveur qui refuse la lecture, sans attendre les relances du client HTTP.
  @visibleForTesting
  static Future<List<Map<String, dynamic>>> Function(MainApiClient client)?
  debugAnnouncementsFetcher;

  /// Remplace la résolution de l'emplacement qui héberge la bannière
  /// (`null` = aucun emplacement disponible).
  ///
  /// Un test de widget ne peut pas provoquer la disparition de l'overlay entre
  /// l'écriture de la marque « vue » et le montage : le cas réel — l'app se
  /// démonte pendant l'écriture (I/O disque), ou l'overlay est déjà détruit —
  /// n'existe que par l'ordonnancement d'une vraie horloge. C'est ce cas que
  /// cette couture rend déterministe.
  @visibleForTesting
  static OverlayState? Function()? debugBannerHostOverride;

  /// Dernier échec de présentation. L'état appartient au présentateur ; cette
  /// façade le garde lisible sous le nom que les tests connaissent.
  @visibleForTesting
  static String? get debugLastDisplayFailure =>
      AnnouncementPresenter.lastDisplayFailure;

  /// Remet tout l'état à zéro (entre deux tests).
  @visibleForTesting
  static void debugResetForTests() {
    debugClientResolver = null;
    debugAnnouncementsFetcher = null;
    debugBannerHostOverride = null;
    AnnouncementPresenter.reset();
    AnnouncementFetcher.reset();
    _busy = false;
    _policy.reset();
  }

  /// Retire l'observateur de cycle de vie (tests et arrêt propre).
  @visibleForTesting
  static void debugDetach({WidgetsBinding? binding}) {
    final observer = _observer;
    if (observer == null) return;
    (binding ?? WidgetsBinding.instance).removeObserver(observer);
    _observer = null;
  }

  // ── Installation ─────────────────────────────────────────────────────────

  /// Câble la racine de navigation et l'écoute du cycle de vie.
  ///
  /// À appeler APRÈS la première peinture (comme la détection de mise à jour) :
  /// rien de tout cela n'est dans la chaîne d'init critique.
  static void install({
    required GlobalKey<NavigatorState> key,
    WidgetsBinding? binding,
  }) {
    navigatorKey = key;
    final target = binding ?? WidgetsBinding.instance;
    _observer ??= _AnnouncementLifecycleObserver();
    target.addObserver(_observer!);
  }

  // ── Récupération ─────────────────────────────────────────────────────────

  /// Demande une récupération puis affiche AU PLUS une annonce.
  ///
  /// Ne lève jamais : l'appelant n'a rien à intercepter. [force] court-circuite
  /// le budget et la garde hors ligne (jamais l'absence de session : on ne
  /// parle pas à un serveur quand personne n'est connecté).
  static Future<void> refresh({bool force = false}) async {
    if (_busy) return;
    _busy = true;
    try {
      final candidates = await AnnouncementFetcher.run(
        force: force,
        policy: _policy,
        offlineCooldown: offlineCooldown,
        clientResolver: debugClientResolver,
        entriesFetcher: debugAnnouncementsFetcher,
      );
      // `null` : rien à présenter (session absente, hors ligne, serveur qui
      // refuse). Sinon, c'est la charge fraîche — ou celle déjà en main si le
      // budget a refusé la requête.
      if (candidates == null) return;
      await _showNextFromCache(candidates);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Announcements: refresh failed',
          error,
          stack,
          fatal: false,
        ),
      );
    } finally {
      _busy = false;
    }
  }

  // ── Affichage ────────────────────────────────────────────────────────────

  /// Affiche l'annonce la plus grave non encore vue, s'il y en a une et si
  /// aucun emplacement n'est déjà occupé : UNE SEULE annonce à la fois.
  ///
  /// [fresh] : la charge qui vient d'être récupérée. Sans elle — bannière
  /// fermée, dialogue refermé, emplacement libéré — on relit le cache du
  /// transport, qui n'existe qu'à un seul endroit.
  static Future<void> _showNextFromCache([List<Announcement>? fresh]) async {
    if (AnnouncementPresenter.isOccupied) return;

    final selection = selectAnnouncementToShow(
      candidates: fresh ?? AnnouncementFetcher.candidates,
      seenIds: await AnnouncementPresenter.seenIds(),
    );
    if (selection == null) return;

    final context = navigatorKey?.currentContext;
    if (context == null || !context.mounted) return;

    // Marquée AVANT l'affichage : une app tuée pendant que l'annonce est à
    // l'écran ne la remontre pas au lancement suivant. C'est cette écriture —
    // et elle seule — qui garantit « jamais deux fois ».
    await AnnouncementPresenter.markSeen(selection.id);

    final presented = switch (presentationFor(selection.severity)) {
      AnnouncementPresentation.banner => AnnouncementPresenter.showBanner(
        host: _bannerHost(),
        announcement: selection,
        onDismissed: () => unawaited(_showNextFromCache()),
      ),
      AnnouncementPresentation.modal => AnnouncementPresenter.showModal(
        context: context,
        announcement: selection,
        navigatorAlive: navigatorKey?.currentState != null,
        onClosed: () => unawaited(_showNextFromCache()),
      ),
    };

    // Présentation impossible : l'annonce n'a PAS été lue, la marque « vue »
    // est donc ANNULÉE. Sans ce retour en arrière, l'écriture faite ci-dessus
    // la consommerait en silence — la garantie « jamais deux fois » protège ce
    // qui a été VU, pas ce qui a échoué à s'afficher.
    if (!presented) {
      await AnnouncementPresenter.unmarkSeen(selection.id);
    }
  }

  /// L'emplacement qui héberge la bannière, ou `null` s'il n'y en a pas.
  ///
  /// Résolu par l'ÉTAT du Navigator, jamais par `Overlay.maybeOf(context)` : ce
  /// lookup cherche un repère publié par l'entrée d'overlay elle-même, donc
  /// introuvable depuis le contexte du Navigator — or l'overlay est un
  /// DESCENDANT de ce contexte. La recherche rendait toujours `null` : aucune
  /// bannière `info`/`important` n'était montée, et l'annonce était consommée
  /// sans avoir été lue.
  static OverlayState? _bannerHost() {
    final override = debugBannerHostOverride;
    if (override != null) return override();
    return navigatorKey?.currentState?.overlay;
  }
}
