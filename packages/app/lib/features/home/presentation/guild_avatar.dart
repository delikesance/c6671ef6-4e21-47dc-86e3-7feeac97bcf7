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
//     (même endpoint que `core/utils/global.dart#getDiscordBotGuildCount` et
//     `bot_sub_pages/guilds.page.dart`), résultat mis en cache mémoire.
//
// Aucune donnée inventée : si aucune des deux sources ne fournit de serveur on
// affiche un repli neutre (icône serveur), jamais une lettre issue d'une seed.
// Si le nom du serveur est connu mais pas son icône, on affiche sa vraie
// initiale.
//
// Cache : Flutter met déjà en cache les octets des `Image.network` via
// `PaintingBinding.instance.imageCache` (configuré dans `main.dart`), et les
// icônes sont demandées en `size=128` (adapté à un cercle de 36 px en 3x).
// Voir `GuildDirectory` pour le cache de la *liste* de serveurs (une requête
// REST par bot et par session, jamais une par rebuild).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart' show discordUrl;
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

/// Nombre maximum d'avatars de serveurs dessinés sur une carte bot.
const int kMaxVisibleGuildAvatars = 2;

/// Base du CDN Discord (les icônes de serveurs y sont servies).
const String discordCdnBaseUrl = 'https://cdn.discordapp.com';

/// Taille d'image demandée au CDN pour un cercle de 36 px (marge 2x/3x).
const int kGuildIconRequestSize = 128;

/// Un serveur Discord, réduit à ce dont la carte bot a besoin.
@immutable
class GuildAvatarInfo {
  const GuildAvatarInfo({required this.id, this.name, this.iconHash});

  /// Identifiant (snowflake) du serveur.
  final String id;

  /// Nom du serveur, quand la source le fournit.
  final String? name;

  /// Hash de l'icône du serveur, `null` si le serveur n'a pas d'icône.
  final String? iconHash;

  /// URL CDN résolue, ou `null` quand aucune icône n'est connue.
  String? get iconUrl => discordGuildIconUrl(id, iconHash);

  @override
  bool operator ==(Object other) =>
      other is GuildAvatarInfo &&
      other.id == id &&
      other.name == name &&
      other.iconHash == iconHash;

  @override
  int get hashCode => Object.hash(id, name, iconHash);
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
      guilds.add(
        GuildAvatarInfo(
          id: id,
          name: name.isEmpty ? null : name,
          iconHash: (icon == null || icon.isEmpty) ? null : icon,
        ),
      );
    }
    return sortGuildsForDisplay(guilds);
  } catch (_) {
    return const <GuildAvatarInfo>[];
  }
}

/// Charge et met en cache les serveurs d'un bot via l'API REST Discord.
///
/// Le token n'est pas disponible dans la liste d'apps streamée par la Home
/// (`getAllApps()` n'expose que `id`/`name`/`avatar`/`guild_count`) : il est
/// relu depuis `AppManager.getApp()`, qui va le chercher dans le stockage
/// sécurisé (même chemin que `bot_sub_pages/guilds.page.dart`).
///
/// Toutes les dépendances (résolution du token, transport HTTP, endpoint)
/// sont injectables : la sémantique du cache est ainsi testable sans réseau.
class GuildDirectory {
  GuildDirectory({
    Future<String?> Function(String botId)? tokenResolver,
    Future<String?> Function(String endpoint, String token)? httpGet,
    String? guildsEndpoint,
    this.cacheTtl = defaultCacheTtl,
  }) : _customTokenResolver = tokenResolver,
       _httpGet = httpGet ?? _httpGetFromDiscord,
       _guildsEndpoint = guildsEndpoint ?? '$discordUrl/users/@me/guilds';

  /// Instance partagée par la Home : une requête par bot et par session.
  static final GuildDirectory instance = GuildDirectory();

  /// Durée de vie du cache mémoire (les icônes de serveurs bougent rarement).
  static const Duration defaultCacheTtl = Duration(minutes: 30);

  static const Duration _requestTimeout = Duration(seconds: 8);

  final Duration cacheTtl;

  /// Résolveur de token injecté (tests) ; sinon stockage sécurisé de l'app.
  final Future<String?> Function(String botId)? _customTokenResolver;
  final Future<String?> Function(String endpoint, String token) _httpGet;
  final String _guildsEndpoint;

  final Map<String, _GuildCacheEntry> _cache = <String, _GuildCacheEntry>{};
  final Map<String, Future<List<GuildAvatarInfo>>> _inFlight =
      <String, Future<List<GuildAvatarInfo>>>{};

  /// File séquentielle : évite de lancer un GET par carte bot en même temps
  /// au premier rendu de la Home (N bots × 1 requête).
  Future<void> _queue = Future<void>.value();

  /// Instance unique de [AppManager] (lecture du token en stockage sécurisé).
  AppManager? _appManager;

