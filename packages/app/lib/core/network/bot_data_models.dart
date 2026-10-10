// MODÈLES DU CONTRAT GRANULAIRE `/api/v2` — DONNÉES SEULES, AUCUN RÉSEAU.
//
// POURQUOI CE FICHIER EXISTE : les formes JSON de la façade `/api/v2` viennent
// d'être figées côté manager (handlers_v2.go + bot_config_facade.go) et elles
// sont le CONTRAT. Les lire à la main dans les appelants (index de map, cast
// `as String` qui explose) est exactement ce qui fait qu'un champ renommé côté
// serveur devient une panne à l'exécution au lieu d'un `null` lisible : d'où un
// lieu unique de décodage, tolérant par construction.
//
// TROIS RÈGLES DE DÉCODAGE, ET ELLES SONT DÉLIBÉRÉES :
//   1. un champ absent, d'un type inattendu ou vide rend une valeur neutre
//      (chaîne vide, zéro, `false`) — jamais une exception : une liste de
//      commandes qu'on ne sait pas décoder entièrement vaut mieux qu'un écran
//      qui refuse de s'ouvrir ;
//   2. RIEN N'EST INVENTÉ : si le serveur ne dit pas d'où vient un champ, le
//      modèle ne le fabrique pas (voir `CommandSummary.contentHash` en legacy) ;
//   3. les modèles sont IMMUABLES et ne portent aucune logique réseau : c'est
//      `BotDataRepository` qui décide, eux qui décrivent.

/// Ce que CE serveur sait faire, tel qu'il l'annonce lui-même
/// (`GET /api/v2/capabilities`).
///
/// POURQUOI LA SONDE EST LA SEULE SOURCE DE VÉRITÉ : le format ne se choisit ni
/// par la version de l'application, ni par un drapeau compilé, ni par la
/// présence d'un champ dans une autre réponse. Un ancien serveur ne connaît pas
/// la route : l'appel rend 404 et la sonde est `null` — c'est le cas NOMINAL
/// d'un parc hétérogène, pas une panne.
class BotCapabilities {
  const BotCapabilities({
    required this.granularApi,
    required this.configRevisionAware,
    required this.commandHistory,
    required this.commandHistoryLimit,
    this.fullPushRevision = false,
  });

  /// Version du contrat granulaire annoncée (aujourd'hui `1`).
  final String granularApi;

  /// Le serveur HONORE-t-il `If-Match` sur la révision du document ?
  ///
  /// C'est une propriété du BINAIRE, pas d'un bot : elle ne dit PAS que la
  /// révision d'un bot donné est connue. Seules les lectures le disent.
  final bool configRevisionAware;

  /// Le journal d'historique par commande est-il branché SUR CE SERVEUR ?
  final bool commandHistory;

  /// Borne de rétention du journal : nombre de versions conservées par entité.
  final int commandHistoryLimit;

  /// `POST /gateway/bots/sync` honore-t-il `expectRevision` ? Un serveur plus
  /// ancien rejette les champs inconnus du corps : on ne l'envoie qu'à un
  /// serveur qui l'annonce.
  final bool fullPushRevision;

  /// Décode la sonde. Rend `null` quand la réponse n'est PAS exploitable
  /// (corps vide, `granular_api` absent) : un `200` sans version annoncée ne
  /// prouve pas qu'un contrat existe, et se rabattre sur le legacy est le seul
  /// choix qui ne peut pas bloquer une sauvegarde.
  static BotCapabilities? fromWire(Map<String, dynamic> json) {
    final version = _wireString(json['granular_api']);
    if (version.isEmpty) return null;
    return BotCapabilities(
      granularApi: version,
      configRevisionAware: json['config_revision_aware'] == true,
      commandHistory: json['command_history'] == true,
      commandHistoryLimit: _wireInt(json['command_history_limit']) ?? 0,
      fullPushRevision: json['full_push_revision'] == true,
    );
  }

