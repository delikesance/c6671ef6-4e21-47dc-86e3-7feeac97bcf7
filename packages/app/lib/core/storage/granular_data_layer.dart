// LA COUCHE GRANULAIRE, BRANCHÉE À L'APPLICATION — LE POINT D'ASSEMBLAGE UNIQUE.
//
// POURQUOI CE FICHIER EXISTE : le dépôt (`bot_data_repository.dart`) et la file
// (`command_outbox_store.dart`) sont complets et testés, mais RIEN ne les
// construisait — la file hors-ligne n'existait donc qu'en test. Ce fichier est
// le SEUL endroit qui les assemble, les rend accessibles à toute l'application,
// et décide QUAND le chemin granulaire a le droit de s'activer.
//
// LA RÈGLE QUI DÉCIDE DE TOUT : `/api/v2` n'est pas déployé. Tant que la sonde
// de capacité n'a pas répondu, la sauvegarde d'une commande doit rester celle
// d'aujourd'hui — même appel, même cadence, aucune requête vers `/api/v2`. C'est
// [granularCommandSaveFor] qui porte cette garde, et elle rend `null` (donc
// « ne change rien ») dès que la v2 n'est pas armée. Un branchement qui
// « rendrait service » sans v2 serait un changement de la sauvegarde de tous
// les utilisateurs, non validé.
//
// DEUX PROPRIÉTÉS DE SURVIE, ET CE QU'ELLES EMPÊCHENT :
//
//  1. LE LANCEMENT NE DÉPEND D'AUCUNE ROUTE. Tout ce fichier est appelé en
//     tâche de fond (`unawaited`) : une sonde qui lève (500, réseau coupé,
//     serveur sans la route) est avalée et laisse la v2 DÉSARMÉE — c'est-à-dire
//     le comportement d'aujourd'hui.
//
//  2. TOUT EST IDEMPOTENT ET RE-APPELABLE. `ensureGranularDataLayer()` est
//     appelée au démarrage ET à chaque reprise d'application : elle ne
//     reconstruit rien, ne rebranche pas deux fois le même crochet, et
//     n'interroge le réseau qu'une fois. C'est aussi ce qui rend la couche
//     accessible après une CONNEXION (au démarrage, il n'y a encore aucune
//     session, donc aucun manager à interroger).

import 'dart:async';

import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/storage/command_outbox_store.dart';
import 'package:flutter/foundation.dart';

/// La fabrique du client du manager, surchargeable en test.
///
/// POURQUOI UN SEAM : la couche doit pouvoir être montée sans réseau réel —
/// sinon la sonde, l'installation de la file et la garde du chemin granulaire
/// ne seraient vérifiables que sur une machine connectée, c'est-à-dire nulle
/// part en test. La fabrique porte AUSSI le délai de reprise, qu'un test de
/// panne doit pouvoir annuler (sinon il attend sept secondes de vraies horloges
/// pour observer un refus définitif).
@visibleForTesting
MainApiClient Function(String baseUrl, String? accessToken)? debugClientFactory;

BotDataRepository? _repository;
CommandOutboxCoordinator? _coordinator;

/// Le dépôt de données de l'application, ou `null` tant qu'il n'est pas
/// construit (aucune session : il n'y a alors aucun manager à interroger).
BotDataRepository? get granularDataRepository => _repository;

/// Le coordinateur de la file hors-ligne, ou `null` tant qu'il n'est pas
/// installé. Exposé pour que l'application — et les tests — puisse lire son
/// dernier rapport de vidage.
CommandOutboxCoordinator? get commandOutboxCoordinator => _coordinator;

/// La table de la file hors-ligne, ou `null` tant qu'elle n'est pas installée.
CommandOutboxStore? get commandOutboxStore => _coordinator?.drainer.store;

/// Vrai quand la v2 est ARMÉE : la seule condition d'activation du chemin
/// granulaire. Faux tant que la sonde n'a pas répondu, et faux pour de bon sur
/// un serveur qui ne connaît pas `/api/v2`.
bool get isGranularSaveEnabled => _repository?.isGranularEnabled ?? false;

/// Construit le dépôt UNE fois, installe la file hors-ligne, puis sonde.
///
/// Rend le dépôt, ou `null` quand aucun manager n'est joignable (application
/// pas encore connectée) : dans ce cas rien n'est installé et la v2 reste
/// désarmée — le comportement d'aujourd'hui, à l'identique.
///
/// NE LÈVE JAMAIS, et c'est l'appelant qui décide de l'attendre ou non : les
/// deux points d'appel de l'application la lancent en tâche de fond
/// (`unawaited`), donc le lancement ne dépend jamais de la sonde. Elle est en
/// revanche ATTENDUE ICI pour que l'état de la couche soit décidé quand ce
/// future se termine — un appelant (ou un test) qui l'attend sait alors si la
/// v2 est armée ou non, au lieu de deviner.
Future<BotDataRepository?> ensureGranularDataLayer() async {
  final repository = await _ensureRepository();
  if (repository == null) return null;
  _installCoordinator(repository);
  // Mise en cache par le dépôt : les reprises suivantes ne re-questionnent pas
  // le serveur, et une sonde qui a ÉCHOUÉ est la seule à être reposée.
  await _probeQuietly(repository);
  return repository;
}