  /// Serveurs de [botId], au plus une requête REST par [cacheTtl].
  Future<List<GuildAvatarInfo>> load(String botId) {
    final id = botId.trim();
    if (id.isEmpty) return Future<List<GuildAvatarInfo>>.value(const []);
    final cached = _cache[id];
    if (cached != null &&
        DateTime.now().difference(cached.fetchedAt) < cacheTtl) {
      return Future<List<GuildAvatarInfo>>.value(cached.guilds);
    }
    // Un chargement déjà en vol est partagé : deux cartes du même bot (ou un
    // rebuild pendant la requête) ne déclenchent pas un second GET.
    final running = _inFlight[id];
    if (running != null) return running;

    final future = _queue
        .then((_) => _fetch(id))
        .whenComplete(() => _inFlight.remove(id));
    // La file ne doit jamais se rompre sur une erreur réseau.
    _queue = future.then((_) {}, onError: (_) {});
    _inFlight[id] = future;
    return future;
  }

  /// Vide le cache mémoire.
  void clearCache() {
    _cache.clear();
    _inFlight.clear();
    _queue = Future<void>.value();
  }

  Future<List<GuildAvatarInfo>> _fetch(String botId) async {
    final token = await _resolveToken(botId);
    if (token == null || token.isEmpty) return const <GuildAvatarInfo>[];
    final body = await _httpGet(_guildsEndpoint, token);
    if (body == null) return const <GuildAvatarInfo>[];
    final guilds = parseGuildsApiPayload(body);
    // Un résultat vide (bot sans serveur, erreur transitoire) n'est pas mis en
    // cache : un prochain affichage pourra retenter.
    if (guilds.isNotEmpty) {
      _cache[botId] = _GuildCacheEntry(guilds, DateTime.now());
    }
    return guilds;
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

class _GuildCacheEntry {
  const _GuildCacheEntry(this.guilds, this.fetchedAt);

  final List<GuildAvatarInfo> guilds;
  final DateTime fetchedAt;
}

/// Cluster d'avatars de serveurs de la ligne « Actif sur N serveurs ».
///
/// Reprend exactement la mise en page historique (cercles de 36 px superposés
/// de 26 px, anneau de séparation) mais remplace les glyphes par les vraies
/// icônes, avec le même contrat de chargement que [HomeBotAvatar] : image
/// `gaplessPlayback`, repli pendant le chargement, repli sur erreur.
class GuildAvatarStrip extends StatefulWidget {
  const GuildAvatarStrip({
    super.key,
    required this.botId,
    required this.guildCount,
    this.guilds = const <GuildAvatarInfo>[],
    this.ringColor,
    this.size = 36,
    this.overlap = 26,
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

  /// Chargeur REST injectable (par défaut [GuildDirectory.load]).
  final Future<List<GuildAvatarInfo>> Function(String botId)? remoteLoader;

  @override
  State<GuildAvatarStrip> createState() => _GuildAvatarStripState();
}

class _GuildAvatarStripState extends State<GuildAvatarStrip> {
  List<GuildAvatarInfo> _fetched = const <GuildAvatarInfo>[];
  bool _requested = false;

  @override
  void initState() {
    super.initState();
    _requestRemoteIfNeeded();
  }

  @override
  void didUpdateWidget(GuildAvatarStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.botId != widget.botId) {
      _fetched = const <GuildAvatarInfo>[];
      _requested = false;
      _requestRemoteIfNeeded();
    }
  }

  void _requestRemoteIfNeeded() {
    if (_requested) return;
    if (widget.botId.trim().isEmpty) return;
    // Le cache du gateway suffit : rien à demander au réseau.
    if (widget.guilds.isNotEmpty) return;
    _requested = true;
    unawaited(_loadRemote());
  }

  Future<void> _loadRemote() async {
    final loader = widget.remoteLoader ?? GuildDirectory.instance.load;
    try {
      final guilds = await loader(widget.botId);
      if (!mounted || guilds.isEmpty) return;
      setState(() => _fetched = guilds);
    } catch (_) {
      // Repli silencieux : une carte ne doit jamais casser pour une icône.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final known = widget.guilds.isNotEmpty ? widget.guilds : _fetched;
    final ringColor =
        widget.ringColor ??
        (isDark ? AppTheme.homeClusterBg : scheme.surfaceContainerLow);
    final slots = guildPresenceSlotCount(
      guildCount: widget.guildCount,
      knownGuilds: known.length,
    );

    return SizedBox(
      width: widget.size + (slots - 1) * widget.overlap,
      height: widget.size,
      child: Stack(
        children: <Widget>[
          for (var i = 0; i < slots; i++)
            Positioned(
              left: i * widget.overlap,
              child: _buildAvatar(
                context,
                index: i,
                info: i < known.length ? known[i] : null,
                ringColor: ringColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context, {
    required int index,
    required GuildAvatarInfo? info,
    required Color ringColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final background = index == 0
        ? (isDark ? AppTheme.homeClusterBorder : scheme.primary)
        : AppTheme.discord;

    return HomeBotAvatar(
      imageUrl: info?.iconUrl,
      size: widget.size,
      background: background,
      ringColor: ringColor,
      ringWidth: 2,
      fallbackIcon: Icons.dns_rounded,
      // Initiale *réelle* du serveur (jamais une lettre tirée d'une seed).
      fallbackLabel: guildAvatarInitial(info?.name),
    );
  }
}