  /// Vrai quand les deux champs d'historique sont cohérents (le serveur garantit
  /// l'ensemble : un journal branché avec une borne nulle serait une promesse
  /// vide). L'appelant ne doit PAS ouvrir d'historique quand c'est faux.
  bool get supportsCommandHistory => commandHistory && commandHistoryLimit > 0;

  @override
  String toString() =>
      'BotCapabilities(granular_api: $granularApi, '
      'config_revision_aware: $configRevisionAware, '
      'command_history: $commandHistory, limit: $commandHistoryLimit)';
}

/// L'entrée ALLÉGÉE d'une commande (`GET /api/v2/bots/{botId}/commands`).
///
/// Elle ne porte AUCUN contenu de commande : ni blocs, ni script, ni données.
/// Il n'y a pas de champ de dossier non plus, et ce n'est pas un oubli : le
/// module Go ne connaît aucun `folder_id` (les dossiers sont purement locaux),
/// donc un tel champ ici serait une valeur inventée.
class CommandSummary {
  const CommandSummary({
    required this.id,
    required this.name,
    required this.trigger,
    required this.contentHash,
  });

  final String id;
  final String name;

  /// Mot déclencheur, dérivé côté serveur du mode legacy de la commande.
  /// Vide quand la commande n'a pas de mot déclencheur — ce n'est pas une
  /// erreur de décodage.
  final String trigger;

  /// Empreinte du contenu EXPURGÉ, calculée par le serveur (sha256 Go).
  ///
  /// POURQUOI ELLE N'EST JAMAIS RECALCULÉE ICI : l'empreinte locale d'un
  /// document Dart ne serait pas comparable à celle du serveur (canonisation et
  /// expurgation différentes) ; comparer l'une à l'autre ferait « détecter » une
  /// différence sur des contenus identiques. Vide = pas d'empreinte, donc
  /// aucune comparaison possible.
  final String contentHash;

  static CommandSummary? fromWire(Object? item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    final id = _wireString(map['id']);
    if (id.isEmpty) return null;
    return CommandSummary(
      id: id,
      name: _wireString(map['name']),
      trigger: _wireString(map['trigger']),
      contentHash: _wireString(map['content_hash']),
    );
  }
}

/// Le résultat d'une lecture de LISTE : les commandes, plus la révision du
/// document qui les porte.
///
/// POURQUOI LA RÉVISION VOYAGE AVEC LA LISTE : c'est elle que le prochain
/// `If-Match` renverra. La mémoriser séparément de la lecture serait un état de
/// plus à tenir à jour, et une occasion de plus d'écrire avec une précondition
/// périmée.
class CommandPage {
  const CommandPage({
    required this.botId,
    required this.commands,
    this.revision,
    this.isLegacy = false,
    this.truncated = false,
  });

  final String botId;
  final List<CommandSummary> commands;

  /// Révision du document telle que le serveur l'a rendue. `null` (ou vide)
  /// veut dire INCONNUE : un client ne doit jamais fabriquer un `If-Match` à
  /// partir de ça (il serait refusé à raison) — il écrit sans précondition.
  final String? revision;

  /// Vrai quand la page vient du DOCUMENT ENTIER (chemin legacy) plutôt que de
  /// la liste allégée : l'appelant peut alors savoir que `trigger` et
  /// `contentHash` sont absents parce que le format legacy ne les porte pas.
  final bool isLegacy;

  /// Vrai quand la page a été bâtie sur une partie seulement du document lu
  /// (liste non conforme). Un appelant qui affiche un écran vide doit pouvoir
  /// dire « je n'ai pas su lire » plutôt que « ce bot n'a aucune commande ».
  final bool truncated;

