// Avatars de serveurs (guilds) affichés dans la carte bot de la Home.
//
// Avant : `_ServerPresenceRow` (home_page.dart) dessinait des lettres tirées
// d'une *seed* — le nom du bot — ce qui donnait « B » / « O » sur une ligne
// « Actif sur N serveurs ». Ces lettres n'avaient aucun rapport avec les vrais
// serveurs Discord du bot.
//
// Ici on affiche les vraies icônes, depuis deux sources réelles :
//
//   * le cache du gateway du bot qui tourne *dans ce processus*
//     (`desktopGatewayForBot(botId).guilds.cache` → objets `Guild` complets,
//     avec `name` et `iconHash`) : synchrone, gratuit, prioritaire ;
//   * à défaut, l'API REST `GET /users/@me/guilds` avec le token du bot
//     (même endpoint que `core/utils/global.dart#getDiscordBotGuildCount`),
//     résultat mis en cache pour toute la session.
//
// Aucune donnée inventée : si aucune des deux sources ne fournit de serveur on
// affiche un repli neutre (icône serveur), jamais une lettre issue d'une seed.
// Si le nom du serveur est connu mais pas son icône, on affiche sa vraie
// initiale.
//
// Cache (demande produit : « actualisation des serveurs au chargement puis
// caching jusqu'au redémarrage de l'app ») :
//
//   * `GuildDirectory` est la *source unique de vérité* de la session : une
//     entrée chargée reste valide jusqu'au redémarrage (plus de TTL), la carte
//     bot de la Home et la page « Serveurs » lisent le même état observable
//     (`ValueListenable<GuildsLoadState>`) et ne déclenchent donc qu'une seule
//     requête HTTP par bot et par session ;
//   * seul `GuildDirectory.refresh` force une nouvelle requête (bouton
//     « Actualiser », tirer-pour-rafraîchir, après « quitter le serveur ») ;
//   * les octets des icônes sont, eux, conservés *sur disque* entre deux
//     lancements par `core/network/image_disk_cache.dart` (les avatars ne
//     repassent plus par le CDN à chaque démarrage).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/global.dart' show discordUrl;
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;

/// Nombre maximum d'avatars de serveurs dessinés sur une carte bot.
const int kMaxVisibleGuildAvatars = 2;

/// Base du CDN Discord (les icônes de serveurs y sont servies).
const String discordCdnBaseUrl = 'https://cdn.discordapp.com';

/// Taille d'image demandée au CDN pour un cercle de 36 px (marge 2x/3x).
const int kGuildIconRequestSize = 128;

/// Un serveur Discord, réduit à ce dont la carte bot et la page « Serveurs »
/// ont besoin.
@immutable
class GuildAvatarInfo {
  const GuildAvatarInfo({
    required this.id,
    this.name,
    this.iconHash,
    this.isOwner = false,
    this.memberCount,
  });

  /// Identifiant (snowflake) du serveur.
  final String id;

  /// Nom du serveur, quand la source le fournit.
  final String? name;

  /// Hash de l'icône du serveur, `null` si le serveur n'a pas d'icône.
  final String? iconHash;

  /// Vrai quand le bot est propriétaire du serveur (`owner` de l'API REST).
  final bool isOwner;

  /// Nombre approximatif de membres, quand l'API le fournit
  /// (`with_counts=true`) — `null` sinon.
  final int? memberCount;

  /// URL CDN résolue, ou `null` quand aucune icône n'est connue.
  String? get iconUrl => discordGuildIconUrl(id, iconHash);

  @override
  bool operator ==(Object other) =>
      other is GuildAvatarInfo &&
      other.id == id &&
      other.name == name &&
      other.iconHash == iconHash &&
      other.isOwner == isOwner &&
      other.memberCount == memberCount;

  @override
  int get hashCode => Object.hash(id, name, iconHash, isOwner, memberCount);
}

