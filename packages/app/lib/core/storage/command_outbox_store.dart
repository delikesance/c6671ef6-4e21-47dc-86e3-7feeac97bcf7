// LA FILE HORS-LIGNE DES COMMANDES : TABLE, HOOK D'ÉCRITURE, VIDAGE.
//
// POURQUOI ELLE EXISTE : jusqu'ici, une panne réseau pendant une sauvegarde de
// commande était un `debugPrint` et rien d'autre — le travail de l'utilisateur
// disparaissait au premier redémarrage. La file garde la commande, la rejoue
// seule quand le réseau revient, et — c'est la règle qui décide de tout le
// reste — **le rejeu passe par le MÊME `saveCommand` que la sauvegarde
// normale** : la file ne connaît ni `/api/v2` ni le document entier, donc elle
// ne peut pas écrire dans un format que le serveur ne parle pas.
//
// TROIS DÉCISIONS NON NÉGOCIABLES, ET CE QU'ELLES EMPÊCHENT :
//
//  1. UNE LIGNE PAR COMMANDE, JAMAIS PAR BOT. La clé primaire
//     `(bot_id, command_id)` fait du `INSERT … ON CONFLICT DO UPDATE` un vrai
//     « dernier qui écrit gagne » PAR COMMANDE. Deux appareils qui éditent deux
//     commandes du même bot ne s'écrasent pas dans la file ; et rééditer la
//     MÊME commande ne laisse qu'une entrée, la dernière.
//
//  2. RIEN N'EST SUPPRIMÉ EN SILENCE. Une entrée n'est effacée QUE par un
//     rejeu qui a réussi. Une entrée dont `payload_json` ne se relit pas
//     (JSON corrompu) n'est PAS jetée : elle est conservée, son compteur
//     d'essais augmente et `last_error` dit pourquoi — et elle n'empêche
//     SURTOUT PAS les autres de partir. Une commande qui disparaît sans trace
//     est exactement ce que cette file existe pour empêcher.
//
//  3. L'ABANDON EST PAR COMMANDE. Au bout de [defaultCommandOutboxMaxAttempts]
//     essais, l'entrée cesse d'être rejouée mais RESTE dans la table, avec son
//     erreur et son compteur : elle est consultable, et le compteur dit à
//     l'utilisateur ce qui s'est passé. Jamais un abandon de tout le bot.
//
// CE QUE LA FILE NE FAIT PAS : elle ne décide pas du format (c'est le dépôt),
// elle ne touche pas au stockage local des commandes (les fichiers
// `apps/<botId>/<commandId>.json` sont l'affaire de l'appelant, et ils sont
// écrits AVANT), et elle n'invente pas de précondition. Le champ `ifMatch`
// d'une écriture mise en file n'est pas persisté : le schéma de la table est
// figé (plan §5.2) et ne porte pas de colonne pour lui ; au rejeu,
// `BotDataRepository.saveCommand` reprend la révision COURANTE qu'il connaît,
// qui est celle du même dépôt qui a refusé l'écriture à l'origine.

import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/storage/variables_database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Nombre d'essais au bout duquel une entrée est ABANDONNÉE — par commande.
const int defaultCommandOutboxMaxAttempts = 5;

/// Le message d'erreur porté par une entrée dont le JSON est illisible.
/// C'est une DONNÉE stockée (elle sera affichée telle quelle par un écran de
/// consultation), pas un libellé d'interface : ce lot n'a aucun écran.
const String commandOutboxUnreadablePayloadError =
    'payload_json illisible : la commande en attente ne peut pas être relue';

/// Le message d'erreur porté par une entrée que le serveur a REFUSÉE parce que
/// la révision attendue était périmée. Un conflit n'est pas une panne : il ne
/// faut pas le rejouer en boucle, il faut le montrer.
const String commandOutboxStaleConflictError =
    'conflit de révision : le document a bougé depuis cette édition';

// ─── Une entrée de la file ───────────────────────────────────────────────────

/// Une ligne de `command_outbox`, telle qu'elle est LUE.
///
/// La charge utile est conservée en TEXTE, exactement comme elle a été écrite :
/// la relire en `Map` pour la réécrire ferait perdre les clés que ce client ne
/// comprend pas (le défaut documenté du « middleware transparent »).
class CommandOutboxEntry {
  CommandOutboxEntry({
    required this.botId,
    required this.commandId,
    required this.payloadHash,
    required this.payloadJson,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
  });

