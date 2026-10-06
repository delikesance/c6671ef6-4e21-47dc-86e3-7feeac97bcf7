/// Contrat entre l'écran « historique des versions d'un bot » (partagé) et la
/// façon dont chaque client parle au serveur : l'app passe par `MainApiClient`
/// (et réapplique la version restaurée dans sa copie locale), le Studio par
/// `StudioApi` (le serveur est la seule source de vérité, rien à réappliquer).
library;

/// Une version de la configuration complète d'un bot, telle que le Manager la
/// liste (`GET /gateway/bots/{id}/versions`).
class BotConfigVersionEntry {
  const BotConfigVersionEntry({required this.key, this.size = 0, this.time});

  /// Clé d'objet de la version (`configs/{bot}/versions/2026-…json`) : c'est
  /// aussi son identifiant pour l'aperçu, la suppression et la restauration.
  final String key;
  final int size;

  /// Horodatage tel que le serveur le rend, ou `null` : l'écran retombe alors
  /// sur la date inscrite dans le nom du fichier.
  final String? time;

  factory BotConfigVersionEntry.fromWire(Map<String, dynamic> json) {
    final time = json['time']?.toString();
    return BotConfigVersionEntry(
      key: (json['key'] ?? '').toString(),
      size: int.tryParse('${json['size']}') ?? 0,
      time: time == null || time.isEmpty ? null : time,
    );
  }
}

/// Noms des commandes d'une configuration, quelle que soit sa forme : liste
/// d'objets, ou table `id -> objet`.
List<String> botConfigCommandNames(dynamic rawCommands) {
  final Iterable<dynamic> items = rawCommands is List
      ? rawCommands
      : rawCommands is Map
      ? rawCommands.values
      : const <dynamic>[];
  return [
    for (final item in items.whereType<Map>()) (item['name'] ?? '?').toString(),
  ];
}

/// Issue d'une restauration CÔTÉ SERVEUR.
enum BotConfigRestoreStatus {
  /// Le serveur a restauré la version.
  restored,

  /// Refus de FOND : la version visée est sous le plancher de plausibilité
  /// (`409 bot_config_version_too_small`). On propose de la forcer.
  floorRefused,

  /// Le serveur a répondu sans confirmer la restauration.
  notConfirmed,

  /// Autre échec (réseau, 5xx…), avec sa raison quand on la connaît.
  failed,
}

class BotConfigRestoreResult {
  const BotConfigRestoreResult(this.status, {this.reason});

  final BotConfigRestoreStatus status;
  final String? reason;
}

abstract class BotConfigVersionsHost {
  /// Les versions du bot. Lève si la liste est injoignable.
  Future<List<BotConfigVersionEntry>> list(String botId);

  /// Le contenu d'une version, pour l'aperçu.
  Future<Map<String, dynamic>> preview(String botId, String key);

  Future<void> delete(String botId, String key);

  /// Les noms des commandes de la version, pour la confirmation. Lève si le
  /// contenu est illisible : l'écran laisse alors restaurer quand même.
  Future<List<String>> commandNames(String botId, String key);

  /// Le nombre de commandes que la restauration va remplacer, ou `null`.
  Future<int?> currentCommandCount(String botId);

  /// Demande la restauration au serveur. [confirmOvershrink] la FORCE : il
  /// n'est posé qu'après un accord explicite de l'utilisateur.
  Future<BotConfigRestoreResult> restore(
    String botId,
    String key, {
    bool confirmOvershrink = false,
  });

  /// Réapplique la version restaurée dans la copie locale du client. Le serveur
  /// A déjà restauré : un échec ici est dit tel quel (la copie locale diverge).
  /// Sans copie locale (Studio), ne fait rien.
  Future<void> applyRestoredLocally(String botId);

  /// Une raison lisible pour une erreur.
  String describeError(Object error);
}