/// URL CDN de l'icône d'un serveur, ou `null` si elle est indéterminable.
///
/// Fonction pure (aucun réseau) : c'est le contrat d'URL de ce fichier, donc
/// directement testable. `discordtest` renvoie un `hash` qui commence par `a_`
/// pour les icônes animées → `.gif`, sinon `.png`.
String? discordGuildIconUrl(
  String? guildId,
  String? iconHash, {
  int size = kGuildIconRequestSize,
}) {
  final id = guildId?.trim() ?? '';
  final hash = iconHash?.trim() ?? '';
  if (id.isEmpty || hash.isEmpty) return null;
  // Un id de serveur est une snowflake : uniquement des chiffres. Toute autre
  // valeur est une donnée corrompue qu'on préfère ignorer (→ repli).
  if (!RegExp(r'^[0-9]+$').hasMatch(id)) return null;
  final extension = hash.startsWith('a_') ? 'gif' : 'png';
  return '$discordCdnBaseUrl/icons/$id/$hash.$extension?size=$size';
}

/// Initiale du nom d'un serveur, ou `null` si le nom est inconnu/vide.
String? guildAvatarInitial(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  // `runes` évite de couper une paire de substitution (emoji) en deux.
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// Ordre d'affichage déterministe : par id croissant (plus ancien en premier).
///
/// Nécessaire car l'ordre du cache du gateway (LRU) et celui de l'API REST ne
/// sont pas stables : sans tri, les deux avatars pourraient permuter d'un
/// rebuild à l'autre.
List<GuildAvatarInfo> sortGuildsForDisplay(List<GuildAvatarInfo> guilds) {
  final sorted = <GuildAvatarInfo>[...guilds]
    ..sort((a, b) => _compareSnowflakeIds(a.id, b.id));
  return List<GuildAvatarInfo>.unmodifiable(sorted);
}

int _compareSnowflakeIds(String a, String b) {
  if (a.length != b.length) return a.length.compareTo(b.length);
  return a.compareTo(b);
}

/// Nombre de cercles à dessiner dans la ligne de présence.
///
/// Les vrais serveurs connus gagnent ; sinon on garde la silhouette
/// historique (1 ou 2 cercles) pilotée par le seul compteur.
int guildPresenceSlotCount({
  required int guildCount,
  required int knownGuilds,
}) {
  var slots = knownGuilds > 0 ? knownGuilds : (guildCount >= 2 ? 2 : 1);
  if (guildCount > 0 && slots > guildCount) slots = guildCount;
  if (slots < 1) slots = 1;
  if (slots > kMaxVisibleGuildAvatars) slots = kMaxVisibleGuildAvatars;
  return slots;
}

/// Serveurs d'un gateway nyxx déjà connecté (bot tournant dans ce processus).
///
/// `gateway.guilds.cache` contient les vrais objets `Guild` dès que le bot a
/// reçu `GUILD_CREATE` : eux seuls exposent `name` et `iconHash`.
/// (`client.guilds[id]` renvoie un `PartialGuild` qui ne porte que l'`id` — y
/// accéder lèverait un `NoSuchMethodError` : d'où le `try` défensif ci-dessous.)
///
/// Synchrone et sans réseau : appelable directement depuis `build()`.
List<GuildAvatarInfo> guildAvatarsFromGateway(
  NyxxGateway? gateway, {
  int limit = kMaxVisibleGuildAvatars,
}) {
  if (gateway == null) return const <GuildAvatarInfo>[];
  final guilds = <GuildAvatarInfo>[];
  for (final guild in gateway.guilds.cache.values) {
    try {
      guilds.add(
        GuildAvatarInfo(
          id: guild.id.toString(),
          name: guild.name,
          iconHash: guild.iconHash,
        ),
      );
    } catch (_) {
      // Entrée de cache non exploitable (guild indisponible / partielle) :
      // on l'ignore, la ligne gardera son repli.
    }
  }
  return sortGuildsForDisplay(guilds).take(limit).toList(growable: false);
}

/// Parse la charge utile de `GET /users/@me/guilds`.
///
/// Tolérant par construction : une entrée sans `id` est ignorée, et une charge
/// utile illisible renvoie une liste vide (→ repli neutre, jamais d'exception).
/// `owner` et `approximate_member_count` (endpoint appelé en `with_counts`)
/// sont conservés quand ils sont présents — la page « Serveurs » les affiche.
List<GuildAvatarInfo> parseGuildsApiPayload(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is! List) return const <GuildAvatarInfo>[];
    final guilds = <GuildAvatarInfo>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final id = (entry['id'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final name = (entry['name'] ?? '').toString();
      final icon = entry['icon']?.toString();
      final members = entry['approximate_member_count'];
      guilds.add(
        GuildAvatarInfo(
          id: id,
          name: name.isEmpty ? null : name,
          iconHash: (icon == null || icon.isEmpty) ? null : icon,
          isOwner: entry['owner'] == true,
          memberCount: members is int ? members : null,
        ),
      );
    }
    return sortGuildsForDisplay(guilds);
  } catch (_) {
    return const <GuildAvatarInfo>[];
  }
}