  /// Décode la liste allégée v2.
  static CommandPage fromWire(Map<String, dynamic> json) {
    final raw = json['commands'];
    final commands = <CommandSummary>[];
    var truncated = false;
    if (raw is List) {
      for (final item in raw) {
        final summary = CommandSummary.fromWire(item);
        if (summary == null) {
          truncated = true;
          continue;
        }
        commands.add(summary);
      }
    } else if (raw != null) {
      truncated = true;
    }
    return CommandPage(
      botId: _wireString(json['bot_id']),
      commands: List<CommandSummary>.unmodifiable(commands),
      revision: _wireNullableString(json['revision']),
      truncated: truncated,
    );
  }

  /// Bâtit la même page à partir du DOCUMENT ENTIER (chemin legacy).
  ///
  /// POURQUOI CE N'EST PAS UNE LISTE ÉQUIVALENTE : le document legacy porte
  /// `commands` (identifiant + nom), mais ni mot déclencheur ni empreinte — ces
  /// deux valeurs sont DÉRIVÉES côté serveur. Les recalculer localement
  /// produirait des valeurs qui ne correspondraient à rien de comparable ; elles
  /// restent donc vides, et `isLegacy` est vrai pour que l'appelant le sache.
  static CommandPage fromLegacyDocument({
    required String botId,
    required Map<String, dynamic> document,
  }) {
    final raw = document['commands'];
    final commands = <CommandSummary>[];
    var truncated = false;
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) {
          truncated = true;
          continue;
        }
        final map = Map<String, dynamic>.from(item);
        final id = _wireString(map['id']);
        if (id.isEmpty) {
          truncated = true;
          continue;
        }
        commands.add(
          CommandSummary(
            id: id,
            name: _wireString(map['name']),
            trigger: '',
            contentHash: '',
          ),
        );
      }
    } else if (raw != null) {
      truncated = true;
    }
    return CommandPage(
      botId: botId,
      commands: List<CommandSummary>.unmodifiable(commands),
      isLegacy: true,
      truncated: truncated,
    );
  }

  /// La map d'entité brute d'une commande du document legacy, ou `null`.
  ///
  /// POURQUOI ICI : la même lecture tolérante du document sert à la liste et au
  /// détail legacy ; la dupliquer dans le dépôt ferait diverger les deux.
  static Map<String, dynamic>? legacyCommandRaw(
    Map<String, dynamic> document,
    String commandId,
  ) {
    final raw = document['commands'];
    if (raw is! List) return null;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      if (_wireString(map['id']) == commandId.trim()) return map;
    }
    return null;
  }
}

/// Une commande ENTIÈRE, telle qu'elle s'écrit (`PATCH …/commands/{commandId}`).
///
/// Le corps envoyé est `raw` TEL QUEL, enveloppé par le client (`{"command":…}`)
/// : le dépôt ne réécrit jamais le contenu d'une commande, il le transporte.
/// C'est la seule façon de garantir qu'une écriture granulaire ne perd aucun
/// champ que ce client ne comprendrait pas.
class CommandDetail {
  const CommandDetail({
    required this.botId,
    required this.commandId,
    required this.raw,
    this.revision,
  });

  final String botId;
  final String commandId;
  final Map<String, dynamic> raw;

  /// Révision du DOCUMENT telle que la LECTURE l'a rendue (v2 seule). `null`
  /// quand la commande vient du document legacy, qui ne porte aucune révision.
  ///
  /// POURQUOI CE CHAMP EXISTE : c'est le seul moment où l'application apprend
  /// où en est le document ; le dépôt la mémorise alors pour le prochain
  /// `If-Match`. À l'écriture, c'est CETTE mémoire qui fait foi et non ce champ,
  /// pour qu'il n'existe qu'une seule vérité par bot.
  final String? revision;

  @override
  String toString() =>
      'CommandDetail(\$botId/\$commandId, \${raw.length} clés)';
}