  final String botId;
  final String commandId;

  /// Empreinte SHA-256 des octets de [payloadJson]. Sert à reconnaître une
  /// réécriture de la MÊME charge utile (voir [CommandOutboxStore.enqueue]) :
  /// elle n'est pas la clé de déduplication, la clé primaire composite l'est.
  final String payloadHash;

  final String payloadJson;

  /// Nombre d'échecs déjà essuyés par CETTE entrée (0 pour une écrasée par une
  /// édition plus récente : une nouvelle charge utile repart à zéro).
  final int attempts;

  /// Dernière erreur connue, vide tant qu'aucun essai n'a échoué.
  final String lastError;

  /// Horodatage de mise en file (millisecondes depuis l'époque). Il est
  /// CONSERVÉ quand la même charge utile est remise en file : l'ancienneté
  /// affichée reste celle du premier `enqueue` non résolu.
  final int createdAt;

  /// La commande décodée, ou `null` si `payload_json` ne se relit pas.
  ///
  /// `null` n'est PAS « pas de commande » : c'est la marque d'une entrée
  /// corrompue, que le vidage doit conserver et signaler.
  Map<String, dynamic>? get command =>
      _decodedCommand ??= _decodeCommandPayload(payloadJson);

  Map<String, dynamic>? _decodedCommand;

  /// Vrai quand la charge utile se relit (objet JSON).
  bool get isReadable => command != null;

  /// Vrai quand cette entrée a épuisé son droit d'essai. Elle reste visible.
  bool isAbandonedAt(int maxAttempts) => attempts >= maxAttempts;

  /// Vrai quand cette entrée doit être rejouée au prochain vidage.
  bool isReplayableAt(int maxAttempts) =>
      !isAbandonedAt(maxAttempts) && isReadable;

  static CommandOutboxEntry fromRow(Map<String, Object?> row) {
    return CommandOutboxEntry(
      botId: _rowString(row['bot_id']),
      commandId: _rowString(row['command_id']),
      payloadHash: _rowString(row['payload_hash']),
      payloadJson: _rowString(row['payload_json']),
      attempts: _rowInt(row['attempts']),
      lastError: _rowString(row['last_error']),
      createdAt: _rowInt(row['created_at']),
    );
  }

  @override
  String toString() =>
      'CommandOutboxEntry($botId/$commandId, essais: $attempts, '
      'erreur: ${lastError.isEmpty ? '—' : lastError})';
}

Map<String, dynamic>? _decodeCommandPayload(String payloadJson) {
  try {
    final decoded = jsonDecode(payloadJson);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  } catch (_) {
    // Un JSON illisible est une DONNÉE, pas une exception à propager : la
    // lever ici ferait tomber le vidage entier à cause d'une seule ligne.
    return null;
  }
}

String _rowString(Object? value) => (value ?? '').toString();

int _rowInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? 0;
  return 0;
}

// ─── La table ────────────────────────────────────────────────────────────────

/// L'accès à `command_outbox`, dans la base des variables.
class CommandOutboxStore {
  /// [database] : un descripteur déjà ouvert (tests, appelant qui possède la
  /// base). [open] : par défaut le point d'ouverture UNIQUE de
  /// `databases/variables.db` — la file n'a pas de seconde base.
  CommandOutboxStore({Database? database, Future<Database> Function()? open})
    : this._(database, open ?? openVariablesDatabase);

  CommandOutboxStore._(this._database, this._open);

  final Database? _database;
  final Future<Database> Function() _open;

  Database? _resolved;
  Future<Database>? _opening;

  Future<Database> get _db async {
    final injected = _database;
    if (injected != null) return injected;
    final resolved = _resolved;
    if (resolved != null) return resolved;
    final opening = _opening ??= _open();
    try {
      final opened = await opening;
      _resolved = opened;
      return opened;
    } catch (_) {
      // Une ouverture ratée n'est pas mise en cache : la suivante réessaie.
      if (identical(_opening, opening)) _opening = null;
      rethrow;
    }
  }