/// Statut de chargement des serveurs d'un bot pour la session en cours.
enum GuildsLoadStatus {
  /// Aucune requête demandée dans cette session.
  idle,

  /// Une requête est en vol.
  loading,

  /// Liste disponible ([GuildsLoadState.guilds] peut être vide si le bot
  /// n'a réellement aucun serveur).
  loaded,

  /// Dernière tentative en échec ; aucune entrée de session n'a été posée,
  /// donc un prochain chargement retentera.
  error,
}

/// État observable des serveurs d'un bot (une entrée par bot et par session).
///
/// C'est l'objet partagé entre la carte bot de la Home et la page
/// « Serveurs » : les deux s'abonnent au même [ValueListenable] et n'affichent
/// jamais deux vérités différentes.
@immutable
class GuildsLoadState {
  const GuildsLoadState({
    required this.status,
    this.guilds = const <GuildAvatarInfo>[],
    this.errorMessage,
  });

  /// État initial : rien de chargé, aucune requête en cours.
  static const GuildsLoadState idle = GuildsLoadState(
    status: GuildsLoadStatus.idle,
  );

  final GuildsLoadStatus status;

  /// Serveurs connus ; vide tant qu'aucun chargement n'a abouti.
  final List<GuildAvatarInfo> guilds;

  /// Détail *technique* du dernier échec (jamais un libellé d'interface :
  /// les écrans l'affichent via une clé i18n générique).
  final String? errorMessage;

  /// Vrai pendant qu'une requête est en vol.
  bool get isLoading => status == GuildsLoadStatus.loading;

  /// Vrai quand la liste a été chargée avec succès pour cette session.
  bool get isLoaded => status == GuildsLoadStatus.loaded;

  @override
  bool operator ==(Object other) =>
      other is GuildsLoadState &&
      other.status == status &&
      other.errorMessage == errorMessage &&
      listEquals(other.guilds, guilds);

  @override
  int get hashCode => Object.hash(status, errorMessage, Object.hashAll(guilds));

  @override
  String toString() =>
      'GuildsLoadState(${status.name}, ${guilds.length} serveur(s))';
}

/// Charge et met en cache les serveurs d'un bot via l'API REST Discord.
///
/// Le token n'est pas disponible dans la liste d'apps streamée par la Home
/// (`getAllApps()` n'expose que `id`/`name`/`avatar`/`guild_count`) : il est
/// relu depuis `AppManager.getApp()`, qui va le chercher dans le stockage
/// sécurisé (même chemin que l'ancienne page « Serveurs »).
///
/// Sémantique de session (« jusqu'au redémarrage de l'app ») :
///
///   * [load] sert l'entrée de session si elle existe, sinon lance *une*
///     requête — jamais une par rebuild, par carte ou par montage d'écran ;
///   * [refresh] force une requête (l'entrée de session est remplacée au
///     succès) ;
///   * un échec n'est pas mis en cache : le chargement suivant retente ;
///   * rien n'est écrit sur disque (la liste reste en mémoire, ce que
///     « jusqu'au redémarrage » demande exactement).
///
/// Toutes les dépendances (résolution du token, transport HTTP, endpoint)
/// sont injectables : la sémantique du cache est ainsi testable sans réseau.
class GuildDirectory {
  GuildDirectory({
    Future<String?> Function(String botId)? tokenResolver,
    Future<String?> Function(String endpoint, String token)? httpGet,
    String? guildsEndpoint,
  }) : _customTokenResolver = tokenResolver,
       _httpGet = httpGet ?? _httpGetFromDiscord,
       _guildsEndpoint = guildsEndpoint ?? _defaultGuildsEndpoint;

