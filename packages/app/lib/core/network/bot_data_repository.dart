// LE DÉPÔT DE DONNÉES D'UN BOT — LE SEUL ENDROIT QUI CHOISIT LE FORMAT.
//
// POURQUOI CE FICHIER EXISTE : `/api/v2` est une façade ADDITIVE. Le jour où
// l'application sait parler aux deux formats, la question « lequel j'utilise ? »
// doit se poser à UN endroit, une fois, et la réponse ne doit jamais pouvoir
// bloquer une sauvegarde. C'est tout l'objet de ce dépôt : il sonde la capacité
// du serveur, lit et écrit par la v2 quand elle est là, et retombe sur le
// document entier (le chemin qui existe depuis toujours) dès qu'elle ne l'est
// pas. Les écrans, la file hors-ligne et le stockage local ne connaissent ni
// `/api/v2` ni le legacy : ils appellent ce dépôt.
//
// LES QUATRE RÈGLES, ET CE QU'ELLES PROTÈGENT :
//
//  1. LA CAPACITÉ EST SONDÉE, JAMAIS SUPPOSÉE. Aucune version d'application,
//     aucun drapeau compilé ne décide du format. Sans sonde réussie, TOUT passe
//     en legacy : c'est le défaut sûr, et c'est ce que vit un ancien serveur.
//
//  2. UN 404 DÉSARME LA V2 ET REJOUE EN LEGACY IMMÉDIATEMENT. Un ancien serveur
//     face à une application récente ne doit JAMAIS bloquer une sauvegarde. Le
//     « désarmement » n'est pas une perte : le chemin legacy écrit le document
//     entier, donc la commande part quand même.
//
//  3. UN 409 NE PERD RIEN. Le serveur a refusé d'écrire (révision périmée) et
//     rien n'a été modifié de son côté ; de ce côté non plus, puisque le dépôt
//     NE TOUCHE JAMAIS au stockage local et ne rejoue SURTOUT PAS une poussée
//     de document entier derrière un 409 — ce serait exactement l'écrasement que
//     le 409 vient d'empêcher. L'appelant reçoit `ConflictStale` et pose la
//     question à l'utilisateur.
//
//  4. UNE PANNE TRANSITOIRE PART EN FILE, ET SEULEMENT SI UNE FILE EXISTE. Le
//     dépôt appelle un hook INJECTABLE ; sans hook installé, il relaie l'erreur
//     au lieu de prétendre avoir mis la commande en attente. Il n'implémente ni
//     table ni base : la file arrive dans son propre lot.
//
// CE FICHIER N'ÉCRIT RIEN. Ni fichier, ni base, ni préférence : la sauvegarde
// locale est l'affaire de l'appelant (elle a lieu AVANT, et c'est elle que le
// chemin legacy publie). Un dépôt qui écrirait localement pourrait « réussir »
// en silence et faire croire à une sauvegarde qui n'a jamais quitté l'appareil.

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';

/// Le chemin LEGACY d'une sauvegarde : pousser le document ENTIER d'un bot.
///
/// POURQUOI UN TYPE DE FONCTION INJECTÉ plutôt qu'un appel direct au batcher :
/// c'est ce qui rend le repli VÉRIFIABLE. Un test injecte un enregistreur et
/// prouve qu'un 404 rejoue bien en legacy, et qu'un 409 ne le fait PAS ; avec un
/// appel direct, la seule façon de le savoir serait de monter toute la base
/// locale et le réseau.
typedef LegacyDocumentPusher = Future<void> Function(String botId);

/// Le hook de la file hors-ligne : reçoit une écriture à rejouer plus tard.
///
/// La file elle-même n'existe pas dans ce lot. Le hook échoue (« je n'ai pas pu
/// garder ta commande ») → l'erreur d'origine est relayée, jamais convertie en
/// « c'est en file » alors que rien ne l'est.
typedef OfflineCommandQueueHook =
    Future<void> Function(OfflineCommandWrite write);

/// Le dépôt de données d'un bot : sondage de capacité, lecture, écriture.
class BotDataRepository {
  BotDataRepository({
    required this.client,
    LegacyDocumentPusher? legacyPusher,
    this.offlineQueueHook,
  }) : _legacyPusher = legacyPusher ?? pushWholeBotDocumentToManager;

  /// Le client du manager. Exposé parce que l'appelant qui a construit ce dépôt
  /// est aussi celui qui sait QUEL manager il interroge.
  final MainApiClient client;

