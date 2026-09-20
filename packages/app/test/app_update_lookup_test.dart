// Parseur de la réponse du lookup iTunes — test PUR sur FIXTURES.
//
// La fixture « normale » reproduit la forme réelle de
// `itunes.apple.com/lookup?bundleId=fr.botcreator.app&country=fr`.
// Le contrat : rendre `null` honnêtement plutôt que d'inventer une version —
// une version inventée ferait proposer une mise à jour fantôme, ou pire,
// ferait croire à l'utilisateur qu'il est à jour.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/app_update/logic/app_update_models.dart';

/// Réponse réelle (forme), app publiée : « Bot Creator Studio » / 2.2.0.
const String _lookupFoundJson = '''
{
  "resultCount": 1,
  "results": [
    {
      "wrapperType": "software",
      "kind": "software",
      "trackId": 6760181193,
      "trackName": "Bot Creator Studio",
      "bundleId": "fr.botcreator.app",
      "version": "2.2.0",
      "country": "FRA",
      "trackViewUrl": "https://apps.apple.com/fr/app/bot-creator-studio/id6760181193?uo=4",
      "releaseNotes": "Correctifs AdMob et barème publicitaire.",
      "currentVersionReleaseDate": "2026-08-30T12:00:00Z"
    }
  ]
}
''';

const String _lookupNotFoundJson = '{"resultCount":0,"results":[]}';

void main() {
  group('parseAppStoreLookup — réponse normale', () {
    test('extrait version, trackId, fiche, notes et date', () {
      final release = parseAppStoreLookup(_lookupFoundJson);
      expect(release, isNotNull);
      expect(release!.version, '2.2.0');
      expect(release.trackId, '6760181193');
      expect(
        release.storeUri.toString(),
        'https://apps.apple.com/fr/app/bot-creator-studio/id6760181193?uo=4',
      );
      expect(release.releaseNotes, 'Correctifs AdMob et barème publicitaire.');
      expect(release.releaseDate, '2026-08-30T12:00:00Z');
    });

    test('la version publiée se compare à la version installée', () {
      final release = parseAppStoreLookup(_lookupFoundJson)!;
      expect(isNewerVersion(release.version, '2.1.10+94'), isTrue);
      expect(isNewerVersion(release.version, '2.2.0+94'), isFalse);
      expect(isNewerVersion(release.version, '2.3.0'), isFalse);
    });
  });

  group('parseAppStoreLookup — cas honnêtes de null', () {
    test('resultCount == 0 (app absente du store) → null', () {
      expect(parseAppStoreLookup(_lookupNotFoundJson), isNull);
    });

    test('JSON illisible → null, sans exception', () {
      expect(parseAppStoreLookup('<html>403 Forbidden</html>'), isNull);
      expect(parseAppStoreLookup('{'), isNull);
      expect(parseAppStoreLookup('null'), isNull);
      expect(parseAppStoreLookup('[]'), isNull);
    });

    test('chaîne vide ou blanche → null', () {
      expect(parseAppStoreLookup(''), isNull);
      expect(parseAppStoreLookup('   '), isNull);
    });

    test('resultCount incohérent avec results → null', () {
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":[]}'),
        isNull,
        reason: 'Annoncer 1 résultat et n\'en servir aucun n\'est pas lisible.',
      );
      expect(
        parseAppStoreLookup('{"resultCount":0,"results":[{"version":"9.9.9"}]}'),
        isNull,
        reason: 'resultCount fait foi : ne pas lire une version qu\'Apple '
            'déclare absente.',
      );
      expect(parseAppStoreLookup('{"results":[{"version":"2.2.0"}]}'), isNull);
    });

    test('champs attendus manquants ou mal typés → null', () {
      expect(parseAppStoreLookup('{"resultCount":1,"results":[{}]}'), isNull);
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":[{"version":""}]}'),
        isNull,
      );
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":[{"version":"  "}]}'),
        isNull,
      );
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":[{"version":2.2}]}'),
        isNull,
      );
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":"oops"}'),
        isNull,
      );
    });
  });

  group('parseAppStoreLookup — fiche reconstruite quand trackViewUrl manque',
      () {
    test('trackId présent, trackViewUrl absent → fiche dérivée', () {
      final release = parseAppStoreLookup(
        '{"resultCount":1,"results":[{"version":"2.2.0","trackId":6760181193,'
        '"country":"FRA"}]}',
        fallbackCountry: 'us',
      );
      expect(release, isNotNull);
      expect(release!.version, '2.2.0');
      // Le pays vient de l'APPEL, pas du champ `country` de la réponse
      // (« FRA » n'est pas un segment d'URL de fiche).
      expect(
        release.storeUri.toString(),
        'https://apps.apple.com/us/app/id6760181193',
      );
    });

    test('pays de repli par défaut : fr', () {
      final release = parseAppStoreLookup(
        '{"resultCount":1,"results":[{"version":"2.2.0","trackId":6760181193}]}',
      );
      expect(
        release!.storeUri.toString(),
        'https://apps.apple.com/fr/app/id6760181193',
      );
    });

    test('ni trackViewUrl ni trackId → null (aucune fiche à ouvrir)', () {
      expect(
        parseAppStoreLookup('{"resultCount":1,"results":[{"version":"2.2.0"}]}'),
        isNull,
      );
    });

    test('trackId numérique est normalisé en chaîne', () {
      final release = parseAppStoreLookup(
        '{"resultCount":1,"results":[{"version":"2.2.0","trackId":6760181193,'
        '"trackViewUrl":"https://apps.apple.com/fr/app/id6760181193"}]}',
      );
      expect(release!.trackId, '6760181193');
    });
  });

  group('NON-VACUITÉ : la fixture est bien celle du JSON attendu', () {
    test('le JSON de fixture est décodable et porte les clés du contrat', () {
      final decoded =
          jsonDecode(_lookupFoundJson) as Map<String, dynamic>;
      expect(decoded['resultCount'], 1);
      final first = (decoded['results'] as List).first as Map<String, dynamic>;
      for (final key in <String>[
        'version',
        'trackId',
        'trackViewUrl',
        'releaseNotes',
        'currentVersionReleaseDate',
      ]) {
        expect(first.containsKey(key), isTrue, reason: 'clé $key absente');
      }
    });
  });
}
