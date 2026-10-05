import 'dart:convert';

import 'package:crypto/crypto.dart';

import './documentation_urls.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentationEntry {
  DocumentationEntry.fromJson(Map<String, dynamic> data)
    : id = data['id'] as String,
      name = data['name'] as String,
      description = data['description'] as String? ?? '',
      category = data['category'] as String? ?? '',
      mode = data['api_type'] as String? ?? 'general',
      status = data['status'] as String? ?? 'documented',
      locale = data['locale'] as String? ?? 'en',
      translationKey = data['translation_key'] as String?,
      revision = data['revision'] as String,
      url = Uri.parse(data['url'] as String),
      markdownUrl = Uri.parse(data['markdown_url'] as String) {
    if (!isNativeDocumentationUrl(markdownUrl) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(revision) ||
        url.scheme != 'https' ||
        url.host != 'bot-creator.fr') {
      throw const FormatException('Invalid documentation URL');
    }
  }

  final String id, name, description, category, mode, status, locale, revision;
  final String? translationKey;
  final Uri url, markdownUrl;
}

bool isNativeDocumentationUrl(Uri uri) =>
    uri.scheme == 'https' &&
    uri.host == 'bot-creator.fr' &&
    uri.userInfo.isEmpty &&
    !uri.hasPort &&
    uri.path.startsWith('/api/native/') &&
    !uri.pathSegments.contains('..');

class DocumentationResult<T> {
  const DocumentationResult(this.value, {this.offline = false});
  final T value;
  final bool offline;
}

class DocumentationRevisionMismatch extends FormatException {
  const DocumentationRevisionMismatch()
    : super('Documentation revision mismatch');
}

class DocumentationHttpException implements Exception {
  const DocumentationHttpException(this.statusCode);
  final int statusCode;
}

/// Public content only. Cache identity includes the build's content revision,
/// so a refreshed index cannot silently reuse an older article body.
class DocumentationRepository {
  DocumentationRepository({http.Client? client, DateTime Function()? now})
    : _client = client ?? http.Client(),
      _now = now ?? DateTime.now;

  static final instance = DocumentationRepository();
  final http.Client _client;
  final DateTime Function() _now;
  final Map<String, Future<DocumentationResult<String>>> _pending = {};
  static const _cacheKey = 'native_documentation_cache_v1';
  static const _maxEntries = 64;
  static const _maxCacheBytes = 4 * 1024 * 1024;
  Map<String, dynamic>? _cache;
  Future<void>? _loadingCache;