  /// Instance partagée par la Home et la page « Serveurs ».
  static final GuildDirectory instance = GuildDirectory();

  /// Endpoint REST des serveurs du bot. `with_counts=true` fournit
  /// `approximate_member_count` (et `owner` est renvoyé dans tous les cas) :
  /// la page « Serveurs » garde ainsi ses compteurs sans seconde requête.
  static const String _defaultGuildsEndpoint =
      '$discordUrl/users/@me/guilds?with_counts=true';

  static const Duration _requestTimeout = Duration(seconds: 8);

  /// Résolveur de token injecté (tests) ; sinon stockage sécurisé de l'app.
  final Future<String?> Function(String botId)? _customTokenResolver;
  final Future<String?> Function(String endpoint, String token) _httpGet;
  final String _guildsEndpoint;

  /// Entrées de session : une liste chargée reste valide jusqu'au
  /// redémarrage de l'app (aucune expiration, aucun TTL).
  final Map<String, List<GuildAvatarInfo>> _cache =
      <String, List<GuildAvatarInfo>>{};

  final Map<String, Future<List<GuildAvatarInfo>>> _inFlight =
      <String, Future<List<GuildAvatarInfo>>>{};

  /// États observables, un par bot, partagés par tous les écrans.
  final Map<String, ValueNotifier<GuildsLoadState>> _states =
      <String, ValueNotifier<GuildsLoadState>>{};

  /// État renvoyé pour un identifiant de bot vide (jamais alimenté).
  static final ValueNotifier<GuildsLoadState> _idleState =
      ValueNotifier<GuildsLoadState>(GuildsLoadState.idle);

  /// File séquentielle : évite de lancer un GET par carte bot en même temps
  /// au premier rendu de la Home (N bots × 1 requête).
  Future<void> _queue = Future<void>.value();

  /// Instance unique de [AppManager] (lecture du token en stockage sécurisé).
  AppManager? _appManager;

  /// État observable des serveurs de [botId] : les widgets s'y abonnent
  /// (`ValueListenableBuilder`) pour ne jamais afficher une donnée périmée.
  ValueListenable<GuildsLoadState> watch(String botId) {
    final id = botId.trim();
    if (id.isEmpty) return _idleState;
    return _stateFor(id);
  }

  /// Serveurs de [botId] : entrée de session si elle existe, sinon une seule
  /// requête REST pour toute la session.
  Future<List<GuildAvatarInfo>> load(String botId) {
    final id = botId.trim();
    if (id.isEmpty) return Future<List<GuildAvatarInfo>>.value(const []);
    final cached = _cache[id];
    if (cached != null) return Future<List<GuildAvatarInfo>>.value(cached);
    return _startFetch(id);
  }

  /// Force une nouvelle requête REST pour [botId] (bouton « Actualiser »,
  /// tirer-pour-rafraîchir, après avoir quitté un serveur) et remplace
  /// l'entrée de session au succès.
  Future<List<GuildAvatarInfo>> refresh(String botId) {
    final id = botId.trim();
    if (id.isEmpty) return Future<List<GuildAvatarInfo>>.value(const []);
    return _startFetch(id);
  }

  /// Vide le cache de session (redémarrage applicatif, tests).
  void clearCache() {
    _cache.clear();
    _inFlight.clear();
    _queue = Future<void>.value();
    // Les états restent en place (des widgets peuvent les écouter) mais
    // repartent de l'état initial : le prochain `load` refera une requête.
    for (final state in _states.values) {
      state.value = GuildsLoadState.idle;
    }
  }

  Future<List<GuildAvatarInfo>> _startFetch(String botId) {
    // Requête déjà en vol (autre carte, page « Serveurs », refresh en double) :
    // on partage la même future — jamais deux GET simultanés pour un bot.
    final running = _inFlight[botId];
    if (running != null) return running;

    _setState(
      botId,
      GuildsLoadState(
        status: GuildsLoadStatus.loading,
        // On conserve la liste déjà affichée pendant un rafraîchissement.
        guilds: _cache[botId] ?? const <GuildAvatarInfo>[],
      ),
    );

    final future = _queue.then((_) => _fetch(botId)).whenComplete(() {
      // Corps de bloc obligatoire : `whenComplete` attend la future
      // éventuellement retournée par son callback. Retourner ici
      // `_inFlight.remove(botId)` (la future en vol elle-même) créerait une
      // attente circulaire et `load()` ne se résoudrait jamais.
      _inFlight.remove(botId);
    });
    // La file ne doit jamais se rompre sur une erreur réseau.
    _queue = future.then((_) {}, onError: (_) {});
    _inFlight[botId] = future;
    return future;
  }

