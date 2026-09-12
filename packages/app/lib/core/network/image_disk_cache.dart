// Cache d'images sur disque, clé = URL, partagé par tous les avatars de l'app.
//
// Motivation (« caching des images pour éviter de call des images via HTTP ») :
// le cache mémoire de Flutter (`PaintingBinding.instance.imageCache`, réglé
// dans `main.dart`) est vidé à chaque redémarrage — chaque icône de serveur
// était donc re-téléchargée au lancement suivant. Ici les octets bruts sont
// conservés dans `<support app>/image_cache/<sha1(url)>.img` et relus depuis le
// disque : le réseau n'est sollicité qu'une fois par URL *et par machine*.
//
// Ordre de résolution : mémoire (providers déjà résolus) → disque → réseau.
// Toute défaillance (dossier indisponible, téléchargement en échec, réponse
// non-2xx) retombe sur `NetworkImage(url)` : l'affichage ne casse jamais et
// aucune exception ne remonte aux widgets.
//
// Aucune dépendance nouvelle : `path_provider` (dossier applicatif), `crypto`
// (sha1), `path` (jointures) et `dart:io` (transport) sont déjà déclarés.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart'
    show FileImage, ImageProvider, NetworkImage;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cache d'images mémoire + disque, indexé par URL.
///
/// Les dépendances (dossier de cache, téléchargement) sont injectables : la
/// sémantique du cache — et notamment l'absence de requête réseau au second
/// appel — est ainsi testable sans toucher au disque réel ni au réseau.
class ImageDiskCache {
  ImageDiskCache({
    Future<Directory?> Function()? cacheDirResolver,
    Future<Uint8List?> Function(String url)? fetcher,
    this.maxEntries = defaultMaxEntries,
  }) : _customDirResolver = cacheDirResolver,
       _fetcher = fetcher ?? _downloadBytes;

  /// Instance partagée par tous les avatars (cartes Home, page Serveurs…).
  static final ImageDiskCache instance = ImageDiskCache();

  /// Nombre maximal de fichiers conservés (au-delà : purge LRU).
  static const int defaultMaxEntries = 200;

  /// Sous-dossier du dossier de support applicatif.
  static const String cacheFolderName = 'image_cache';

  /// Suffixe des fichiers d'images mis en cache.
  static const String _fileSuffix = '.img';

  static const Duration _requestTimeout = Duration(seconds: 15);

  final int maxEntries;

  /// Résolveur de dossier injecté (tests) ; sinon dossier de support.
  final Future<Directory?> Function()? _customDirResolver;
  final Future<Uint8List?> Function(String url) _fetcher;

  /// Providers déjà résolus : aucun accès disque ni réseau pour eux.
  final Map<String, ImageProvider> _providers = <String, ImageProvider>{};

  /// Téléchargements en vol (même URL demandée par plusieurs avatars).
  final Map<String, Future<Uint8List?>> _downloads =
      <String, Future<Uint8List?>>{};

  /// Résolutions en vol : deux appels concurrents partagent le même travail.
  final Map<String, Future<ImageProvider>> _resolving =
      <String, Future<ImageProvider>>{};

  /// Récence en mémoire : clé = chemin du fichier, valeur = compteur monotone
  /// de dernière utilisation (écriture ou lecture disque) dans ce processus.
  ///
  /// Mesuré : `File.lastModified()` n'a qu'une granularité de *seconde* sur ce
  /// système — trois écritures espacées de 20 ms y portent la même date, ce
  /// qui rendrait la purge LRU arbitraire (départage par chemin). Ce
  /// compteur ordonne les fichiers utilisés pendant la session ; la date de
  /// modification ne sert plus que de repli pour les fichiers d'un lancement
  /// précédent (mémoire vide).
  final Map<String, int> _recency = <String, int>{};

  /// Compteur monotone alimentant [_recency].
  int _recencyTick = 0;

  Directory? _cacheDir;

  /// Vrai dès qu'une résolution de dossier a été tentée (succès ou échec), pour
  /// ne pas rappeler `path_provider` à chaque avatar quand il est indisponible
  /// (plateformes sans plugin, tests de widgets).
  bool _dirResolved = false;

  /// Provider d'image pour [url] : mémoire → disque → réseau.
  ///
  /// Ne lève jamais : en dernier recours c'est un `NetworkImage` qui est rendu.
  Future<ImageProvider> providerFor(String url) {
    final known = _providers[url];
    if (known != null) return Future<ImageProvider>.value(known);

    final running = _resolving[url];
    if (running != null) return running;

    final future = _resolve(url).whenComplete(() {
      // Corps de bloc obligatoire : retourner ici la future en vol créerait
      // une attente circulaire (voir `whenComplete` : une future retournée est
      // attendue avant de compléter la future dérivée).
      _resolving.remove(url);
    });
    _resolving[url] = future;
    return future;
  }

  /// Vide le cache mémoire *et* le dossier disque.
  Future<void> clear() async {
    _providers.clear();
    _downloads.clear();
    _resolving.clear();
    _recency.clear();
    _recencyTick = 0;
    final dir = _cacheDir;
    _cacheDir = null;
    _dirResolved = false;
    if (dir == null) return;
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {
      // Purge best-effort : un dossier verrouillé ne doit pas faire échouer
      // l'appelant.
    }
  }

