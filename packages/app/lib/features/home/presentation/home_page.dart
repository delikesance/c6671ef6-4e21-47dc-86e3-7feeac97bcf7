import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:bot_creator/core/analytics/activation_funnel.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/storage/granular_data_layer.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/duration_formatter.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/string_sanitizer.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/features/ads/logic/ad_ssv_context.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/features/ads/presentation/native_ad_slot.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_presenter.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_merge.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_auto_recovery.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_config_pull_dialog.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_config_overshrink_dialog.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_scan.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_sync.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/containers/logic/turnkey_bot_invite.dart';
import 'package:bot_creator/features/containers/presentation/container_detail_page.dart';
import 'package:bot_creator/features/containers/presentation/home_turnkey_container_card.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/home/logic/bot_run_source.dart';
import 'package:bot_creator/features/home/logic/bot_runtime_affinity.dart';
import 'package:bot_creator/features/home/logic/bot_start_branch.dart';
import 'package:bot_creator/features/home/logic/bot_start_outcome.dart';
import 'package:bot_creator/features/home/logic/bot_start_server_request.dart';
import 'package:bot_creator/features/home/logic/bot_start_target.dart';
import 'package:bot_creator/features/home/logic/home_project_split.dart';
import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:bot_creator/features/home/presentation/widgets/bot_start_target_dialog.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/plan_limit_dialog.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscriptions_hub_page.dart';
import 'package:bot_creator/features/team/logic/team_models.dart';
import 'package:bot_creator/features/team/presentation/team_chat_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyxx/nyxx.dart' hide Locale, Logger;
import 'package:url_launcher/url_launcher.dart';

