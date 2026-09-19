import 'dart:async';

import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:test/test.dart';

/// Sortie audio factice : aucun serveur Lavalink, aucun réseau.
///
/// Elle joue le rôle du player réel — dont elle reproduit le comportement
/// observable : `play()` remplace le morceau courant, et le morceau « joué »
/// n'est confirmé qu'à l'arrivée d'un `TrackStart` ([confirmPlay]).
class _FakeOutput implements LavalinkAudioOutput {
  _FakeOutput({this.confirmPlay = true});

  /// Quand false, [play] ne fait pas encore apparaître le morceau comme joué :
  /// c'est le délai réel entre la requête et l'événement `TrackStart`.
  final bool confirmPlay;

  final List<Track> played = <Track>[];
  int stopCount = 0;
  int pauseCount = 0;
  int resumeCount = 0;
  int volume = 100;

  Track? _current;
  bool _connected = true;

  @override
  Future<void> play(Track track) async {
    played.add(track);
    if (confirmPlay) _current = track;
  }

  /// Simule l'arrivée de l'événement `TrackStart` pour le dernier morceau joué.
  void confirmLastPlay() {
    if (played.isNotEmpty) _current = played.last;
  }

  /// Simule la réaction du VRAI player à une fin de morceau : `LavalinkPlayer`
  /// remet `currentTrack` à `null` sur `TrackEnd`
  /// (nyxx_lavalink 4.1.0, `lavalink_player.dart:86`). Sans cela, la sortie
  /// factice prétendrait qu'un morceau continue de jouer après sa fin.
  void endCurrentTrack() {
    _current = null;
  }

  @override
  Future<void> stop() async {
    stopCount++;
    _current = null;
  }

  @override
  Future<void> setPaused(bool paused) async {
    paused ? pauseCount++ : resumeCount++;
  }

  @override
  Future<void> setVolume(int value) async {
    volume = value;
  }

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> disconnect() async {
    _connected = false;
    _current = null;
  }

  @override
  Track? get currentTrack => _current;

  @override
  Duration get position => Duration.zero;

  @override
  bool get isConnected => _connected;
}

/// Fabrique un morceau identifiable par sa charge utile encodée.
Track _track(String id) {
  return Track.fromJson(<String, Object?>{
    'encoded': 'encoded-$id',
    'info': <String, Object?>{
      'identifier': id,
      'isSeekable': true,
      'author': 'auteur',
      'length': 1000,
      'isStream': false,
      'position': 0,
      'title': 'titre-$id',
      'uri': 'https://example.com/$id',
      'artworkUrl': 'https://example.com/$id.png',
      'isrc': null,
      'sourceName': 'youtube',
    },
    'pluginInfo': <String, Object?>{},
    'userData': null,
  });
}

