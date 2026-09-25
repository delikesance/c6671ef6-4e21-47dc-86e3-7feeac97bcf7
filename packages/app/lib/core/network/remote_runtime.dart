import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/runtime_preferences.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class ResolvedRemoteRuntime {
  const ResolvedRemoteRuntime({
    required this.source,
    this.client,
    this.detailLabel,
    this.unavailableReason,
  });

  final RemoteRuntimeSource source;
  final RemoteRuntimeClient? client;
  final String? detailLabel;
  final String? unavailableReason;

  bool get isLocal => source == RemoteRuntimeSource.local;

  bool get isRemote => client != null;

  bool get isManager => source == RemoteRuntimeSource.manager;

  bool get isRunner => source == RemoteRuntimeSource.runner;

  bool get blocksLocalFallback =>
      source == RemoteRuntimeSource.manager && client == null;
}

String _runtimeCopy({required String fr, required String en}) {
  final lang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  return lang.startsWith('fr') ? fr : en;
}

Future<ResolvedRemoteRuntime> resolveRemoteRuntime({
  required bool supportsManagerRuntime,
  String? botId,
  Duration getTimeout = const Duration(seconds: 30),
  // Plafond d'ecriture volontairement BORNÉ : un POST qui n'aboutit pas ne doit pas figer
  // l'interface ni bloquer la suite de la sequence. Mieux vaut un echec lisible (et
  // reessayable) qu'une attente de 90 secondes qui ressemble a un gel de l'application.
  Duration postTimeout = const Duration(seconds: 25),
  RemoteRuntimeSource? forcedSource,
}) async {
  // Choix EXPLICITE de l'utilisateur (pop-up de démarrage) : il prime sur
  // l'association du bot. C'est ce qui rend vraie la promesse de l'écran — « en
  // local » démarre en local même si le bot est associé au manager, et « sur le
  // serveur » vise le manager même sans association. Sans ce passage, la pop-up
  // serait purement décorative et le bot repartirait là où l'association décide.
  if (forcedSource == RemoteRuntimeSource.local) {
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }
  if (forcedSource == RemoteRuntimeSource.manager) {
    final forcedConfig = await MainApiSettingsStore.loadConfig();
    final forcedSession = await MainApiSettingsStore.loadSession();
    if (forcedConfig.isConfigured &&
        forcedSession != null &&
        !forcedSession.isExpired) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.manager,
        client: MainApiClient(
          baseUrl: forcedConfig.baseUrl,
          accessToken: forcedSession.accessToken,
          timeout: postTimeout,
        ),
        detailLabel: forcedConfig.baseUrl,
      );
    }
    // La cible DEMANDÉE, sans client : `blocksLocalFallback` devient vrai, et l'écran
    // explique pourquoi le serveur est hors de portée. On ne bascule PAS en local —
    // exécuter sur la machine autre chose que ce que l'utilisateur a choisi, sans le lui
    // dire, est exactement le mensonge que ce repli produisait : la pop-up n'offre
    // « serveur » qu'avec une session valide, mais le résolveur la relit et peut en juger
    // autrement. Il doit alors le DIRE, pas décider à sa place.
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.manager);
  }

  if (kIsWeb) {
    final runnerConfig = await RunnerSettings.getConfig();
    if (runnerConfig != null) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.runner,
        client: runnerConfig.createClient(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
        detailLabel: runnerConfig.name ?? runnerConfig.url,
      );
    }
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  final platform = defaultTargetPlatform;
  final isIOS = platform == TargetPlatform.iOS;
  final isAndroid = platform == TargetPlatform.android;
  final isDesktop =
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
  final effectiveSupportsManagerRuntime = supportsManagerRuntime;

  // Le poste de travail n'est plus exclu du manager : la plateforme ne verrouille
  // plus l'ACCÈS AUX DONNÉES du compte (solde, bots, conteneurs clé en main, snapshot).
  // Ce qui décide d'un PILOTAGE à distance, c'est l'association du bot
  // (`RunnerSettings.getAssociatedRunnerId(botId) == 'manager'`), traitée ci-dessous —
  // pas l'OS. Un bot non associé reste donc exécuté en local (runner embarqué).

  // 1. Check for explicit bot association first (overrides global preferences)
  if (botId != null) {
    final associatedId = RunnerSettings.getAssociatedRunnerId(botId);
    if (associatedId == 'manager' && effectiveSupportsManagerRuntime) {
      final mainApiConfig = await MainApiSettingsStore.loadConfig();
      final mainApiSession = await MainApiSettingsStore.loadSession();

      if (mainApiConfig.isConfigured &&
          mainApiSession != null &&
          !mainApiSession.isExpired) {
        return ResolvedRemoteRuntime(
          source: RemoteRuntimeSource.manager,
          client: MainApiClient(
            baseUrl: mainApiConfig.baseUrl,
            accessToken: mainApiSession.accessToken,
            timeout: postTimeout,
          ),
          detailLabel: mainApiConfig.baseUrl,
        );
      }
    } else if (associatedId != null && associatedId != 'local') {
      final runners = await RunnerSettings.getRunners();
      final match = runners.where((r) => r.id == associatedId);
      if (match.isNotEmpty) {
        final config = match.first;
        var useAssociation = true;
        if (isDesktop) {
          final engine = await getBotRuntimeEngine(botId);
          if (engine == runtimeEngineJavascript &&
              !RunnerSettings.supportsJavascriptRunner(config)) {
            useAssociation = false;
          }
        }
        if (useAssociation) {
          final hydrated = await RunnerSettings.hydrateRunnerConnectionConfig(
            config,
          );
          if (hydrated == null) {
            return const ResolvedRemoteRuntime(
              source: RemoteRuntimeSource.local,
            );
          }
          return ResolvedRemoteRuntime(
            source: RemoteRuntimeSource.runner,
            client: hydrated.createClient(
              getTimeout: getTimeout,
              postTimeout: postTimeout,
            ),
            detailLabel: hydrated.name ?? hydrated.url,
          );
        }
      }
    }
  }

  if (!effectiveSupportsManagerRuntime) {
    final runnerConfig = botId != null
        ? await RunnerSettings.resolveConfigForBot(botId)
        : await RunnerSettings.getConfig();
    if (runnerConfig != null) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.runner,
        client: runnerConfig.createClient(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
        detailLabel: runnerConfig.name ?? runnerConfig.url,
      );
    }
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  if (isAndroid && await RuntimePreferences.isMobileLocalHostingEnabled()) {
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  final mainApiConfig = await MainApiSettingsStore.loadConfig();
  final mainApiSession = await MainApiSettingsStore.loadSession();

  if (mainApiConfig.isConfigured) {
    final session = await loadMainApiSession();

    if (session != null && !session.isExpired) {
      // Sur un poste de travail, une résolution PAR BOT qui n'a pas été associée au
      // manager (branche 1 ci-dessus, non prise) reste LOCALE : sinon un bot pensé pour
      // le runner embarqué partirait sur les serveurs Bot Creator simplement parce
      // qu'un compte est connecté. La résolution GLOBALE (`botId == null` : compte,
      // solde, conteneurs, snapshot, état d'exécution) et toutes les plateformes
      // mobiles gardent le manager comme source de vérité.
      if (botId == null || !isDesktop) {
        return ResolvedRemoteRuntime(
          source: RemoteRuntimeSource.manager,
          client: MainApiClient(
            baseUrl: mainApiConfig.baseUrl,
            accessToken: session.accessToken,
            timeout: postTimeout,
          ),
          detailLabel: mainApiConfig.baseUrl,
        );
      }
    }

    // Poste de travail sans session exploitable : le manager ne doit pas devenir une
    // prison. Un bot SANS association au manager continue de tourner en LOCAL (runner
    // embarqué), donc on laisse la résolution descendre vers le repli runner/local au
    // lieu de bloquer le repli local comme sur mobile. Sur mobile le comportement est
    // inchangé : sans compte connecté, c'est le manager (à reconnecter) qui porte le
    // message, et le repli local est explicitement interdit.
    if (!isDesktop) {
      final unavailableReason = mainApiSession == null
          ? (isIOS
                ? _runtimeCopy(
                    fr: 'Le mode local n\'est pas pris en charge sur iOS. Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                    en: 'Local mode is not supported on iOS. Sign in to Bot Creator in Settings before starting this bot.',
                  )
                : _runtimeCopy(
                    fr: 'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                    en: 'Sign in to Bot Creator in Settings before starting this bot.',
                  ))
          : _runtimeCopy(
              fr: 'Votre session Bot Creator a expire. Reconnectez-vous dans les parametres pour demarrer ce bot.',
              en: 'Your Bot Creator session expired. Sign in again in Settings to start this bot.',
            );

      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.manager,
        detailLabel: mainApiConfig.baseUrl,
        unavailableReason: unavailableReason,
      );
    }
  }

  if (isIOS) {
    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.manager,
      unavailableReason: _runtimeCopy(
        fr: 'Le mode local n\'est pas pris en charge sur iOS. Configurez Bot Creator pour demarrer ce bot.',
        en: 'Local mode is not supported on iOS. Configure Bot Creator to start this bot.',
      ),
    );
  }

  final runnerConfig = botId != null
      ? await RunnerSettings.resolveConfigForBot(botId)
      : await RunnerSettings.getConfig();
  if (runnerConfig != null) {
    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.runner,
      client: runnerConfig.createClient(
        getTimeout: getTimeout,
        postTimeout: postTimeout,
      ),
      detailLabel: runnerConfig.name ?? runnerConfig.url,
    );
  }

  return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
}

