import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_shared/bot/bot_config.dart';

/// A single persisted bot entry (config + metadata).
class RunnerBotEntry {
  RunnerBotEntry({
    required this.id,
    required this.name,
    required this.syncedAt,
    required this.config,
    this.running = false,
  });

  final String id;
  final String name;
  final DateTime syncedAt;
  final BotConfig config;
  final bool running;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'syncedAt': syncedAt.toUtc().toIso8601String(),
    'config': config.toJson(),
    'running': running,
  };

  factory RunnerBotEntry.fromJson(Map<String, dynamic> json) {
    return RunnerBotEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      syncedAt: DateTime.parse(json['syncedAt'] as String),
      config: BotConfig.fromJson(
        Map<String, dynamic>.from(json['config'] as Map),
      ),
      running: json['running'] as bool? ?? false,
    );
  }

  RunnerBotEntry copyWith({
    String? name,
    DateTime? syncedAt,
    BotConfig? config,
    bool? running,
  }) {
    return RunnerBotEntry(
      id: id,
      name: name ?? this.name,
      syncedAt: syncedAt ?? this.syncedAt,
      config: config ?? this.config,
      running: running ?? this.running,
    );
  }
}

/// Persistent store for bot configs synced from the app.
///
/// Each bot is stored as a JSON file at `<dataDir>/<botId>/config.json`.
/// Default data directory is resolved from the `BOT_CREATOR_DATA_DIR`
/// environment variable, falling back to `/bots`.
class RunnerBotStore {
  RunnerBotStore({String? dataDir})
    : _dataDir =
          dataDir ??
          (Platform.environment['BOT_CREATOR_DATA_DIR'] != null &&
                  Platform.environment['BOT_CREATOR_DATA_DIR']!.isNotEmpty
              ? Platform.environment['BOT_CREATOR_DATA_DIR']!
              : '/bots');

  final String _dataDir;
  final Map<String, BotConfig> _memoryConfigs = <String, BotConfig>{};

  /// Retire les secrets avant écriture disque, SANS toucher au schéma de
  /// configuration.
  ///
  /// La musique est décrite par `lavalink: { enabled, custom_servers }` : une
  /// reconstruction depuis l'ancienne forme (serveur unique `host`/`port`)
  /// perdait `enabled` et `custom_servers`, donc le bot redémarrait avec la
  /// musique activée de force et sans ses serveurs de repli.
  static BotConfig sanitizeForStorage(BotConfig config) {
    final lavalink = config.lavalinkConfig;
    return config.copyWith(
      token: '',
      lavalinkConfig: lavalink == null
          ? null
          : LavalinkConfig(
              // Schéma figé conservé tel quel…
              enabled: lavalink.enabled,
              // …mais les mots de passe des serveurs de repli sont vidés : le
              // fichier disque ne doit contenir aucun secret en clair (ils
              // restent en RAM, cf. `_memoryConfigs`).
              customServers: lavalink.customServers
                  .map(
                    (server) => LavalinkServerConfig(
                      host: server.host,
                      port: server.port,
                      password: '',
                      secure: server.secure,
                    ),
                  )
                  .toList(growable: false),
              // Ancienne forme conservée pour un lecteur plus ancien.
              host: lavalink.host,
              port: lavalink.port,
              password: '',
              useSsl: lavalink.useSsl,
            ),
    );
  }

  File _fileForBot(String botId) {
    final safe = botId.replaceAll(RegExp(r'[^\w\-]'), '_');
    return File('$_dataDir/$safe/config.json');
  }

  Future<void> save(
    String botId,
    String botName,
    BotConfig config, {
    bool? running,
  }) async {
    // Retain full secret-bearing config in volatile RAM only
    _memoryConfigs[botId] = config;

    final existing = await loadEntry(botId);
    final sanitizedConfig = sanitizeForStorage(config);
    final entry = RunnerBotEntry(
      id: botId,
      name: botName,
      syncedAt: DateTime.now().toUtc(),
      config: sanitizedConfig,
      running: running ?? existing?.running ?? false,
    );
    final file = _fileForBot(botId);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(entry.toJson()));
  }

  Future<void> setRunning(String botId, bool running) async {
    final entry = await loadEntry(botId);
    if (entry != null) {
      await save(botId, entry.name, entry.config, running: running);
    }
  }

  Future<BotConfig?> load(String botId) async {
    final entry = await loadEntry(botId);
    return entry?.config;
  }

  Future<RunnerBotEntry?> loadEntry(String botId) async {
    final file = _fileForBot(botId);
    if (!await file.exists()) {
      // Compatibility with old layout: <botId>.json
      final oldSafe = botId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final oldFile = File('$_dataDir/$oldSafe.json');
      if (!await oldFile.exists()) return null;

      try {
        final raw = await oldFile.readAsString();
        final json = jsonDecode(raw);
        final entry = RunnerBotEntry.fromJson(
          Map<String, dynamic>.from(json as Map),
        );
        // Migrate to new layout
        await save(botId, entry.name, entry.config, running: entry.running);
        await oldFile.delete();
        return _hydrateEntryWithMemory(botId, entry);
      } catch (_) {
        return null;
      }
    }

    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw);
      final entry = RunnerBotEntry.fromJson(
        Map<String, dynamic>.from(json as Map),
      );
      return _hydrateEntryWithMemory(botId, entry);
    } catch (_) {
      return null;
    }
  }

  RunnerBotEntry _hydrateEntryWithMemory(String botId, RunnerBotEntry entry) {
    final mem = _memoryConfigs[botId];
    if (mem == null) return entry;

    // La config en RAM est la seule qui porte les secrets : elle gagne dès
    // qu'elle décrit une vraie configuration. `customServers` compte autant que
    // le mot de passe du schéma hérité — sinon les serveurs de repli saisis
    // dans l'app (dont les mots de passe sont vidés sur disque) seraient perdus.
    final memLavalink = mem.lavalinkConfig;
    final memLavalinkUsable =
        memLavalink != null &&
        (memLavalink.password.isNotEmpty || memLavalink.hasCustomServers);

    return entry.copyWith(
      config: entry.config.copyWith(
        token: mem.token.isNotEmpty ? mem.token : entry.config.token,
        lavalinkConfig: memLavalinkUsable
            ? memLavalink
            : entry.config.lavalinkConfig,
      ),
    );
  }

  Future<List<RunnerBotEntry>> listAll() async {
    final dir = Directory(_dataDir);
    if (!await dir.exists()) return <RunnerBotEntry>[];
    final entries = <RunnerBotEntry>[];

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('config.json')) {
        try {
          final raw = await entity.readAsString();
          final json = jsonDecode(raw);
          final entry = RunnerBotEntry.fromJson(
            Map<String, dynamic>.from(json as Map),
          );
          entries.add(_hydrateEntryWithMemory(entry.id, entry));
        } catch (_) {}
      }
    }
    return entries;
  }

  Future<void> delete(String botId) async {
    _memoryConfigs.remove(botId);
    final file = _fileForBot(botId);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
