// Règles d'affichage, mémoire « déjà vue » et budget réseau des annonces.
//
// Tout est PUR et testable sans plateforme : quelle forme d'affichage pour
// quelle gravité, quelle annonce unique afficher, quelles clés de mémoire
// écrire, et — surtout — QUAND une requête a le droit de partir.
//
// Aucun `Timer` de sondage n'est créé ici : la cadence est celle du socle
// partagé `PollCadence` (le même que les écrans à polling), consultée à chaque
// déclenchement (démarrage, retour au premier plan). On demande, on ne boucle
// pas.
import 'package:bot_creator/core/network/poll_cadence.dart';

import 'announcement.dart';

/// Forme sous laquelle une annonce est présentée.
enum AnnouncementPresentation {
  /// Bandeau refermable en haut de l'accueil.
  banner,

  /// Dialogue modal.
  modal,
}

/// Bannière pour `info` ET `important`, dialogue modal pour `critical`.
AnnouncementPresentation presentationFor(AnnouncementSeverity severity) {
  return severity == AnnouncementSeverity.critical
      ? AnnouncementPresentation.modal
      : AnnouncementPresentation.banner;
}

/// Voies de fermeture qu'un dialogue doit offrir.
enum AnnouncementCloseRoute {
  /// Bouton d'acquittement — TOUJOURS présent, quelle que soit la publication.
  acknowledge,

  /// Bouton « Plus tard », tap hors du dialogue, retour système : seulement
  /// pour une annonce publiée `dismissible: true`.
  defer,
}

/// Les voies de fermeture d'un dialogue.
///
/// Invariant de conception : cette liste n'est JAMAIS vide. Une annonce
/// `dismissible: false` retire le report et le tap hors du dialogue (elle doit
/// être vue et acquittée), pas le bouton qui ferme — un dialogue sans issue
/// serait un piège, jamais une intention produit.
List<AnnouncementCloseRoute> modalCloseRoutes(Announcement announcement) {
  return announcement.dismissible
      ? const <AnnouncementCloseRoute>[
          AnnouncementCloseRoute.acknowledge,
          AnnouncementCloseRoute.defer,
        ]
      : const <AnnouncementCloseRoute>[AnnouncementCloseRoute.acknowledge];
}

/// Le tap hors du dialogue le ferme-t-il ?
bool modalBarrierDismissible(Announcement announcement) =>
    announcement.dismissible;

/// La bannière porte-t-elle une croix de fermeture ?
bool bannerShowsCloseButton(Announcement announcement) =>
    announcement.dismissible;

/// L'annonce à afficher MAINTENANT : la plus grave qui n'a pas encore été vue.
///
/// C'est ici, et nulle part dans l'UI, que vit la règle « UNE SEULE annonce à
/// la fois » : la fonction rend au plus une annonce, et rend `null` quand tout
/// a déjà été vu. L'ordre du serveur n'influence pas le résultat (tri stable
/// par gravité puis identifiant).
Announcement? selectAnnouncementToShow({
  required List<Announcement> candidates,
  required Set<String> seenIds,
}) {
  for (final announcement in sortAnnouncements(candidates)) {
    if (!seenIds.contains(announcement.id)) return announcement;
  }
  return null;
}

/// Mémoire locale « déjà vue » : une clé par identifiant d'annonce.
///
/// Une clé par identifiant — et pas un horodatage global — parce que deux
/// annonces publiées en parallèle doivent pouvoir être vues indépendamment :
/// marquer l'une ne doit pas masquer l'autre, et republier une annonce
/// existante ne doit pas la faire réapparaître.
class AnnouncementSeenStore {
  const AnnouncementSeenStore._();

  static const String keyPrefix = 'announcements.seen.';

  /// Nombre maximal d'identifiants mémorisés. Au-delà, les plus anciens sont
  /// oubliés : sans borne, une clé par annonce vue ferait grossir
  /// `SharedPreferences` indéfiniment.
  static const int maxEntries = 200;

  static String keyFor(String id) => '$keyPrefix$id';

