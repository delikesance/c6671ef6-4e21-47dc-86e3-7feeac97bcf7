// Annonce in-app publiée depuis l'admin, et son décodage DÉFENSIF.
//
// Le serveur est la seule source de ces annonces, mais il n'est pas la seule
// chose qui peut mal tourner : une entrée peut arriver sans identifiant, avec
// une gravité inconnue (un manager plus récent que l'app installée), un corps
// ou un lien d'un type inattendu, ou dans un tableau mixte. Rien de tout cela
// ne doit faire tomber le décodage NI produire une demi-annonce à l'écran :
// une entrée illisible est IGNORÉE, les autres passent.
//
// Fichier PUR : aucun import Flutter, aucun réseau, aucun accès disque. Ce qui
// décide (gravité connue ? identifiant exploitable ? lien sûr ?) est ici, donc
// vérifiable sans appareil.
import 'dart:convert';

/// Gravité d'une annonce, telle que publiée depuis l'admin.
///
/// L'ordre de déclaration EST l'ordre de gravité : `index` sert de priorité.
enum AnnouncementSeverity {
  info,
  important,
  critical;

  /// Plus la valeur est haute, plus l'annonce est intrusive.
  int get priority => index;

  /// `null` pour toute valeur inconnue ou d'un type inattendu.
  ///
  /// L'appelant DOIT alors ignorer l'annonce : la gravité décide de la forme
  /// d'affichage (bannière ou dialogue bloquant), donc deviner serait prendre
  /// le risque d'un modal intrusif pour un simple message d'information.
  static AnnouncementSeverity? tryParse(Object? raw) {
    if (raw is! String) return null;
    final normalized = raw.trim().toLowerCase();
    for (final severity in values) {
      if (severity.name == normalized) return severity;
    }
    return null;
  }
}