  /// LE HOOK : met une écriture en file. Sa signature EST
  /// `OfflineCommandQueueHook`, donc il s'installe tel quel
  /// (`repository.offlineQueueHook = store.enqueue`).
  ///
  /// L'écriture est un `INSERT … ON CONFLICT DO UPDATE`, et la clause de mise à
  /// jour porte la seule subtilité du lot : si la charge utile est IDENTIQUE
  /// (même empreinte), le compteur d'essais, l'erreur et l'horodatage de
  /// l'entrée existante sont CONSERVÉS. Sans cela, remettre en file la même
  /// écriture remettrait le compteur à zéro et l'abandon au bout de N essais ne
  /// se déclencherait jamais. Une charge utile DIFFÉRENTE, elle, repart à zéro :
  /// c'est une nouvelle tentative d'écriture, pas la même.
  Future<void> enqueue(OfflineCommandWrite write) async {
    final botId = write.botId.trim();
    final commandId = write.commandId.trim();
    if (botId.isEmpty || commandId.isEmpty) {
      // Une ligne sans clé serait inutilisable et invisible dans une liste par
      // bot : mieux vaut refuser bruyamment que stocker un fantôme.
      throw ArgumentError(
        'command_outbox : bot_id et command_id sont obligatoires '
        '(reçu bot_id="$botId", command_id="$commandId")',
      );
    }

    final payloadJson = jsonEncode(write.command);
    final payloadHash = sha256.convert(utf8.encode(payloadJson)).toString();
    final db = await _db;
    await db.rawInsert(_upsertSql, <Object?>[
      botId,
      commandId,
      payloadHash,
      payloadJson,
      DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  /// Toutes les entrées, de la plus ancienne à la plus récente.
  ///
  /// AUCUNE ENTRÉE N'EST FILTRÉE ICI : les abandonnées et les illisibles en
  /// font partie, c'est ce qui les rend consultables.
  Future<List<CommandOutboxEntry>> entries() async {
    final db = await _db;
    final rows = await db.query(
      commandOutboxTableName,
      orderBy: 'created_at ASC, bot_id ASC, command_id ASC',
    );
    return rows.map(CommandOutboxEntry.fromRow).toList(growable: false);
  }

  /// Une entrée précise, ou `null`.
  Future<CommandOutboxEntry?> find(String botId, String commandId) async {
    final db = await _db;
    final rows = await db.query(
      commandOutboxTableName,
      where: 'bot_id = ? AND command_id = ?',
      whereArgs: <Object?>[botId.trim(), commandId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CommandOutboxEntry.fromRow(rows.first);
  }

  /// Le nombre d'entrées en file, toutes catégories confondues.
  Future<int> count() async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $commandOutboxTableName',
    );
    return _rowInt(rows.first['total']);
  }

  /// Enregistre un ESSAI QUI A ÉCHOUÉ : le compteur monte, l'erreur est
  /// conservée. L'entrée reste en place — c'est tout l'objet de la méthode.
  Future<void> recordAttemptFailure({
    required String botId,
    required String commandId,
    required String error,
  }) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE $commandOutboxTableName '
      'SET attempts = attempts + 1, last_error = ? '
      'WHERE bot_id = ? AND command_id = ?',
      <Object?>[error, botId.trim(), commandId.trim()],
    );
  }

  /// Retire une entrée — APPELÉE UNIQUEMENT APRÈS UN REJEU RÉUSSI.
  Future<void> removeEntry({
    required String botId,
    required String commandId,
  }) async {
    final db = await _db;
    await db.delete(
      commandOutboxTableName,
      where: 'bot_id = ? AND command_id = ?',
      whereArgs: <Object?>[botId.trim(), commandId.trim()],
    );
  }

  /// Le `UPSERT`. La clause `DO UPDATE` laisse les colonnes d'essai
  /// inchangées quand l'empreinte est la même (voir [enqueue]).
  static const String _upsertSql = '''
    INSERT INTO $commandOutboxTableName
      (bot_id, command_id, payload_hash, payload_json, attempts, last_error, created_at)
    VALUES (?, ?, ?, ?, 0, '', ?)
    ON CONFLICT(bot_id, command_id) DO UPDATE SET
      payload_hash = excluded.payload_hash,
      payload_json = excluded.payload_json,
      attempts = CASE WHEN $commandOutboxTableName.payload_hash = excluded.payload_hash
                      THEN $commandOutboxTableName.attempts ELSE 0 END,
      last_error = CASE WHEN $commandOutboxTableName.payload_hash = excluded.payload_hash
                        THEN $commandOutboxTableName.last_error ELSE '' END,
      created_at = CASE WHEN $commandOutboxTableName.payload_hash = excluded.payload_hash
                        THEN $commandOutboxTableName.created_at ELSE excluded.created_at END
  ''';
}

// ─── Le sélecteur (pur : aucune base, aucun réseau) ──────────────────────────

/// Le partage d'une liste d'entrées en trois catégories, sans base ni réseau.
///
/// POURQUOI CE TYPE EST SÉPARÉ DU VIDAGE : la règle « qui part, qui est
/// abandonnée, qui est illisible » doit pouvoir être prouvée sans monter
/// SQLite ni un serveur. Le vidage, lui, ne fait qu'exécuter ce partage.
class CommandOutboxSelection {
  const CommandOutboxSelection({
    required this.replayable,
    required this.abandoned,
    required this.unreadable,
  });