void main() {
  late _FakeOutput output;
  late LavalinkSession session;

  setUp(() {
    output = _FakeOutput();
    session = LavalinkSession(output: output);
  });

  /// Fin de morceau telle que le player la vit réellement : le player lâche son
  /// morceau courant, PUIS la session enchaîne. C'est exactement ce que branche
  /// `LavalinkSession.fromPlayer` sur un vrai `LavalinkPlayer`.
  Future<void> endAndAdvance(String reason) async {
    output.endCurrentTrack();
    await session.handleTrackEnd(reason);
  }

  group(r'$skipMusic — le skip ne rejoue JAMAIS le morceau courant', () {
    test('passe au morceau suivant distinct', () async {
      final a = _track('a');
      final b = _track('b');
      final c = _track('c');

      await session.enqueue(a);
      await session.enqueue(b);
      await session.enqueue(c);
      expect(output.played, <Track>[a], reason: 'un seul démarrage');

      await session.skip();
      expect(output.played.last, b);
      expect(session.currentTrack, b);
      expect(output.played.where((t) => t.encoded == a.encoded), hasLength(1));
    });

    test('deux skips d\'affilée avancent de deux morceaux', () async {
      final a = _track('a');
      final b = _track('b');
      final c = _track('c');

      await session.enqueue(a);
      await session.enqueue(b);
      await session.enqueue(c);

      await session.skip();
      await session.skip();

      expect(output.played.map((t) => t.encoded).toList(), <String>[
        'encoded-a',
        'encoded-b',
        'encoded-c',
      ]);
      expect(session.currentTrack, c);
    });

    test('file d\'un seul morceau en boucle : skip arrête proprement, ne rejoue pas', () async {
      final a = _track('a');
      await session.enqueue(a);
      session.setLoop(true);

      await session.skip();

      expect(output.played, <Track>[a], reason: 'le skip ne rejoue pas le morceau courant');
      expect(output.stopCount, 1, reason: 'file épuisée => arrêt propre');
      expect(session.isPlaying, isFalse);
      expect(session.currentTrack, isNull);
    });

    test('file vide : skip est un arrêt propre sans erreur', () async {
      await session.skip();

      expect(output.played, isEmpty);
      expect(output.stopCount, 1);
      expect(session.isPlaying, isFalse);
    });

    test('en boucle, un skip sur le dernier morceau NE boucle PAS : la boucle ne s\'applique jamais à un skip', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);
      session.setLoop(true);

      await session.skip(); // a -> b
      await session.skip(); // fin de file : le skip s'arrête, il ne revient pas à a

      expect(
        output.played.map((t) => t.encoded).toList(),
        <String>['encoded-a', 'encoded-b'],
        reason: 'la boucle est réservée à l\'enchaînement automatique',
      );
      expect(output.stopCount, 1, reason: 'file épuisée => arrêt propre');
      expect(session.currentTrack, isNull);
      expect(session.isPlaying, isFalse);
      expect(session.loop, isTrue, reason: 'la boucle reste active pour la suite');
    });
  });

  group('file d\'attente — un seul modèle, aucune croissance parasite', () {
    test('ajouter N morceaux donne exactement N entrées à jouer', () async {
      final tracks = <Track>[
        _track('1'),
        _track('2'),
        _track('3'),
        _track('4'),
        _track('5'),
      ];

      for (final track in tracks) {
        await session.enqueue(track);
      }

      expect(session.queueLength, 5, reason: 'N entrées, pas une de plus');
      expect(output.played, hasLength(1), reason: 'seul le premier démarre');
      expect(session.queueSize, 4, reason: 'queueSize = morceaux encore à jouer');
      expect(
        session.entries.map((t) => t.encoded).toSet(),
        hasLength(5),
        reason: 'aucun doublon',
      );
    });

    test('le rapport utilisateur : 30 morceaux demandés = 30 entrées, jamais 60', () async {
      for (var i = 0; i < 30; i++) {
        await session.enqueue(_track('t$i'));
      }

      expect(session.queueLength, 30);
      expect(session.queueSize, 29, reason: 'file de 30 morceaux, 1 en cours');
      expect(
        session.entries.map((t) => t.encoded).toSet(),
        hasLength(30),
        reason: '« the queue it just adding a queue of 15 or 30 » : ici 30, pas de dérive',
      );
      expect(output.played, hasLength(1));
    });

    test('un ajout pendant la lecture ne rejoue pas et ne duplique rien', () async {
      final a = _track('a');
      final b = _track('b');

      await session.enqueue(a);
      await session.enqueue(b);

      expect(output.played, <Track>[a]);
      expect(session.queueLength, 2);
      expect(session.currentTrack, a, reason: 'le morceau courant ne change pas');
    });

    test('sans confirmation TrackStart, un second ajout ne remplace pas le premier', () async {
      output = _FakeOutput(confirmPlay: false);
      session = LavalinkSession(output: output);

      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      expect(
        output.played,
        <Track>[a],
        reason: 'sans confirmation, B attend son tour au lieu de remplacer A',
      );
      expect(session.isPlaying, isTrue, reason: 'le démarrage en cours compte comme lecture');
    });

    test('la file ne compte jamais deux fois le morceau en cours', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      final encoded = session.entries.map((t) => t.encoded).toList();
      expect(encoded.where((e) => e == 'encoded-a'), hasLength(1));
      expect(session.queueSize, 1);
    });
  });

  group('fin de morceau — enchaînement automatique', () {
    test('la fin d\'un morceau enchaîne sur le suivant sans intervention', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      await endAndAdvance('finished');

      expect(output.played.map((t) => t.encoded).toList(), <String>[
        'encoded-a',
        'encoded-b',
      ]);
      expect(session.currentTrack, b);
      expect(session.isPlaying, isTrue);
    });

    test('la fin du dernier morceau arrête la file, sans boucle', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      await endAndAdvance('finished'); // -> b
      await endAndAdvance('finished'); // fin de b

      expect(output.played, hasLength(2));
      expect(session.isPlaying, isFalse);
      expect(session.queueSize, 0);
    });

    test('la boucle, choisie explicitement, repart au début', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);
      session.setLoop(true);

      await endAndAdvance('finished'); // a -> b
      await endAndAdvance('finished'); // b -> a (boucle)

      expect(output.played.map((t) => t.encoded).toList(), <String>[
        'encoded-a',
        'encoded-b',
        'encoded-a',
      ]);
      expect(session.loop, isTrue);
    });

    test('`replaced` (remplacement volontaire) n\'avance pas deux fois', () async {
      final a = _track('a');
      final b = _track('b');
      final c = _track('c');
      await session.enqueue(a);
      await session.enqueue(b);
      await session.enqueue(c);

      // Un skip remplace le morceau : Lavalink signale l'ancien en `replaced`.
      await session.skip();
      await endAndAdvance('replaced');

      expect(
        output.played.map((t) => t.encoded).toList(),
        <String>['encoded-a', 'encoded-b'],
        reason: 'pas de double avancement',
      );
      expect(session.currentTrack, b);
    });

    test('l\'arrêt (stopMusic) ne relance rien ensuite', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      await session.stop();
      await endAndAdvance('stopped');

      expect(output.played, hasLength(1));
      expect(output.stopCount, 1);
      expect(session.queueSize, 0);
      expect(session.isPlaying, isFalse);
    });
  });

  group('câblage des événements — la file avance toute seule', () {
    test('un vrai flux de fins de morceau fait avancer la file', () async {
      final events = StreamController<String>();
      addTearDown(events.close);

      final a = _track('a');
      final b = _track('b');
      final local = LavalinkSession(output: output, trackEndReasons: events.stream);

      await local.enqueue(a);
      await local.enqueue(b);

      events.add('finished');
      await pumpEventQueue();

      expect(local.currentTrack, b);
      expect(output.played.map((t) => t.encoded).toList(), <String>[
        'encoded-a',
        'encoded-b',
      ]);
    });

    test('un flux `replaced` ne fait pas avancer la file', () async {
      final events = StreamController<String>();
      addTearDown(events.close);

      final a = _track('a');
      final b = _track('b');
      final local = LavalinkSession(output: output, trackEndReasons: events.stream);

      await local.enqueue(a);
      await local.enqueue(b);

      events.add('replaced');
      await pumpEventQueue();

      expect(output.played, <Track>[a]);
      expect(local.currentTrack, a);
    });
  });

  group('contrôles de lecture', () {
    test('pause/resume/volume restent cohérents avec la session', () async {
      await session.enqueue(_track('a'));

      await session.pause();
      expect(session.isPaused, isTrue);
      expect(output.pauseCount, 1);

      await session.resume();
      expect(session.isPaused, isFalse);
      expect(output.resumeCount, 1);

      await session.setVolume(250);
      expect(session.volume, 200, reason: 'borné à 200');
      expect(output.volume, 200);
    });

    test('rebrancher la session conserve la file sans la dupliquer', () async {
      final a = _track('a');
      final b = _track('b');
      await session.enqueue(a);
      await session.enqueue(b);

      final newOutput = _FakeOutput();
      session.rebind(output: newOutput);

      expect(session.queueLength, 2, reason: 'la file est conservée, jamais recopiée');
      expect(newOutput.played, isEmpty, reason: 'aucun redémarrage');
    });
  });
}