  Future<ImageProvider> _resolve(String url) async {
    try {
      final dir = await _resolveCacheDir();
      // Sans dossier exploitable (test, plateforme sans plugin) : réseau direct.
      if (dir == null) return _remember(url, NetworkImage(url));

      final file = _fileFor(dir, url);
      if (await _isUsable(file)) {
        // Lecture disque : marque le fichier comme « récemment utilisé » (LRU),
        // en mémoire *et* sur disque (repli après redémarrage).
        await _touch(file);
        _markUsed(file);
        return _remember(url, FileImage(file));
      }

      final bytes = await _fetchOnce(url);
      if (bytes == null || bytes.isEmpty) {
        return _remember(url, NetworkImage(url));
      }

      await _write(file, bytes);
      _markUsed(file);
      await _enforceLimit(dir);
      return _remember(url, FileImage(file));
    } catch (_) {
      // Jamais d'exception : le repli réseau garde l'avatar affichable.
      return _remember(url, NetworkImage(url));
    }
  }

  ImageProvider _remember(String url, ImageProvider provider) {
    _providers[url] = provider;
    return provider;
  }

  /// Télécharge [url] au plus une fois à la fois (dédoublonnage in-flight).
  Future<Uint8List?> _fetchOnce(String url) {
    final running = _downloads[url];
    if (running != null) return running;

    final future = _fetcher(url).whenComplete(() {
      _downloads.remove(url);
    });
    _downloads[url] = future;
    return future;
  }

  Future<Directory?> _resolveCacheDir() async {
    if (_cacheDir != null) return _cacheDir;
    if (_dirResolved) return null;
    _dirResolved = true;
    try {
      final base = _customDirResolver != null
          ? await _customDirResolver()
          : await _applicationSupportDirectory();
      if (base == null) return null;
      final dir = Directory(p.join(base.path, cacheFolderName));
      await dir.create(recursive: true);
      _cacheDir = dir;
      return dir;
    } catch (_) {
      return null;
    }
  }

  Future<Directory?> _applicationSupportDirectory() async {
    try {
      return await getApplicationSupportDirectory();
    } catch (_) {
      return null;
    }
  }

  File _fileFor(Directory dir, String url) =>
      File(p.join(dir.path, '${_sha1Hex(url)}$_fileSuffix'));

  Future<bool> _isUsable(File file) async {
    try {
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> _touch(File file) async {
    try {
      await file.setLastModified(DateTime.now());
    } catch (_) {
      // Certaines plateformes refusent de modifier la date : le LRU s'appuie
      // alors uniquement sur la récence mémoire, ce n'est pas bloquant.
    }
  }

  /// Marque [file] comme le plus récemment utilisé de ce processus.
  void _markUsed(File file) {
    _recency[file.path] = ++_recencyTick;
  }

  /// Écriture atomique : le fichier final n'apparaît jamais à moitié écrit.
  Future<void> _write(File file, Uint8List bytes) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(file.path);
  }

  /// Purge LRU : au-delà de [maxEntries], les fichiers les moins récemment
  /// utilisés sont supprimés.
  ///
  /// L'ordre vient d'abord de la récence mémoire ([_recency], alimentée à
  /// chaque écriture et lecture disque) : déterministe quelle que soit la
  /// granularité — mesurée à la seconde — des dates du système de fichiers.
  /// Les fichiers d'un lancement précédent (absents de [_recency]) sont
  /// classés entre eux par `lastModified`, puis par chemin en cas d'égalité.
  Future<void> _enforceLimit(Directory dir) async {
    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith(_fileSuffix)) {
        files.add(entity);
      }
    }
    if (files.length <= maxEntries) return;

    final dated =
        <({int recency, DateTime? modified, String path, File file})>[];
    for (final file in files) {
      final recency = _recency[file.path];
      try {
        dated.add((
          recency: recency ?? 0,
          // La date n'est lue que pour les fichiers d'un lancement précédent.
          modified: recency == null ? await file.lastModified() : null,
          path: file.path,
          file: file,
        ));
      } catch (_) {
        // Fichier disparu entre le listage et la lecture : rien à purger.
      }
    }
    dated.sort((a, b) {
      final byRecency = a.recency.compareTo(b.recency);
      if (byRecency != 0) return byRecency;
      final modifiedA = a.modified;
      final modifiedB = b.modified;
      if (modifiedA != null && modifiedB != null) {
        final byDate = modifiedA.compareTo(modifiedB);
        if (byDate != 0) return byDate;
      }
      return a.path.compareTo(b.path);
    });

    final excess = dated.length - maxEntries;
    for (var i = 0; i < excess; i++) {
      final entry = dated[i];
      try {
        await entry.file.delete();
        _recency.remove(entry.path);
      } catch (_) {
        // Purge best-effort : un fichier verrouillé n'empêche pas l'affichage.
      }
    }
  }

  static String _sha1Hex(String url) =>
      sha1.convert(utf8.encode(url)).toString();

  /// Transport réel (CDN Discord) : octets bruts, `null` sur toute erreur.
  static Future<Uint8List?> _downloadBytes(String url) async {
    final client = HttpClient()..connectionTimeout = _requestTimeout;
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final builder = BytesBuilder(copy: false);
      await for (final chunk in response) {
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