String homeUiCopy(
  BuildContext context, {
  required String fr,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
}

/// Détecte si un nom de bot masque son identité réelle (vide, 'Unnamed Bot',
/// 'Unknown App', égal à son identifiant snowflake, ou composé uniquement de chiffres).
bool botNameHidesIdentity(String? name, String botId) {
  if (name == null) return true;
  final trimmed = name.trim();
  if (trimmed.isEmpty ||
      trimmed == 'Unnamed Bot' ||
      trimmed == 'Unknown App' ||
      trimmed == botId.trim()) {
    return true;
  }
  if (trimmed.length >= 15 && BigInt.tryParse(trimmed) != null) {
    return true;
  }
  return false;
}

/// Issue d'une tentative de rafraîchissement de l'accueil par le snapshot agrégé.
enum HomeSnapshotOutcome {
  /// 200 : le snapshot (compte + bots) a été appliqué.
  applied,

  /// 304 : rien n'a changé depuis l'ETag mémorisé, donc rien à réappliquer.
  notModified,

  /// Le manager ne connaît pas `/gateway/snapshot` (404) ou est injoignable : on est
  /// retombé sur le repli historique, une requête par bot.
  fellBack,
}

/// Signature de l'appel réseau utilisé par le repli : une fonction plutôt qu'une
/// interface, pour que la décision soit vérifiable avec un client factice qui compte
/// les appels — `MainApiClient` expose exactement cette signature.
typedef GatewaySnapshotFetcher =
    Future<GatewaySnapshotResponse?> Function({String? etag});

/// Charge utile du snapshot agrégé décomposée en objets du canal temps réel : la source
/// interrogée (HTTP) et la source poussée (WebSocket) traversent ainsi le même code.
class HomeSnapshotData {
  const HomeSnapshotData({required this.bots, this.account, this.etag});

  final List<GatewayBotEventPayload> bots;
  final GatewayAccountEventPayload? account;
  final String? etag;
}

/// Analyse la charge utile de `GET /gateway/snapshot` (`{account, bots[], containers[]}`).
///
/// Les clés sont celles déjà comprises par `GatewayBotEventPayload.fromJson` et
/// `GatewayAccountEventPayload.fromJson` : même contrat que le canal temps réel, donc
/// aucune divergence possible entre l'état poussé et l'état interrogé.
HomeSnapshotData parseGatewaySnapshotPayload(
  Map<String, dynamic> payload, {
  String? etag,
}) {
  final bots = <GatewayBotEventPayload>[];
  final rawBots = payload['bots'];
  if (rawBots is List) {
    for (final raw in rawBots) {
      if (raw is Map) {
        bots.add(
          GatewayBotEventPayload.fromJson(Map<String, dynamic>.from(raw)),
        );
      }
    }
  }
  GatewayAccountEventPayload? account;
  final rawAccount = payload['account'];
  if (rawAccount is Map) {
    account = GatewayAccountEventPayload.fromJson(
      Map<String, dynamic>.from(rawAccount),
    );
  }
  return HomeSnapshotData(bots: bots, account: account, etag: etag);
}

/// Repli HTTP de l'accueil quand la WebSocket est coupée : UNE requête pour tout l'état
/// (compte + bots) au lieu d'une par bot.
///
/// - `applySnapshot` est appelé sur un 200 seulement ;
/// - un 304 (`fetchSnapshot` rend `null`) ne réapplique rien : c'est le but de l'ETag ;
/// - toute erreur — dont le 404 d'un manager plus ancien — retombe sur le repli
///   historique, car cesser de rafraîchir l'accueil serait une régression.
Future<HomeSnapshotOutcome> refreshHomeFromGatewaySnapshot({
  required GatewaySnapshotFetcher fetchSnapshot,
  required String? etag,
  required Future<void> Function(HomeSnapshotData snapshot) applySnapshot,
  required Future<void> Function() fallbackToPerBotRefresh,
}) async {
  GatewaySnapshotResponse? response;
  try {
    response = await fetchSnapshot(etag: etag);
  } catch (_) {
    // Manager plus ancien (404) ou API injoignable : la rétro-compatibilité est une
    // exigence, pas une option.
    await fallbackToPerBotRefresh();
    return HomeSnapshotOutcome.fellBack;
  }
  if (response == null) {
    return HomeSnapshotOutcome.notModified;
  }
  await applySnapshot(
    parseGatewaySnapshotPayload(response.payload, etag: response.etag),
  );
  return HomeSnapshotOutcome.applied;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onManageBot});

  /// When set, Manage opens inside the shell instead of pushing [AppEditPage].
  final void Function(String id, String name)? onManageBot;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// The currently active HomePage instance. Set in initState, cleared in dispose.
  /// Replaces the old module-level GlobalKey pattern that caused
  /// "Multiple widgets used the same GlobalKey" crashes during navigation.
  static HomePageState? current;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> triggerRefresh() async {
    await _refreshIndicatorKey.currentState?.show();
  }

  /// IDs des bots en cours d'exécution.
  Set<String> _runningBotIds = <String>{};

  RemoteRuntimeSource _runtimeSource = RemoteRuntimeSource.local;
  String? _runtimeDetailLabel;
  final Map<String, RemoteRuntimeSource> _runtimeSourceByBotId = {};
  final Map<String, String?> _runtimeDetailLabelByBotId = {};

  /// ID du bot en cours d'action (démarrage/arrêt/ajout de temps).
  String? _botIdInAction;

  /// Conteneurs clé en main (« turnkey ») du compte, affichés sur l'accueil à
  /// côté des bots classiques. Remplis par [_refreshTurnkeyContainers].
  List<ContainerInfo> _turnkeyContainers = const <ContainerInfo>[];

  /// ID du conteneur dont une action (démarrage/arrêt) est en cours : sa carte
  /// se verrouille le temps de la requête.
  String? _containerIdInAction;

  /// Garde de réentrance du chargement des conteneurs : un seul appel en vol,
  /// pour ne jamais dupliquer la requête (accueil + tirage pour rafraîchir).
  bool _isRefreshingTurnkeyContainers = false;

  /// ID du conteneur dont l'INVITATION est en cours : sa carte désactive le
  /// bouton et affiche l'indicateur d'occupation, donc pas de double envoi.
  String? _inviteContainerIdInAction;

  /// Service d'invitation unique de l'accueil.
  ///
  /// Il est créé UNE fois (à la première invitation) et garde donc sa garde de
  /// réentrance entre deux clics : recréer un service par clic perdrait la
  /// protection anti double clic. Le client est résolu au même moment, comme
  /// pour le reste de l'accueil.
  TurnkeyBotInviteService? _turnkeyInviteService;

  /// Un AnimationController par carte (clé = bot id) pour l'effet pulse.
  final Map<String, AnimationController> _pulseControllers = {};

  /// Contrôleur de secours si une carte est construite alors qu'aucun
  /// contrôleur dédié n'existe encore (aucun crash, aucune mutation au build).
  late final AnimationController _fallbackPulseController;

  /// Ids du dernier snapshot reçu du stream d'apps.
  Set<String> _knownAppIds = <String>{};
  StreamSubscription<List<dynamic>>? _appsSub;
  Map<String, int> _freeMinutesByBotId = <String, int>{};
  final Map<String, DateTime> _sessionExpiresAtByBotId = <String, DateTime>{};
  final Map<String, int> _botNotFoundStreak = <String, int>{};
  final Set<String> _skippedMissingBotIds = <String>{};

  /// Ids des bots où l'utilisateur n'est QUE collaborateur, tels que le SERVEUR
  /// les annonce (`is_collaborative` sur `GET /gateway/bots`).
  ///
  /// Aucune heuristique locale : un serveur plus ancien ne renvoie pas ce champ,
  /// l'ensemble reste vide, et TOUS les bots restent dans « My bots » — un faux
  /// positif déplacerait un bot de son propriétaire vers un écran étranger.
  Set<String> _collaborativeBotIds = <String>{};

  /// Identifiant du propriétaire par bot PARTAGÉ (`owner_id` du serveur, chaîne
  /// vide s'il ne le donne pas). Sert uniquement au libellé de la carte, jamais
  /// à décider d'un droit.
  Map<String, String> _sharedBotOwnerIds = <String, String>{};

  /// Droits de l'utilisateur sur les bots PARTAGÉS, lus côté serveur
  /// (`my_permissions`). Une entrée ABSENTE = droits inconnus => la carte
  /// partagée n'offre aucune action sensible (démarrage/arrêt désactivés).
  Map<String, BotPermissions> _sharedBotPermissions =
      <String, BotPermissions>{};

  /// Empêche deux chargements du partage de se superposer (démarrage, reprise,
  /// rafraîchissement manuel).
  bool _isLoadingSharedBots = false;

  static const int _missingBot404Threshold = 3;
  Timer? _statusRefreshTimer;
  StreamSubscription<GatewayBotEvent>? _gatewayEventsSub;
  StreamSubscription<bool>? _gatewayConnectionSub;
  bool _gatewayEventsConnected = false;
  int _httpFallbackTick = 0;

  /// Session du canal temps réel actuellement câblée par l'accueil (une seule à la fois).
  GatewayBotEventsSession? _gatewayEventsSession;

  /// Identité du serveur qui a fourni [_gatewayEventsSession] (base du client manager).
  ///
  /// C'est elle qui distingue « le canal demandé est DÉJÀ en place » de « le canal
  /// demandé vise un autre serveur » : changer de serveur (ou de compte) change la base,
  /// donc impose une session neuve, tandis qu'un simple appel répété pour la même base
  /// doit ne rien faire du tout.
  String? _gatewayEventsClientKey;

  /// Dernier ETag du snapshot agrégé : c'est lui qui transforme le repli suivant en
  /// `304` (rien à retélécharger, rien à réappliquer) tant que l'état n'a pas bougé.
  String? _snapshotEtag;

  /// Empêche deux replis de se superposer : le tick est de 15 s alors que le délai
  /// HTTP peut monter à 30 s. Le garde couvre TOUS les déclencheurs — le tick de 60 s,
  /// la reprise d'application et la perte de connexion WebSocket — puisque tous passent
  /// par [_refreshFromSnapshot].
  bool _isRefreshingFromSnapshot = false;

  /// Collaborateurs du repli, remplaçables en test uniquement.
  ///
  /// Le repli réel résout son client HTTP depuis la session enregistrée, ce qui n'est
  /// pas interceptable dans un test ; or c'est précisément le NOMBRE de requêtes
  /// (1 snapshot contre N requêtes par bot) que les tests doivent verrouiller.
  @visibleForTesting
  static GatewaySnapshotFetcher? debugSnapshotFetcherOverride;

  @visibleForTesting
  static Future<void> Function()? debugPerBotRefreshOverride;

  /// Nombre de sessions du canal temps réel CÂBLÉES par l'accueil depuis le début du
  /// processus.
  ///
  /// Sans ce témoin, rien ne prouve qu'un second appel ne recrée pas de session : une
  /// session réutilisée ne se distingue pas de l'extérieur (le canal n'est pas rouvert,
  /// aucun message n'est journalisé), et un test ne peut donc pas verrouiller
  /// l'idempotence. Le compteur s'incrémente UNIQUEMENT quand l'accueil câble réellement
  /// une session, jamais quand il constate que le canal est déjà en place.
  @visibleForTesting
  static int debugGatewaySessionsCreated = 0;

  /// Client manager imposé à [_ensureGatewayBotEvents] en test.
  ///
  /// En production le client vient de la session enregistrée, que le test ne peut pas
  /// connaître ; et le piloter par les préférences ferait partir de vraies requêtes HTTP.
  /// Le test d'idempotence doit pourtant traverser la VRAIE méthode de l'accueil, d'où ce
  /// point d'injection unique qui ne concerne que le canal temps réel.
  @visibleForTesting
  static MainApiClient? debugGatewayEventsClientOverride;

  /// Session du canal temps réel actuellement câblée (nulle si aucune).
  @visibleForTesting
  GatewayBotEventsSession? get debugGatewayEventsSession =>
      _gatewayEventsSession;

  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;

  /// Poste de travail, lu à travers le seam [isDesktopRunPlatform] (surchargeable en
  /// test) et non plus avec `Platform.*` en dur : sans ce seam, aucun scénario
  /// « desktop » n'était vérifiable, la plateforme de test ne changeant pas.
  bool get _isDesktop => isDesktopRunPlatform;

  /// Capacité de parler au manager, et RIEN de plus : la plateforme n'est plus un
  /// verrou d'ACCÈS AUX DONNÉES du compte (solde, bots du compte, conteneurs clé en
  /// main, snapshot). Ce qui décide du PILOTAGE à distance, c'est l'association par
  /// bot (`RunnerSettings.getAssociatedRunnerId(botId) == 'manager'`), résolue dans
  /// `resolveRemoteRuntime` — un bot non associé sur un poste de travail continue de
  /// tourner en local via le runner embarqué.
  // Une seule règle dans toute l'application (voir `run_platform.dart`) : le serveur
  // pilote depuis n'importe quelle plateforme, poste de travail compris.
  bool get _supportsManagerRuntime => supportsManagerRuntime;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    current = this;
    AnnouncementPresenter.absorbOverlayIntoInline();
    _fallbackPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Controllers are created from the app stream (never during build).
    _appsSub = appManager.getAppStream().listen(_handleAppsSnapshot);
    appendBotDebugLog('>>>> [BOT_DEBUG] HomePage.initState ENTERED <<<<');
    WidgetsBinding.instance.addObserver(this);
    AppAnalytics.logScreenView(screenName: 'HomePage', screenClass: 'HomePage');
    AppAnalytics.logEvent(name: 'home_page_opened');
    unawaited(() async {
      try {
        if (warmUpFuture != null) {
          await warmUpFuture;
        }
      } catch (_) {}
      // Detect running state immediately so the user sees online bots
      // right away, even if the full manager sync takes longer.
      await _initRunningState();
      await syncAllBotsFromManager(silent: true);
      // Les conteneurs clé en main ne retardent PLUS l'affichage de l'accueil : la
      // carte apparaît quand la réponse arrive, mais on ne fait pas attendre les bots
      // classiques (ni l'utilisateur) derrière un aller-retour réseau.
      unawaited(_refreshTurnkeyContainers());
      await _ensureGatewayBotEvents();
    }());

    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      // Local FREE countdown tick (no HTTP).
      if (_sessionExpiresAtByBotId.isNotEmpty) {
        setState(() {});
      }
      // Repli HTTP uniquement WebSocket coupée. Cadence : un tick = 15 s, donc le repli
      // part à CHAQUE tick (15 s) et non tous les 4 (60 s). Constat : le canal temps réel
      // ne pousse plus rien quand il est coupé, et 60 secondes d'écart entre deux
      // corrections de statut, c'est ce que l'utilisateur ressent comme « la resynchro
      // est interminable ». Le coût du repli est d'une seule requête agrégée (snapshot).
      if (!_gatewayEventsConnected) {
        _httpFallbackTick++;
        if (_httpFallbackTick >= 1) {
          _httpFallbackTick = 0;
          unawaited(_refreshFromSnapshot());
        }
      } else {
        _httpFallbackTick = 0;
      }
    });
  }

  @override
  void dispose() {
    if (current == this) current = null;
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    unawaited(_appsSub?.cancel());
    // Le canal temps réel est libéré ENTIER (WebSocket fermée), pas seulement
    // débranché : annuler les deux abonnements laisserait la socket ouverte.
    _releaseGatewayBotEvents();
    for (final ctrl in _pulseControllers.values) {
      ctrl.dispose();
    }
    _fallbackPulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MainApiClient.resetCircuitBreakers();
      // La couche granulaire est (re)tentée à chaque reprise : c'est ce qui
      // l'installe après une CONNEXION (au démarrage il n'y a encore aucune
      // session, donc aucun manager à interroger), et ce qui repose la sonde de
      // capacité quand la première a échoué. Idempotente : une fois installée,
      // elle ne reconstruit rien et ne réinterroge pas le serveur.
      unawaited(ensureGranularDataLayer());
      // Immediately refresh running state so the UI updates fast,
      // then do the full sync in background.
      unawaited(_ensureGatewayBotEvents());
      if (!_gatewayEventsConnected) {
        // WebSocket coupée : repli par le snapshot agrégé, lancé TOUT DE SUITE — attendre
        // le tick de 60 s afficherait un état périmé au retour sur l'application.
        unawaited(_refreshFromSnapshot());
      }
      syncAllBotsFromManager(silent: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(appManager.flushPendingWrites());
    }
  }

  // ── Repli HTTP : snapshot agrégé ───────────────────────────────────────────

  /// Repli de l'accueil quand la WebSocket est coupée.
  ///
  /// Une requête unique ramène le compte et tous les bots ; c'est le remplacement de
  /// `_initRunningState()` (une requête par bot) sur ce chemin. La rétro-compatibilité
  /// est assurée par [refreshHomeFromGatewaySnapshot] : si le manager ne connaît pas
  /// `/gateway/snapshot` (404), c'est `_initRunningState()` qui reprend la main.
  ///
  /// Point d'entrée unique des trois déclencheurs (tick de 60 s, reprise d'application,
  /// perte de connexion WebSocket) : le garde de réentrance et la bascule vers le repli
  /// historique sont donc partagés, et aucun déclencheur ne peut court-circuiter l'autre.
  Future<void> _refreshFromSnapshot() async {
    if (_isRefreshingFromSnapshot) return;
    _isRefreshingFromSnapshot = true;
    try {
      // Repli historique, exécuté si le snapshot est indisponible : en test il est
      // remplaçable pour être COMPTÉ (c'est lui qui faisait N requêtes par bot).
      final perBotFallback = debugPerBotRefreshOverride ?? _initRunningState;
      GatewaySnapshotFetcher fetchSnapshot;
      final fetcherOverride = debugSnapshotFetcherOverride;
      if (fetcherOverride != null) {
        fetchSnapshot = fetcherOverride;
      } else {
        final remoteClient = await _resolveGlobalMainApiClient();
        if (remoteClient == null) {
          // Sans client manager, seul le repli local sait calculer l'état des bots.
          await perBotFallback();
          return;
        }
        fetchSnapshot = remoteClient.getGatewaySnapshotWithEtag;
      }
      final outcome = await refreshHomeFromGatewaySnapshot(
        fetchSnapshot: fetchSnapshot,
        etag: _snapshotEtag,
        applySnapshot: _applySnapshot,
        fallbackToPerBotRefresh: perBotFallback,
      );
      appendBotDebugLog(
        '[home] Repli snapshot: ${outcome.name} '
        '(etag=${_snapshotEtag ?? 'none'}).',
      );
    } finally {
      _isRefreshingFromSnapshot = false;
    }
  }

  /// Applique le snapshot agrégé avec exactement les mêmes fonctions que le canal temps
  /// réel — `_applyPushedAccount` pour le compte, `_applyGatewayBotSnapshot` pour les
  /// bots — pour que l'état interrogé et l'état poussé ne puissent pas diverger.
  Future<void> _applySnapshot(HomeSnapshotData snapshot) async {
    _snapshotEtag = snapshot.etag ?? _snapshotEtag;
    final account = snapshot.account;
    if (account != null) {
      await _applyPushedAccount(account);
    }
    _applyGatewayBotSnapshot(snapshot.bots);
    // `_applyGatewayBotSnapshot` marque la connexion comme active (c'est exact pour le
    // canal temps réel). Ici on vient justement du repli : la WebSocket est toujours
    // coupée, et si ce drapeau restait à vrai, le repli ne se relancerait jamais.
    _gatewayEventsConnected = false;
  }

  // ── Initialisation de l'état running ───────────────────────────────────────

  /// Guards against concurrent [_initRunningState] calls.
  bool _isRefreshingRunningState = false;

  // ── Partage : ce qui m'appartient, ce qu'on m'a partagé ────────────────────

  /// Charge l'ensemble des bots PARTAGÉS et, pour eux seuls, mes droits.
  ///
  /// Dégradation SILENCIEUSE : hors ligne, sans session manager, ou face à un
  /// serveur plus ancien qui n'annonce pas `is_collaborative`, l'ensemble
  /// redevient vide et l'accueil montre tout dans « My bots ». Jamais d'écran
  /// d'erreur, jamais de fausse section « partagé ».
  Future<void> _loadSharedBots() async {
    if (_isLoadingSharedBots) return;
    _isLoadingSharedBots = true;
    try {
      final client = await _resolveGlobalMainApiClient();
      if (client == null) return;
      final owners = await client.fetchCollaborativeBotOwners();
      if (!mounted) return;
      setState(() {
        _collaborativeBotIds = owners.keys.toSet();
        _sharedBotOwnerIds = owners;
      });
      // Les droits ne concernent QUE les bots partagés : une requête par bot
      // partagé, aucune pour les miens (le propriétaire a tous les droits).
      await _loadSharedBotPermissions(
        client,
        owners.keys.toList(growable: false),
      );
    } catch (error) {
      appendBotDebugLog(
        '[_loadSharedBots] Sharing unavailable, keeping everything in My bots: $error',
      );
      if (mounted) {
        setState(() {
          _collaborativeBotIds = <String>{};
          _sharedBotOwnerIds = <String, String>{};
          _sharedBotPermissions = <String, BotPermissions>{};
        });
      }
    } finally {
      _isLoadingSharedBots = false;
    }
  }

  /// Mes droits sur chaque bot partagé (`my_permissions`).
  ///
  /// Un bot dont les droits restent illisibles (serveur plus ancien, erreur
  /// réseau) n'obtient AUCUNE entrée : la carte retombe alors sur le refus au
  /// lieu d'offrir une action que le propriétaire n'a peut-être pas accordée.
  Future<void> _loadSharedBotPermissions(
    MainApiClient client,
    List<String> botIds,
  ) async {
    if (botIds.isEmpty) return;
    final permissions = <String, BotPermissions>{};
    for (final botId in botIds) {
      try {
        final raw = await client.fetchMyTeamPermissions(botId);
        if (raw == null) continue;
        permissions[botId] = BotPermissions.fromJson(raw);
      } catch (error) {
        appendBotDebugLog(
          '[_loadSharedBotPermissions] Rights unavailable for $botId: $error',
        );
      }
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() => _sharedBotPermissions = permissions);
  }

  Future<void> _initRunningState() async {
    if (_isRefreshingRunningState) return;
    _isRefreshingRunningState = true;
    try {
      final runningIds = <String>{};
      _runtimeSourceByBotId.clear();
      _runtimeDetailLabelByBotId.clear();
      appendBotDebugLog('[_initRunningState] Starting running-state refresh.');
      final remoteClient = await _resolveGlobalMainApiClient();
      final remoteRuntime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 25),
      );
      appendBotDebugLog(
        '[_initRunningState] Resolved runtime: source=${remoteRuntime.source}, hasClient=${remoteRuntime.client != null}, blocksLocalFallback=${remoteRuntime.blocksLocalFallback}, detail=${remoteRuntime.detailLabel ?? 'none'}.',
      );
      final apps = await appManager.getAllApps();
      final localBotIds = apps
          .whereType<Map>()
          .map((raw) => (raw['id'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      appendBotDebugLog(
        '[_initRunningState] Local bot ids loaded: count=${localBotIds.length}, ids=${localBotIds.join(',')}.',
      );

      unawaited(
        SubscriptionService.resolveEffectivePremiumStatus(
          client: remoteClient,
          forceRefresh: true,
        ),
      );

      final hasActiveRemote =
          remoteClient != null || remoteRuntime.client != null;
      if (hasActiveRemote || localBotIds.isNotEmpty) {
        appendBotDebugLog(
          '[_initRunningState] Performing running-state detection (remoteClient=${remoteClient?.runtimeType}, remoteRuntime=${remoteRuntime.client?.runtimeType}, localBotIds=${localBotIds.length}).',
        );
        try {
          if (localBotIds.isEmpty) {
            appendBotDebugLog(
              '[_initRunningState] No local bot ids found. Falling back to global status list.',
            );
            final statusClient = remoteClient ?? remoteRuntime.client;
            if (statusClient != null) {
              final status = await statusClient.getStatus();
              appendBotDebugLog(
                '[_initRunningState] Global status fetched: bots=${status.bots.length}, running=${status.running}.',
              );
              for (final bot in status.bots) {
                if (bot.isRunning) {
                  runningIds.add(bot.botId);
                  appendBotDebugLog(
                    '[_initRunningState] Marked running (global): ${bot.botId}.',
                  );
                }
              }
            }
          } else {
            appendBotDebugLog(
              '[_initRunningState] Checking per-bot status with owner-aware client resolution.',
            );
            final runningChecks = localBotIds
                .where((botId) => !_skippedMissingBotIds.contains(botId))
                .map((botId) async {
                  try {
                    appendBotDebugLog(
                      '[_initRunningState] Resolving client for bot $botId.',
                    );

                    // Check local in-app running state first!
                    final isInternalRunning = _supportsForegroundTask
                        ? isMobileBotRunning(botId)
                        : desktopRunningBotIds.contains(botId);
                    if (isInternalRunning) {
                      appendBotDebugLog(
                        '[_initRunningState] Bot $botId is running internally in-app.',
                      );
                      if (mounted) {
                        setState(() {
                          _runtimeSourceByBotId[botId] =
                              RemoteRuntimeSource.local;
                          _runtimeDetailLabelByBotId[botId] = null;
                        });
                      }
                      return botId;
                    }

                    final perBotClient = await _resolveMainApiClientForBot(
                      botId: botId,
                      attemptSessionRestore: false,
                    );
                    final botRuntime = remoteRuntime;

                    final associatedId = RunnerSettings.getAssociatedRunnerId(
                      botId,
                    );
                    final isManagerBot =
                        associatedId == 'manager' ||
                        (associatedId == null && perBotClient != null);

                    final source = isManagerBot
                        ? RemoteRuntimeSource.manager
                        : botRuntime.source;
                    final detailLabel = isManagerBot
                        ? (remoteRuntime.detailLabel ?? 'Bot Creator servers')
                        : botRuntime.detailLabel;

                    if (mounted) {
                      setState(() {
                        _runtimeSourceByBotId[botId] = source;
                        _runtimeDetailLabelByBotId[botId] = detailLabel;
                      });
                    }
                    final statusClient = isManagerBot
                        ? (perBotClient ?? remoteClient)
                        : (botRuntime.client ?? perBotClient ?? remoteClient);
                    appendBotDebugLog(
                      '[_initRunningState] Bot $botId status client: ${statusClient.runtimeType}, resolvedSource=$source, usedFallbackToGlobal=${!isManagerBot && botRuntime.client == null}.',
                    );
                    if (statusClient == null) {
                      return null;
                    }
                    final status = await statusClient.getStatus(botId: botId);
                    final isRunning = status.isBotRunning(botId);
                    _noteBotFound(botId);
                    appendBotDebugLog(
                      '[_initRunningState] Bot $botId status fetched: statusRunning=${status.running}, activeBotId=${status.activeBotId ?? 'none'}, botEntries=${status.bots.length}, isBotRunning=$isRunning.',
                    );
                    return isRunning ? botId : null;
                  } catch (error) {
                    if (error is MainApiClientException &&
                        error.statusCode == 404) {
                      _noteBotNotFound(botId);
                      appendBotDebugLog(
                        '[_initRunningState] Bot $botId missing on manager (404 streak=${_botNotFoundStreak[botId]}).',
                      );
                    } else {
                      appendBotDebugLog(
                        'Failed to sync running status for $botId: $error',
                      );
                    }
                    return null;
                  }
                })
                .toList(growable: false);

            final resolvedRunningIds = await Future.wait(runningChecks);
            for (final botId in resolvedRunningIds.whereType<String>()) {
              runningIds.add(botId);
              appendBotDebugLog(
                '[_initRunningState] Marked running (per-bot): $botId.',
              );
            }
          }
        } catch (_) {}

        appendBotDebugLog(
          '[_initRunningState] Remote detection completed. Running ids=${runningIds.join(',')}.',
        );

        if (!mounted) return;
        setState(() {
          _runningBotIds = runningIds;
          _runtimeSource = remoteRuntime.source;
          _runtimeDetailLabel = remoteRuntime.detailLabel;
        });
        _syncPulse(runningIds);
        await _syncDiscordRpcPresence(runningIds);
        unawaited(_refreshBotRuntimeBalances());
        return;
      }

      if (remoteRuntime.blocksLocalFallback) {
        appendBotDebugLog(
          '[_initRunningState] No remote client and local fallback is blocked. Running set remains empty.',
        );
        if (!mounted) return;
        setState(() {
          _runningBotIds = runningIds;
          _runtimeSource = remoteRuntime.source;
          _runtimeDetailLabel = remoteRuntime.detailLabel;
        });
        _syncPulse(runningIds);
        await _syncDiscordRpcPresence(runningIds);
        unawaited(_refreshBotRuntimeBalances());
        return;
      }

      if (_supportsForegroundTask) {
        try {
          appendBotDebugLog(
            '[_initRunningState] Falling back to foreground task running-state detection.',
          );
          final running = await FlutterForegroundTask.isRunningService;
          appendBotDebugLog(
            '[_initRunningState] Foreground service running=$running.',
          );
          if (running) {
            final configuredIds = await getConfiguredMobileBotIds();
            appendBotDebugLog(
              '[_initRunningState] Configured mobile bot ids: count=${configuredIds.length}, ids=${configuredIds.join(',')}.',
            );
            if (configuredIds.isNotEmpty) {
              runningIds.addAll(configuredIds);
              for (final botId in configuredIds) {
                addMobileRunningBotId(botId);
              }
            } else {
              final fallbackId =
                  mobileRunningBotId ??
                  await FlutterForegroundTask.getData<String>(
                    key: 'running_bot_id',
                  );
              if (fallbackId != null && fallbackId.isNotEmpty) {
                runningIds.add(fallbackId);
                addMobileRunningBotId(fallbackId);
                appendBotDebugLog(
                  '[_initRunningState] Added fallback running bot id from foreground task data: $fallbackId.',
                );
              }
            }
          }
        } on MissingPluginException {
          // Plateforme non supportée.
          appendBotDebugLog(
            '[_initRunningState] Foreground plugin unavailable on this platform.',
          );
        }
      } else if (_isDesktop) {
        // Repli local : seuls les bots lancés par le runner EMBARQUÉ du poste de
        // travail (registre `desktopRunningBotIds`) sont réputés actifs. Ailleurs ce
        // registre est vide — d'où le test de plateforme plutôt qu'un `else` fourre-tout.
        runningIds.addAll(desktopRunningBotIds);
        appendBotDebugLog(
          '[_initRunningState] Using desktop running ids fallback: ${desktopRunningBotIds.join(',')}.',
        );
      }
      if (!mounted) return;
      setState(() {
        _runningBotIds = runningIds;
        _runtimeSource = RemoteRuntimeSource.local;
        _runtimeDetailLabel = null;
      });

      for (final botId in desktopRunningBotIds) {
        final guildCount = desktopGatewayForBot(botId)?.guilds.cache.length;
        if (guildCount != null) {
          appManager.updateGuildCount(botId, guildCount);
        }
      }
      _syncPulse(runningIds);
      await _syncDiscordRpcPresence(runningIds);
      unawaited(_refreshBotRuntimeBalances());
      appendBotDebugLog(
        '[_initRunningState] Completed with local fallback. Running ids=${runningIds.join(',')}.',
      );
    } finally {
      _isRefreshingRunningState = false;
    }
  }

  // ── Conteneurs clé en main (« turnkey ») ───────────────────────────────────

  /// Charge les conteneurs clé en main du compte et les expose à la liste
  /// d'accueil, à côté des bots classiques.
  ///
  /// Réutilise le client global déjà résolu pour les bots ([_resolveGlobalMainApiClient])
  /// et l'endpoint existant `listContainers()` : aucune seconde instance de
  /// client, aucune requête dupliquée (garde de réentrance).
  Future<void> _refreshTurnkeyContainers() async {
    if (_isRefreshingTurnkeyContainers) return;
    _isRefreshingTurnkeyContainers = true;
    try {
      final client = await _resolveGlobalMainApiClient();
      if (client == null) return;
      final containers = await client.listContainers();
      if (!mounted) return;
      setState(() => _turnkeyContainers = containers);
    } catch (error) {
      // Un conteneur illisible ne doit jamais casser l'accueil : les bots
      // classiques restent affichés.
      appendBotDebugLog(
        '[_refreshTurnkeyContainers] Failed to load turnkey containers: $error',
      );
    } finally {
      _isRefreshingTurnkeyContainers = false;
    }
  }

  /// Arrête ou démarre un conteneur clé en main depuis sa carte d'accueil,
  /// puis recharge la liste pour refléter le nouvel état.
  Future<void> _toggleTurnkeyContainer(
    ContainerInfo container, {
    required bool start,
  }) async {
    if (_containerIdInAction != null) return;
    setState(() => _containerIdInAction = container.id);
    try {
      final client = await _resolveGlobalMainApiClient();
      if (client == null) return;
      if (start) {
        await client.startContainer(container.id);
      } else {
        await client.stopContainer(container.id);
      }
      await _refreshTurnkeyContainers();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.container_detail_failed('$error'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _containerIdInAction = null);
      } else {
        _containerIdInAction = null;
      }
    }
  }

  /// Invite le bot d'un conteneur clé en main dans un serveur Discord, depuis sa
  /// carte d'accueil.
  ///
  /// Le parcours lui-même (identité connue → lien direct, sinon résolution par
  /// le manager) vit dans [TurnkeyBotInviteService] ; ici on ne fait que verrouiller
  /// la carte pendant l'appel et rendre le message d'échec — jamais de crash,
  /// jamais de message vide devant un bouton qui ne réagit pas.
  Future<void> _inviteTurnkeyBot(ContainerInfo container) async {
    if (_inviteContainerIdInAction != null) return;
    setState(() => _inviteContainerIdInAction = container.id);
    try {
      final service = _turnkeyInviteService ??= TurnkeyBotInviteService(
        client: await _resolveGlobalMainApiClient(),
      );
      final outcome = await service.invite(container);
      if (!mounted) return;
      _showInviteOutcomeMessage(outcome);
    } catch (error) {
      // Le service attrape déjà ses propres pannes : ici, seul un imprévu
      // (résolution du client) peut arriver, et il mérite quand même un texte.
      appendBotDebugLog('[_inviteTurnkeyBot] Unexpected failure: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.container_invite_failed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _inviteContainerIdInAction = null);
      } else {
        _inviteContainerIdInAction = null;
      }
    }
  }

  /// Affiche le message de [outcome], en ignorant les issues qui n'ont rien à
  /// dire (lien ouvert, tap ignoré pendant une invitation en cours).
  void _showInviteOutcomeMessage(BotInviteOutcome outcome) {
    final message = botInviteOutcomeMessage(outcome, context.tr);
    if (message.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ouvre la console de logs d'un conteneur clé en main depuis l'accueil.
  Future<void> _openTurnkeyContainerLogs(ContainerInfo container) async {
    final client = await _resolveGlobalMainApiClient();
    if (!mounted || client == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeContainerLogsPage(
          client: client,
          containerId: container.id,
          title: turnkeyContainerTitle(container, context.tr),
        ),
      ),
    );
  }

  /// Ouvre le parcours existant d'ajout de temps (recharge du TTL) : la page de
  /// détail du conteneur porte la recharge par solde/publicité, on ne la
  /// duplique pas sur l'accueil.
  Future<void> _openTurnkeyContainerDetail(ContainerInfo container) async {
    final client = await _resolveGlobalMainApiClient();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ContainerDetailPage(containerId: container.id, client: client),
      ),
    );
    await _refreshTurnkeyContainers();
  }

  int _extractFreeMinutes(dynamic raw) {
    if (raw == null) {
      return 0;
    }
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw.toString()) ?? 0;
  }

  DateTime? _extractSessionExpiresAt(Map<String, dynamic> runtime) {
    final raw = runtime['session_expires_at'] ?? runtime['sessionExpiresAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  String _fundingModeOf(Map<String, dynamic> runtime) {
    return (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  int _remainingMinutesUntil(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    if (!expiresAt.isAfter(now)) return 0;
    final delta = expiresAt.difference(now);
    var minutes = delta.inMinutes;
    if (delta.inSeconds % 60 != 0) minutes++;
    return minutes < 0 ? 0 : minutes;
  }

  /// Minutes d'hébergement à AFFICHER pour ce bot.
  ///
  /// Le décompte n'a de sens que pendant que le bot consomme : un horodatage d'expiration
  /// est figé au moment où le serveur a ouvert la session, donc bot éteint il ne s'écoule
  /// plus rien — l'afficher comme un compte à rebours faisait croire que le temps partait
  /// tout seul, et le chiffre baissait à chaque redessin de l'écran.
  ///
  /// En marche : on décompte jusqu'à l'échéance de session. À l'arrêt : on rend le SOLDE
  /// du serveur, tel quel — c'est lui la vérité quand rien ne tourne.
  int _displayFreeMinutesForBot(String botId) {
    final expires = _sessionExpiresAtByBotId[botId];
    final isRunning = _runningBotIds.contains(botId);
    if (expires == null) {
      return _freeMinutesByBotId[botId] ?? 0;
    }
    if (isRunning) {
      return _remainingMinutesUntil(expires);
    }
    // À l'arrêt, le solde du serveur prime : il vaut mieux ne rien dire qu'annoncer une
    // expiration qui n'avance pas.
    return _freeMinutesByBotId[botId] ?? _remainingMinutesUntil(expires);
  }

  void _noteBotNotFound(String botId) {
    final next = (_botNotFoundStreak[botId] ?? 0) + 1;
    _botNotFoundStreak[botId] = next;
    if (next >= _missingBot404Threshold) {
      _skippedMissingBotIds.add(botId);
      _sessionExpiresAtByBotId.remove(botId);
      _freeMinutesByBotId.remove(botId);
    }
  }

  void _noteBotFound(String botId) {
    _botNotFoundStreak.remove(botId);
    _skippedMissingBotIds.remove(botId);
  }

  /// Câble — UNE SEULE FOIS par serveur — la session du canal temps réel.
  ///
  /// Idempotente : un appel pour un serveur dont la session est déjà vivante ne crée rien
  /// et n'annule RIEN. Le défaut corrigé ici se lit dans les journaux d'un utilisateur
  /// sous la forme d'une alternance sans fin (« canal temps réel rétabli » puis
  /// « indisponible ») : chaque appel remplaçait la session et annulait les abonnements de
  /// la précédente, donc le canal en place — celui qui porte l'état des bots et du compte
  /// — était détruit à chaque reprise d'application. L'indicateur de connexion retombait
  /// à « Hors ligne » et plus aucune donnée serveur n'arrivait, alors que le serveur
  /// exécutait bien les bots.
  ///
  /// Un changement de serveur (ou de compte) change la clé : l'ancienne session est alors
  /// réellement libérée — WebSocket fermée — avant d'en câbler une neuve.
  Future<void> _ensureGatewayBotEvents() async {
    final MainApiClient? remoteClient;
    final override = debugGatewayEventsClientOverride;
    if (override != null) {
      remoteClient = override;
    } else {
      final remoteRuntime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 10),
        postTimeout: const Duration(seconds: 20),
      );
      final client = remoteRuntime.client;
      remoteClient = client is MainApiClient ? client : null;
    }
    if (remoteClient == null) {
      return;
    }
    final clientKey = remoteClient.baseUrl;
    // Canal DÉJÀ en place pour ce même serveur : retour immédiat, sans toucher aux
    // abonnements vivants. C'est ici — et nulle part ailleurs — que se décide la
    // réutilisation plutôt que la reconstruction.
    if (_gatewayEventsSession != null && _gatewayEventsClientKey == clientKey) {
      return;
    }
    _releaseGatewayBotEvents();
    final session = remoteClient.connectGatewayBotEvents();
    debugGatewaySessionsCreated++;
    _gatewayEventsSession = session;
    _gatewayEventsClientKey = clientKey;
    _gatewayEventsSub = session.events.listen(_onGatewayBotEvent);
    _gatewayConnectionSub = session.connectionChanges.listen(
      handleGatewayConnectionChange,
    );
    if (session.isConnected && mounted) {
      setState(() => _gatewayEventsConnected = true);
    }
  }

  /// Libère la session du canal temps réel : abonnements annulés PUIS session détruite
  /// (`GatewayBotEventsSession.dispose` ferme la WebSocket et ses flux).
  ///
  /// Ces libérations ne sont JAMAIS attendues : une annulation d'abonnement ne rend pas la
  /// main avant la fermeture du flux, et `dispose()` attend ces mêmes annulations — même
  /// constat que `GatewayBotEventsSession._connect`, qui rend la main tout de suite pour
  /// ne pas geler sa reconnexion. Ici, attendre figerait le CÂBLAGE : le canal neuf du
  /// nouveau serveur ne serait jamais ouvert. L'effet utile est immédiat — le
  /// désabonnement est effectif sur-le-champ, la session marquée détruite (donc plus
  /// aucune reconnexion) et sa WebSocket fermée dès que le flux rend la main.
  void _releaseGatewayBotEvents() {
    final session = _gatewayEventsSession;
    _gatewayEventsSession = null;
    _gatewayEventsClientKey = null;
    final eventsSub = _gatewayEventsSub;
    final connectionSub = _gatewayConnectionSub;
    _gatewayEventsSub = null;
    _gatewayConnectionSub = null;
    unawaited(eventsSub?.cancel());
    unawaited(connectionSub?.cancel());
    if (session != null) {
      unawaited(session.dispose());
    }
  }

  /// Changement d'état du canal temps réel (WebSocket).
  ///
  /// Extrait du listener pour être appelable en test : c'est le déclencheur « perte de
  /// connexion » du repli, l'autre étant la reprise d'application.
  @visibleForTesting
  void handleGatewayConnectionChange(bool connected) {
    if (!mounted) return;
    setState(() => _gatewayEventsConnected = connected);
    if (connected) {
      _httpFallbackTick = 0;
    } else {
      // Connexion perdue : repli immédiat par le snapshot agrégé (une requête au lieu
      // d'une par bot). Attendre le tick de 60 s laisserait l'accueil figé sur l'état
      // d'avant la coupure.
      unawaited(_refreshFromSnapshot());
    }
  }

  void _onGatewayBotEvent(GatewayBotEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case GatewayBotEventType.snapshot:
        // L'instantané porte aussi l'état du compte : plus besoin d'appeler
        // `/gateway/runtime` à l'ouverture.
        final snapshotAccount = event.account;
        if (snapshotAccount != null) {
          unawaited(_applyPushedAccount(snapshotAccount));
        }
        _applyGatewayBotSnapshot(event.bots);
        break;
      case GatewayBotEventType.botUpdated:
        final bot = event.bot;
        if (bot != null) {
          _applyGatewayBotUpdate(bot);
        }
        break;
      case GatewayBotEventType.botDeleted:
        final botId = event.bot?.botId.trim() ?? '';
        if (botId.isNotEmpty) {
          _applyGatewayBotDeleted(botId);
        }
        break;
      case GatewayBotEventType.accountUpdated:
        final account = event.account;
        if (account != null) {
          unawaited(_applyPushedAccount(account));
        }
        break;
      case GatewayBotEventType.containerUpdated:
      case GatewayBotEventType.ping:
      case GatewayBotEventType.unknown:
        break;
      // Consommé par l'onglet « Équipe et tchat », qui s'abonne lui-même au canal
      // pendant qu'il est monté : l'accueil n'a rien à en faire, mais
      // l'énumération exhaustive doit être à jour.
      case GatewayBotEventType.teamChatMessage:
      case GatewayBotEventType.teamMembersUpdated:
        break;
    }
  }

  /// Applique la formule poussée par le canal temps réel : le serveur est l'autorité
  /// et vient de donner l'état exact, donc aucune requête HTTP n'est nécessaire
  /// (miroir de ce que faisait le rafraîchissement périodique de `/gateway/runtime`).
  Future<void> _applyPushedAccount(GatewayAccountEventPayload account) async {
    await SubscriptionService.applyPushedAccountState(account.toRuntimeMap());
    if (!mounted) return;
    setState(() {});
  }

  void _applyGatewayBotSnapshot(List<GatewayBotEventPayload> bots) {
    final running = <String>{};
    final freeMinutes = <String, int>{};
    final expires = <String, DateTime>{};
    for (final bot in bots) {
      final botId = bot.botId.trim();
      if (botId.isEmpty) continue;
      _noteBotFound(botId);
      if (bot.isRunning) {
        running.add(botId);
        // Le serveur dit ce bot en cours d'exécution : c'est donc lui qu'il faut
        // arrêter (voir `noteManagerReportedRuntime`).
        noteManagerReportedRuntime(bot);
      }
      if (bot.fundingMode == 'premium') {
        continue;
      }
      if (bot.sessionExpiresAt != null && bot.fundingMode == 'free') {
        expires[botId] = bot.sessionExpiresAt!;
        freeMinutes[botId] = _remainingMinutesUntil(bot.sessionExpiresAt!);
      } else {
        freeMinutes[botId] = bot.freeMinutesBalance;
      }
    }
    setState(() {
      _runningBotIds = running;
      _freeMinutesByBotId = freeMinutes;
      _sessionExpiresAtByBotId
        ..clear()
        ..addAll(expires);
      _gatewayEventsConnected = true;
    });
    _syncPulse(running);
    unawaited(_syncDiscordRpcPresence(running));
  }

  void _applyGatewayBotUpdate(GatewayBotEventPayload bot) {
    final botId = bot.botId.trim();
    if (botId.isEmpty) return;
    _noteBotFound(botId);
    // Un bot que le SERVEUR exécute s'arrête sur le serveur, d'où qu'il ait été
    // démarré (mobile, manager) — voir `noteManagerReportedRuntime`. Posé AVANT le
    // `setState` : écrire une préférence n'est pas un changement d'état de l'écran.
    noteManagerReportedRuntime(bot);
    setState(() {
      if (bot.isRunning) {
        _runningBotIds = {..._runningBotIds, botId};
      } else {
        _runningBotIds = {..._runningBotIds}..remove(botId);
      }
      if (bot.fundingMode == 'premium') {
        _freeMinutesByBotId.remove(botId);
        _sessionExpiresAtByBotId.remove(botId);
      } else if (bot.sessionExpiresAt != null && bot.fundingMode == 'free') {
        _sessionExpiresAtByBotId[botId] = bot.sessionExpiresAt!;
        _freeMinutesByBotId[botId] = _remainingMinutesUntil(
          bot.sessionExpiresAt!,
        );
      } else {
        _sessionExpiresAtByBotId.remove(botId);
        _freeMinutesByBotId[botId] = bot.freeMinutesBalance;
      }
    });
    _syncPulse(_runningBotIds);
    unawaited(_syncDiscordRpcPresence(_runningBotIds));
  }

  void _applyGatewayBotDeleted(String botId) {
    setState(() {
      _runningBotIds = {..._runningBotIds}..remove(botId);
      _freeMinutesByBotId.remove(botId);
      _sessionExpiresAtByBotId.remove(botId);
      _skippedMissingBotIds.add(botId);
      _botNotFoundStreak.remove(botId);
    });
    _syncPulse(_runningBotIds);
    unawaited(_syncDiscordRpcPresence(_runningBotIds));
  }

  bool _hasFreeRuntimeAvailable(Map<String, dynamic> runtime, int balance) {
    final fundingMode =
        (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final sessionActiveRaw =
        runtime['session_active'] ?? runtime['sessionActive'];
    final sessionActive =
        sessionActiveRaw == true ||
        sessionActiveRaw?.toString().toLowerCase() == 'true';
    return balance > 0 || fundingMode == 'free' || sessionActive;
  }

  Future<void> _refreshBotRuntimeBalances({Iterable<String>? botIds}) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      if (mounted && _freeMinutesByBotId.isNotEmpty) {
        setState(() {
          _freeMinutesByBotId = <String, int>{};
          _sessionExpiresAtByBotId.clear();
        });
      }
      return;
    }

    final ids = <String>{...?(botIds?.where((id) => id.trim().isNotEmpty))};
    if (ids.isEmpty) {
      final names = await _loadBotNamesById();
      ids.addAll(names.keys.where((id) => id.trim().isNotEmpty));
    }
    ids.removeWhere(_skippedMissingBotIds.contains);
    if (ids.isEmpty) {
      return;
    }

    final updated = <String, int>{..._freeMinutesByBotId};
    final updatedExpires = <String, DateTime>{..._sessionExpiresAtByBotId};
    for (final botId in ids) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        _noteBotFound(botId);
        final funding = _fundingModeOf(runtime);
        if (funding == 'premium') {
          updated.remove(botId);
          updatedExpires.remove(botId);
          continue;
        }
        final expires = _extractSessionExpiresAt(runtime);
        if (expires != null && funding == 'free') {
          updatedExpires[botId] = expires;
          updated[botId] = _remainingMinutesUntil(expires);
        } else {
          updatedExpires.remove(botId);
          updated[botId] = _extractFreeMinutes(
            runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
          );
        }
      } catch (error) {
        if (error is MainApiClientException && error.statusCode == 404) {
          _noteBotNotFound(botId);
          updated.remove(botId);
          updatedExpires.remove(botId);
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _freeMinutesByBotId = updated;
      _sessionExpiresAtByBotId
        ..clear()
        ..addAll(updatedExpires);
    });
  }

  Future<MainApiClient?> _resolveManagerClientForSync() async {
    final remoteClient = await _resolveGlobalMainApiClient();
    if (remoteClient != null) {
      return remoteClient;
    }

    final apps = await appManager.getAllApps();
    appendBotDebugLog(
      '[_resolveManagerClientForSync] Global manager client unavailable. Trying local bot tokens from ${apps.length} apps.',
    );
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp.cast<dynamic, dynamic>());
      final botId = (app['id'] ?? '').toString().trim();
      final token = (app['token'] ?? '').toString().trim();
      if (botId.isEmpty || token.isEmpty) {
        continue;
      }

      appendBotDebugLog(
        '[_resolveManagerClientForSync] Attempting manager session restore from bot $botId.',
      );
      final client = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: token,
        attemptSessionRestore: true,
      );
      if (client != null) {
        appendBotDebugLog(
          '[_resolveManagerClientForSync] Restored manager client from bot $botId.',
        );
        return client;
      }
    }

    appendBotDebugLog(
      '[_resolveManagerClientForSync] Unable to restore a manager client from local bot tokens.',
    );
    return null;
  }

  Future<void> syncAllBotsFromManager({bool silent = false}) async {
    appendBotDebugLog(
      '[syncAllBotsFromManager] Starting sync. silent=$silent.',
    );
    final remoteClient = await _resolveManagerClientForSync();
    if (remoteClient == null) {
      appendBotDebugLog(
        '[syncAllBotsFromManager] Global manager client unavailable. Starting direct Discord API sync for local bots.',
      );
      try {
        final apps = await appManager.getAllApps();
        final syncTasks = apps.map((rawApp) async {
          if (rawApp is! Map) {
            return;
          }
          final app = Map<String, dynamic>.from(
            rawApp.cast<dynamic, dynamic>(),
          );
          final botId = (app['id'] ?? '').toString().trim();
          final token = (app['token'] ?? '').toString().trim();
          if (botId.isEmpty || token.isEmpty) {
            return;
          }

          try {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Syncing local bot $botId directly from Discord.',
            );
            final discordUser = await getDiscordUser(token);
            final botName = discordUser.username.sanitizedUtf16;
            final avatarHash = discordUser.avatarHash;
            final discriminator = discordUser.discriminator.toString();

            int? fetchedApproxGuildCount;
            try {
              final guildCount = await getDiscordBotGuildCount(token);
              if (guildCount != null) {
                fetchedApproxGuildCount = guildCount;
              } else {
                final ownerMetadata = await getDiscordApplicationOwnerMetadata(
                  token,
                );
                if (ownerMetadata != null) {
                  final approx =
                      ownerMetadata.rawJson['approximate_guild_count'];
                  if (approx is int) {
                    fetchedApproxGuildCount = approx;
                  } else if (approx != null) {
                    fetchedApproxGuildCount = int.tryParse(approx.toString());
                  }
                }
              }
            } catch (error) {
              appendBotDebugLog(
                '[syncAllBotsFromManager] Failed to fetch Discord guild count for local bot $botId: $error',
              );
            }

            await appManager.createOrUpdateApp(
              id: Snowflake.parse(botId),
              username: botName,
              avatarHash: avatarHash,
              discriminator: discriminator,
              token: token,
              intents: (app['intents'] as Map?)?.cast<String, bool>(),
              prefix: app['prefix']?.toString(),
              approximateGuildCount: fetchedApproxGuildCount,
            );
            appendBotDebugLog(
              '[syncAllBotsFromManager] Local bot $botId metadata updated successfully.',
            );
          } catch (e) {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Failed to sync local bot $botId directly: $e',
            );
          }
        });
        await Future.wait(syncTasks);
      } catch (e) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Failed to fetch local apps for direct sync: $e',
        );
      }

      if (mounted) {
        await _initRunningState();
        // Aucun client manager : le partage ne peut pas être rafraîchi, mais
        // l'appel reste tenté (il retombe silencieusement sur « tout à moi »).
        await _loadSharedBots();
      }
      return;
    }

    try {
      final botsById = <String, Map<String, dynamic>>{};

      void mergeBots(List<Map<String, dynamic>> bots) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Merging bot payload batch size=${bots.length}.',
        );
        for (final bot in bots) {
          final botId = (bot['bot_id'] ?? '').toString().trim();
          if (botId.isEmpty) {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Skipping bot payload with empty bot_id.',
            );
            continue;
          }
          botsById[botId] = bot;
        }
      }

      mergeBots(await remoteClient.listBots());
      final apps = await appManager.getAllApps();
      appendBotDebugLog(
        '[syncAllBotsFromManager] Local apps for owner expansion count=${apps.length}.',
      );
      // ── Phase 1: collect owner list clients (global session or one fallback) ──
      final ownerClients = <String, MainApiClient>{};
      final globalClient = await _resolveGlobalMainApiClient(
        attemptRestore: false,
      );
      if (globalClient != null) {
        ownerClients['global'] = globalClient;
      } else {
        final apps = await appManager.getAllApps();
        for (final rawApp in apps) {
          if (rawApp is! Map) continue;
          final botId = (rawApp['id'] ?? '').toString().trim();
          final token = (rawApp['token'] ?? '').toString().trim();
          if (token.isEmpty) continue;
          final ephemeral = await _ownerSyncHelper
              .exchangeEphemeralBotTokenClient(token);
          if (ephemeral != null) {
            ownerClients['bot:$botId'] = ephemeral;
            break;
          }
        }
      }

      // ── Phase 2: fetch listBots in parallel ──
      if (ownerClients.isNotEmpty) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Fetching listBots for ${ownerClients.length} unique owners in parallel.',
        );
        final listBotsTasks = ownerClients.entries
            .map((entry) async {
              final dedupeKey = entry.key;
              final client = entry.value;
              try {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Fetching listBots for dedupeKey=$dedupeKey.',
                );
                mergeBots(await client.listBots());
              } catch (error) {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] listBots failed for dedupeKey=$dedupeKey: $error',
                );
              }
            })
            .toList(growable: false);
        await Future.wait(listBotsTasks);
      }

      final bots = botsById.values.toList(growable: false);
      appendBotDebugLog(
        '[syncAllBotsFromManager] Total merged bot payloads=${bots.length}.',
      );

      // ── Reprise automatique du jeton des bots de ce poste ──────────────────
      // Un poste qui n'a jamais saisi le jeton d'un bot du compte ne peut pas
      // l'exécuter localement, et un rafraîchissement n'y change rien : le
      // manager RÉDIGE `bot_token` dans ses listes, donc la synchro n'apporte
      // jamais le jeton. On le redemande au compte, une fois par bot et par
      // lancement d'application (voir `recoverMissingBotTokens` : aucune rafale,
      // aucun nouvel essai après un 409/500, rien hors ligne).
      // Placé AVANT la phase 3 pour que le jeton repris serve aussitôt au profil
      // Discord et au comptage de serveurs du même passage.
      try {
        final localTokensById = <String, String>{};
        for (final rawApp in apps) {
          if (rawApp is! Map) continue;
          final localBotId = (rawApp['id'] ?? '').toString().trim();
          if (localBotId.isEmpty) continue;
          localTokensById[localBotId] = (rawApp['token'] ?? '')
              .toString()
              .trim();
        }
        final importOutcomes = await recoverMissingBotTokens(
          client: remoteClient,
          accountBots: bots,
          localTokenOf: (botId) => localTokensById[botId] ?? '',
          // Un jeton qui vient d'arriver ouvre la seule occasion d'interroger
          // Discord sur le VRAI nom du bot : on la saisit immédiatement, avec le
          // même garde-fou « une tentative par bot et par lancement ».
          onTokenStored: (botId, token) =>
              refreshBotIdentityFromDiscord(botId: botId, token: token),
        );
        if (importOutcomes.isNotEmpty) {
          appendBotDebugLog(
            '[syncAllBotsFromManager] Bot token recovery outcomes=${importOutcomes.map((outcome) => outcome.name).join(',')}.',
          );
        }

        // ── Nom réel des bots dont le nom vaut l'ID ───────────────────────────
        // Défaut constaté : un bot affiché sous son ID (`1488275294…`) sur sa
        // carte et en tête de sa page, côté app ET côté compte. Un nom qui vaut
        // l'ID n'est pas un nom : on demande son identité à Discord, une seule
        // fois par bot et par lancement d'application (`refreshBotIdentities…` :
        // aucune requête pour un nom déjà réel, aucune rafale, rien hors ligne).
        final identityOutcomes = await refreshBotIdentitiesFromDiscord(
          accountBots: bots,
          localAppOf: (botId) => appManager.getApp(botId),
          // Un bot HÉBERGÉ n'a aucun jeton sur ce poste — le manager le rédige
          // volontairement dans ses listes. Sans ce client, le balayage n'aurait
          // rien à présenter à Discord et le nom resterait l'ID ; avec lui, il
          // reprend le jeton par la route dédiée (`POST /gateway/bots/{id}/token`,
          // une tentative par bot et par lancement) avant d'interroger Discord.
          client: remoteClient,
        );
        if (identityOutcomes.isNotEmpty) {
          appendBotDebugLog(
            '[syncAllBotsFromManager] Bot identity outcomes=${identityOutcomes.map((outcome) => outcome.name).join(',')}.',
          );
        }
      } catch (error) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Bot token recovery skipped: $error',
        );
      }

      // Phase 3: sync each bot (network calls in parallel, filesystem sequential)
      appendBotDebugLog(
        '[syncAllBotsFromManager] Syncing ${bots.length} bots - network phase in parallel.',
      );

      final botSyncTasks = bots
          .map((bot) async {
            final botId = bot['bot_id']?.toString() ?? '';
            if (botId.isEmpty) return null;

            var botName = bot['bot_name']?.toString() ?? 'Unnamed Bot';
            final config = bot['config'] as Map<String, dynamic>? ?? {};

            Map<String, dynamic>? existingLocal;
            try {
              existingLocal = await appManager.getApp(botId);
            } catch (_) {}

            String token = bot['bot_token']?.toString() ?? '';
            if (token.isEmpty && existingLocal != null) {
              token = (existingLocal['token'] ?? '').toString();
            }

            if (botNameHidesIdentity(botName, botId) && existingLocal != null) {
              final localName = existingLocal['name']?.toString().trim();
              if (localName != null &&
                  !botNameHidesIdentity(localName, botId)) {
                botName = localName;
              }
            }

            String? avatarHash =
                bot['avatar_hash']?.toString() ??
                existingLocal?['avatar_hash']?.toString();
            if (avatarHash == null || avatarHash.isEmpty) {
              final rawAvatar =
                  bot['avatar']?.toString() ??
                  existingLocal?['avatar']?.toString();
              if (rawAvatar != null && rawAvatar.isNotEmpty) {
                final match = RegExp(
                  r'([a-f0-9]{32}|a_[a-f0-9]{32})',
                  caseSensitive: false,
                ).allMatches(rawAvatar);
                if (match.isNotEmpty) {
                  avatarHash = match.last.group(0);
                }
              }
            }
            String? discriminator = bot['discriminator']?.toString();

            int? fetchedApproxGuildCount;
            if (token.trim().isNotEmpty) {
              final shouldFetchProfile =
                  (avatarHash == null || avatarHash.isEmpty) ||
                  botNameHidesIdentity(botName, botId);
              if (shouldFetchProfile) {
                try {
                  final profile = await getDiscordBotUserProfile(token);
                  if (profile != null) {
                    final fetchedAvatar = profile['avatar']?.toString();
                    if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
                      avatarHash = fetchedAvatar;
                    }
                    final fetchedDiscrim = profile['discriminator']?.toString();
                    if (fetchedDiscrim != null && fetchedDiscrim.isNotEmpty) {
                      discriminator = fetchedDiscrim;
                    }
                    final fetchedName = profile['username']?.toString();
                    if (fetchedName != null &&
                        fetchedName.isNotEmpty &&
                        !botNameHidesIdentity(fetchedName, botId)) {
                      botName = fetchedName;
                    }
                  }
                } catch (error) {
                  appendBotDebugLog(
                    '[syncAllBotsFromManager] Avatar profile fetch failed for $botId: $error',
                  );
                }
              }

              try {
                final guildCount = await getDiscordBotGuildCount(token);
                if (guildCount != null) {
                  fetchedApproxGuildCount = guildCount;
                } else {
                  final ownerMetadata =
                      await getDiscordApplicationOwnerMetadata(token);
                  if (ownerMetadata != null) {
                    final approx =
                        ownerMetadata.rawJson['approximate_guild_count'];
                    if (approx is int) {
                      fetchedApproxGuildCount = approx;
                    } else if (approx != null) {
                      fetchedApproxGuildCount = int.tryParse(approx.toString());
                    }
                  }
                }
              } catch (error) {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Guild count fetch failed for $botId: $error',
                );
              }
            }

            return _BotSyncResult(
              botId: botId,
              botName: botName,
              token: token,
              config: config,
              guildCount: fetchedApproxGuildCount,
              avatarHash: avatarHash,
              discriminator: discriminator,
            );
          })
          .toList(growable: false);

      final syncResults = await Future.wait(botSyncTasks);

      AppManager.isSyncingFromRemote = true;
      try {
        for (final result in syncResults) {
          if (result == null) continue;
          try {
            await appManager.createOrUpdateApp(
              id: Snowflake.parse(result.botId),
              username: result.botName,
              avatarHash: result.avatarHash,
              discriminator: result.discriminator,
              token: result.token,
              intents: (result.config['intents'] as Map?)?.cast<String, bool>(),
              prefix: result.config['prefix']?.toString(),
              approximateGuildCount: result.guildCount,
            );

            // Rehydrate commands and workflows from remote config
            var remoteConfig = result.config;
            if (remoteConfig['commands'] == null) {
              try {
                final fullRemote = await remoteClient.getBotConfig(
                  result.botId,
                );
                if (fullRemote.isNotEmpty) {
                  remoteConfig = fullRemote;
                }
              } catch (_) {}
            }
            final remoteCommands = extractCommandListFromConfig(
              remoteConfig['commands'],
            );
            final localCommands = await appManager.listAppCommands(
              result.botId,
              forceRefresh: true,
            );
            final localWorkflows = await appManager.getWorkflows(result.botId);
            final remoteWorkflows = remoteConfig['workflows'];

            final hasRemoteData =
                remoteCommands.isNotEmpty ||
                (remoteWorkflows is List && remoteWorkflows.isNotEmpty) ||
                (remoteWorkflows is Map && remoteWorkflows.isNotEmpty);

            if (hasRemoteData) {
              if (localCommands.isEmpty && localWorkflows.isEmpty) {
                // Fresh device / newly synced bot: restore all commands and workflows
                await applyManagerConfigToLocal(
                  appManager: appManager,
                  botId: result.botId,
                  remoteConfig: remoteConfig,
                  saveAppMetadata: false,
                );
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Restored ${remoteCommands.length} commands for bot ${result.botId} to local DB.',
                );
              } else {
                // Check if remote has newer edits
                final localNewer = botConfigLocalHasNewerEdits(
                  localCommands,
                  remoteCommands,
                );
                final diff = computeBotConfigMergeDiff(
                  localCommands,
                  remoteCommands,
                );
                if (!localNewer && diff.hasChanges) {
                  await applyManagerConfigToLocal(
                    appManager: appManager,
                    botId: result.botId,
                    remoteConfig: remoteConfig,
                    saveAppMetadata: false,
                  );
                  appendBotDebugLog(
                    '[syncAllBotsFromManager] Auto-merged updated commands/workflows from remote for bot ${result.botId}.',
                  );
                }
              }
            }
          } catch (e) {
            developer.log('Failed to sync bot ${result.botId}: $e');
            appendBotDebugLog(
              '[syncAllBotsFromManager] Failed to sync bot ${result.botId}: $e',
            );
          }
        }
      } finally {
        AppManager.isSyncingFromRemote = false;
      }

      if (mounted) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Triggering _initRunningState after bot sync.',
        );
        await _initRunningState();
        // Le partage vient du serveur : c'est ici qu'il se rafraîchit, comme le
        // reste des données du compte (démarrage, reprise, tirer-pour-actualiser).
        await _loadSharedBots();
      }
    } catch (e) {
      appendBotDebugLog('[syncAllBotsFromManager] Sync failed: $e');
      if (mounted && !silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr.home_sync_failed)));
      }
    }
  }

  // ── Gestion des animations pulse ───────────────────────────────────────────

  AnimationController _getOrCreatePulseController(String botId) {
    return _pulseControllers.putIfAbsent(
      botId,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  /// Creates pulse controllers ahead of build (stream listener, not build) and
  /// disposes the ones belonging to bots that no longer exist.
  void _handleAppsSnapshot(List<dynamic> apps) {
    final ids = <String>{
      for (final app in apps)
        if (app is Map && (app['id'] ?? '').toString().trim().isNotEmpty)
          (app['id']).toString().trim(),
    };
    _knownAppIds = ids;
    for (final id in ids) {
      _getOrCreatePulseController(id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _disposeStalePulseControllers(_knownAppIds);
    });
  }

  void _disposeStalePulseControllers(Set<String> liveBotIds) {
    final stale = _pulseControllers.keys
        .where((id) => !liveBotIds.contains(id))
        .toList(growable: false);
    for (final id in stale) {
      _pulseControllers.remove(id)?.dispose();
    }
  }

  void _syncPulse(Set<String> runningIds) {
    for (final entry in _pulseControllers.entries) {
      if (runningIds.contains(entry.key)) {
        if (!entry.value.isAnimating) {
          entry.value.repeat(reverse: true);
        }
      } else {
        entry.value
          ..stop()
          ..value = 0;
      }
    }
  }

  String _uiCopy({required String fr, required String en}) =>
      homeUiCopy(context, fr: fr, en: en);

  String? _runtimeBadgeLabel(String botId) {
    final source = _runtimeSourceByBotId[botId] ?? _runtimeSource;
    final detailLabel =
        _runtimeDetailLabelByBotId[botId] ?? _runtimeDetailLabel;
    return switch (source) {
      RemoteRuntimeSource.manager => _uiCopy(
        fr: 'Serveurs Bot Creator',
        en: 'Bot Creator servers',
      ),
      RemoteRuntimeSource.runner =>
        (detailLabel?.trim().isNotEmpty ?? false)
            ? context.tr.runner_source_label(detailLabel!)
            : _uiCopy(fr: 'Runner', en: 'Runner'),
      RemoteRuntimeSource.local => null,
    };
  }

  Future<Map<String, String>> _loadBotNamesById() async {
    final apps = await appManager.getAllApps();
    final namesById = <String, String>{};
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp);
      final botId = (app['id'] ?? '').toString();
      if (botId.isEmpty) {
        continue;
      }
      namesById[botId] = (app['name'] ?? botId).toString();
    }
    return namesById;
  }

  Future<void> _syncDiscordRpcPresence(
    Set<String> runningBotIds, {
    String? preferredBotId,
    String? preferredBotName,
  }) async {
    try {
      final botNamesById = await _loadBotNamesById();
      await DiscordRpcService.instance.syncBotRuntimeState(
        runningBotIds: runningBotIds,
        botNamesById: botNamesById,
        runtimeSource: _runtimeSource,
        preferredBotId: preferredBotId,
        preferredBotName: preferredBotName,
        activeSourceLabel: _runtimeDetailLabel,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to sync Discord RPC presence: $error',
        name: 'HomePage',
        stackTrace: stackTrace,
      );
    }
  }

  /// Ce qui peut être proposé pour démarrer [botId], d'après l'état RÉEL du compte.
  ///
  /// Mêmes faits que ceux qui décideront côté serveur — session présente et non
  /// expirée, formule, interrupteur d'hébergement cloud du serveur, solde de minutes
  /// de CE bot — pour ne rien proposer qui échouerait ensuite.
  Future<BotStartChoices> _botStartChoicesFor(String botId) async {
    // La traduction est lue AVANT toute attente : plus de `context` après un `await`.
    final tr = context.tr;
    var hasSession = false;
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      hasSession = config.isConfigured && session != null && !session.isExpired;
    } catch (_) {
      hasSession = false;
    }
    return resolveBotStartChoices(
      supportsManagerRuntime: _supportsManagerRuntime,
      hasValidSession: hasSession,
      premium: SubscriptionService.isSubscribed,
      cloudDisabledByServer: SubscriptionService.premiumCloudDisabled,
      freeMinutesBalance: _freeMinutesByBotId[botId] ?? 0,
      tr: tr,
    );
  }

  /// Redemande au compte le jeton du bot, pour pouvoir le démarrer sur ce poste.
  ///
  /// Pourquoi c'est nécessaire : un bot créé/synchronisé par le serveur n'a AUCUN jeton
  /// sur le poste — le manager le rédige volontairement dans toutes ses réponses. Sans
  /// cette reprise, « démarrer sur ce poste » échouait sur un jeton manquant alors que le
  /// jeton existe, sur le compte.
  ///
  /// Le jeton reçu est écrit par le chemin d'écriture UNIQUE (`persistImportedBotToken`,
  /// appelé par la brique), donc il ne peut pas effacer un jeton déjà présent. On ne
  /// prétend rien sur sa validité : la route répond `409`/`500` si elle ne peut pas le
  /// rendre, et l'issue est journalisée telle quelle.
  Future<String?> _recoverBotTokenForLocalStart(String botId) async {
    try {
      final client = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: null,
        attemptSessionRestore: true,
      );
      if (client == null) {
        return null;
      }
      final outcome =
          await BotTokenImporter(
            client: client,
            // Même occasion saisie ici : le jeton qui vient d'arriver permet de
            // demander à Discord le VRAI nom du bot, écrit par le chemin unique.
            onTokenStored: (botId, token) =>
                refreshBotIdentityFromDiscord(botId: botId, token: token),
          ).importAutomatically(
            botId: botId,
            serverAnnouncesTokenValid: true,
            hasLocalToken: false,
          );
      appendBotDebugLog(
        '[_toggleBot] reprise du jeton avant démarrage sur ce poste : $outcome',
        botId: botId,
      );
      final app = await appManager.getApp(botId);
      final recovered = (app['token'] ?? '').toString().trim();
      return recovered.isEmpty ? null : recovered;
    } catch (error) {
      appendBotDebugLog(
        '[_toggleBot] reprise du jeton impossible : $error',
        botId: botId,
      );
      return null;
    }
  }

  /// Arrête la session serveur avant de démarrer le bot sur ce poste.
  ///
  /// Pourquoi ce n'est pas facultatif : Discord n'accepte qu'UNE connexion par jeton, et
  /// le manager relance tout bot dont l'état désiré est resté « en marche ». Un bot
  /// laissé en marche côté serveur continue donc de tourner — et de consommer — alors que
  /// l'utilisateur a explicitement demandé ce poste. Attente BORNÉE : mieux vaut démarrer
  /// ici sans avoir pu arrêter là-bas que bloquer l'utilisateur ; l'échec est journalisé.
  Future<void> _stopRemoteSessionBeforeLocalStart(String botId) async {
    try {
      final client = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: null,
        attemptSessionRestore: true,
      );
      if (client == null) {
        return;
      }
      await client
          .stopBot(botId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => <String, dynamic>{},
          );
      appendBotDebugLog(
        '[_toggleBot] session serveur arrêtée avant un démarrage sur ce poste',
        botId: botId,
      );
    } catch (error) {
      appendBotDebugLog(
        '[_toggleBot] arrêt de la session serveur impossible '
        '(démarrage local poursuivi) : $error',
        botId: botId,
      );
    }
  }

  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    String? botId,
    RemoteRuntimeSource? forcedSource,
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 25),
  }) async {
    // Seul point où la plateforme pèse encore sur l'EXÉCUTION — et seulement en creux :
    // le web n'a pas d'accès direct au manager. Partout ailleurs (poste de travail,
    // mobile) `resolveRemoteRuntime` tranche par bot : association « manager » → pilotage
    // à distance, sinon runner/local (le runner embarqué reste le défaut sur desktop).
    // `forcedSource` porte le CHOIX de l'utilisateur (pop-up de démarrage) et prime.
    return resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: botId,
      forcedSource: forcedSource,
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  MainApiOwnerSyncHelper get _ownerSyncHelper => MainApiOwnerSyncHelper(
    resolveRuntime:
        ({
          getTimeout = const Duration(seconds: 30),
          postTimeout = const Duration(seconds: 25),
        }) => _resolveRemoteRuntime(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
    loadLocalBotById: (botId) async => await appManager.getApp(botId),
    log: appendBotDebugLog,
  );

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
  }) async {
    return _ownerSyncHelper.restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: botToken,
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    // Aucun verrou de plateforme : c'est une DONNÉE du compte. Le refus légitime —
    // manager non configuré ou session absente/expirée — est décidé plus bas par
    // `MainApiOwnerSyncHelper`. Un poste de travail connecté doit voir ses bots.
    return _ownerSyncHelper.resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: attemptSessionRestore,
    );
  }

  Future<MainApiClient?> _resolveGlobalMainApiClient({
    bool attemptRestore = true,
  }) async {
    // Idem : plus de refus lié au poste de travail. Le compte, les bots du compte et
    // les conteneurs clé en main sont des données du manager, pas une capacité d'OS.
    appendBotDebugLog(
      '[_resolveGlobalMainApiClient] Resolving global client (attemptRestore=$attemptRestore).',
    );

    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Manager is not configured. Returning null.',
      );
      return null;
    }

    var session = await loadMainApiSession();

    if (session != null && !session.isExpired) {
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Active global session found. Returning MainApiClient.',
      );
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }

    if (attemptRestore) {
      final apps = await appManager.getAllApps();
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] No active session; trying one ephemeral bot-token exchange from ${apps.length} local apps.',
      );
      for (final rawApp in apps) {
        if (rawApp is! Map) continue;
        final token = (rawApp['token'] ?? '').toString().trim();
        if (token.isEmpty) continue;
        final client = await _ownerSyncHelper.exchangeEphemeralBotTokenClient(
          token,
        );
        if (client != null) {
          appendBotDebugLog(
            '[_resolveGlobalMainApiClient] Success: ephemeral client from local bot token.',
          );
          return client;
        }
        break;
      }
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Failed to create ephemeral client from local apps.',
      );
    }

    return null;
  }

  // ── Démarrage / Arrêt du bot ───────────────────────────────────────────────

  Future<void> _toggleBot({
    required String botId,
    required String botName,
  }) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    // Trace du GESTE, avant toute décision : le seul point qui prouve que le bouton a
    // été pressé, et dans quel sens. Aucun jeton n'y apparaît.
    appendBotStartTrace(
      'bouton presse bot=$botId enMarche=${_runningBotIds.contains(botId)}',
      botId: botId,
    );

    // Read before the try: the same method also stops a running bot, and the
    // catch has to know whether this attempt was a start to report an outcome.
    final isRunning = _runningBotIds.contains(botId);

    // Les quotas de la formule sont des quotas de DÉMARRAGE. Un bot « en plus »
    // n'est pas refusé : il tourne financé par pub — à condition de le dire AVANT
    // de lancer, pour que l'utilisateur sache qu'il regardera des pubs pour ce bot.
    var adFundedByPlan = false;
    if (!isRunning) {
      final block = SubscriptionService.ownBotStartBlock(
        runningBots: _runningBotIds.length,
      );
      if (block != null) {
        if (!mounted) return;
        setState(() => _botIdInAction = null);
        final action = await _showPlanLimit(block);
        if (action != PlanLimitAction.continueAdFunded) return;
        adFundedByPlan = true;
      }
    }

    // ── Où démarrer ? La question est posée, jamais devinée ───────────────────
    // L'association du bot décidait seule jusqu'ici : un bot associé au manager
    // repartait sur Bot Creator Server sans que rien ne le dise, alors que ce chemin
    // consomme des minutes d'hébergement. Le choix est explicite à chaque démarrage
    // (aucune mémoire : la décision a un coût, elle se reprend à chaque fois).
    RemoteRuntimeSource? forcedSource;
    // ── Où démarrer ? La question n'a de sens QUE sur un poste de travail ──────
    // Sur mobile, l'app ne peut pas héberger un bot dans les mêmes conditions et le
    // choix n'appartient pas à l'utilisateur : on garde le comportement historique
    // (l'association du bot décide), sans rien lui demander. Imposer cette question
    // sur un téléphone serait une décision de plateforme, pas un service.
    if (!isRunning && isDesktopRunPlatform) {
      if (!mounted) return;
      final choices = await _botStartChoicesFor(botId);
      if (!mounted) return;
      final choice = await showBotStartTargetDialog(
        context,
        botName: botName,
        choices: choices,
      );
      if (choice == null) {
        // Annulé : le bot ne démarre pas, et la carte revient au repos.
        if (mounted) setState(() => _botIdInAction = null);
        return;
      }
      forcedSource = choice == BotStartTarget.local
          ? RemoteRuntimeSource.local
          : RemoteRuntimeSource.manager;
    }

    // ── Un démarrage ICI commence par arrêter LÀ-BAS ───────────────────────────
    // Discord n'accepte qu'UNE connexion par jeton, et le manager relance tout bot dont
    // l'état désiré est resté « en marche ». Sans cet arrêt, « démarrer sur ce poste »
    // laissait la session serveur vivre et se relancer : le bot semblait démarrer H24
    // sur Bot Creator, et la page de logs montrait (à juste titre) les logs du serveur.
    // On ATTEND l'arrêt, borné : démarrer ici avant que là-bas soit arrêté, c'est
    // laisser les deux sessions se disputer le jeton.
    if (forcedSource == RemoteRuntimeSource.local) {
      await _stopRemoteSessionBeforeLocalStart(botId);
    }

    try {
      var runtime = await _resolveRemoteRuntime(
        botId: botId,
        forcedSource: forcedSource,
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 25),
      );

      // ── Fetch + validate token before anything else (only when starting) ──
      String? token;
      if (!isRunning) {
        final app = await appManager.getApp(botId);
        // Garde-fou : une entrée locale marquée clé en main est un CONTENEUR, pas
        // un bot. Elle est purgée au chargement et filtrée de la liste d'accueil ;
        // ce verrou garantit qu'aucun autre appelant ne peut la DÉMARRER — donc la
        // synchroniser (`syncBot` / `saveDiscordBotSnapshot`) et créer une ligne
        // de bot fantôme côté manager.
        if (AppManager.isTurnkeyAppEntry(app)) {
          appendBotDebugLog(
            '[_toggleBot] Entrée clé en main $botId ignorée : un conteneur se '
            'pilote depuis sa carte d\'accueil, il n\'est jamais démarré comme un bot.',
          );
          return;
        }
        token = app['token']?.toString();

        // Sync config from manager before startup (the basic sync)
        try {
          appendBotDebugLog(
            '[_toggleBot] Fetching latest config from manager before launch...',
          );
          final syncClient = await _resolveMainApiClientForBot(
            botId: botId,
            botToken: token,
            attemptSessionRestore: true,
          );
          if (syncClient != null) {
            final remoteConfig = await syncClient
                .getBotConfig(botId)
                .timeout(const Duration(seconds: 15));
            if (remoteConfig.isNotEmpty) {
              if (remoteConfig['inboundWebhooks'] is bool) {
                remoteConfig.remove('inboundWebhooks');
              }
              if (app['avatar'] != null && remoteConfig['avatar'] == null) {
                remoteConfig['avatar'] = app['avatar'];
              }
              if (app['name'] != null && remoteConfig['name'] == null) {
                remoteConfig['name'] = app['name'];
              }
              final existingToken = (app['token'] ?? token ?? '')
                  .toString()
                  .trim();
              remoteConfig['token'] = existingToken;

              final localCommands = await appManager.listAppCommands(
                botId,
                forceRefresh: true,
              );
              final remoteCommands = extractCommandListFromConfig(
                remoteConfig['commands'],
              );
              final diff = computeBotConfigMergeDiff(
                localCommands,
                remoteCommands,
              );
              final localNewer = botConfigLocalHasNewerEdits(
                localCommands,
                remoteCommands,
              );

              if (!diff.hasChanges) {
                appendBotDebugLog(
                  '[_toggleBot] Pre-launch pull skipped: no remote updates'
                  '${diff.localOnlyCount > 0 ? ' (local-only commands preserved)' : ''}'
                  '${localNewer ? ' (local edits are newer)' : ''}',
                );
              } else if (localCommands.isEmpty ||
                  (!localNewer && diff.localOnlyCount == 0)) {
                await applyManagerConfigToLocal(
                  appManager: appManager,
                  botId: botId,
                  remoteConfig: remoteConfig,
                );
                appendBotDebugLog(
                  '[_toggleBot] Pre-launch config sync auto-applied for $botId',
                );
              } else {
                if (!mounted) return;
                final confirmed = await showBotConfigPullConfirmDialog(
                  context: context,
                  diff: diff,
                  remoteTimestamp: formatBotConfigTimestamp(remoteConfig),
                  localTimestamp: await formatLocalBotConfigTimestamp(
                    appManager,
                    botId,
                  ),
                );
                if (confirmed) {
                  await applyManagerConfigToLocal(
                    appManager: appManager,
                    botId: botId,
                    remoteConfig: remoteConfig,
                  );
                  appendBotDebugLog(
                    '[_toggleBot] Pre-launch config sync confirmed and applied for $botId',
                  );
                } else {
                  appendBotDebugLog(
                    '[_toggleBot] Pre-launch pull declined for $botId',
                  );
                }
              }
            }
          }
        } catch (e) {
          appendBotDebugLog(
            '[_toggleBot] Pre-launch config sync failed/skipped: $e',
          );
        }

        var usingRunner = runtime.client != null || runtime.blocksLocalFallback;

        if (runtime.blocksLocalFallback) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();

          final sessionRestored = await _restoreMainApiSessionWithBotToken(
            botId: botId,
            botToken: token,
          );
          if (sessionRestored) {
            // `forcedSource` est REPASSÉ ici : cette seconde résolution décidait
            // auparavant sans le choix de l'utilisateur, et c'est exactement par là que
            // « serveurs Bot Creator » devenait un démarrage local silencieux.
            runtime = await _resolveRemoteRuntime(
              botId: botId,
              forcedSource: forcedSource,
              getTimeout: const Duration(seconds: 30),
              postTimeout: const Duration(seconds: 25),
            );
            usingRunner = runtime.client != null || runtime.blocksLocalFallback;
          }

          if (!sessionRestored || runtime.blocksLocalFallback) {
            final message =
                runtime.unavailableReason ??
                _uiCopy(
                  fr: 'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en: 'Sign in to Bot Creator in Settings before starting this bot.',
                );
            throw Exception(message);
          }
        }

        if (!usingRunner) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();
          if (token == null || token.trim().isEmpty) {
            throw Exception(context.tr.home_token_missing(botName));
          }

          // Token check against Discord before showing ads
          try {
            await getDiscordUser(token);
          } catch (_) {
            if (!mounted) return;
            final proceed = await AppTheme.showConfirmDialog(
              context,
              title: context.tr.bot_home_token_invalid_title,
              content: context.tr.bot_home_token_invalid_content,
              confirmLabel: context.tr.bot_home_start,
            );
            if (!proceed || !mounted) return;
          }
        }

        final adUnlocked = await _maybeOfferRewardedAd(
          botId: botId,
          botToken: token,
          adFundedByPlan: adFundedByPlan,
          successMessage: context.tr.rewarded_start_thanks,
        );
        if (!adUnlocked) {
          return;
        }
        if (!mounted) return;
      }

      // ── Runner API (API only) ─────────────────────────────────────────────
      // `forcedSource` est repassé ICI aussi : c'est la résolution qui décide vraiment
      // du chemin emprunté. Sans le choix de l'utilisateur, un « local » pouvait
      // repartir sur les serveurs ET un « serveurs » retomber en local — les deux dans
      // le dos de l'utilisateur.
      runtime = await _resolveRemoteRuntime(
        botId: botId,
        forcedSource: forcedSource,
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 25),
      );
      // Témoin de décision : la pop-up promet « ce poste » ou « les serveurs Bot Creator »,
      // et un chemin décide ensuite. Sans cette ligne, un choix non honoré ne laisse
      // aucune trace exploitable — on ne sait pas si la cible a été perdue à la
      // résolution, au choix du runner, ou plus loin. Le jeton n'apparaît JAMAIS ici.
      appendBotDebugLog(
        '[_toggleBot] choix=${forcedSource ?? 'aucun (bot deja en marche)'} '
        'cible=${runtime.source} client=${runtime.client != null} '
        'blocage=${runtime.blocksLocalFallback}',
        botId: botId,
      );

      // ── GARDE : le choix de l'utilisateur ne se replie JAMAIS en silence ──────
      // Mesuré chez le propriétaire : « clic=serveurs Bot Creator », puis un démarrage
      // local sans un mot. Le repli venait de résolutions qui perdaient le choix
      // (corrigées ci-dessus) ; cette garde le rend impossible même si une résolution
      // future l'oubliait : si les serveurs ont été choisis et que la branche décidée
      // n'est pas la leur, on EXPLIQUE et on s'arrête. Exécuter sur la machine de
      // l'utilisateur autre chose que ce qu'il a choisi est le défaut, pas une option.
      final startPlan = planBotStart(
        serverChosen: forcedSource == RemoteRuntimeSource.manager,
        hasRemoteClient: runtime.client != null,
        clientIsManager: runtime.client is MainApiClient,
        runnerIsEmbedded:
            RunnerSettings.getAssociatedRunnerId(botId) ==
            RunnerSettings.embeddedRunnerId,
        supportsForegroundTask: _supportsForegroundTask,
        // Le moteur ne pèse que sans client distant, exactement comme le code : la
        // ligne ne peut donc pas annoncer une sous-branche que le code n'emprunte pas.
        engineIsJavascript:
            runtime.client == null &&
            await getBotRuntimeEngine(botId) == runtimeEngineJavascript,
        serverUnavailableDetail: runtime.unavailableReason ?? '',
      );
      if (!startPlan.allowed) {
        appendBotStartTrace(startPlan.refusalTrace!, botId: botId);
        final detail =
            startPlan.serverUnavailableDetail?.trim().isNotEmpty ?? false
            ? startPlan.serverUnavailableDetail!.trim()
            : _uiCopy(
                fr: 'aucune session serveur exploitable depuis ce poste',
                en: 'no usable server session from this device',
              );
        throw Exception(
          _uiCopy(
            fr:
                'Les serveurs Bot Creator ont ete choisis et ne peuvent pas '
                'executer ce bot : $detail. Aucune execution locale n a ete '
                'entamee — relancez le demarrage apres avoir regle ce point.',
            en:
                'Bot Creator servers were chosen and cannot run this bot: '
                '$detail. No local run was started — retry the start once this '
                'is resolved.',
          ),
        );
      }

      final client = runtime.client;
      if (client != null) {
        // Nomme la BRANCHE réellement empruntée. La ligne témoin ci-dessus dit la cible
        // retenue, celle-ci dit le code qui s'exécute : la branche vient du PLAN, établi
        // par les mêmes tests que ce bloc, donc le libellé ne peut pas désigner une
        // autre branche que celle où l'on entre.
        appendBotStartTrace(startPlan.branchTrace, botId: botId);
        try {
          if (isRunning) {
            appendBotLog(
              'Bot stop requested',
              botId: botId,
              source: runtime.source,
            );
            await client.stopBot(botId);

            endBotLogSession(botId: botId, source: runtime.source);
            unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds}..remove(botId);
              });
            }
            setBotRuntimeActive(_runningBotIds.isNotEmpty);
          } else {
            startBotLogSession(botId: botId, source: runtime.source);
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: runtime.source,
            );
            if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
              await validateJsBotPayloadOrThrow(botId);
            }
            final payload = await buildRemotePayload(botId);
            if (client is MainApiClient) {
              final app = await appManager.getApp(botId);
              final botToken = (app['token'] ?? '').toString().trim();
              if (botToken.isNotEmpty) {
                try {
                  await client.saveDiscordBotSnapshot(
                    botId: botId,
                    botToken: botToken,
                    config: payload,
                  );
                } catch (_) {
                  // Best-effort only: do not block start if save route fails.
                }
              }
              // La poussée de DÉMARRAGE passe par la MÊME orchestration que la
              // poussée canonique : un `409 bot_config_overshrink` — suppression
              // massive, peut-être volontaire — n'est pas une panne mais une
              // QUESTION, et on la POSE au lieu d'afficher un simple message qui
              // obligerait l'utilisateur à relancer son geste pour confirmer.
              // Sans accord, rien n'est envoyé, le local reste intact, et le
              // démarrage s'arrête ici : lancer le bot sur la configuration que
              // le serveur vient de refuser serait un mensonge sur ce qui a été
              // appliqué.
              final pushOutcome = await pushStartBotConfigToleratingOvershrink(
                client: client,
                botId: botId,
                botName: botName,
                config: payload,
                askConfirmation: _askOvershrinkConfirmation,
              );
              if (pushOutcome != BotConfigPushOutcome.sent) {
                _reportOvershrinkNothingSent();
                return;
              }
              // Encadré : la demande part, puis le RÉSULTAT est écrit. Sans ces deux
              // lignes, un refus du serveur ne laissait aucune trace côté démarrage —
              // on ne pouvait pas distinguer « jamais demandé » de « demandé et refusé ».
              await requestManagerBotStartWithTraces(
                client: client,
                botId: botId,
                botName: botName,
                trace: (message) => appendBotStartTrace(message, botId: botId),
              );
              RunnerSettings.associateBotWithRunner(botId, 'manager');
            } else {
              await client.syncBot(botId, botName, payload);
              await client.startBot(botId, botName: botName);
              final runnerConfig = await RunnerSettings.resolveConfigForBot(
                botId,
              );
              if (runnerConfig != null) {
                RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
              }
            }
            setBotRuntimeActive(true);
            // The runtime confirmed the start: the funnel's success point.
            unawaited(ActivationFunnel.botStart());
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds, botId};
                _runtimeSource = runtime.source;
                _runtimeDetailLabel = runtime.detailLabel;
              });
            }
          }
        } catch (error) {
          // La garde anti-config-vide a refusé AVANT tout appel réseau : la
          // laisser passer dans `describeManagerRuntimeFailure` la déguiserait en
          // panne des serveurs Bot Creator (« pas encore prêts », « démarrage en
          // cours »). On la laisse donc remonter TELLE QUELLE : le `catch`
          // extérieur affiche son message localisé dédié. Idem pour le refus
          // SERVEUR de sur-réduction (`409 bot_config_overshrink`) : c'est une
          // question à poser au propriétaire, pas une panne.
          if (isBotPayloadRefusal(error) ||
              isBotConfigOvershrinkRefusal(error)) {
            rethrow;
          }
          if (client is MainApiClient) {
            throw Exception(await describeManagerRuntimeFailure(client, error));
          }
          rethrow;
        }
        _syncPulse(_runningBotIds);
        await _syncDiscordRpcPresence(
          _runningBotIds,
          preferredBotId: _runningBotIds.contains(botId) ? botId : null,
          preferredBotName: _runningBotIds.contains(botId) ? botName : null,
        );
        return;
      }

      // ── Local engine ──────────────────────────────────────────────────────
      // Token already fetched and validated above; re-read if needed (stop path)
      if (token == null) {
        final app = await appManager.getApp(botId);
        token = app['token']?.toString();
      }
      if (token == null || token.trim().isEmpty) {
        // Le bot est GÉRÉ par le serveur : son jeton vit chez lui et toutes les réponses
        // le rédigent. Sans cette reprise, « démarrer sur ce poste » ne pouvait pas
        // aboutir — il annonçait un jeton manquant pour un bot qui en a bien un, sur le
        // compte. Une seule tentative par bot et par lancement (garde de la brique).
        token = await _recoverBotTokenForLocalStart(botId);
      }
      if (token == null || token.trim().isEmpty) {
        throw Exception(context.tr.home_token_missing(botName));
      }

      if (!isRunning) {
        clearBotBaselineRss();
        final engine = await getBotRuntimeEngine(botId);
        final isJsDesktop =
            !_supportsForegroundTask && engine == runtimeEngineJavascript;
        if (!isJsDesktop) {
          startBotLogSession(botId: botId);
          appendBotLog('Bot start requested', botId: botId);
        }
      }

      if (_supportsForegroundTask) {
        // ── Mobile (Android / iOS) ─────────────────────────────────────────
        appendBotStartTrace(
          botStartBranchTrace(BotStartBranch.mobile),
          botId: botId,
        );
        if (isRunning) {
          appendBotLog('Bot stop requested', botId: botId);
          await stopMobileBotSession(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
          setBotRuntimeActive(_runningBotIds.isNotEmpty);
        } else {
          // Vérifier / demander la permission de notification.
          try {
            var perm =
                await FlutterForegroundTask.checkNotificationPermission();
            if (perm != NotificationPermission.granted) {
              await FlutterForegroundTask.requestNotificationPermission();
            }
          } on MissingPluginException {
            // Continuer sans vérification sur les plateformes non supportées.
          }

          await initForegroundService(eventIntervalMs: 5000);
          await startMobileBotSession(botId: botId, token: token);

          try {
            final running = await FlutterForegroundTask.isRunningService;
            if (!running) {
              throw Exception(context.tr.home_foreground_service_not_started);
            }
          } on MissingPluginException {
            // Accepter sur les plateformes de dev.
          }

          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
          // The foreground service reported itself running: the mobile start
          // succeeded, even though the bot is not "launched" locally yet.
          unawaited(ActivationFunnel.botStart());
        }
      } else {
        // ── Desktop (Linux / Windows / macOS) ─────────────────────────────
        if (isRunning) {
          appendBotLog(
            context.tr.home_log_desktop_stop_requested,
            botId: botId,
          );
          await stopDesktopBot(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          setBotRuntimeActive(
            isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
          );
          clearBotBaselineRss();
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
        } else {
          if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
            final runnerConfig = await RunnerSettings.resolveConfigForBot(
              botId,
            );
            if (runnerConfig == null) {
              final startupDetail =
                  await RunnerSettings.embeddedRunnerStartupFailureDetail();
              final detailSuffix =
                  startupDetail == null || startupDetail.isEmpty
                  ? ''
                  : ' ($startupDetail)';
              throw Exception(
                _uiCopy(
                  fr: 'Le runner JS embarque n\'a pas pu demarrer. Relancez completement l\'application (pas un hot reload).$detailSuffix',
                  en: 'The embedded JS runner could not start. Fully restart the app (not hot reload).$detailSuffix',
                ),
              );
            }

            appendBotStartTrace(
              botStartBranchTrace(BotStartBranch.localJsEngine),
              botId: botId,
            );
            final client = runnerConfig.createClient();
            startBotLogSession(
              botId: botId,
              source: RemoteRuntimeSource.runner,
            );
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: RemoteRuntimeSource.runner,
            );
            await validateJsBotPayloadOrThrow(botId);
            final payload = await buildRemotePayload(botId);
            await client.syncBot(botId, botName, payload);
            await client.startBot(botId, botName: botName);
            RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
            setBotRuntimeActive(true);
            // The runner accepted the start: the funnel's success point.
            unawaited(ActivationFunnel.botStart());
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds, botId};
                _runtimeSource = RemoteRuntimeSource.runner;
                _runtimeDetailLabel = runnerConfig.name ?? runnerConfig.url;
              });
            }
            _syncPulse(_runningBotIds);
            await _syncDiscordRpcPresence(
              _runningBotIds,
              preferredBotId: botId,
              preferredBotName: botName,
            );
            return;
          }
          appendBotStartTrace(
            botStartBranchTrace(BotStartBranch.localDesktop),
            botId: botId,
          );
          await startDesktopBot(token);
          // Ce POSTE exécute le bot : une association « manager » héritée (ou posée par
          // un démarrage distant précédent) ferait envoyer le prochain Stop au serveur,
          // qui n'aurait rien à arrêter, et le bot continuerait ici.
          RunnerSettings.associateBotWithRunner(botId, 'local');
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
          // The local engine is running the bot: the funnel's success point.
          unawaited(ActivationFunnel.botStart());
        }
      }

      _syncPulse(_runningBotIds);
      await _syncDiscordRpcPresence(
        _runningBotIds,
        preferredBotId: _runningBotIds.contains(botId) ? botId : null,
        preferredBotName: _runningBotIds.contains(botId) ? botName : null,
      );
    } catch (e) {
      // Only a start attempt is reported here: this method stops bots too.
      if (!isRunning) {
        unawaited(ActivationFunnel.botStartFailed(e));
      }
      // POURQUOI ce cas AVANT tout le reste : la poussée a été REFUSÉE par la
      // garde anti-config-vide. Rien n'est parti, rien n'a été effacé en local —
      // annoncer le diagnostic brut (ou une panne serveur) ferait croire à une
      // perte de configuration et pousserait à « réparer » des données intactes.
      // `mounted` AVANT `context.tr` : la page peut avoir été quittée pendant la
      // tentative, et lire les traductions sur un contexte détruit lèverait dans
      // le `catch` — soit une erreur masquant l'erreur d'origine.
      // Le refus SERVEUR de sur-réduction reçoit la même phrase qu'une poussée
      // refusée en local (une seule version des faits) : rien n'est parti, la
      // configuration locale est intacte — et jamais « les serveurs ne sont pas
      // prêts », qui serait un mensonge sur un refus volontaire.
      final refusal = mounted
          ? (localizedBotPayloadRefusalMessage(context.tr, e) ??
                localizedBotConfigOvershrinkNothingSent(context.tr, e))
          : null;
      // Le serveur reste seul juge : un refus lié à la formule arrive ici quand
      // la formule a changé depuis le dernier rafraîchissement local. On affiche
      // la même explication et la même issue qu'un blocage anticipé.
      final block = isRunning ? null : _planLimitBlockFromError(e);
      if (mounted && refusal != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(refusal),
            backgroundColor: AppTheme.error,
          ),
        );
      } else if (mounted && block != null) {
        await _showPlanLimit(block);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.error_with_details(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _botIdInAction = null);
      // Contrôle de RÉALITÉ, pour un démarrage seulement : il doit être programmé même
      // si la tentative a levé, sinon l'échec — le cas qui a motivé ces traces — serait
      // le seul à n'en laisser aucune.
      if (!isRunning) {
        _scheduleBotStartRealityChecks(botId);
      }
    }
  }

  /// Programme les deux contrôles de réalité d'un démarrage (5 s puis 10 s).
  ///
  /// Pourquoi DEUX : le serveur met parfois quelques secondes à faire passer
  /// `runtime_state` à `running` (placement du conteneur). Un contrôle unique à 5 s
  /// déclarerait « échec » un démarrage simplement lent ; celui de 10 s tranche.
  /// Aucun des deux n'est ATTENDU : le démarrage ne doit jamais dépendre d'un
  /// diagnostic, qui n'est là que pour dire la vérité après coup.
  void _scheduleBotStartRealityChecks(String botId) {
    for (final seconds in const <int>[5, 10]) {
      unawaited(
        Future<void>.delayed(Duration(seconds: seconds), () {
          unawaited(_logBotStartReality(botId: botId, moment: '+${seconds}s'));
        }),
      );
    }
  }

  /// Interroge LES DEUX sources (locale et serveur) et journalise où le bot tourne
  /// réellement, quelques secondes après le geste.
  ///
  /// La décision elle-même est pure ([resolveBotStartOutcome] / [formatBotStartRealityLog]):
  /// c'est donc la même phrase que celle prouvée par le test, pas une copie.
  /// Ne journalise JAMAIS un jeton ni le corps d'une réponse : uniquement des états.
  Future<void> _logBotStartReality({
    required String botId,
    required String moment,
  }) async {
    // Application fermée (ou page démontée) entre-temps : plus rien à observer, et
    // surtout pas un appel réseau lancé depuis un écran qui n'existe plus.
    if (!mounted) return;

    // « Ce poste l'exécute-t-il ? » — lu OÙ le démarrage local l'écrit.
    //
    // Pourquoi pas l'ensemble des bots en marche de la page d'accueil, qui servait
    // jusqu'ici : c'est un état d'ÉCRAN, remplacé en bloc à chaque rafraîchissement de
    // liste. Mesuré chez le propriétaire : le bot tournait bien ici (son gateway Nyxx
    // annonçait « Connected to Gateway ») et la ligne annonçait pourtant
    // « LOCAL=arrete … demarre nulle part (echec) ». Le diagnostic désignait une panne
    // là où il n'y en avait pas — c'est le deuxième mensonge corrigé ici.
    final localRunning = thisMachineExecutesBot(
      desktopEngineSession: isDesktopBotRunningId(botId),
      mobileSession: isMobileBotRunning(botId),
      embeddedRunnerSession:
          RunnerSettings.getAssociatedRunnerId(botId) ==
          RunnerSettings.embeddedRunnerId,
    );

    bool? serverRunning;
    Map<String, dynamic>? serverEntry;
    try {
      // Client du COMPTE, session en cache uniquement : le contrôle ne déclenche ni
      // connexion ni échange de jeton, et n'a donc rien à gagner à échouer bruyamment.
      final client = await _resolveGlobalMainApiClient(attemptRestore: false);
      if (client != null) {
        final bots = await client.listBots().timeout(
          const Duration(seconds: 8),
        );
        for (final entry in bots) {
          if ((entry['bot_id'] ?? entry['id'] ?? '').toString().trim() ==
              botId) {
            serverEntry = entry;
            break;
          }
        }
        // Entrée absente = le compte ne gère pas ce bot : le serveur ne l'exécute pas.
        serverRunning = serverBotIsRunning(serverEntry);
      }
    } catch (_) {
      // Serveur injoignable, session absente : l'état reste « non lu », ce que la
      // ligne dira. Un diagnostic ne doit jamais lever — c'est lui qui explique.
      serverRunning = null;
    }

    if (!mounted) return;
    appendBotStartTrace(
      formatBotStartRealityLog(
        moment: moment,
        localRunning: localRunning,
        serverRunning: serverRunning,
        serverBotEntry: serverEntry,
      ),
      botId: botId,
    );
  }

  /// Traduit un refus serveur (403 de formule) en blocage affichable.
  PlanLimitBlock? _planLimitBlockFromError(Object error) {
    final refusal = planLimitRefusalFromError(error);
    return refusal == null ? null : PlanLimitDialog.blockFromRefusal(refusal);
  }

  /// Pose la question du refus SERVEUR de sur-réduction (`409
  /// bot_config_overshrink`) — la MÊME question que la poussée canonique.
  ///
  /// Sans interface pour la poser (page quittée pendant la tentative), la réponse
  /// est NON : ne rien envoyer est la seule issue qui ne peut pas remplacer la
  /// configuration vivante du bot.
  Future<bool> _askOvershrinkConfirmation() async {
    if (!mounted) {
      return false;
    }
    return showBotConfigOvershrinkConfirmation(context);
  }

  /// Dit que la poussée n'a rien envoyé et n'a rien effacé.
  ///
  /// POURQUOI la phrase du dialogue sert aussi ici : elle dit exactement cela
  /// (rien n'est parti, la configuration locale est intacte, le serveur tourne
  /// toujours sur la précédente), et l'i18n de ce lot reste à quatre clés.
  void _reportOvershrinkNothingSent() {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizedBotConfigOvershrinkConfirmation(context.tr).body),
        backgroundColor: AppTheme.error,
      ),
    );
  }

  /// Un démarrage refusé par la formule n'est pas une panne : on explique, et on
  /// propose les offres. Un bot au-delà du quota, lui, peut démarrer financé par pub.
  Future<PlanLimitAction> _showPlanLimit(PlanLimitBlock block) async {
    final action = await showPlanLimitDialog(context, block);
    if (action == PlanLimitAction.viewOffers && mounted) {
      await SubscriptionsHubPage.open(context);
    }
    return action;
  }

  Future<int?> _fetchMainApiRuntimeBalance(String botId) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return null;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      return _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _waitForMainApiRewardCredit({
    required String botId,
    required int? previousBalance,
  }) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return true;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final balance = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );

        if (mounted) {
          setState(() {
            _freeMinutesByBotId = <String, int>{
              ..._freeMinutesByBotId,
              botId: balance,
            };
          });
        }

        if (previousBalance == null ||
            balance > previousBalance ||
            _hasFreeRuntimeAvailable(runtime, balance)) {
          return true;
        }
      } catch (_) {
        // Keep polling until timeout.
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<bool> _ensureMainApiBotSnapshotForAd(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) {
      return false;
    }

    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    if (remoteClient == null) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager client unavailable before snapshot sync.',
      );
      return false;
    }

    final payload = await buildRemotePayload(botId);
    try {
      await remoteClient.saveDiscordBotSnapshot(
        botId: botId,
        botToken: botToken,
        config: payload,
      );
      return true;
    } catch (error) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager snapshot sync failed: $error',
      );
      return false;
    }
  }

  /// Contexte SSV du flux « bot » — construction partagée avec l'éditeur de
  /// bot (`ad_ssv_context.dart`) : ici, la session Manager suffit à résoudre le
  /// propriétaire, le contexte reste donc sans `discord_owner_id` comme avant.
  Future<AdRewardSsvContext?> _buildMainApiAdSsvContext(String botId) {
    return buildMainApiAdSsvContext(
      botId: botId,
      resolveOwnerIds: () async {
        final app = await appManager.getApp(botId);
        final botToken = (app['token'] ?? '').toString().trim();
        if (botToken.isEmpty) {
          return null;
        }

        final session = await MainApiSettingsStore.loadSession();
        final ownerId = (session?.userId ?? '').trim();
        if (ownerId.isEmpty) {
          return null;
        }

        return BotAdSsvOwnerIds(ownerId: ownerId);
      },
    );
  }

  Future<void> _addHostingTime(String botId) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    try {
      final app = await appManager.getApp(botId);
      final botToken = (app['token'] ?? '').toString().trim();

      final rewarded = await _maybeOfferRewardedAd(
        botId: botId,
        botToken: botToken.isNotEmpty ? botToken : null,
        force: true,
        successMessage: context.tr.home_time_added,
      );
      if (rewarded && mounted) {
        unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.error_with_details(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _botIdInAction = null);
      }
    }
  }

  Future<bool> _isMainApiPremiumUser({
    required String botId,
    String? botToken,
  }) async {
    try {
      final remoteClient = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: botToken,
        attemptSessionRestore: true,
      ).timeout(const Duration(seconds: 4), onTimeout: () => null);

      return await SubscriptionService.canSkipRewardedAdsWithTimeout(
        client: remoteClient is MainApiClient ? remoteClient : null,
        forceRefresh: true,
        allowStoredManagerSession: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _maybeOfferRewardedAd({
    required String botId,
    String? botToken,
    bool force = false,
    bool adFundedByPlan = false,
    String? successMessage,
  }) async {
    if (!_supportsForegroundTask || !mounted) {
      return true;
    }

    // Un bot au-delà du quota tourne financé par pub, même sur un compte premium :
    // on ne saute donc pas l'étape pub pour lui (c'est sa source de temps).
    if (!adFundedByPlan &&
        await _isMainApiPremiumUser(botId: botId, botToken: botToken)) {
      return true;
    }

    if (!force && _displayFreeMinutesForBot(botId) > 0) {
      return true;
    }

    if (!AdRewardService.hasReadyRewardedAd) {
      // Try to load an ad on-demand and wait up to 4 seconds
      final loaded = await AdRewardService.ensureAdLoaded(
        timeout: const Duration(seconds: 4),
      );
      if (!loaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details(
                  context.tr.rewarded_start_no_ad_available,
                ),
              ),
            ),
          );
        }
        return false;
      }
    }

    if (!await AdRewardService.shouldOfferRewardedAd(
      checkPremiumCapability: false,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.ad_limit_or_cooldown,
            ),
          ),
        );
      }
      return false;
    }

    final consentGranted = await _ensureAdsConsent();
    if (!consentGranted && kReleaseMode) {
      return false;
    }
    if (!mounted) {
      return false;
    }

    final snapshotReady = await _ensureMainApiBotSnapshotForAd(botId);
    if (!snapshotReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.ad_sync_config_failed,
            ),
          ),
        );
      }
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to sync bot snapshot (/applications/@me).',
      );
      return false;
    }

    final ssvContext = await _buildMainApiAdSsvContext(botId);
    if (ssvContext == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.ad_context_failed,
            ),
          ),
        );
      }
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to resolve Discord owner via /applications/@me.',
      );
      return false;
    }

    var rewardEarned = false;
    final adShown = await AdRewardService.showRewardedAd(
      ssvContext: ssvContext,
      onRewardEarned: () async {
        rewardEarned = true;
      },
    );
    if (!adShown) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                context.tr.rewarded_start_no_ad_available,
              ),
            ),
          ),
        );
      }
      return false;
    }

    if (!rewardEarned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                context.tr.rewarded_start_complete_ad,
              ),
            ),
          ),
        );
      }
      return false;
    }

    final previousBalance = await _fetchMainApiRuntimeBalance(botId);

    // L'annonce est terminée, mais la RÉCOMPENSE n'est pas encore créditée : le
    // manager la valide de son côté (callback SSV), ce qui prend quelques
    // secondes. On le dit, au lieu d'annoncer un succès que personne ne peut
    // encore constater — l'ancien code affichait le message de succès à cet
    // instant précis et, si le crédit n'arrivait jamais, ne laissait qu'une ligne
    // de journal : l'utilisateur avait vu « merci » et n'avait rien reçu.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.rewarded_start_credit_pending)),
      );
    }

    unawaited(() async {
      final rewardCredited = await _waitForMainApiRewardCredit(
        botId: botId,
        previousBalance: previousBalance,
      );
      if (rewardCredited) {
        await _refreshBotRuntimeBalances(botIds: <String>[botId]);
      }
      if (!mounted) {
        return;
      }
      if (!rewardCredited) {
        appendBotDebugLog(
          'Reward credit still pending for $botId after ad completion; start flow continues with automatic manager retry.',
        );
      }
      // L'état RÉEL, à l'écran : le message de succès de l'appelant (par exemple
      // « minutes ajoutées ») n'est affiché QUE lorsque le crédit est constaté.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              rewardCredited
                  ? (successMessage ?? context.tr.rewarded_start_credit_confirmed)
                  : context.tr.rewarded_start_credit_unconfirmed,
            ),
          ),
        );
    }());

    await SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true);
    return mounted;
  }

  Future<bool> _ensureAdsConsent() async {
    final consentGranted = await AdConsentService.ensureCanRequestAds();
    if (!consentGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.ads_consent_refused_info)),
      );
    }
    return consentGranted;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  Object? _lastReportedStreamError;

  /// [StreamBuilder] errors only surface during build, so the log is deferred to
  /// the end of the frame (and deduplicated) instead of spamming every rebuild.
  void _reportStreamError(Object? error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || identical(error, _lastReportedStreamError)) return;
      _lastReportedStreamError = error;
      developer.log('Error loading data: $error', name: 'HomePage');
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: appManager.getAppStream(),
      initialData: appManager.isInitialized ? appManager.currentApps : null,
      builder: (context, snapshot) {
        // Un bot clé en main est un conteneur, pas un bot : une entrée locale
        // marquée comme telle (créée par une ancienne version de l'écran de
        // déploiement) n'est jamais une carte de bot. `AppManager` les supprime
        // au chargement ; ce filtre garantit qu'aucune ne repasse par la liste
        // des bots — donc par une synchronisation vers le manager — entre-temps.
        final apps = snapshot.data
            ?.where((app) => app is! Map || !AppManager.isTurnkeyAppEntry(app))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= AppTheme.desktopBreakpoint;
            final columns = isWide ? 2 : 1;
            // Largeur réellement rendue par [PageContent] : bornée par la
            // largeur commune puis réduite des marges de la zone disponible.
            final contentWidth = width > AppPageLayout.maxContentWidth
                ? AppPageLayout.maxContentWidth
                : width;
            final innerWidth =
                contentWidth - 2 * AppPageLayout.horizontalPaddingFor(width);

            void openCreate() {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppCreatePage()),
              );
            }

            final children = <Widget>[
              _HomeHeader(
                onRefresh: () {
                  unawaited(triggerRefresh());
                },
                onDocs: () {
                  openDocumentationHub(context, showDiscordJsTab: true);
                },
                onSettings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingPage()),
                  );
                },
                // Compact: create lives in the dashed CTA. Wide keeps a
                // header shortcut plus docs/settings (no bottom tabs).
                showCreate: isWide,
                showShellActions: isWide,
                onCreate: openCreate,
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<Announcement?>(
                valueListenable: AnnouncementPresenter.bannerNotifier,
                builder: (context, announcement, _) {
                  if (announcement == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AnnouncementBanner(
                      announcement: announcement,
                      onDismiss: AnnouncementPresenter.dismissBanner,
                    ),
                  );
                },
              ),
              _CreateBotCard(onTap: openCreate),
              const SizedBox(height: 20),
            ];

            if (snapshot.hasError) {
              _reportStreamError(snapshot.error);
              children.add(
                _buildHomeInfoCard(
                  context,
                  Icons.error_outline_rounded,
                  context.tr.app_loading_error,
                ),
              );
            } else if (apps == null) {
              children.add(
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (apps.isEmpty && _turnkeyContainers.isEmpty) {
              children.add(const _EmptyStateWithSupport());
            } else {
              if (AdsPlacementPolicy.isPlacementEnabled(
                    NativeAdPlacement.homeBots,
                  ) &&
                  apps.length >= AdsPlacementPolicy.listInterval) {
                children.add(
                  const NativeAdSlot(
                    placement: NativeAdPlacement.homeBots,
                    height: 118,
                    margin: EdgeInsets.only(bottom: 16),
                  ),
                );
              }

              // Deux sections : ce que je POSSÈDE, puis ce qu'on m'a PARTAGÉ. Le
              // partage ne vient jamais d'une heuristique locale : seuls les ids
              // annoncés par le serveur (`is_collaborative`) basculent, donc un
              // bot ne peut pas apparaître dans les deux sections.
              final appMaps = <Map<String, dynamic>>[
                for (final app in apps)
                  if (app is Map) Map<String, dynamic>.from(app),
              ];
              final split = splitHomeProjects(appMaps, _collaborativeBotIds);

              // Bots classiques puis conteneurs clé en main : les deux familles
              // partagent la même liste d'accueil (et le même layout ci-dessous).
              // Les conteneurs clé en main sont TOUJOURS à moi.
              final ownCards = buildHomeProjectCards(
                botCards: <Widget>[
                  for (final app in split.owned)
                    _buildRedesignBotCard(
                      context,
                      app,
                      // The primary action of a running bot stays visible without
                      // an extra tap on compact layouts.
                      initiallyExpanded:
                          isWide ||
                          _runningBotIds.contains(app['id']?.toString() ?? ''),
                    ),
                ],
                containers: _turnkeyContainers,
                actionsFor: _homeContainerActions,
              );

              final sharedCards = split.shared.isEmpty
                  ? const <Widget>[]
                  : buildHomeProjectCards(
                      botCards: <Widget>[
                        for (final app in split.shared)
                          _buildRedesignBotCard(
                            context,
                            app,
                            // Une carte partagée reste repliée : ses actions sont
                            // conditionnées par les droits accordés, pas par la
                            // largeur de l'écran.
                            initiallyExpanded: false,
                            shared: true,
                          ),
                      ],
                      containers: const <ContainerInfo>[],
                      actionsFor: _homeContainerActions,
                    );

              final sections = <({String title, List<Widget> cards})>[
                (title: context.tr.home_section_my_bots, cards: ownCards),
                if (sharedCards.isNotEmpty)
                  (
                    title: context.tr.home_section_shared_with_me,
                    cards: sharedCards,
                  ),
              ];

              for (var index = 0; index < sections.length; index++) {
                if (index > 0) {
                  children.add(const SizedBox(height: 28));
                }
                children.add(_HomeSectionTitle(label: sections[index].title));
                _addHomeCards(
                  children,
                  sections[index].cards,
                  columns,
                  innerWidth,
                );
              }
            }

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () async {
                await syncAllBotsFromManager(silent: false);
                // Un tirage rafraîchit aussi l'état des conteneurs clé en main
                // (démarrage/arrêt/expiration), une requête pour tous.
                await _refreshTurnkeyContainers();
              },
              // Largeur et marges communes à toutes les pages de l'app : la
              // liste n'impose plus ses propres bornes (1000/640, sidePad 28).
              child: PageContent(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    24,
                    0,
                    isWide
                        ? 40
                        : FloatingGlassNavBar.contentClearanceOf(context) + 24,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: children,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Actions d'une carte de conteneur clé en main (identiques avant/après la
  /// séparation en sections : cette extraction ne change AUCUN comportement).
  HomeContainerActions _homeContainerActions(ContainerInfo container) =>
      HomeContainerActions(
        busy: _containerIdInAction == container.id,
        onStart: () => _toggleTurnkeyContainer(container, start: true),
        onStop: () => _toggleTurnkeyContainer(container, start: false),
        onLogs: () => _openTurnkeyContainerLogs(container),
        onDetail: () => _openTurnkeyContainerDetail(container),
        onInvite: () => _inviteTurnkeyBot(container),
        inviteBusy: _inviteContainerIdInAction == container.id,
      );

  /// Range les cartes d'une section : une colonne en compact, la grille à deux
  /// colonnes en large — exactement le layout d'avant, partagé par « My bots »
  /// et « Shared with me » pour qu'ils ne puissent pas diverger.
  void _addHomeCards(
    List<Widget> children,
    List<Widget> cards,
    int columns,
    double innerWidth,
  ) {
    if (columns == 1) {
      for (var i = 0; i < cards.length; i++) {
        children.add(
          Padding(
            padding: EdgeInsets.only(bottom: i == cards.length - 1 ? 0 : 20),
            child: cards[i],
          ),
        );
      }
      return;
    }
    const gap = 20.0;
    final cardWidth = (innerWidth - (columns - 1) * gap) / columns;
    children.add(
      Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final card in cards) SizedBox(width: cardWidth, child: card),
        ],
      ),
    );
  }

  Widget _buildRedesignBotCard(
    BuildContext context,
    dynamic app, {
    required bool initiallyExpanded,
    bool shared = false,
  }) {
    final id = app['id']?.toString() ?? '';
    final rawName = app['name']?.toString().sanitizedUtf16 ?? '';
    final name = (rawName.isNotEmpty && !botNameHidesIdentity(rawName, id))
        ? rawName
        : context.tr.home_unknown_app;
    final avatar = app['avatar']?.toString();
    final guildCount = switch (app['guild_count'] ??
        app['approximate_guild_count']) {
      final int value => value,
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };
    final isRunning = _runningBotIds.contains(id);
    // Droits de l'utilisateur sur un bot PARTAGÉ, tels que le serveur les
    // annonce (`my_permissions`). `null` = droits INCONNUS (serveur plus ancien,
    // hors ligne) : on n'offre alors aucune action que le propriétaire n'a
    // peut-être pas accordée — le refus par défaut, jamais l'inverse.
    final permissions = shared ? _sharedBotPermissions[id] : null;
    final canEdit = !shared || (permissions?.canEditCommands ?? false);
    final canStartStop = !shared || (permissions?.canStartStop ?? false);
    final canToggle = _botIdInAction == null && canStartStop;
    // Nom du propriétaire : uniquement une INFORMATION, reçue du serveur.
    final ownerId = shared ? (_sharedBotOwnerIds[id] ?? '') : '';
    // Controllers are created by the app-stream listener, never during build.
    final pulseCtrl = _pulseControllers[id] ?? _fallbackPulseController;
    // Source d'exécution VIVANTE de ce bot (association + état annoncé par le
    // serveur), décidée par la brique partagée `bot_run_source.dart` — la page de
    // détail d'un bot l'interroge aussi. `null` sur mobile : l'affichage
    // historique y est conservé tel quel.
    final runOrigin = desktopBotRunOrigin(
      botId: id,
      serverReportsRunning: isRunning,
    );
    // Un bot exécuté par ce poste ne consomme pas le solde cloud : on ne laisse
    // donc AUCUNE valeur de solde descendre jusqu'à la carte, sinon une ligne
    // d'expiration pourrait réapparaître sans que la source soit cloud.
    final showsHostingExpiration =
        runOrigin == null || runOrigin.isHostedRemotely;
    final freeMinutes = showsHostingExpiration
        ? _displayFreeMinutesForBot(id)
        : 0;

    final isTurnkey =
        app['is_turnkey'] == true ||
        app['type'] == 'turnkey' ||
        (app['container_id']?.toString().isNotEmpty ?? false);
    final containerId = app['container_id']?.toString();
    // Un bot sans jeton local est inexploitable (le manager rédige le sien dans
    // ses listes) : c'est aussi le seul cas où l'import depuis le compte a
    // quelque chose à faire.
    final hasLocalToken = (app['token'] ?? '').toString().trim().isNotEmpty;

    return HomeBotCard(
      key: ValueKey<String>(id),
      name: name,
      id: id,
      avatar: avatar,
      guildCount: guildCount,
      isRunning: isRunning,
      canToggle: canToggle,
      isTogglingThisBot: _botIdInAction == id,
      initiallyExpanded: initiallyExpanded,
      runtimeBadgeLabel: runOrigin == null
          // Mobile : badge historique, seulement quand le bot tourne.
          ? (isRunning ? _runtimeBadgeLabel(id) : null)
          : botRunSourceLabel(context.tr, runOrigin),
      freeMinutes: freeMinutes,
      showsHostingExpiration: showsHostingExpiration,
      pulseController: pulseCtrl,
      showPremiumLabels: _supportsForegroundTask,
      isTurnkey: isTurnkey,
      // Un bot partagé porte le badge d'équipe et le nom de son propriétaire ;
      // un bot à moi garde EXACTEMENT l'affichage d'avant.
      showTeamBadge: shared,
      ownerLabel: ownerId.isEmpty ? null : ownerId,
      onManage: canEdit
          ? () {
              if (isTurnkey && containerId != null && containerId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ContainerDetailPage(containerId: containerId),
                  ),
                ).then((_) => _initRunningState());
                return;
              }
              final parsedId = int.tryParse(id) ?? 0;
              final manage = widget.onManageBot;
              if (manage != null) {
                manage(id, name);
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AppEditPage(
                    appName: name,
                    id: parsedId,
                    avatarUrl: avatar,
                  ),
                ),
              ).then((_) => _initRunningState());
            }
          // Sans droit d'édition, le bouton n'existe PAS (plutôt qu'un bouton
          // désactivé qui laisserait croire qu'il suffit d'insister).
          : null,
      // Le tchat d'équipe est l'USAGE PRINCIPAL d'un collaborateur, et le serveur
      // le lui accorde par défaut (`can_view_chat`) : son accès ne dépend donc
      // d'AUCUN droit d'édition — sinon un collaborateur sans `can_edit_commands`
      // se retrouverait sans le moindre chemin vers son équipe. « Gérer », lui,
      // reste conditionné par `can_edit_commands` (voir `onManage` ci-dessus).
      onTeam: !shared
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TeamChatPage(botId: id)),
            ),
      onToggle: () => _toggleBot(botId: id, botName: name),
      // Ajouter du temps engage de l'argent : jamais sur le bot d'un autre.
      onAddTime: shared ? null : () => _addHostingTime(id),
      onLogs: isRunning
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BotLogsPage(botId: id)),
            )
          : null,
      hasLocalToken: hasLocalToken,
      onTokenImported: () async {
        // Le jeton est écrit en local : les états de la carte (jeton présent,
        // exécution possible) se rechargent, comme après un « gérer ».
        if (!mounted) return;
        await _initRunningState();
      },
    );
  }

  Widget _buildHomeInfoCard(
    BuildContext context,
    IconData icon,
    String message,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── En-tête d'accueil ─────────────────────────────────────────────────────────

/// En-tête de section de la liste d'accueil (« MY BOTS », « SHARED WITH ME ») :
/// le MÊME style que le surtitre « MY PROJECTS » ([homeSectionLabelStyle]), donc
/// aucune hiérarchie visuelle inventée pour la séparation.
class _HomeSectionTitle extends StatelessWidget {
  const _HomeSectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: homeSectionLabelStyle(context)),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onRefresh,
    required this.onDocs,
    required this.onSettings,
    required this.onCreate,
    this.showCreate = true,
    this.showShellActions = true,
  });

  final VoidCallback onRefresh;
  final VoidCallback onDocs;
  final VoidCallback onSettings;
  final VoidCallback onCreate;
  final bool showCreate;
  final bool showShellActions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.home_overline,
                style: homeSectionLabelStyle(context),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr.app_title,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.getFont(
                    'Alexandria',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.22,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (showCreate) ...[
          HomeHeaderIconButton(
            icon: Icons.add_rounded,
            iconSize: 16,
            tooltip: context.tr.app_create_button,
            onTap: onCreate,
          ),
          const SizedBox(width: 10),
        ],
        HomeHeaderIconButton(
          icon: Icons.sync_rounded,
          iconSize: 13,
          tooltip: context.tr.common_refresh,
          onTap: onRefresh,
        ),
        if (showShellActions) ...[
          const SizedBox(width: 10),
          HomeHeaderIconButton(
            icon: Icons.menu_book_outlined,
            iconSize: 16,
            tooltip: context.tr.docs_hub_title,
            onTap: onDocs,
          ),
          const SizedBox(width: 10),
          HomeHeaderIconButton(
            icon: Icons.settings_outlined,
            iconSize: 16,
            tooltip: context.tr.settings_tab,
            onTap: onSettings,
          ),
        ],
      ],
    );
  }
}

