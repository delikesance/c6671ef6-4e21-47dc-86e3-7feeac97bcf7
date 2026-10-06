/// Contrat entre la modale d'historique d'une commande (partagée) et la façon
/// dont chaque client parle au serveur : l'app passe par son dépôt granulaire,
/// le Studio par `StudioApi`.
library;

/// Une version journalisée d'une commande.
class CommandHistoryEntry {
  const CommandHistoryEntry({
    required this.historyId,
    required this.createdAt,
    this.authorOwnerId = '',
    this.sizeBytes = 0,
  });

  final String historyId;
  final DateTime? createdAt;

  /// Identifiant du propriétaire auteur, tel que le serveur le rend (jamais
  /// traduit, vide quand le serveur n'en donne pas).
  final String authorOwnerId;
  final int sizeBytes;
}

/// Issue d'une restauration. Un conflit n'est jamais une panne : le serveur a
/// refusé d'écrire, rien n'a changé.
enum CommandRestoreStatus {
  /// Version restaurée côté serveur.
  restored,

  /// `409` : la révision attendue est périmée, on propose de recharger.
  conflict,

  /// Refus de FOND : la version visée est trop pauvre (plancher serveur).
  floorRefused,

  /// Autre échec (réseau, 5xx…), éventuellement avec sa raison.
  failed,
}

class CommandRestoreResult {
  const CommandRestoreResult(this.status, {this.reason});

  final CommandRestoreStatus status;
  final String? reason;
}

abstract class CommandHistoryHost {
  /// Vrai quand le serveur sert un historique à ce client. Faux est un ÉTAT
  /// (la modale dit pourquoi), pas une erreur.
  Future<bool> isAvailable();

  /// Les versions, la plus récente d'abord. Lève si la liste est injoignable.
  Future<List<CommandHistoryEntry>> list(
    String botId,
    String commandId, {
    int? limit,
  });

  /// Le contenu d'une version, pour l'aperçu.
  Future<Map<String, dynamic>> preview(
    String botId,
    String commandId,
    String historyId,
  );

  Future<void> delete(String botId, String commandId, String historyId);

  Future<CommandRestoreResult> restore(
    String botId,
    String commandId,
    String historyId, {
    bool confirmOvershrink = false,
  });

  /// Relit la commande côté serveur (pour que le rejeu parte avec la bonne
  /// révision). Lève si la relecture échoue.
  Future<void> reload(String botId, String commandId);

  /// Une raison lisible pour une erreur, ou vide.
  String describeError(Object error);
}