  Future<List<GuildAvatarInfo>> _fetch(String botId) async {
    try {
      final token = await _resolveToken(botId);
      if (token == null || token.isEmpty) {
        _fail(botId, 'missing bot token');
        return const <GuildAvatarInfo>[];
      }

      final body = await _httpGet(_guildsEndpoint, token);
      if (body == null) {
        _fail(botId, 'GET $_guildsEndpoint failed');
        return const <GuildAvatarInfo>[];
      }

      final guilds = parseGuildsApiPayload(body);
      if (guilds.isEmpty) {
        // Bot réellement sans serveur (ou charge utile illisible) : l'état est
        // publié pour que les écrans affichent leur état vide, mais rien n'est
        // mis en cache — un prochain affichage pourra retenter.
        _setState(
          botId,
          const GuildsLoadState(status: GuildsLoadStatus.loaded),
        );
        return const <GuildAvatarInfo>[];
      }

      // Entrée de session : plus aucune requête pour ce bot avant le
      // redémarrage de l'app (sauf `refresh` explicite).
      _cache[botId] = guilds;
      _setState(
        botId,
        GuildsLoadState(status: GuildsLoadStatus.loaded, guilds: guilds),
      );
      return guilds;
    } catch (error) {
      // Aucune exception ne doit sortir d'ici : les appelants (widgets)
      // n'ont jamais à gérer un échec réseau.
      _fail(botId, error.toString());
      return const <GuildAvatarInfo>[];
    }
  }

  void _fail(String botId, String message) {
    _setState(
      botId,
      GuildsLoadState(status: GuildsLoadStatus.error, errorMessage: message),
    );
  }

  ValueNotifier<GuildsLoadState> _stateFor(String botId) => _states.putIfAbsent(
    botId,
    () => ValueNotifier<GuildsLoadState>(GuildsLoadState.idle),
  );

  void _setState(String botId, GuildsLoadState state) {
    _stateFor(botId).value = state;
  }

  Future<String?> _resolveToken(String botId) =>
      _customTokenResolver?.call(botId) ?? _tokenFromAppStorage(botId);

