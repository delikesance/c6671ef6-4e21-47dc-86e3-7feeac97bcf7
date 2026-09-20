import 'dart:developer' as developer;

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart' show Snowflake;

/// Issue d'une reprise du jeton d'un bot depuis le compte.
///
/// Les cinq dernières valeurs recopient la cause transportée par
/// [BotTokenExportFailure] : elles existent ici pour que l'interface n'ait
/// qu'une seule liste à traiter, avec les deux issues propres à l'app
/// (déjà présent, aucune tentative possible).
enum BotTokenImportOutcome {
  /// Le jeton est arrivé ET a été enregistré sur ce poste.
  imported,

  /// Ce poste a déjà un jeton utilisable : il n'y a rien à reprendre.
  alreadyPresent,

  /// Le compte annonce lui-même ce jeton comme invalide (`token_invalid = true`) :
  /// le reprendre ne donnerait qu'une credential morte, donc on n'essaie pas.
  serverAnnouncesInvalid,

  /// Une tentative a déjà eu lieu pour ce bot dans ce lancement d'application.
  alreadyAttempted,

  /// Aucun compte connecté sur cet appareil : personne à qui demander le jeton.
  noAccount,

  /// `404 bot_not_found` : ce bot n'est pas sur ton compte.
  botMissing,

  /// `409 token_unavailable` : aucune credential enregistrée côté compte.
  notStored,

  /// `500 token_decrypt_failed` : le serveur n'arrive pas à relire son jeton.
  serverCannotRead,

  /// `404` de route / `501` : le serveur ne connaît pas encore cette route.
  serverUnsupported,

  /// Autre `5xx` ou panne réseau : réessayer a un sens.
  network,
}

/// Bots déjà tentés par la reprise AUTOMATIQUE depuis le démarrage.
///
/// C'est cet ensemble qui tient la promesse « au plus une tentative par bot et
/// par lancement d'application » : il meurt avec le processus (un redémarrage
/// rend donc la reprise possible), et aucune synchro répétée ne peut la rejouer.
/// Une entrée est posée AVANT l'appel réseau, pour qu'une seconde synchro qui
/// se chevauche ne produise pas un second export.
final Set<String> _automaticallyAttemptedBotIds = <String>{};

/// Vide la comptabilité des tentatives automatiques (tests uniquement).
@visibleForTesting
void resetBotTokenAutoImportAttempts() => _automaticallyAttemptedBotIds.clear();

/// Reprend le jeton d'un bot auprès du compte, quand ce poste n'en a pas.
///
/// Pourquoi cette classe : le jeton d'un bot ne circule que dans UN sens — le
/// poste l'envoie au serveur (`POST /gateway/bots/discord/save`), le serveur ne
/// le rendait jamais, et `GET /gateway/bots` le rédige volontairement. Un
/// appareil qui ne l'a jamais saisi affichait donc « Token invalid or missing »
/// sans aucun recours, même en rafraîchissant. La seule sortie est de le
/// REDEMANDER au compte (`POST /gateway/bots/{id}/token`), ce que fait cette
/// classe — une fois, ou sur demande explicite de l'utilisateur.
class BotTokenImporter {
  BotTokenImporter({required this.client});

  /// Client du compte (manager). `null` — compte non configuré, ou aucune
  /// session — arrête la reprise AVANT toute requête : hors connexion, le
  /// comportement reste celui d'avant.
  final MainApiClient? client;

  /// Reprise déclenchée par la synchro, pour un bot qui est (a) sur le compte,
  /// (b) sans jeton utilisable en local, (c) annoncé `token_invalid = false`.
  ///
  /// Au plus une tentative par bot et par lancement d'application : ni boucle,
  /// ni rafale, ni nouvel essai après un `409` ou un `500` (ces cas ne se
  /// résolvent pas en réessayant).
  Future<BotTokenImportOutcome> importAutomatically({
    required String botId,
    required bool serverAnnouncesTokenValid,
    required bool hasLocalToken,
  }) {
    if (hasLocalToken) return Future.value(BotTokenImportOutcome.alreadyPresent);
    if (!serverAnnouncesTokenValid) {
      return Future.value(BotTokenImportOutcome.serverAnnouncesInvalid);
    }
    if (_automaticallyAttemptedBotIds.contains(botId)) {
      return Future.value(BotTokenImportOutcome.alreadyAttempted);
    }
    // Réservé AVANT l'appel : un chevauchement de synchros ne peut pas
    // déclencher deux exports du même jeton.
    _automaticallyAttemptedBotIds.add(botId);
    return _export(botId, source: 'auto');
  }