  /// La file hors-ligne, quand elle existe.
  ///
  /// POURQUOI CE CHAMP EST INSTALLABLE APRÈS COUP : la file (table, base) est
  /// construite plus tard que ce dépôt, qui ne doit en dépendre ni pour
  /// compiler ni pour fonctionner. Tant qu'il est `null`, une panne réseau
  /// remonte à l'appelant au lieu d'être silencieusement « mise en attente ».
  OfflineCommandQueueHook? offlineQueueHook;

  /// La valeur par défaut est le chemin EXISTANT du dépôt
  /// (`buildRemotePayload` → `buildBotPayload`, poussé par le batcher) : le
  /// repli n'est pas une seconde implémentation, c'est celui qui tourne déjà
  /// pour chaque sauvegarde de commande de l'application.
  final LegacyDocumentPusher _legacyPusher;

  BotCapabilities? _caps;
  bool _probed = false;
  final Map<String, String> _revisions = <String, String>{};

  /// Les capacités sondées, ou `null` quand la v2 est ABSENTE (ou pas encore
  /// sondée — les deux mènent au même chemin).
  BotCapabilities? get capabilities => _caps;

  /// Vrai quand les routes `/api/v2` ont répondu et sont exploitables.
  bool get isGranularEnabled => _caps != null;

  /// Vrai quand une sonde a déjà abouti (présente ou absente). Permet à
  /// l'appelant de ne pas re-sonder à chaque écran sans confondre « pas encore
  /// sondé » et « v2 absente ».
  bool get hasProbed => _probed;

  /// La dernière révision CONNUE de ce bot, ou `null` si aucune ne l'est.
  String? revisionFor(String botId) => _revisions[botId.trim()];

  /// Sonde `/api/v2/capabilities` — UNE fois, puis met en cache.
  ///
  /// POURQUOI `force` EXISTE : la sonde est mise en cache pour la vie de
  /// l'objet (un serveur ne change pas de version au milieu d'une session),
  /// mais un appelant qui vient de VIVRE un 404 (le serveur a été remplacé ?)
  /// doit pouvoir reposer la question sans recréer le dépôt.
  ///
  /// Une sonde qui ÉCHOUE n'est pas une absence : l'erreur est relayée et rien
  /// n'est mémorisé, donc `_caps` reste ce qu'il était. Seul un 404/405 — la
  /// réponse d'un serveur qui ne connaît pas la route — vaut absence.
  Future<BotCapabilities?> probe({bool force = false}) async {
    if (_probed && !force) return _caps;
    final caps = await client.fetchCapabilities();
    _caps = caps;
    _probed = true;
    return caps;
  }

  /// La liste des commandes, par la v2 quand elle est là, par le DOCUMENT
  /// ENTIER sinon.
  ///
  /// POURQUOI LA LECTURE LEGACY RESTE ENTIÈRE : le runner local a besoin du
  /// document complet pour démarrer (il ne sait pas charger une commande
  /// seule). La liste allégée est un CONFORT pour l'interface, jamais le seul
  /// moyen d'obtenir les données.
  Future<CommandPage> listCommands(String botId) async {
    if (_caps == null) return _listCommandsLegacy(botId);
    try {
      final page = await client.listCommandsV2(botId);
      _rememberRevision(botId, page.revision);
      return page;
    } on MainApiClientException catch (error) {
      if (error.statusCode == 404) {
        // La route n'existe pas sur CE serveur, quoi qu'ait répondu la sonde
        // (binaire changé, proxy en travers). On désarme et on relit le
        // document entier : une liste de secours vaut mieux qu'une erreur.
        _disarm();
        return _listCommandsLegacy(botId);
      }
      rethrow;
    }
  }

  /// Une commande ENTIÈRE : la v2 quand elle est là, le document sinon.
  ///
  /// Un `404` AVEC code (`bot_command_not_found`) est une RÉPONSE, pas une
  /// panne de route : on la relaie telle quelle. Un `404` SANS code veut dire
  /// que la route elle-même est absente : là, et seulement là, on désarme et on
  /// relit le document.
  Future<CommandDetail> getCommand(String botId, String commandId) async {
    if (_caps == null) return _getCommandLegacy(botId, commandId);
    try {
      final detail = await client.getCommandV2(botId, commandId);
      // La lecture est le moment où l'application apprend où en est le
      // document : c'est cette révision que portera la prochaine écriture.
      _rememberRevision(botId, detail.revision);
      return detail;
    } on MainApiClientException catch (error) {
      if (error.statusCode == 404 && error.code == null) {
        _disarm();
        return _getCommandLegacy(botId, commandId);
      }
      rethrow;
    }
  }

