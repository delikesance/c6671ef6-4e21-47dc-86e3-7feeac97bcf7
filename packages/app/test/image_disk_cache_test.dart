// Cache d'images sur disque (`ImageDiskCache`) et son branchement dans
// `HomeBotAvatar`.
//
// Contrat verrouillé ici (« caching des images pour éviter de call des images
// via HTTP ») :
//
//   * le second appel ne fait AUCUNE requête HTTP : les octets sont relus sur
//     le disque, y compris après un « redémarrage » (nouvelle instance sur le
//     même dossier) ;
//   * au-delà du plafond d'entrées, les fichiers les moins récemment utilisés
//     sont purgés (LRU par date de modification) ;
//   * une URL en échec ne lève jamais : repli `NetworkImage`, rien d'écrit ;
//   * deux demandes concurrentes de la même URL ne téléchargent qu'une fois ;
//   * `HomeBotAvatar` sert bien l'image depuis le disque (un seul GET).
//
// Dossier injecté (`Directory.systemTemp`) et `fetcher` factice : ni le dossier
// réel de l'app, ni le réseau, ne sont touchés.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bot_creator/core/network/image_disk_cache.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;

/// PNG 1×1 valide (70 octets) : les octets mis en cache sont décodables.
final Uint8List _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

const String _urlA = 'https://cdn.discordapp.com/icons/1/hash_a.png?size=128';
const String _urlB = 'https://cdn.discordapp.com/icons/2/hash_b.png?size=128';
const String _urlC = 'https://cdn.discordapp.com/icons/3/hash_c.png?size=128';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('image_disk_cache_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  ImageDiskCache cacheWith(
    Future<Uint8List?> Function(String url) fetcher, {
    int maxEntries = ImageDiskCache.defaultMaxEntries,
  }) => ImageDiskCache(
    cacheDirResolver: () async => tmp,
    fetcher: fetcher,
    maxEntries: maxEntries,
  );

  Future<List<File>> cachedFiles() async {
    final dir = Directory(p.join(tmp.path, ImageDiskCache.cacheFolderName));
    if (!await dir.exists()) return const <File>[];
    final entries = await dir.list().toList();
    return entries
        .whereType<File>()
        .where((file) => file.path.endsWith('.img'))
        .toList();
  }

  String fileNameFor(String url) => '${sha1.convert(utf8.encode(url))}.img';

  setUpAll(() {
    // Convention du dépôt : la typo est bundlée, jamais récupérée au runtime.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('le second appel sert le disque, sans aucune requête HTTP', () async {
    var hits = 0;
    Future<Uint8List?> fetcher(String url) async {
      hits++;
      return _pngBytes;
    }

    final first = cacheWith(fetcher);
    final provider = await first.providerFor(_urlA);

    expect(hits, 1);
    expect(provider, isA<FileImage>());
    expect((provider as FileImage).file.existsSync(), isTrue);
    expect((await cachedFiles()), hasLength(1));

    // Nouvelle instance sur le même dossier = redémarrage de l'app.
    final restarted = cacheWith(fetcher);
    final again = await restarted.providerFor(_urlA);

    expect(hits, 1, reason: 'le disque doit éviter tout nouveau GET');
    expect(again, isA<FileImage>());
  });

  test('le second appel sur la même instance sert la mémoire', () async {
    var hits = 0;
    final cache = cacheWith((url) async {
      hits++;
      return _pngBytes;
    });

    final first = await cache.providerFor(_urlA);
    final second = await cache.providerFor(_urlA);

    expect(hits, 1);
    expect(second, same(first));
  });

  test('purge LRU au-delà du plafond d\'entrées', () async {
    final cache = cacheWith((url) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return _pngBytes;
    }, maxEntries: 2);

    for (final url in <String>[_urlA, _urlB, _urlC]) {
      await cache.providerFor(url);
      // Marge pour que les dates de modification soient strictement ordonnées.
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }

    final files = await cachedFiles();
    expect(files, hasLength(2));
    final names = files.map((file) => p.basename(file.path)).toSet();
    expect(
      names,
      isNot(contains(fileNameFor(_urlA))),
      reason: 'le plus ancien fichier doit avoir été purgé',
    );
    expect(names, contains(fileNameFor(_urlC)));
  });

  test('une lecture disque rafraîchit la récence (LRU)', () async {
    var hits = 0;
    Future<Uint8List?> fetcher(String url) async {
      hits++;
      return _pngBytes;
    }

    // Session 1 : A puis B écrits (B est le plus récent à l'écriture).
    final first = cacheWith(fetcher, maxEntries: 2);
    await first.providerFor(_urlA);
    await first.providerFor(_urlB);
    expect(hits, 2);

    // « Redémarrage » sur le même dossier : A est relu DEPUIS LE DISQUE, ce
    // qui doit rafraîchir sa récence sans aucune requête HTTP.
    final restarted = cacheWith(fetcher, maxEntries: 2);
    expect(await restarted.providerFor(_urlA), isA<FileImage>());
    expect(hits, 2, reason: 'la relecture disque ne re-télécharge pas');

    // L'écriture de C dépasse le plafond : le moins récemment utilisé est B
    // (A vient d'être relu, C vient d'être écrit).
    await restarted.providerFor(_urlC);
    expect(hits, 3);

    final names = (await cachedFiles())
        .map((file) => p.basename(file.path))
        .toSet();
    expect(names, contains(fileNameFor(_urlA)), reason: 'A vient d\'être relu');
    expect(names, contains(fileNameFor(_urlC)));
    expect(
      names,
      isNot(contains(fileNameFor(_urlB))),
      reason: 'B est le moins récemment utilisé',
    );
  });

  test('une URL en échec retombe sur NetworkImage, sans rien écrire', () async {
    final cache = cacheWith((url) async => null);

    final provider = await cache.providerFor(_urlA);

    expect(provider, isA<NetworkImage>());
    expect((provider as NetworkImage).url, _urlA);
    expect(await cachedFiles(), isEmpty);
  });

  test('un fetcher qui lève ne casse pas l\'appel', () async {
    final cache = cacheWith((url) async => throw StateError('offline'));

    expect(await cache.providerFor(_urlA), isA<NetworkImage>());
  });

  test(
    'sans dossier disponible, repli réseau immédiat (aucun GET tenté)',
    () async {
      var hits = 0;
      final cache = ImageDiskCache(
        cacheDirResolver: () async => null,
        fetcher: (url) async {
          hits++;
          return _pngBytes;
        },
      );

      expect(await cache.providerFor(_urlA), isA<NetworkImage>());
      expect(hits, 0);
    },
  );

  test('deux demandes concurrentes ne téléchargent qu\'une fois', () async {
    var hits = 0;
    final gate = Completer<void>();
    final cache = cacheWith((url) async {
      hits++;
      await gate.future;
      return _pngBytes;
    });

    final both = Future.wait([
      cache.providerFor(_urlA),
      cache.providerFor(_urlA),
    ]);
    gate.complete();
    final providers = await both;

    expect(hits, 1);
    expect(providers.first, same(providers.last));
  });

  test('clear() vide la mémoire et le dossier', () async {
    var hits = 0;
    final cache = cacheWith((url) async {
      hits++;
      return _pngBytes;
    });

    await cache.providerFor(_urlA);
    expect(await cachedFiles(), hasLength(1));

    await cache.clear();
    expect(await cachedFiles(), isEmpty);

    // Le disque est vide : un nouvel appel doit re-télécharger.
    await cache.providerFor(_urlA);
    expect(hits, 2);
  });

  testWidgets('HomeBotAvatar sert l\'image depuis le disque (un seul GET)', (
    tester,
  ) async {
    var hits = 0;
    final cache = cacheWith((url) async {
      hits++;
      return _pngBytes;
    });

    // Le cache fait de la VRAIE I/O disque (dossier temporaire, écriture du
    // fichier, lecture) : sous le binding de test elle ne progresse que dans
    // `runAsync`, qui redonne une boucle d'événements réelle.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HomeBotAvatar(imageUrl: _urlA, diskCache: cache),
            ),
          ),
        ),
      );
      // Rejoint la résolution lancée par l'avatar (téléchargement unique puis
      // écriture du fichier) et attend sa fin réelle.
      await cache.providerFor(_urlA);
      // Laisse le `FutureBuilder` recevoir le provider résolu.
      await tester.pump();
    });
    await tester.pump();

    expect(hits, 1);
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      image.image,
      isA<FileImage>(),
      reason: 'l\'avatar doit lire le fichier mis en cache',
    );
    expect((image.image as FileImage).file.existsSync(), isTrue);

    // Une seconde carte du même bot réutilise le provider mémoire : aucun GET.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: HomeBotAvatar(imageUrl: _urlA, diskCache: cache),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(hits, 1);
    expect(tester.takeException(), isNull);
  });
}