/// Une annonce telle qu'affichée : bannière (`info`, `important`) ou dialogue
/// modal (`critical`).
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    this.linkUrl,
    this.dismissible = true,
  });

  /// Identifiant serveur. Sert de clé à la mémoire « déjà vue » : sans lui,
  /// une annonce ne peut pas être dédupliquée, donc ne peut pas être affichée.
  final String id;

  final String title;

  /// Corps optionnel : absent ou illisible, il vaut `''` et n'est simplement
  /// pas rendu.
  final String body;

  final AnnouncementSeverity severity;

  /// Lien « En savoir plus », déjà validé `https` absolu.
  final Uri? linkUrl;

  /// `false` = publiée par l'admin comme non refermable sans action.
  final bool dismissible;

  bool get isCritical => severity == AnnouncementSeverity.critical;

  bool get hasLink => linkUrl != null;

  /// Décode UNE entrée. `null` = illisible → à ignorer, jamais à afficher.
  static Announcement? tryParse(Object? raw) {
    if (raw is! Map) return null;

    final id = _readIdentifier(raw['id']);
    if (id == null) return null;

    final title = _readText(raw['title']);
    if (title == null) return null;

    // Gravité inconnue, absente ou d'un autre type : on ignore l'annonce
    // entière plutôt que de choisir bannière ou dialogue à sa place.
    final severity = AnnouncementSeverity.tryParse(raw['severity']);
    if (severity == null) return null;

    return Announcement(
      id: id,
      title: title,
      // Un corps d'un type inattendu ne condamne pas l'annonce : le titre
      // reste lisible et c'est lui qui porte le message.
      body: _readText(raw['body']) ?? '',
      severity: severity,
      // Un lien invalide n'est jamais ouvert, mais ne fait pas disparaître
      // l'annonce.
      linkUrl: safeLinkUri(raw['link_url']),
      dismissible: _readDismissible(raw['dismissible']),
    );
  }

  /// Décode un lot, dans n'importe laquelle des formes que peut rendre le
  /// client : `List`, `List<Map>`, ou l'objet qui enveloppe le tableau
  /// (`{"data": [...]}` / `{"announcements": [...]}`).
  ///
  /// Rend TOUJOURS une liste, triée du plus grave au moins grave : jamais
  /// d'exception, jamais d'entrée partielle.
  static List<Announcement> parseEntries(Object? decoded) {
    final List<Object?> rawEntries;
    if (decoded is List) {
      rawEntries = decoded;
    } else if (decoded is Map) {
      rawEntries = _listFromMap(decoded);
    } else {
      rawEntries = const <Object?>[];
    }

    final byId = <String, Announcement>{};
    for (final entry in rawEntries) {
      final announcement = tryParse(entry);
      // Entrée illisible (chaîne, `null`, nombre, objet sans id…) : ignorée.
      if (announcement == null) continue;
      final existing = byId[announcement.id];
      // Doublon d'identifiant : on garde la PLUS GRAVE — un `critical` ne doit
      // jamais être rétrogradé en `info` par la seconde occurrence. À gravité
      // égale, la première occurrence gagne.
      if (existing == null ||
          announcement.severity.priority > existing.severity.priority) {
        byId[announcement.id] = announcement;
      }
    }

    return sortAnnouncements(byId.values);
  }

  /// Décode le corps d'une réponse HTTP. Un JSON illisible ou d'une autre
  /// forme rend une liste vide — jamais une exception qui remonterait à
  /// l'écran.
  static List<Announcement> parseList(String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return const <Announcement>[];
    }
    return parseEntries(decoded);
  }

  static List<Object?> _listFromMap(Map<Object?, Object?> map) {
    for (final key in const <String>['data', 'announcements', 'items']) {
      final value = map[key];
      if (value is List) return value;
    }
    return const <Object?>[];
  }

  /// Identifiant exploitable : une chaîne non vide, ou un entier (un `id`
  /// numérique arrive en `int` après `jsonDecode`). Tout le reste — absent,
  /// `null`, objet, liste, chaîne vide — rend `null`.
  static String? _readIdentifier(Object? raw) {
    if (raw is String) {
      final trimmed = raw.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (raw is int) return raw.toString();
    return null;
  }

  static String? _readText(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// `false` seulement quand le serveur dit explicitement `false`. Une valeur
  /// d'un autre type rend `true` : un champ illisible ne doit JAMAIS
  /// transformer une annonce refermable en dialogue dont on ne sort pas.
  static bool _readDismissible(Object? raw) => raw is bool ? raw : true;

  /// Lien ouvrable : une chaîne absolue en `https` uniquement. `http`, `file:`,
  /// `javascript:` ou un type inattendu sont refusés à la source — le lien
  /// n'est jamais ouvert, l'annonce reste affichée sans lui.
  static Uri? safeLinkUri(Object? raw) {
    if (raw is! String) return null;
    try {
      final uri = Uri.tryParse(raw.trim());
      if (uri == null) return null;
      if (uri.scheme.toLowerCase() != 'https') return null;
      if (uri.host.isEmpty) return null;
      return uri;
    } catch (_) {
      return null;
    }
  }
}

/// Ordre d'affichage : du plus grave au moins grave, puis par identifiant
/// croissant.
///
/// Le second critère n'est pas cosmétique : il rend la sélection DÉTERMINISTE
/// quel que soit l'ordre (ou le désordre) rendu par le serveur, donc
/// reproductible d'un lancement à l'autre.
int compareAnnouncementsBySeverity(Announcement a, Announcement b) {
  final bySeverity = b.severity.priority.compareTo(a.severity.priority);
  return bySeverity != 0 ? bySeverity : a.id.compareTo(b.id);
}

/// Copie triée de [candidates] (la liste d'entrée n'est pas modifiée).
List<Announcement> sortAnnouncements(Iterable<Announcement> candidates) {
  final sorted = candidates.toList(growable: false)
    ..sort(compareAnnouncementsBySeverity);
  return sorted;
}