  /// L'historique d'UNE commande (métadonnées seules).
  ///
  /// Le legacy n'a AUCUN historique : il n'y a donc pas de repli possible. La
  /// route v2 est appelée même sans sonde, pour que la réponse du serveur (et
  /// son code, `bot_command_history_unavailable` par exemple) soit la vérité
  /// plutôt qu'une erreur inventée côté client.
  Future<List<CommandVersionInfo>> listCommandHistory(
    String botId,
    String commandId, {
    int? limit,
  }) async {
    return client.listCommandHistoryV2(botId, commandId, limit: limit);
  }

  /// Écrit UNE commande. LA méthode du lot : tout le reste n'est que lecture.
  ///
  /// L'ordre des décisions n'est pas négociable :
  ///   - v2 absente → legacy, tout de suite, sans exception ;
  ///   - `409` → `ConflictStale`, le travail local intact (voir l'en-tête) ;
  ///   - `404` → la v2 est désarmée et la sauvegarde est REJOUÉE en legacy ;
  ///   - panne transitoire → la file, si elle est installée ;
  ///   - tout le reste (401, 403, 400, 422) → relayé : ce sont de vraies
  ///     réponses, pas des états normaux à contourner.
  ///
  /// La précondition vient de la MÉMOIRE DU DÉPÔT pour ce bot, jamais de
  /// `command.revision` : une seule source de vérité, sinon deux écritures
  /// rapprochées pourraient partir avec deux révisions différentes.
  ///
  /// [ifMatch] est la SEULE exception, et elle n'ajoute pas de source : c'est la
  /// révision qu'une écriture précédente avait déjà reçue et contre laquelle
  /// elle a échoué. Le rejeu de la file la fournit parce que la mémoire du dépôt
  /// est VIDE après un redémarrage de l'application — sans elle, la commande
  /// repartirait sans précondition et écraserait en silence une version
  /// distante plus récente.
  Future<SaveOutcome> saveCommand(
    String botId,
    CommandDetail command, {
    String? ifMatch,
  }) async {
    if (_caps == null) return _saveLegacy(botId);
    final expected = _normalizeRevision(ifMatch) ?? revisionFor(botId);
    try {
      final result = await client.patchCommandV2(
        botId,
        command.commandId,
        command.raw,
        ifMatch: expected,
      );
      _rememberRevision(botId, result.revision);
      return SavedGranular(
        revision: result.revision,
        historyId: result.historyId,
        runnerSynced: result.runnerSynced,
      );
    } on MainApiClientException catch (error) {
      if (error.statusCode == 409) {
        // Rien n'a été écrit côté serveur, rien ne l'est non plus ici : on
        // rend la décision à l'appelant, sans relâcher ni écraser quoi que ce
        // soit. La révision courante, quand le serveur la dit, permet à
        // l'interface de proposer « recharger et écraser » en connaissance.
        return ConflictStale(currentRevision: _conflictRevision(error.message));
      }
      if (error.statusCode == 404) {
        _disarm();
        return _saveLegacy(botId);
      }
      if (AppDiagnostics.isTransientNetworkError(error)) {
        return _queueOffline(botId, command, ifMatch: expected, cause: error);
      }
      rethrow;
    } catch (error) {
      // Les pannes réseau brutes (socket, TLS, délai d'attente) ne passent pas
      // par une réponse HTTP : elles sortent d'ici sans statut. Les confondre
      // avec un bug, c'est perdre la commande ; les mettre en file, c'est la
      // garder.
      if (AppDiagnostics.isTransientNetworkError(error)) {
        return _queueOffline(botId, command, ifMatch: expected, cause: error);
      }
      rethrow;
    }
  }

  /// Restaure une version journalisée d'une commande.
  ///
  /// Pas de repli legacy possible (l'historique n'existe que côté v2) : un 404
  /// de route remonte tel quel. Un `409` se traite comme une écriture : rien
  /// n'est écrit, l'appelant relit.
  ///
  /// [confirmOvershrink] demande la restauration FORCÉE quand le serveur refuse
  /// la version parce qu'elle est passée sous son plancher de plausibilité :
  /// c'est un retour en arrière demandé, pas une suppression accidentelle.
  Future<SaveOutcome> restoreCommandVersion(
    String botId,
    String commandId,
    String historyId, {
    String? ifMatch,
    bool confirmOvershrink = false,
  }) async {
    final expected = _normalizeRevision(ifMatch) ?? revisionFor(botId);
    final result = await client.restoreCommandVersionV2(
      botId,
      commandId,
      historyId,
      ifMatch: expected,
      confirmOvershrink: confirmOvershrink,
    );
    _rememberRevision(botId, result.revision);
    return SavedGranular(
      revision: result.revision,
      historyId: result.historyId,
      runnerSynced: result.runnerSynced,
    );
  }