  /// Reprise demandée par l'utilisateur (bouton « Importer le jeton depuis mon
  /// compte ») : il a le droit d'essayer autant de fois qu'il le souhaite, aucun
  /// quota de tentatives ne s'applique ici.
  Future<BotTokenImportOutcome> importFromUserAction({
    required String botId,
  }) {
    return _export(botId, source: 'manual');
  }

  Future<BotTokenImportOutcome> _export(
    String botId, {
    required String source,
  }) async {
    final activeClient = client;
    if (activeClient == null) return BotTokenImportOutcome.noAccount;

    final BotTokenExport export;
    try {
      export = await activeClient.fetchBotToken(botId);
    } on BotTokenExportException catch (error) {
      return outcomeForExportFailure(error.failure);
    } catch (_) {
      // Rien d'autre ne doit remonter jusqu'à l'écran sous forme de crash.
      return BotTokenImportOutcome.network;
    }

    try {
      await persistImportedBotToken(botId, export.token);
    } catch (error) {
      developer.log(
        'Failed to persist an imported bot token: $error',
        name: 'BotTokenImporter',
      );
      return BotTokenImportOutcome.network;
    }

    // Événement SANS la valeur du jeton : seuls l'identifiant et la provenance.
    await AppAnalytics.logEvent(
      name: 'bot_token_imported',
      parameters: <String, Object>{'bot_id': botId, 'source': source},
    );
    return BotTokenImportOutcome.imported;
  }
}

/// Écrit un jeton reçu sur ce poste, par le chemin d'écriture UNIQUE des
/// applications.
///
/// `createOrUpdateApp` ne peut plus effacer un jeton connu depuis `900aee2b` :
/// c'est aussi ce qui rend une reprise inoffensive quand le serveur n'apporte
/// rien. Le reste de la fiche (nom, préfixe, intents, avatar) est relu avant
/// l'écriture pour n'en perdre aucun morceau — un avatar nul est conservé par
/// `createOrUpdateApp` quand ni `avatarHash` ni `discriminator` ne changent.
Future<void> persistImportedBotToken(String botId, String token) async {
  final manager = AppManager();
  final existing = await manager.getApp(botId);
  final guildCount = existing['approximate_guild_count'];
  await manager.createOrUpdateApp(
    id: Snowflake.parse(botId),
    username: (existing['name'] ?? '').toString(),
    token: token,
    prefix: existing['prefix']?.toString(),
    intents: (existing['intents'] as Map?)?.cast<String, bool>(),
    approximateGuildCount: guildCount is int ? guildCount : null,
  );
}

/// Traduit une cause de transport en issue de reprise.
BotTokenImportOutcome outcomeForExportFailure(BotTokenExportFailure failure) {
  switch (failure) {
    case BotTokenExportFailure.botMissing:
      return BotTokenImportOutcome.botMissing;
    case BotTokenExportFailure.notStored:
      return BotTokenImportOutcome.notStored;
    case BotTokenExportFailure.serverCannotRead:
      return BotTokenImportOutcome.serverCannotRead;
    case BotTokenExportFailure.serverUnsupported:
      return BotTokenImportOutcome.serverUnsupported;
    case BotTokenExportFailure.network:
      return BotTokenImportOutcome.network;
  }
}

/// Message à montrer pour [outcome], ou chaîne vide quand il n'y a rien à dire.
///
/// Chaque ÉCHEC a donc son texte : jamais de dialogue vide, et jamais
/// « vérifie ta connexion » pour un serveur qui ne connaît pas encore la route —
/// deux situations que l'utilisateur ne peut pas distinguer sinon.
String botTokenImportMessage(
  BotTokenImportOutcome outcome,
  AppLocalizations tr,
) {
  switch (outcome) {
    case BotTokenImportOutcome.imported:
      return tr.bot_token_import_success;
    case BotTokenImportOutcome.botMissing:
      return tr.bot_token_import_missing;
    case BotTokenImportOutcome.notStored:
      return tr.bot_token_import_not_stored;
    case BotTokenImportOutcome.serverCannotRead:
      return tr.bot_token_import_server_cannot_read;
    case BotTokenImportOutcome.serverUnsupported:
      return tr.bot_token_import_server_unsupported;
    case BotTokenImportOutcome.network:
      return tr.bot_token_import_network;
    case BotTokenImportOutcome.noAccount:
      return tr.bot_token_import_no_account;
    case BotTokenImportOutcome.alreadyPresent:
    case BotTokenImportOutcome.serverAnnouncesInvalid:
    case BotTokenImportOutcome.alreadyAttempted:
      // Issues propres à la reprise automatique : rien à annoncer à l'écran.
      return '';
  }
}