  /// Identifiants reconnus dans un ensemble de clés de préférences.
  static Set<String> idsFromKeys(Iterable<String> keys) {
    final ids = <String>{};
    for (final key in keys) {
      if (!key.startsWith(keyPrefix)) continue;
      final id = key.substring(keyPrefix.length);
      if (id.isEmpty) continue;
      ids.add(id);
    }
    return ids;
  }

  /// Clés à supprimer pour que la mémoire reste bornée : on garde les
  /// [capacity] entrées les plus récentes et on oublie les plus anciennes.
  static List<String> keysToEvict(
    Map<String, int> seenAtByKey, {
    int capacity = AnnouncementSeenStore.maxEntries,
  }) {
    if (seenAtByKey.length <= capacity) return const <String>[];
    final oldestFirst = seenAtByKey.entries.toList(growable: false)
      ..sort((a, b) => a.value.compareTo(b.value));
    return oldestFirst
        .take(seenAtByKey.length - capacity)
        .map((entry) => entry.key)
        .toList(growable: false);
  }
}

/// Budget de récupération : au plus une requête par intervalle courant.
///
/// La cadence est celle du socle partagé : tant que le contenu ne change pas,
/// l'intervalle double jusqu'au plafond ; dès qu'une annonce apparaît, il
/// revient au nominal pour que la suivante arrive tout de suite.
class AnnouncementFetchPolicy {
  AnnouncementFetchPolicy({
    Duration nominal = const Duration(minutes: 5),
    Duration ceiling = const Duration(minutes: 30),
  }) : _cadence = PollCadence(nominal: nominal, ceiling: ceiling);

  final PollCadence _cadence;

  /// Intervalle minimal courant entre deux requêtes.
  Duration get interval => _cadence.current;

  /// Une récupération est-elle due ? (Aucune requête n'est faite ici.)
  bool isDue({required DateTime now, required DateTime? lastAttemptAt}) {
    if (lastAttemptAt == null) return true;
    return now.difference(lastAttemptAt) >= _cadence.current;
  }

  /// Requête aboutie : la cadence ne se resserre que si le contenu a changé.
  void recordSuccess({required bool contentChanged}) {
    _cadence.consume(
      contentChanged ? TickOutcome.changed : TickOutcome.unchanged,
    );
  }

  /// Échec (réseau coupé, 4xx, 5xx) : aucune erreur visible, mais l'intervalle
  /// s'espace comme s'il n'y avait rien de neuf. Un serveur en panne ne doit
  /// pas être martelé par une app qu'on rouvre en boucle.
  void recordFailure() => _cadence.consume(TickOutcome.unchanged);

  /// Retour au premier plan après une longue absence, ou action explicite.
  void reset() => _cadence.reset();
}

/// Pourquoi une récupération est refusée — décidé SANS toucher au réseau.
enum AnnouncementFetchBlock {
  /// Aucune session : l'app ne parle pas au manager pour un utilisateur qui
  /// n'est pas connecté.
  notConnected,

  /// Session expirée sans renouvellement possible : même chose.
  sessionExpired,

  /// Adresse du manager inconnue.
  noServer,

  /// Dernier essai en échec réseau : on attend avant de retenter.
  offlineCooldown,

  /// Budget de requêtes : la cadence n'autorise pas encore le prochain appel.
  budget,
}

/// Décision pure : `null` = la requête peut partir.
AnnouncementFetchBlock? blockAnnouncementFetch({
  required bool hasSession,
  required bool sessionExpired,
  required String serverBaseUrl,
  required DateTime now,
  required DateTime? lastAttemptAt,
  required DateTime? offlineUntil,
  required AnnouncementFetchPolicy policy,
}) {
  if (!hasSession) return AnnouncementFetchBlock.notConnected;
  if (sessionExpired) return AnnouncementFetchBlock.sessionExpired;
  if (serverBaseUrl.trim().isEmpty) return AnnouncementFetchBlock.noServer;
  if (offlineUntil != null && now.isBefore(offlineUntil)) {
    return AnnouncementFetchBlock.offlineCooldown;
  }
  if (!policy.isDue(now: now, lastAttemptAt: lastAttemptAt)) {
    return AnnouncementFetchBlock.budget;
  }
  return null;
}