  Future<String?> _tokenFromAppStorage(String botId) async {
    try {
      final app = await (_appManager ??= AppManager()).getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      return token.isEmpty ? null : token;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _httpGetFromDiscord(
    String endpoint,
    String token,
  ) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client.getUrl(Uri.parse(endpoint));
      request.headers.set(HttpHeaders.authorizationHeader, 'Bot $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final response = await request.close().timeout(_requestTimeout);
      final payload = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return payload;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Cluster d'avatars de serveurs de la ligne « Actif sur N serveurs ».
///
/// Reprend exactement la mise en page historique (cercles de 36 px superposés
/// de 26 px, anneau de séparation) mais remplace les glyphes par les vraies
/// icônes, avec le même contrat de chargement que [HomeBotAvatar] : image
/// `gaplessPlayback`, repli pendant le chargement, repli sur erreur.
///
/// Source 1 : [guilds] (cache du gateway, synchrone — aucun réseau).
/// Source 2 : l'état de session partagé de [directory] (voir [GuildDirectory]),
/// auquel le widget s'abonne — un chargement lancé par la page « Serveurs »
/// fait donc apparaître les avatars ici sans nouvelle requête. Pendant le
/// chargement, le repli neutre habituel est affiché (jamais de données
/// inventées).
class GuildAvatarStrip extends StatefulWidget {
  const GuildAvatarStrip({
    super.key,
    required this.botId,
    required this.guildCount,
    this.guilds = const <GuildAvatarInfo>[],
    this.ringColor,
    this.size = 36,
    this.overlap = 26,
    this.directory,
    this.remoteLoader,
  });

  /// Bot dont on résout les serveurs.
  final String botId;

  /// Compteur de serveurs de la carte (`guild_count`).
  final int guildCount;

  /// Serveurs déjà connus (cache du gateway) — source préférée.
  final List<GuildAvatarInfo> guilds;

  /// Couleur de l'anneau qui sépare deux avatars superposés.
  final Color? ringColor;

  /// Diamètre d'un avatar.
  final double size;

  /// Décalage horizontal entre deux avatars superposés.
  final double overlap;

  /// Répertoire partagé injectable (tests) ; par défaut l'instance unique
  /// [GuildDirectory.instance], partagée avec la page « Serveurs ».
  final GuildDirectory? directory;

  /// Chargeur REST injectable, conservé pour compatibilité ascendante : quand
  /// il est fourni, le widget affiche son résultat et n'utilise *pas* l'état
  /// de session partagé (réservé aux tests qui ne veulent pas de cache).
  final Future<List<GuildAvatarInfo>> Function(String botId)? remoteLoader;

  @override
  State<GuildAvatarStrip> createState() => _GuildAvatarStripState();
}

class _GuildAvatarStripState extends State<GuildAvatarStrip> {
  /// Résultat du chargeur injecté ([GuildAvatarStrip.remoteLoader]).
  List<GuildAvatarInfo> _injected = const <GuildAvatarInfo>[];

  GuildDirectory get _directory => widget.directory ?? GuildDirectory.instance;

  @override
  void initState() {
    super.initState();
    _ensureLoadStarted();
  }

  @override
  void didUpdateWidget(GuildAvatarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId ||
        oldWidget.directory != widget.directory) {
      _injected = const <GuildAvatarInfo>[];
      _ensureLoadStarted();
    }
  }

  /// Démarre un chargement *seulement* si le cache du gateway ne fournit
  /// encore aucun serveur : ce cache est synchrone et gratuit, il ne doit
  /// jamais provoquer d'appel distant — ni le chargeur injecté, ni l'état de
  /// session partagé.
  ///
  /// Idempotent : `GuildDirectory.load` sert l'entrée de session ou partage la
  /// requête déjà en vol — ce n'est jamais une requête par rebuild.
  void _ensureLoadStarted() {
    if (widget.guilds.isNotEmpty) return;
    if (widget.remoteLoader != null) {
      unawaited(_loadInjected());
      return;
    }
    if (widget.botId.trim().isEmpty) return;
    unawaited(_directory.load(widget.botId));
  }

  /// Chemin de compatibilité : chargeur injecté, aucun état partagé.
  Future<void> _loadInjected() async {
    final loader = widget.remoteLoader;
    if (loader == null) return;
    try {
      final guilds = await loader(widget.botId);
      if (!mounted || guilds.isEmpty) return;
      setState(() => _injected = guilds);
    } catch (_) {
      // Repli silencieux : une carte ne doit jamais casser pour une icône.
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.botId.trim();
    if (id.isEmpty) return _buildStrip(context, widget.guilds);

    // Chemin de compatibilité (chargeur injecté) : aucun abonnement partagé.
    if (widget.remoteLoader != null) {
      return _buildStrip(
        context,
        widget.guilds.isNotEmpty ? widget.guilds : _injected,
      );
    }

    // Abonnement systématique : un rafraîchissement lancé ailleurs (page
    // « Serveurs ») met la ligne à jour sans requête supplémentaire.
    return ValueListenableBuilder<GuildsLoadState>(
      valueListenable: _directory.watch(id),
      builder: (context, state, _) => _buildStrip(
        context,
        widget.guilds.isNotEmpty ? widget.guilds : state.guilds,
      ),
    );
  }

  Widget _buildStrip(BuildContext context, List<GuildAvatarInfo> known) {
    // La présentation (cercles superposés, anneau, initiales) vit dans
    // `bot_creator_ui`, partagée avec le Studio.
    return ui.GuildAvatarStack(
      guildCount: widget.guildCount,
      guilds: [
        for (final g in known)
          ui.GuildStackItem(id: g.id, name: g.name, iconUrl: g.iconUrl),
      ],
      ringColor: widget.ringColor,
      size: widget.size,
      overlap: widget.overlap,
    );
  }
}