/// Une entrée d'historique — MÉTADONNÉES SEULEMENT
/// (`GET …/commands/{commandId}/history`).
///
/// Le contenu d'une version ne sort JAMAIS du serveur : la restauration se fait
/// par `historyId`, donc un historique ne peut pas devenir un canal de fuite.
class CommandVersionInfo {
  const CommandVersionInfo({
    required this.historyId,
    required this.createdAt,
    required this.authorOwnerId,
    required this.sizeBytes,
    required this.contentHash,
    required this.revision,
  });

  final String historyId;
  final DateTime? createdAt;
  final String authorOwnerId;
  final int sizeBytes;
  final String contentHash;
  final String revision;

  static CommandVersionInfo? fromWire(Object? item) {
    if (item is! Map) return null;
    final map = Map<String, dynamic>.from(item);
    final historyId = _wireString(map['history_id']);
    if (historyId.isEmpty) return null;
    final createdAtRaw = _wireString(map['created_at']);
    return CommandVersionInfo(
      historyId: historyId,
      createdAt: createdAtRaw.isEmpty
          ? null
          : DateTime.tryParse(createdAtRaw)?.toLocal(),
      authorOwnerId: _wireString(map['author_owner_id']),
      sizeBytes: _wireInt(map['size_bytes']) ?? 0,
      contentHash: _wireString(map['content_hash']),
      revision: _wireString(map['revision']),
    );
  }

  /// Décode la liste d'un historique, en ignorant les entrées illisibles (une
  /// entrée illisible ne doit pas masquer les autres).
  static List<CommandVersionInfo> listFromWire(Map<String, dynamic> json) {
    final raw = json['versions'];
    if (raw is! List) return const <CommandVersionInfo>[];
    final versions = <CommandVersionInfo>[];
    for (final item in raw) {
      final version = CommandVersionInfo.fromWire(item);
      if (version != null) versions.add(version);
    }
    return List<CommandVersionInfo>.unmodifiable(versions);
  }
}

/// Le résultat BRUT d'une écriture granulaire réussie
/// (`PATCH` et `POST …/rollback/{historyId}`), tel que le serveur le rend.
///
/// Il n'est PAS un résultat d'application : le dépôt le traduit en [SaveOutcome]
/// après avoir mémorisé la nouvelle révision. Séparer les deux évite qu'un
/// appelant croie qu'un `200` du serveur est déjà une sauvegarde locale.
class GranularWriteResult {
  const GranularWriteResult({
    required this.revision,
    required this.command,
    required this.historyId,
    required this.runnerSynced,
  });

  final String revision;
  final Map<String, dynamic>? command;

  /// Entrée de journal créée par CETTE écriture. Vide quand le journal est
  /// éteint ou que son écriture best-effort a échoué — l'écriture de
  /// configuration, elle, a bien eu lieu.
  final String historyId;

  /// Le relais au nœud runner a-t-il abouti ? Faux n'est pas un échec de
  /// sauvegarde : la configuration est écrite, elle sera chargée au prochain
  /// démarrage.
  final bool runnerSynced;

  static GranularWriteResult fromWire(Map<String, dynamic> json) {
    final rawCommand = json['command'];
    return GranularWriteResult(
      revision: _wireString(json['revision']),
      command: rawCommand is Map ? Map<String, dynamic>.from(rawCommand) : null,
      historyId: _wireString(json['history_id']),
      runnerSynced: json['runner_synced'] == true,
    );
  }
}

/// Ce qu'une sauvegarde de commande a donné — LA décision que l'appelant doit
/// traiter, et elle est fermée (`sealed`) : il n'existe aucun autre cas, donc un
/// `switch` exhaustif ne peut pas en oublier un.
///
/// POURQUOI UN TYPE FERMÉ PLUTÔT QU'UN BOOLÉEN : « c'est sauvegardé » et « c'est
/// sauvegardé en legacy » et « c'est en conflit » et « c'est en file » demandent
/// QUATRE comportements différents d'interface (dont un dialogue de relecture).
/// Un booléen obligerait l'appelant à deviner lequel, et c'est ainsi qu'un 409
/// finit affiché comme une panne serveur.
sealed class SaveOutcome {
  const SaveOutcome();
}