  /// À rejouer maintenant (lisible et sous la limite d'essais).
  final List<CommandOutboxEntry> replayable;

  /// Au bout de leurs essais : plus jamais rejouées, toujours présentes.
  final List<CommandOutboxEntry> abandoned;

  /// `payload_json` illisible : jamais rejouées telles quelles, jamais jetées.
  final List<CommandOutboxEntry> unreadable;

  static CommandOutboxSelection of(
    List<CommandOutboxEntry> entries, {
    required int maxAttempts,
  }) {
    final replayable = <CommandOutboxEntry>[];
    final abandoned = <CommandOutboxEntry>[];
    final unreadable = <CommandOutboxEntry>[];
    for (final entry in entries) {
      if (entry.isAbandonedAt(maxAttempts)) {
        abandoned.add(entry);
      } else if (!entry.isReadable) {
        unreadable.add(entry);
      } else {
        replayable.add(entry);
      }
    }
    return CommandOutboxSelection(
      replayable: List<CommandOutboxEntry>.unmodifiable(replayable),
      abandoned: List<CommandOutboxEntry>.unmodifiable(abandoned),
      unreadable: List<CommandOutboxEntry>.unmodifiable(unreadable),
    );
  }

  /// Le nombre d'entrées encore en attente d'un rejeu réussi.
  int get pendingCount =>
      replayable.length + abandoned.length + unreadable.length;
}

// ─── Le vidage ───────────────────────────────────────────────────────────────

/// Rejoue UNE écriture. `BotDataRepository.saveCommand` a exactement cette
/// signature : c'est ce qui fait que le rejeu emprunte le même chemin que la
/// sauvegarde normale (v2 si elle est là, legacy sinon).
typedef CommandOutboxReplay =
    Future<SaveOutcome> Function(String botId, CommandDetail command);

/// Ce qu'un vidage a donné. Des COMPTES, pas une impression : chaque catégorie
/// correspond à une ligne de la table, et la somme doit tomber juste.
class CommandOutboxDrainReport {
  const CommandOutboxDrainReport({
    required this.replayed,
    required this.failed,
    required this.unreadable,
    required this.abandoned,
    required this.deferred,
    required this.remaining,
    required this.stoppedOffline,
  });

  /// Rejouées avec succès, donc RETIRÉES de la file.
  final int replayed;

  /// Rejouées et refusées (exception ou conflit) : la ligne est conservée et
  /// son compteur d'essais a augmenté.
  final int failed;

  /// Charge utile illisible : la ligne est conservée et son compteur a
  /// augmenté, mais AUCUN rejeu n'a été tenté.
  final int unreadable;

  /// Au bout de leurs essais : non rejouées, toujours présentes.
  final int abandoned;

  /// Laissées en file parce que le réseau est encore absent. Elles ne sont ni
  /// comptées comme des échecs, ni touchées.
  final int deferred;

  /// Nombre de lignes restantes dans la table après le vidage.
  final int remaining;

  /// Vrai quand le vidage s'est arrêté sur une panne transitoire : les entrées
  /// restantes repartiront au prochain déclencheur, intactes.
  final bool stoppedOffline;

  /// Rien qui mérite une notification d'interface.
  bool get isSilent =>
      replayed == 0 && failed == 0 && unreadable == 0 && remaining == 0;