// ── Carte bot (collapsible) ───────────────────────────────────────────────────

/// Carte d'accueil d'un bot classique (repliable) : avatar, serveurs, état et
/// actions (démarrer/arrêter, gérer, logs).
///
/// Publique — et non privée — pour que le test de la liste d'accueil monte la
/// vraie carte d'un bot classique À CÔTÉ de celle d'un conteneur clé en main
/// ([buildHomeProjectCards]), c'est-à-dire la composition réellement rendue.
class HomeBotCard extends StatefulWidget {
  const HomeBotCard({
    super.key,
    required this.name,
    required this.id,
    required this.avatar,
    required this.guildCount,
    required this.isRunning,
    required this.canToggle,
    required this.isTogglingThisBot,
    required this.initiallyExpanded,
    required this.pulseController,
    required this.onManage,
    required this.onToggle,
    required this.onAddTime,
    required this.onLogs,
    required this.showPremiumLabels,
    required this.freeMinutes,
    this.onTeam,
    this.runtimeBadgeLabel,
    this.showsHostingExpiration = true,
    this.isTurnkey = false,
    this.showTeamBadge = false,
    this.ownerLabel,
    this.hasLocalToken = true,
    this.onTokenImported,
  });

  final String name;
  final String id;
  final String? avatar;
  final int guildCount;
  final bool isRunning;
  final bool canToggle;
  final bool isTogglingThisBot;
  final bool initiallyExpanded;
  final String? runtimeBadgeLabel;
  final int freeMinutes;

