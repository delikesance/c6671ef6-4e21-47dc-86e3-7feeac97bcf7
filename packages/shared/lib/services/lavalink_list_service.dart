/// Fetches and caches the public Lavalink server list from
/// the community-maintained REST API at lavalink-list.ajieblogs.eu.org.
///
/// The list is refreshed every 10 minutes by the upstream API.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A single Lavalink server entry from the public list.
class LavalinkServerEntry {
  final String uniqueId;
  final String identifier;
  final String host;
  final int port;
  final String password;
  final bool secure;
  final String version;

  const LavalinkServerEntry({
    required this.uniqueId,
    required this.identifier,
    required this.host,
    required this.port,
    required this.password,
    required this.secure,
    required this.version,
  });

  factory LavalinkServerEntry.fromJson(Map<String, dynamic> json) {
    return LavalinkServerEntry(
      uniqueId: (json['unique-id'] ?? '').toString(),
      identifier: (json['identifier'] ?? '').toString(),
      host: (json['host'] ?? '').toString(),
      port: int.tryParse((json['port'] ?? '2333').toString()) ?? 2333,
      password: (json['password'] ?? '').toString(),
      secure: json['secure'] == true,
      version: (json['version'] ?? 'v4').toString(),
    );
  }

  /// Human-readable label for UI dropdowns.
  String get label => '$host:$port ($version${secure ? ", SSL" : ""})';

  /// True when this entry speaks the v4 protocol (REST `/v4`).
  ///
  /// The bot only probes v4 servers: the pre-check and the plugin both target
  /// the `/v4` endpoints, so a v3 entry can never be used.
  bool get isV4 => version.trim().toLowerCase() == requiredVersion;

  /// Version requise pour qu'un serveur soit exploitable.
  static const String requiredVersion = 'v4';

  /// Badge URL for this server's status.
  Uri badgeUrl(String type) => Uri.parse(
    'https://lavalink-list-api.ajieblogs.eu.org/$uniqueId/badge/$type',
  );
}

/// Service that fetches the public Lavalink server list.
///
/// Usage:
/// ```dart
/// final service = LavalinkListService();
/// final servers = await service.fetchServers();
/// ```
class LavalinkListService {
  static const _baseUrl = 'https://lavalink-list.ajieblogs.eu.org';

  /// Keeps only the entries usable by the bot, i.e. [`v4`](LavalinkServerEntry.requiredVersion).
  ///
  /// The public list mixes v3 and v4 servers; probing a v3 one is wasted time.
  static List<LavalinkServerEntry> filterV4(List<LavalinkServerEntry> entries) {
    return entries.where((entry) => entry.isV4).toList(growable: false);
  }

  List<LavalinkServerEntry>? _cached;
  DateTime? _lastFetch;

  /// Returns cached servers if less than 5 minutes old, otherwise fetches fresh.
  Future<List<LavalinkServerEntry>> getServers({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age < const Duration(minutes: 5)) {
        return _cached!;
      }
    }
    return fetchServers();
  }

  /// Fetch all servers (SSL + NonSSL combined).
  Future<List<LavalinkServerEntry>> fetchServers() async {
    final entries = <LavalinkServerEntry>[];

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/All'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        for (final item in data) {
          if (item is Map<String, dynamic>) {
            entries.add(LavalinkServerEntry.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Return cached data on failure
      if (_cached != null) return _cached!;
    }

    _cached = entries;
    _lastFetch = DateTime.now();
    return entries;
  }
}