  @override
  String toString() =>
      'CommandOutboxDrainReport(rejouées: $replayed, échecs: $failed, '
      'illisibles: $unreadable, abandonnées: $abandoned, différées: $deferred, '
      'restantes: $remaining, hors-ligne: $stoppedOffline)';
}

/// Rejoue les entrées de la file par le [replay] injecté.
class CommandOutboxDrainer {
  CommandOutboxDrainer({
    required this.store,
    required this.replay,
    this.maxAttempts = defaultCommandOutboxMaxAttempts,
  });

  final CommandOutboxStore store;
  final CommandOutboxReplay replay;
  final int maxAttempts;

  Future<CommandOutboxDrainReport>? _inFlight;

  /// Vrai quand un vidage est en cours. Les trois déclencheurs peuvent se
  /// produire ensemble (réseau retrouvé + réveil + poussée réussie) : le
  /// second appel reçoit la MÊME exécution au lieu d'en lancer une deuxième,
  /// qui rejouerait deux fois la même écriture.
  bool get isDraining => _inFlight != null;

  /// Le vidage, jamais deux à la fois.
  Future<CommandOutboxDrainReport> drain() {
    final running = _inFlight;
    if (running != null) return running;
    final future = _drainOnce();
    _inFlight = future;
    // `onError` sur la copie, pas sur `future` : l'appelant reste seul à
    // décider quoi faire d'un échec, et cette copie ne laisse pas traîner une
    // erreur asynchrone non observée si personne n'attend le vidage.
    unawaited(
      future
          .then<void>((_) {}, onError: (Object _) {})
          .whenComplete(() {
            if (identical(_inFlight, future)) _inFlight = null;
          }),
    );
    return future;
  }

  Future<CommandOutboxDrainReport> _drainOnce() async {
    final selection = CommandOutboxSelection.of(
      await store.entries(),
      maxAttempts: maxAttempts,
    );

    var replayed = 0;
    var failed = 0;
    var unreadable = 0;
    var deferred = 0;
    var stoppedOffline = false;

    // 1. LES ILLISIBLES D'ABORD, ET SANS RÉSEAU. Une entrée corrompue n'a pas
    //    besoin d'un serveur pour être signalée ; la traiter ici garantit
    //    qu'elle ne bloque rien, même hors-ligne.
    for (final entry in selection.unreadable) {
      unreadable++;
      await store.recordAttemptFailure(
        botId: entry.botId,
        commandId: entry.commandId,
        error: commandOutboxUnreadablePayloadError,
      );
    }

    // 2. LES REJOUABLES, dans l'ordre où elles ont été mises en file.
    for (final entry in selection.replayable) {
      if (stoppedOffline) {
        deferred++;
        continue;
      }
      final command = entry.command;
      if (command == null) {
        // Inatteignable (le partage les a classées), mais un `null` non
        // couvert ici ferait tomber le vidage : on refuse de le supposer.
        unreadable++;
        await store.recordAttemptFailure(
          botId: entry.botId,
          commandId: entry.commandId,
          error: commandOutboxUnreadablePayloadError,
        );
        continue;
      }

      try {
        final outcome = await replay(
          entry.botId,
          CommandDetail(
            botId: entry.botId,
            commandId: entry.commandId,
            raw: command,
          ),
        );
        switch (outcome) {
          case SavedGranular() || SavedLegacy():
            // LE SEUL ENDROIT QUI SUPPRIME UNE LIGNE : un rejeu accepté.
            await store.removeEntry(
              botId: entry.botId,
              commandId: entry.commandId,
            );
            replayed++;
          case ConflictStale():
            // Le serveur a refusé (document modifié ailleurs). Rejouer en
            // boucle échouerait pareil : on compte l'essai et on la montre.
            failed++;
            await store.recordAttemptFailure(
              botId: entry.botId,
              commandId: entry.commandId,
              error: commandOutboxStaleConflictError,
            );
          case QueuedOffline():
            // Le réseau est encore absent : le hook du dépôt vient de RÉÉCRIRE
            // cette même ligne (même empreinte, donc compteur intact). On ne
            // la touche pas — la compter comme échec la ferait abandonner pour
            // une raison qui n'est pas la sienne. Les suivantes connaîtraient
            // le même sort : le réseau est une propriété de l'appareil, pas
            // d'une commande, donc on s'arrête là plutôt que d'enchaîner les
            // délais d'attente.
            deferred++;
            stoppedOffline = true;
        }
      } catch (error) {
        // UNE ENTRÉE QUI ÉCHOUE N'ARRÊTE PAS LES AUTRES. C'est la règle la
        // plus importante du vidage : une commande impossible à écrire ne doit
        // pas retenir le travail des autres.
        failed++;
        await store.recordAttemptFailure(
          botId: entry.botId,
          commandId: entry.commandId,
          error: error.toString(),
        );
        debugPrint(
          '[CommandOutbox] ${entry.botId}/${entry.commandId} reste en file '
          '(tentative ${entry.attempts + 1}/$maxAttempts) : $error',
        );
      }
    }

    return CommandOutboxDrainReport(
      replayed: replayed,
      failed: failed,
      unreadable: unreadable,
      abandoned: selection.abandoned.length,
      deferred: deferred,
      remaining: await store.count(),
      stoppedOffline: stoppedOffline,
    );
  }
}

// ─── Les déclencheurs ────────────────────────────────────────────────────────

/// Assemble et déclenche le vidage : retour de connectivité, retour au premier
/// plan, poussée réussie.
///
/// LE VIDAGE DRAINE TOUTE LA FILE, PAS SEULEMENT LE BOT QUI VIENT DE PARLER.
/// Un réseau retrouvé ou un réveil sont des propriétés de l'appareil, et une
/// poussée réussie pour un bot prouve que le manager répond : dans les trois
/// cas, toutes les commandes en attente peuvent partir. La granularité de la
/// file est par COMMANDE (une ligne, une écriture) ; c'est le rejeu qui est
/// global, et c'est voulu.
///
/// Les trois déclencheurs sont FIRE-AND-FORGET et n'échouent jamais : appelés
/// depuis un cycle de vie d'application, ils ne peuvent pas laisser remonter
/// une exception. Le rapport du dernier vidage reste lisible sur [lastReport].
class CommandOutboxCoordinator with WidgetsBindingObserver {
  CommandOutboxCoordinator({
    required this.drainer,
    BotDataRepository? repository,
    bool attachLifecycle = false,
    bool attachPushHook = false,
  }) {
    if (repository != null) {
      repository.offlineQueueHook = drainer.store.enqueue;
    }
    if (attachLifecycle) attachAppLifecycle();
    if (attachPushHook) attachDocumentPushHook();
  }