Future<String> describeManagerRuntimeFailure(
  MainApiClient client,
  Object error,
) async {
  bool isInvalidBotId(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('invalid bot_id') ||
        normalized.contains('invalid bot id') ||
        normalized.contains('invalid_bot_id');
  }

  final originalError = error.toString();

  // La formule du compte prime : inutile d'interroger le diagnostic du runner,
  // le refus vient du plan et l'offre est la seule issue.
  if (planLimitRefusalFromError(error) != null) {
    return _runtimeCopy(
      fr: 'Votre formule ne permet pas ce demarrage. Consultez les offres pour changer de formule.',
      en: 'Your plan does not allow this start. Check the plans to upgrade your formula.',
    );
  }

  if (isInvalidBotId(originalError)) {
    return _runtimeCopy(
      fr: 'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Erreur initiale : $error',
      en: 'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Original error: $error',
    );
  }

  try {
    final info = await client.getRunnerInfo();
    final deployed = info['deployed'] == true;
    final runner = (info['runner'] is Map)
        ? Map<String, dynamic>.from(info['runner'] as Map)
        : const <String, dynamic>{};
    final latestDeployJob = (info['latest_deploy_job'] is Map)
        ? Map<String, dynamic>.from(info['latest_deploy_job'] as Map)
        : const <String, dynamic>{};

    final jobStatus = (latestDeployJob['status'] ?? '').toString().trim();
    final jobError = (latestDeployJob['error'] ?? '').toString().trim();
    final runnerState = (runner['state'] ?? '').toString().trim();
    final healthStatus = (runner['health_status'] ?? '').toString().trim();

    if (isInvalidBotId(jobError)) {
      return _runtimeCopy(
        fr: 'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Details : $jobError',
        en: 'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Details: $jobError',
      );
    }

    if (!deployed) {
      return _runtimeCopy(
        fr: 'Les serveurs Bot Creator ne sont pas encore prets pour ce bot. Erreur initiale : $error',
        en: 'Bot Creator servers are not ready for this bot yet. Original error: $error',
      );
    }
    if (jobStatus == 'QUEUED' || jobStatus == 'RUNNING') {
      return _runtimeCopy(
        fr: 'Le demarrage sur les serveurs Bot Creator est encore en cours ($jobStatus). Le traitement peut etre en attente ou toujours en cours. Erreur initiale : $error',
        en: 'Bot Creator server startup is still in progress ($jobStatus). Processing may still be queued or running. Original error: $error',
      );
    }
    if (jobStatus == 'FAILED') {
      final suffix = jobError.isEmpty ? '' : ' Details: $jobError';
      return _runtimeCopy(
        fr: 'Le demarrage sur les serveurs Bot Creator a echoue.$suffix Erreur initiale : $error',
        en: 'Bot Creator server startup failed.$suffix Original error: $error',
      );
    }
    if (healthStatus.toLowerCase() == 'unreachable' ||
        runnerState.toUpperCase() == 'DEGRADED') {
      return _runtimeCopy(
        fr: 'Les serveurs Bot Creator sont temporairement injoignables. Erreur initiale : $error',
        en: 'Bot Creator servers are temporarily unreachable. Original error: $error',
      );
    }
  } catch (_) {
    // Fall back to the original error when the diagnostic endpoint is unavailable.
  }
  return _runtimeCopy(
    fr: 'La requete vers les serveurs Bot Creator a echoue : $error',
    en: 'Request to Bot Creator servers failed: $error',
  );
}