/// LA GARDE DU CHEMIN GRANULAIRE — ET ELLE EST LA SEULE.
///
/// Rend l'écriture à attendre par l'appelant, ou `null` quand l'écriture
/// granulaire ne doit PAS avoir lieu. `null` veut dire exactement : « la sonde
/// n'a pas armé `/api/v2`, garde ton appel d'aujourd'hui ». AUCUNE requête
/// n'est émise dans ce cas, et c'est ce qui garantit un comportement inchangé
/// tant que la façade n'est pas déployée.
///
/// POURQUOI UNE FONCTION PLUTÔT QU'UN `if` DANS L'ÉCRAN : la règle doit être
/// vérifiable sans monter l'éditeur de commande (3 000 lignes, client Discord,
/// base locale), et il ne doit exister qu'UNE copie de la condition. Deux
/// copies, c'est deux réponses le jour où l'une change.
Future<SaveOutcome>? granularCommandSaveFor(
  BotDataRepository? repository, {
  required String botId,
  required String commandId,
  required Map<String, dynamic> command,
}) {
  if (repository == null || !repository.isGranularEnabled) return null;
  final normalizedBotId = botId.trim();
  final normalizedCommandId = commandId.trim();
  if (normalizedBotId.isEmpty || normalizedCommandId.isEmpty) return null;
  return repository.saveCommand(
    normalizedBotId,
    CommandDetail(
      botId: normalizedBotId,
      commandId: normalizedCommandId,
      raw: command,
    ),
  );
}

/// Installe la couche sur un dépôt imposé. Réservé aux tests.
@visibleForTesting
CommandOutboxCoordinator installGranularDataLayerForTest({
  required BotDataRepository repository,
  CommandOutboxStore? store,
}) {
  _repository = repository;
  return _installCoordinator(repository, store: store);
}

/// Remet la couche à zéro : sans cela, un test hérite du crochet du précédent.
@visibleForTesting
void resetGranularDataLayerForTest() {
  _coordinator?.dispose();
  _coordinator = null;
  _repository = null;
  MainApiClient.onConnectivityRestored = null;
  debugClientFactory = null;
}

// ─── Assemblage ──────────────────────────────────────────────────────────────

Future<BotDataRepository?> _ensureRepository() async {
  final existing = _repository;
  if (existing != null) return existing;
  try {
    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) return null;
    final session = await MainApiSettingsStore.loadSession();
    if (session == null || session.isExpired) return null;
    final build = debugClientFactory ?? _defaultClient;
    final repository = BotDataRepository(
      client: build(config.baseUrl, session.accessToken),
    );
    _repository = repository;
    debugPrint('[GranularData] dépôt construit (${config.baseUrl}).');
    return repository;
  } catch (error) {
    // Lire une configuration ne doit JAMAIS faire tomber un lancement.
    debugPrint('[GranularData] configuration illisible : $error');
    return null;
  }
}

MainApiClient _defaultClient(String baseUrl, String? accessToken) =>
    MainApiClient(baseUrl: baseUrl, accessToken: accessToken);

CommandOutboxCoordinator _installCoordinator(
  BotDataRepository repository, {
  CommandOutboxStore? store,
}) {
  final existing = _coordinator;
  if (existing != null) return existing;

  // Le rejeu emprunte `BotDataRepository.saveCommand` : le dépôt choisit donc
  // le format, exactement comme pour une sauvegarde normale (v2 si elle est
  // armée, document entier sinon).
  final drainer = CommandOutboxDrainer(
    store: store ?? CommandOutboxStore(),
    replay: repository.saveCommand,
  );
  final coordinator = CommandOutboxCoordinator(
    drainer: drainer,
    // Installe le hook de file (`repository.offlineQueueHook`), le retour au
    // premier plan (ii) et la poussée réussie (iii).
    repository: repository,
    attachLifecycle: true,
    attachPushHook: true,
  );
  _coordinator = coordinator;

  // (i) Retour de connectivité. Le client du manager est le SEUL objet de
  // l'application qui sache qu'une panne a eu lieu ET qu'elle est terminée :
  // la première requête qui aboutit après des échecs est exactement le retour
  // du réseau, sans sonde périodique ni dépendance de plateforme.
  MainApiClient.onConnectivityRestored = () {
    unawaited(coordinator.onConnectivityRestored());
  };

  debugPrint('[GranularData] file hors-ligne installée.');
  return coordinator;
}

Future<void> _probeQuietly(BotDataRepository repository) async {
  if (repository.hasProbed) return;
  try {
    final capabilities = await repository.probe();
    debugPrint(
      capabilities == null
          ? '[GranularData] sonde : /api/v2 absente — chemin legacy conservé.'
          : '[GranularData] sonde : /api/v2 armée '
                '(granular_api=${capabilities.granularApi}).',
    );
  } catch (error) {
    // Une sonde qui ÉCHOUE n'est pas une absence, et elle n'est pas une raison
    // d'échouer non plus : rien n'est armé, rien n'est cassé, et la prochaine
    // reprise redemandera (une sonde ratée n'est jamais mise en cache).
    debugPrint('[GranularData] sonde impossible : $error');
  }
}