  final CommandOutboxDrainer drainer;

  CommandOutboxDrainReport? lastReport;
  bool _lifecycleAttached = false;

  bool get isLifecycleAttached => _lifecycleAttached;

  /// (ii) Retour au premier plan. L'observateur est branché ici, sur le
  /// binding réel, plutôt que laissé à la charge de l'appelant : un réveil
  /// oublié est un vidage oublié.
  void attachAppLifecycle() {
    if (_lifecycleAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleAttached = true;
  }

  void detachAppLifecycle() {
    if (!_lifecycleAttached) return;
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleAttached = false;
  }

  /// (iii) Branche le vidage sur la poussée réussie du document d'un bot.
  void attachDocumentPushHook() {
    onBotDocumentPushed = _onBotDocumentPushed;
  }

  void detachDocumentPushHook() {
    // On ne retire que le nôtre : un autre dépositaire garde le sien.
    if (onBotDocumentPushed == _onBotDocumentPushed) {
      onBotDocumentPushed = null;
    }
  }

  void dispose() {
    detachAppLifecycle();
    detachDocumentPushHook();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(onAppResumed());
  }

  /// (i) Retour de connectivité.
  Future<void> onConnectivityRestored() => _drain('connectivité retrouvée');

  /// (ii) Retour au premier plan.
  Future<void> onAppResumed() => _drain('retour au premier plan');

  /// (iii) Après un `push`/`pull` réussi.
  Future<void> afterPushOrPullSucceeded(String botId) =>
      _drain('échange réussi ($botId)');

  Future<void> _onBotDocumentPushed(String botId) =>
      afterPushOrPullSucceeded(botId);

  Future<void> _drain(String cause) async {
    try {
      final report = await drainer.drain();
      lastReport = report;
      debugPrint('[CommandOutbox] vidage ($cause) — $report');
    } catch (error) {
      // Une file illisible ne doit jamais faire remonter une exception dans un
      // cycle de vie. On la NOMME et on s'arrête là — rien n'est supprimé.
      debugPrint('[CommandOutbox] vidage ($cause) impossible : $error');
    }
  }
}