bool isPendingFreeRuntimeCreditError(Object error) {
  final normalized = error.toString().toLowerCase();
  return normalized.contains('bot_free_time_required') ||
      normalized.contains('free runtime credits before start');
}

/// Refus de démarrage dû à la formule du compte (403 du manager).
///
/// Le serveur est seul juge des quotas : quand il refuse, l'écran doit proposer
/// l'offre plutôt qu'afficher un message technique.
enum PlanLimitRefusal {
  excludesOwnBots,
  botQuotaReached,
  excludesTurnkey,
  turnkeyQuotaReached,
}

/// Détecte un refus lié à la formule depuis l'erreur renvoyée par le manager.
///
/// On matche le message servi par l'API (que l'application remonte telle quelle)
/// **et** les codes d'erreur, au cas où le code serait renvoyé à la place.
PlanLimitRefusal? planLimitRefusalFromError(Object error) {
  final normalized = error.toString().toLowerCase();
  bool has(List<String> needles) => needles.any(normalized.contains);

  if (has(const ['does not include personal bots', 'own_bots_not_allowed'])) {
    return PlanLimitRefusal.excludesOwnBots;
  }
  if (has(const ['personal bot limit reached', 'bot_quota_reached'])) {
    return PlanLimitRefusal.botQuotaReached;
  }
  if (has(const ['does not include turnkey apps', 'turnkey_not_allowed'])) {
    return PlanLimitRefusal.excludesTurnkey;
  }
  if (has(const ['turnkey app limit reached', 'turnkey_quota_reached'])) {
    return PlanLimitRefusal.turnkeyQuotaReached;
  }
  return null;
}