  // ─── Legacy ──────────────────────────────────────────────────────────────

  Future<CommandPage> _listCommandsLegacy(String botId) async {
    final document = await client.getBotConfig(botId);
    return CommandPage.fromLegacyDocument(botId: botId, document: document);
  }

  Future<CommandDetail> _getCommandLegacy(
    String botId,
    String commandId,
  ) async {
    final document = await client.getBotConfig(botId);
    final raw = CommandPage.legacyCommandRaw(document, commandId);
    if (raw == null) {
      // 404 local, avec le code du serveur pour la MÊME condition : l'appelant
      // traite « commande inconnue » de la même façon quel que soit le chemin
      // qui le lui a appris.
      throw const MainApiClientException(
        'the command does not exist in this bot',
        statusCode: 404,
        code: 'bot_command_not_found',
      );
    }
    return CommandDetail(botId: botId, commandId: commandId, raw: raw);
  }

  /// Le repli : confier le DOCUMENT ENTIER au chemin existant.
  ///
  /// L'attente porte sur la DEMANDE de poussée, pas sur la poussée : c'est la
  /// sémantique actuelle de l'application (le batcher ne fait jamais attendre un
  /// enregistrement sur un aller-retour réseau), et la conserver évite de
  /// bloquer l'interface pendant qu'un document entier part.
  Future<SaveOutcome> _saveLegacy(String botId) async {
    await _legacyPusher(botId);
    return const SavedLegacy();
  }

  // ─── File hors-ligne ─────────────────────────────────────────────────────

  Future<SaveOutcome> _queueOffline(
    String botId,
    CommandDetail command, {
    required String? ifMatch,
    required Object cause,
  }) async {
    final hook = offlineQueueHook;
    if (hook == null) {
      // AUCUNE FILE : on ne ment pas. « En attente » alors que rien n'est gardé
      // ferait disparaître le travail de l'utilisateur au premier redémarrage.
      throw cause;
    }
    await hook(
      OfflineCommandWrite(
        botId: botId,
        commandId: command.commandId,
        command: command.raw,
        ifMatch: ifMatch,
      ),
    );
    return const QueuedOffline();
  }

  // ─── État interne ────────────────────────────────────────────────────────

  /// Désarmer la v2 : la prochaine opération passe en legacy sans re-sonder.
  ///
  /// POURQUOI CE N'EST PAS DÉFINITIF : `probe(force: true)` réarme la
  /// granularité (nouvelle session, réseau retrouvé, serveur mis à jour). Le
  /// coût d'un désarmement à tort est un document entier poussé en trop — jamais
  /// une sauvegarde perdue.
  void _disarm() {
    _caps = null;
    _probed = true;
  }

  void _rememberRevision(String botId, String? revision) {
    final normalized = _normalizeRevision(revision);
    if (normalized == null) {
      // Une révision VIDE serait un `If-Match` impossible à honorer : on préfère
      // ne rien savoir, et écrire sans précondition (le serveur accepte).
      _revisions.remove(botId.trim());
      return;
    }
    _revisions[botId.trim()] = normalized;
  }
}

/// La révision courante, extraite du message de conflit du serveur.
///
/// POURQUOI UNE LECTURE DE TEXTE ICI, ET NULLE PART AILLEURS : le code
/// applicatif (`bot_config_revision_conflict`) est le contrat ; la phrase, elle,
/// est faite pour un humain. Mais cette phrase porte la SEULE information dont
/// l'appelant a besoin pour repartir — la révision où le serveur en est — et la
/// réponse ne la transporte que là. L'extraction est donc bornée au motif exact
/// du manager (`is at revision "…"`) : un message qui ne le porte pas rend
/// `null`, jamais une devinette. Le motif est volontairement distinct du
/// « expected revision » du cas « révision inconnue », qui ne dit rien de la
/// révision courante.
final RegExp _conflictRevisionPattern = RegExp(r'is at revision\s+"([^"]+)"');

String? _conflictRevision(String message) {
  final match = _conflictRevisionPattern.firstMatch(message);
  if (match == null) return null;
  return _normalizeRevision(match.group(1));
}

String? _normalizeRevision(String? revision) {
  final trimmed = revision?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