/// Écriture granulaire ACCEPTÉE par le serveur (v2 avec `If-Match` honoré).
class SavedGranular extends SaveOutcome {
  const SavedGranular({
    required this.revision,
    required this.historyId,
    required this.runnerSynced,
  });

  /// NOUVELLE révision du document : c'est elle que portera le prochain
  /// `If-Match` de ce bot.
  final String revision;

  /// Entrée d'historique créée par cette écriture (vide si aucun journal).
  final String historyId;

  final bool runnerSynced;

  @override
  String toString() =>
      'SavedGranular(revision: $revision, history: $historyId, '
      'runner: $runnerSynced)';
}

/// Sauvegarde passée par le CHEMIN LEGACY (document entier).
///
/// POURQUOI CE TYPE NE PORTE AUCUNE RÉVISION : le chemin legacy n'en rend
/// aucune (la poussée du document entier ne répond pas de révision), et
/// fabriquer un champ vide laisserait croire à un `If-Match` possible ensuite.
/// Un `SavedLegacy` veut dire : la commande est enregistrée localement et le
/// document entier a été confié au chemin existant (construit par
/// `buildBotPayload`, poussé par le batcher).
class SavedLegacy extends SaveOutcome {
  const SavedLegacy();
}

/// Le serveur REFUSE l'écriture parce que la révision attendue est périmée.
///
/// RIEN n'a été écrit côté serveur, et RIEN ne doit l'être côté client : c'est
/// une QUESTION posée à l'utilisateur, pas une panne. Le travail local est
/// intact par construction — le dépôt ne touche jamais au stockage local.
class ConflictStale extends SaveOutcome {
  const ConflictStale({this.currentRevision});

  /// Révision courante du serveur, quand sa réponse la donne. `null` = le
  /// serveur a refusé sans dire où il en est : l'appelant doit alors RELIRE
  /// avant de proposer d'écraser.
  final String? currentRevision;

  @override
  String toString() => 'ConflictStale(current: $currentRevision)';
}

/// La panne était transitoire et la commande a été CONFIÉE à la file hors-ligne.
///
/// Ce type n'est rendu QUE si un hook de file est installé ET a accepté
/// l'entrée : sans file, le dépôt relaie l'erreur au lieu de prétendre avoir
/// mis quelque chose en attente.
class QueuedOffline extends SaveOutcome {
  const QueuedOffline();
}

/// Une écriture à rejouer plus tard, telle qu'elle est confiée à la file.
///
/// POURQUOI ELLE PORTE LA PRÉCONDITION D'ORIGINE : une commande rejouée APRÈS
/// le retour du réseau doit l'être dans les mêmes termes que la tentative qui a
/// échoué. La rejouer sans `If-Match` transformerait une panne réseau en
/// écrasement du travail d'un autre appareil — exactement l'incident de juin
/// 2026. Avec la précondition d'origine, un serveur qui a bougé depuis REFUSE
/// (409) au lieu d'écraser.
class OfflineCommandWrite {
  const OfflineCommandWrite({
    required this.botId,
    required this.commandId,
    required this.command,
    this.ifMatch,
  });

  final String botId;
  final String commandId;
  final Map<String, dynamic> command;

  /// Révision attendue au moment de la tentative (vide = aucune précondition,
  /// parce qu'aucune révision n'était connue à ce moment-là).
  final String? ifMatch;

  @override
  String toString() => 'OfflineCommandWrite($botId/$commandId)';
}

// ─── Lecture tolérante des champs (une seule implémentation) ───────────────

String _wireString(Object? value) => (value ?? '').toString().trim();

String? _wireNullableString(Object? value) {
  final text = _wireString(value);
  return text.isEmpty ? null : text;
}

int? _wireInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}