bool isPendingManagerRunnerError(Object error) {
  final normalized = error.toString().toLowerCase();
  return normalized.contains('runner_not_deployed') ||
      normalized.contains('runner is not deployed') ||
      normalized.contains('runner_unreachable') ||
      normalized.contains('runner is unreachable');
}

Future<void> startManagerBotWithCreditRetry({
  required MainApiClient client,
  required String botId,
  String? botName,
  Duration timeout = const Duration(seconds: 15),
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (true) {
    try {
      await client.startBot(botId, botName: botName);
      return;
    } catch (error) {
      if (!isPendingFreeRuntimeCreditError(error) &&
              !isPendingManagerRunnerError(error) ||
          DateTime.now().isAfter(deadline)) {
        rethrow;
      }
      await Future<void>.delayed(retryDelay);
    }
  }
}

/// Vrai quand [error] est le refus typé de la garde anti-config-vide.
bool isBotPayloadRefusal(Object error) =>
    error is DegenerateBotPayloadException;

/// Message localisé à afficher quand la poussée a été REFUSÉE par la garde
/// anti-config-vide, ou `null` quand [error] n'est pas un refus — l'appelant
/// garde alors son message d'erreur habituel.
///
/// POURQUOI cette traduction vit ICI, à côté de [describeManagerRuntimeFailure] :
/// les écrans qui poussent une configuration importent déjà ce fichier, et une
/// seule phrase doit servir partout. Le refus doit dire les deux choses que
/// l'utilisateur ne peut pas deviner — rien n'est parti, et rien n'a été effacé
/// en local — sans quoi il croirait à une panne et « réparerait » une
/// configuration intacte.
String? localizedBotPayloadRefusalMessage(AppLocalizations l10n, Object error) {
  if (!isBotPayloadRefusal(error)) {
    return null;
  }
  return l10n.bot_payload_refused_local_kept;
}

/// Code applicatif du refus SERVEUR d'une sur-réduction VOLONTAIRE :
/// `POST /gateway/bots/sync` rend `409 bot_config_overshrink` quand la
/// configuration poussée passe sous le plancher de plausibilité ou pèse moins de
/// 20 % de la configuration vivante. Le serveur n'applique RIEN et a restauré la
/// configuration précédente.
const String botConfigOvershrinkErrorCode = 'bot_config_overshrink';

/// Vrai quand [error] est CE refus précis : statut `409` ET code
/// [botConfigOvershrinkErrorCode].
///
/// POURQUOI c'est distinct de [isBotPayloadRefusal] : la garde LOCALE (charge
/// vide) refuse AVANT le réseau, sans rien demander à personne. Ici le serveur a
/// bien reçu la poussée, l'a refusée et a restauré la configuration précédente :
/// ce n'est ni une panne, ni une erreur de l'application, c'est une QUESTION.
/// Laisser un tel refus filer vers le diagnostic de panne afficherait « les
/// serveurs Bot Creator ne sont pas prêts » devant un refus volontaire.
///
/// Le statut est vérifié EN PLUS du code : un `409` d'une autre nature
/// (`bot_config_unreadable`, `token_unavailable`…) ne doit pas ouvrir ce
/// dialogue.
bool isBotConfigOvershrinkRefusal(Object error) {
  if (error is! MainApiClientException) {
    return false;
  }
  if (error.statusCode != 409) {
    return false;
  }
  final code = (error.code ?? '').trim().toLowerCase();
  if (code == botConfigOvershrinkErrorCode) {
    return true;
  }
  // Repli : certaines passerelles ne recopient que le texte de l'erreur. Le
  // message du manager COMMENCE par le code (`bot_config_overshrink: ...`), donc
  // le refus reste reconnaissable même sans le champ `code` — et ce repli ne
  // peut jamais accepter un `409` d'une autre nature.
  return error.message.toLowerCase().contains(botConfigOvershrinkErrorCode);
}

/// Code applicatif du refus SERVEUR d'une version trop pauvre à la
/// restauration : `POST /gateway/bots/{id}/versions/restore` rend
/// `409 bot_config_version_too_small` quand le fichier de version visé pèse
/// moins que le plancher de plausibilité (2048 octets). Le serveur n'applique
/// RIEN : restaurer une configuration quasi vide reviendrait à vider le bot.
const String botConfigVersionTooSmallErrorCode = 'bot_config_version_too_small';

/// Vrai quand [error] est CE refus précis : statut `409` ET code connu.
///
/// POURQUOI c'est distinct d'un CONFLIT de révision — alors que les deux sont
/// des `409` : une précondition périmée se règle en RELISANT, ce refus-là ne se
/// règle pas (la version demandée existe, elle est seulement trop pauvre). Le
/// présenter comme « recharger et écraser » fait tourner l'utilisateur en boucle
/// sur une action qui ne peut pas aboutir ; le traiter comme une panne cache la
/// seule information utile, à savoir que la version est vide.
bool isBotConfigVersionFloorRefusal(Object error) {
  if (error is! MainApiClientException) {
    return false;
  }
  if (error.statusCode != 409) {
    return false;
  }
  final code = (error.code ?? '').trim().toLowerCase();
  if (code == botConfigVersionTooSmallErrorCode) {
    return true;
  }
  // Repli : certaines passerelles ne recopient que le texte de l'erreur, qui
  // COMMENCE par le code (`bot_config_version_too_small: ... is 1776 bytes`).
  return error.message.toLowerCase().contains(
    botConfigVersionTooSmallErrorCode,
  );
}

/// Les quatre phrases du dialogue de sur-réduction, traduites.
class BotConfigOvershrinkConfirmation {
  const BotConfigOvershrinkConfirmation({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.keepLocalLabel,
  });

  final String title;
  final String body;
  final String confirmLabel;
  final String keepLocalLabel;
}

/// Phrases du dialogue de sur-réduction (`409 bot_config_overshrink`).
///
/// La question ne dépend pas du contenu refusé : elle dit les deux choses que
/// l'utilisateur ne peut pas deviner — RIEN n'a encore été envoyé, et sa copie
/// locale est intacte (le serveur fait toujours tourner la configuration
/// précédente) — puis demande s'il veut envoyer quand même.
BotConfigOvershrinkConfirmation localizedBotConfigOvershrinkConfirmation(
  AppLocalizations l10n,
) => BotConfigOvershrinkConfirmation(
  title: l10n.bot_config_overshrink_title,
  body: l10n.bot_config_overshrink_body,
  confirmLabel: l10n.bot_config_overshrink_send_anyway,
  keepLocalLabel: l10n.bot_config_overshrink_keep_local,
);

/// Phrase à afficher quand le refus de sur-réduction n'a PAS ouvert de dialogue
/// (poussée de démarrage, ou écran sans interface pour poser la question) :
/// rien n'est parti, rien n'a été effacé. `null` quand [error] n'est pas ce refus.
///
/// POURQUOI la même phrase que le corps du dialogue : l'utilisateur ne doit
/// entendre qu'une version des faits, et les quatre clés i18n du dialogue
/// suffisent à couvrir le retour après annulation.
String? localizedBotConfigOvershrinkNothingSent(
  AppLocalizations l10n,
  Object error,
) => isBotConfigOvershrinkRefusal(error)
    ? l10n.bot_config_overshrink_body
    : null;

/// Issue d'une poussée de configuration vers le manager.
enum BotConfigPushOutcome {
  /// La configuration est partie — du premier coup, ou après accord explicite.
  sent,

  /// Rien n'est parti et rien n'a été effacé : l'utilisateur a gardé sa version
  /// locale.
  keptLocal,

  /// Rien n'est parti : le serveur refuse la sur-réduction MÊME avec l'accord
  /// explicite (plancher absolu — configuration quasi vide). Redemander la même
  /// chose ne changerait rien.
  overshrinkFloorRefused,
}

/// Pousse une configuration vers le manager en traitant le refus SERVEUR de
/// sur-réduction.
///
/// Contrat (`POST /gateway/bots/sync`) : la poussée part D'ABORD sans
/// `confirmOvershrink`. Si le serveur la refuse par `409 bot_config_overshrink`
/// — suppression massive, peut-être volontaire — on demande confirmation
/// ([askConfirmation]) et, sur accord SEULEMENT, on rejoue EXACTEMENT la même
/// poussée avec `confirmOvershrink: true`.
///
/// POURQUOI cette orchestration vit ici et pas dans l'écran : c'est une règle
/// (rien ne part sans accord, on ne demande jamais deux fois, un refus ne se
/// déguise pas en succès), et elle se prouve sans monter `AppHomePage`.
///
/// Toute erreur qui n'est PAS ce refus remonte telle quelle : une panne reste une
/// panne, et l'appelant garde son message d'erreur habituel.
Future<BotConfigPushOutcome> pushBotConfigToleratingOvershrink({
  required Future<void> Function(bool confirmOvershrink) push,
  required Future<bool> Function() askConfirmation,
  bool confirmOvershrink = false,
}) async {
  try {
    await push(confirmOvershrink);
    return BotConfigPushOutcome.sent;
  } catch (error) {
    if (!isBotConfigOvershrinkRefusal(error)) {
      rethrow;
    }
    if (confirmOvershrink) {
      // Le drapeau du contrat était DÉJÀ posé : ce n'est plus une question mais
      // le plancher absolu du serveur, qui refuse même sur accord.
      return BotConfigPushOutcome.overshrinkFloorRefused;
    }
  }

  final confirmed = await askConfirmation();
  if (!confirmed) {
    // Refus de l'utilisateur : rien n'est envoyé, rien n'est effacé.
    return BotConfigPushOutcome.keptLocal;
  }
  // Accord explicite : LA MÊME poussée, drapeau du contrat en plus. Un second
  // refus ne rouvre pas le dialogue (voir [BotConfigPushOutcome.overshrinkFloorRefused]).
  return pushBotConfigToleratingOvershrink(
    push: push,
    askConfirmation: askConfirmation,
    confirmOvershrink: true,
  );
}

/// La poussée de configuration d'un DÉMARRAGE de bot, sur-réduction comprise.
///
/// POURQUOI elle existe : un démarrage pousse la configuration AVANT de demander
/// au serveur de lancer le bot, et cette poussée est refusée pour sur-réduction
/// exactement comme la poussée canonique. La règle est identique — demander,
/// rejouer la MÊME poussée sur accord SEULEMENT, ne jamais demander deux fois —
/// et elle vit dans [pushBotConfigToleratingOvershrink]. Cette fonction n'en
/// adapte que le TRANSPORT : l'écran de démarrage détient un client de runtime
/// (manager ou runner), pas un client d'API.
///
/// Le drapeau `confirmOvershrink` n'existe que sur le protocole du MANAGER, seul
/// serveur qui refuse une sur-réduction : un runner reçoit donc EXACTEMENT la
/// poussée d'aujourd'hui, sans champ ajouté — et ne peut pas, non plus, produire
/// [isBotConfigOvershrinkRefusal], qui exige une erreur d'API de statut `409`.
Future<BotConfigPushOutcome> pushStartBotConfigToleratingOvershrink({
  required RemoteRuntimeClient client,
  required String botId,
  required String botName,
  required Map<String, dynamic> config,
  required Future<bool> Function() askConfirmation,
}) => pushBotConfigToleratingOvershrink(
  push: (confirmOvershrink) => client is MainApiClient
      ? client.syncBot(
          botId,
          botName,
          config,
          confirmOvershrink: confirmOvershrink,
        )
      : client.syncBot(botId, botName, config),
  askConfirmation: askConfirmation,
);