  /// Faut-il afficher la ligne d'expiration / de réserve d'hébergement ?
  ///
  /// Vrai par défaut (affichage historique, notamment mobile). Un écran d'un
  /// poste de travail le passe à `false` dès que la source d'exécution n'est pas
  /// les serveurs Bot Creator : un bot qui tourne ICI ne consomme pas le solde
  /// cloud, donc afficher « Expire le … » serait un mensonge — c'est exactement
  /// le défaut signalé par le propriétaire (échéance en 2038 sur un bot local).
  final bool showsHostingExpiration;

  final AnimationController pulseController;
  final bool showPremiumLabels;
  final bool isTurnkey;

  /// Badge « équipe » : vrai sur une carte PARTAGÉE (le bot ne m'appartient pas).
  /// Faux par défaut, donc une carte à moi ne change pas d'un pixel.
  final bool showTeamBadge;

  /// Propriétaire du bot, quand la carte doit le nommer (bot partagé). `null`
  /// quand le serveur ne l'a pas annoncé : la ligne entière disparaît plutôt que
  /// d'afficher un libellé inventé.
  final String? ownerLabel;

  final VoidCallback? onManage;

  /// Ouvre le tchat d'équipe du bot. Renseigné sur une carte PARTAGÉE
  /// uniquement : le collaborateur garde ainsi un chemin vers son équipe même
  /// sans droit d'édition. `null` sur une carte « à moi », qui garde donc
  /// exactement ses actions d'avant.
  final VoidCallback? onTeam;