  Future<void> _loadCache() => _loadingCache ??= () async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      _cache = raw == null
          ? {}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
      _cache!.removeWhere(
        (key, value) =>
            value is! Map || value['body'] is! String || value['time'] is! int,
      );
    } catch (_) {
      _cache = {};
    }
  }();

  Future<DocumentationResult<String>> _read(
    Uri uri, {
    required String identity,
    required Duration ttl,
    bool refresh = false,
    required void Function(String) validate,
  }) {
    final key = '$uri@$identity';
    final pendingKey = '$key@$refresh';
    return _pending[pendingKey] ??=
        _readUnshared(uri, key, ttl, refresh, validate).whenComplete(() {
          _pending.remove(pendingKey);
        });
  }

  Future<DocumentationResult<String>> _readUnshared(
    Uri uri,
    String key,
    Duration ttl,
    bool refresh,
    void Function(String) validate,
  ) async {
    await _loadCache();
    final stored = _cache![key];
    String? cached;
    int timestamp = 0;
    if (stored is Map && stored['body'] is String && stored['time'] is int) {
      try {
        validate(stored['body'] as String);
        cached = stored['body'] as String;
        timestamp = stored['time'] as int;
      } catch (_) {
        _cache!.remove(key);
      }
    }
    if (!refresh &&
        cached != null &&
        _now().millisecondsSinceEpoch - timestamp < ttl.inMilliseconds) {
      return DocumentationResult(cached);
    }
    try {
      final request = http.Request('GET', uri)..followRedirects = false;
      if (refresh) request.headers['Cache-Control'] = 'no-cache';
      final response = await (() async {
        final streamed = await _client.send(request);
        if (streamed.statusCode != 200) {
          throw DocumentationHttpException(streamed.statusCode);
        }
        final bytes = <int>[];
        await for (final chunk in streamed.stream) {
          bytes.addAll(chunk);
          if (bytes.length > 1024 * 1024) {
            throw const FormatException('Documentation too large');
          }
        }
        return utf8.decode(bytes);
      })().timeout(const Duration(seconds: 12));
      validate(response);
      _cache![key] = {'body': response, 'time': _now().millisecondsSinceEpoch};
      while (_cache!.length > _maxEntries ||
          utf8.encode(jsonEncode(_cache)).length > _maxCacheBytes) {
        final oldest = _cache!.keys.reduce(
          (a, b) => (_cache![a]['time'] as int) <= (_cache![b]['time'] as int)
              ? a
              : b,
        );
        _cache!.remove(oldest);
      }
      // Disk cache failure must not discard a successful network response.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(_cache));
      } catch (_) {}
      return DocumentationResult(response);
    } catch (error) {
      final reason = switch (error) {
        DocumentationRevisionMismatch() => 'revision_mismatch',
        DocumentationHttpException(:final statusCode) => 'http_$statusCode',
        FormatException() => 'invalid_content',
        _ => 'transport_or_storage',
      };
      debugPrint(
        '[Documentation] load rejected path=${uri.path} reason=$reason '
        'cached=${cached != null}',
      );
      if (cached != null) return DocumentationResult(cached, offline: true);
      rethrow;
    }
  }

  List<DocumentationEntry> _parseIndex(String body) =>
      (jsonDecode(body) as List)
          .map(
            (entry) => DocumentationEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList();

  Future<DocumentationResult<List<DocumentationEntry>>> index(
    DocumentationSection section, {
    bool refresh = false,
  }) async {
    if (section == DocumentationSection.discordJs) {
      throw ArgumentError('External documentation');
    }
    final library = section == DocumentationSection.guide ? 'guides' : 'docs';
    final result = await _read(
      Uri.parse('https://bot-creator.fr/api/native-$library-index.json'),
      identity: 'index',
      ttl: const Duration(hours: 1),
      refresh: refresh,
      validate: (body) {
        _parseIndex(body);
      },
    );
    return DocumentationResult(
      _parseIndex(result.value),
      offline: result.offline,
    );
  }

  Future<DocumentationResult<String>> article(
    DocumentationEntry entry, {
    bool refresh = false,
  }) => _read(
    entry.markdownUrl,
    identity: entry.revision,
    ttl: const Duration(days: 1),
    refresh: refresh,
    validate: (body) {
      if (sha256.convert(utf8.encode(body)).toString() != entry.revision) {
        throw const DocumentationRevisionMismatch();
      }
      if (body.trim().isEmpty ||
          body.trimLeft().toLowerCase().startsWith('<!doctype html') ||
          body.trimLeft().toLowerCase().startsWith('<html')) {
        throw const FormatException('Expected Markdown');
      }
    },
  );

  Future<(DocumentationEntry, DocumentationResult<String>)> loadArticle(
    Uri url, {
    DocumentationEntry? entry,
    bool refresh = false,
  }) async {
    final current = !refresh && entry != null
        ? entry
        : await resolve(url, refresh: refresh);
    if (current != null) {
      try {
        return (current, await article(current, refresh: refresh));
      } on DocumentationRevisionMismatch {
        // A deployment can replace Markdown while the index is still cached.
      } on DocumentationHttpException catch (error) {
        if (error.statusCode != 404) rethrow;
      }
    }
    // One recovery only: keep hash validation even if deployment is incomplete.
    final latest = await resolve(url, refresh: true);
    if (latest == null) throw StateError('Article not indexed');
    return (latest, await article(latest, refresh: true));
  }

  Future<DocumentationEntry?> resolve(Uri url, {bool refresh = false}) async {
    if (url.scheme != 'https' || url.host != 'bot-creator.fr') return null;
    final sections = url.path.startsWith('/docs/')
        ? [DocumentationSection.botCreatorDocs]
        : [DocumentationSection.guide, DocumentationSection.botCreatorDocs];
    for (final section in sections) {
      final entries = (await index(section, refresh: refresh)).value;
      for (final entry in entries) {
        if (_path(entry.url) == _path(url)) return entry;
      }
    }
    return null;
  }

  String _path(Uri uri) => Uri.decodeComponent(
    uri.path,
  ).replaceFirst(RegExp(r'/$'), '').replaceFirst(RegExp(r'\.html$'), '');
}