  final VoidCallback onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onLogs;

  /// Faux quand ce poste n'a AUCUN jeton utilisable pour ce bot : c'est la
  /// seule situation où « Importer le jeton depuis mon compte » a quelque
  /// chose à faire, donc la seule où le bouton est offert.
  final bool hasLocalToken;

  /// Relais après un import RÉUSSI depuis la carte (l'accueil se recharge).
  final Future<void> Function()? onTokenImported;

  @override
  State<HomeBotCard> createState() => HomeBotCardState();
}

class HomeBotCardState extends State<HomeBotCard> {
  bool _hovered = false;
  late bool _expanded = widget.initiallyExpanded;
  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;

  @override
  void didUpdateWidget(covariant HomeBotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Realign on the layout-driven default when the window width changes
    // (desktop resize / rotation).
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String _startLabel(BuildContext context) {
    if (widget.isRunning) return context.tr.home_stop;
    if (!widget.showPremiumLabels) return context.tr.bot_home_start;
    if (SubscriptionService.isSubscribed) return context.tr.home_start_premium;
    if (widget.freeMinutes > 0) return context.tr.bot_home_start;
    return context.tr.home_start_ads;
  }

  String _serverCountLabel(BuildContext context) {
    final count = widget.guildCount;
    return count == 1
        ? context.tr.home_active_on_servers_one(count)
        : context.tr.home_active_on_servers_other(count);
  }

  /// Ajouter du temps n'a de sens que pour un bot réellement en marche, et
  /// seulement sur les plateformes capables d'héberger la tâche de fond. Un
  /// poste de travail n'a aucun concept d'hébergement : l'action n'y est jamais
  /// proposée.
  bool get _showAddHosting {
    if (!widget.isRunning) return false;
    if (!_supportsForegroundTask) return false;
    return !SubscriptionService.isSubscribed;
  }

  /// Ligne d'échéance de l'hébergement (« Expire le … ») ou de réserve en pause.
  ///
  /// N'est appelée que lorsque la ligne a le droit d'exister : un solde cloud
  /// converti en date n'a de sens que pour un bot exécuté par les serveurs.
  String _hostingExpirationLabel(BuildContext context) {
    if (widget.freeMinutes <= 0) {
      return context.tr.home_hosting_status_paused;
    }
    final expiresAt = DateTime.now().add(Duration(minutes: widget.freeMinutes));
    return formatSessionExpiration(context, expiresAt);
  }

  Widget _buildExpandedContent(BuildContext context, ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    // Ligne d'échéance / de réserve : absente du layout dès que la source n'est
    // pas les serveurs Bot Creator (`null` = rien à afficher, la ligne entière
    // disparaît — voir `_ServerPresenceRow`).
    final String? expirationLabel = widget.showsHostingExpiration
        ? _hostingExpirationLabel(context)
        : null;
    // La source vivante (« Ce poste », « Serveurs Bot Creator ») porte l'état ;
    // sans source, on retombe sur l'ancien libellé mobile.
    final badge =
        widget.runtimeBadgeLabel ??
        (widget.isRunning ? context.tr.home_synced_active : null);
    final String? statusLabel;
    if (badge == null) {
      statusLabel = expirationLabel;
    } else {
      statusLabel = expirationLabel == null
          ? badge
          : '$badge • $expirationLabel';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? tokens.cardBorder : scheme.outlineVariant,
        ),
        const SizedBox(height: 16),
        _ServerPresenceRow(
          botId: widget.id,
          guildCount: widget.guildCount,
          title: _serverCountLabel(context),
          statusLabel: statusLabel,
          isRunning: widget.isRunning,
        ),
        if (widget.showPremiumLabels && SubscriptionService.isSubscribed) ...[
          const SizedBox(height: 10),
          _InfoChip(
            icon: Icons.all_inclusive_rounded,
            value: context.tr.hosted_app_subscription_benefit_unlimited,
            badge: true,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HomeCardActionButton(
                icon: widget.isRunning
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                label: _startLabel(context),
                onTap: widget.canToggle ? widget.onToggle : null,
                loading: widget.isTogglingThisBot,
                accent: widget.isRunning ? AppTheme.danger : null,
                stopSquare: widget.isRunning,
              ),
            ),
            if (widget.onManage != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: HomeCardActionButton(
                  icon: Icons.tune_rounded,
                  iconSize: 14,
                  label: context.tr.home_manage,
                  onTap: widget.onManage,
                ),
              ),
            ],
            // Chemin vers l'équipe : offert même sans droit d'édition, c'est
            // l'usage principal d'un collaborateur. MÊME libellé que l'onglet du
            // même nom dans l'éditeur du bot.
            if (widget.onTeam != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: HomeCardActionButton(
                  icon: Icons.groups_outlined,
                  iconSize: 14,
                  label: context.tr.team_tab,
                  onTap: widget.onTeam,
                ),
              ),
            ],
          ],
        ),
        if (_showAddHosting) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: HomeCardActionButton(
              icon: Icons.add_rounded,
              iconSize: 14,
              label: context.tr.home_add_time,
              onTap: widget.canToggle ? widget.onAddTime : null,
            ),
          ),
        ],
        if (widget.onLogs != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: HomeCardActionButton(
              icon: Icons.article_outlined,
              iconSize: 14,
              label: context.tr.home_logs_tooltip,
              onTap: widget.onLogs,
            ),
          ),
        ],
        // La reprise du jeton est devenue AUTOMATIQUE (synchro + démarrage sur ce poste) :
        // offrir un bouton « Importer le jeton depuis mon compte » obligeait l'utilisateur
        // à comprendre un détail d'implémentation pour que son bot démarre. Il ne reste
        // donc aucun geste à faire ici, pas même quand ce poste n'a aucun jeton.
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final cardColor = isDark ? tokens.card : scheme.surfaceContainer;
    final borderColor = isDark ? tokens.cardBorder : scheme.outlineVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: borderColor),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HomeBotAvatar(imageUrl: widget.avatar),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: homeDisplayStyle(
                                      16,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (widget.isTurnkey) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: scheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      homeUiCopy(
                                        context,
                                        fr: 'Clé en main',
                                        en: 'Turnkey',
                                      ),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.showTeamBadge) ...[
                                  const SizedBox(width: 8),
                                  const _SharedBotBadge(),
                                ],
                              ],
                            ),
                            if (widget.ownerLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.ownerLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? tokens.muted
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      HomeStatusPill(
                        isRunning: widget.isRunning,
                        pulseController: widget.pulseController,
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: isDark ? tokens.muted : scheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildExpandedContent(context, scheme),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge « équipe » d'une carte PARTAGÉE : ce bot appartient à quelqu'un d'autre.
///
/// Libellé pris dans l'i18n (`team_tab_short`) plutôt qu'écrit en dur : une UI
/// française n'affiche pas un mot anglais figé.
class _SharedBotBadge extends StatelessWidget {
  const _SharedBotBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.discord.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.discord.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, size: 11, color: AppTheme.discord),
          const SizedBox(width: 4),
          Text(
            context.tr.team_tab_short,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.discord,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.value,
    this.badge = false,
  });

  final IconData icon;
  final String value;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badge
            ? tokens.dataAccent.withValues(alpha: 0.12)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: badge
              ? tokens.dataAccent.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: badge ? tokens.dataAccent : tokens.muted),
          const SizedBox(width: 5),
          Flexible(
            child: RichText(
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.dataAccent,
                ),
                text: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state avec CTA support ──────────────────────────────────────────

class _EmptyStateWithSupport extends StatelessWidget {
  const _EmptyStateWithSupport();

  static const _discordUrl = 'https://discord.gg/gyEGNBUZdA';
  static const _discordColor = AppTheme.discord;

  Future<void> _openDiscord() async {
    final uri = Uri.parse(_discordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr.app_no_apps,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            context.tr.home_empty_support_hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openDiscord,
            icon: const Icon(Icons.forum_rounded, size: 18),
            label: Text(context.tr.home_empty_support_btn),
            style: FilledButton.styleFrom(
              backgroundColor: _discordColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

@visibleForTesting
class CreateBotCard extends StatelessWidget {
  const CreateBotCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final fill = isDark
        ? tokens.accent.withValues(alpha: 0.30)
        : scheme.surfaceContainerHighest;
    final border = isDark ? tokens.accent : scheme.primary;
    final avatarFill = tokens.accent;
    final avatarIconColor = isDark ? Colors.white : tokens.onAccent;

    return Stack(
      children: [
        Material(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: avatarFill,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 26,
                      color: avatarIconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.home_create_bot_title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeDisplayStyle(16, color: scheme.onSurface),
                        ),
                        Text(
                          context.tr.home_create_bot_subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: homeDisplayStyle(
                            12,
                            weight: FontWeight.w400,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.30)
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isDark
                        ? tokens.muted
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: HomeDashedRoundedRectPainter(
                color: border,
                radius: AppTheme.radiusCard,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

typedef _CreateBotCard = CreateBotCard;

class _ServerPresenceRow extends StatelessWidget {
  const _ServerPresenceRow({
    required this.botId,
    required this.guildCount,
    required this.title,
    required this.statusLabel,
    required this.isRunning,
  });

  /// Id du bot : sert à résoudre les vrais serveurs (cache gateway puis REST).
  final String botId;
  final int guildCount;
  final String title;
  final String? statusLabel;
  final bool isRunning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final clusterBg = isDark ? tokens.clusterBg : scheme.surfaceContainerLow;
    final clusterBorder = isDark ? tokens.clusterBorder : scheme.outlineVariant;
    // Serveurs réels du bot qui tourne dans ce processus (synchrone, gratuit).
    // `null`/vide hors desktop ou bot à l'arrêt : `GuildAvatarStrip` bascule
    // alors sur la *source partagée de session* (`GuildDirectory`, la même que
    // la page « Serveurs ») puis sur le repli neutre. Une seule requête HTTP
    // par bot et par lancement de l'app ; l'état `loading` affiche le repli
    // discret, et les avatars apparaissent ensuite sans re-fetch.
    final localGuilds = guildAvatarsFromGateway(
      desktopGatewayForBot(botId),
      limit: kMaxVisibleGuildAvatars,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: clusterBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: clusterBorder),
      ),
      child: Row(
        children: [
          GuildAvatarStrip(
            botId: botId,
            guildCount: guildCount,
            guilds: localGuilds,
            ringColor: clusterBg,
            // Source unique de vérité de la session : la page « Serveurs »
            // écrit dans ce même répertoire, la carte ne refait donc jamais
            // de requête pour afficher ses avatars.
            directory: GuildDirectory.instance,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? tokens.dataAccent
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isRunning ? AppTheme.online : tokens.muted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          statusLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: isDark
                                ? tokens.muted
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BotSyncResult {
  const _BotSyncResult({
    required this.botId,
    required this.botName,
    required this.token,
    required this.config,
    required this.guildCount,
    this.avatarHash,
    this.discriminator,
  });

  final String botId;
  final String botName;
  final String token;
  final Map<String, dynamic> config;
  final int? guildCount;
  final String? avatarHash;
  final String? discriminator;
}
