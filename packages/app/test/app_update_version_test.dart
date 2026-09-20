// Comparateur de versions — test PUR, sans plateforme ni plugin.
//
// C'est le verrou central du sujet : `isNewerVersion` décide si l'app propose
// une mise à jour. S'il redevenait une comparaison de chaînes, ces cas
// échoueraient (voir le dernier test, qui documente le piège explicitement).
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/app_update/logic/app_update_models.dart';

void main() {
  group('isNewerVersion — comparaison numérique segment par segment', () {
    test('longueurs inégales : 2.2 vs 2.2.0 → PAS de mise à jour', () {
      expect(isNewerVersion('2.2', '2.2.0'), isFalse);
      expect(isNewerVersion('2.2.0', '2.2'), isFalse);
      expect(isNewerVersion('2', '2.0.0'), isFalse);
    });

    test('2.2.10 vs 2.2.9 → mise à jour', () {
      expect(isNewerVersion('2.2.10', '2.2.9'), isTrue);
      expect(isNewerVersion('2.2.9', '2.2.10'), isFalse);
    });

    test('2.10.0 vs 2.9.9 → mise à jour', () {
      expect(isNewerVersion('2.10.0', '2.9.9'), isTrue);
      expect(isNewerVersion('2.9.9', '2.10.0'), isFalse);
    });

    test('suffixe +build ignoré des deux côtés', () {
      // « 2.2.0+94 » est un numéro de build, pas une version plus récente.
      expect(isNewerVersion('2.2.0+94', '2.2.0'), isFalse);
      expect(isNewerVersion('2.2.0', '2.2.0+94'), isFalse);
      expect(isNewerVersion('2.2.0+95', '2.2.0+94'), isFalse);
      // …mais il ne masque pas une vraie différence de version.
      expect(isNewerVersion('2.2.1+1', '2.2.0+94'), isTrue);
      expect(isNewerVersion('2.3.0+1', '2.2.0+94'), isTrue);
    });

    test('version du store plus ancienne → pas de mise à jour (pas de retour '
        'en arrière proposé)', () {
      expect(isNewerVersion('2.1.0', '2.2.0'), isFalse);
      expect(isNewerVersion('1.9.9', '2.0.0'), isFalse);
    });

    test('version identique → pas de mise à jour', () {
      expect(isNewerVersion('2.2.0', '2.2.0'), isFalse);
    });

    test('chaîne vide ou blanche → false (aucune conclusion)', () {
      expect(isNewerVersion('', '2.2.0'), isFalse);
      expect(isNewerVersion('2.2.0', ''), isFalse);
      expect(isNewerVersion('   ', '   '), isFalse);
      expect(isNewerVersion('2.2.0', '   '), isFalse);
    });

    test('format inattendu → false, jamais d\'exception', () {
      expect(isNewerVersion('inconnu', '2.2.0'), isFalse);
      expect(isNewerVersion('2.2.0', 'inconnu'), isFalse);
      expect(isNewerVersion('2.x.0', '2.1.0'), isFalse);
      expect(isNewerVersion('2..0', '2.0.0'), isFalse);
      expect(isNewerVersion('+', '2.0.0'), isFalse);
      expect(isNewerVersion('2.2.0 (build 94)', '2.2.0'), isFalse);
      expect(isNewerVersion('99999999999999999999', '2.2.0'), isFalse,
          reason: 'Segment hors plage entière : on refuse de conclure, on ne '
              'lève pas (int.parse lèverait une FormatException).');
    });

    test('tolérances utiles : préfixe v, préversion -rc, espaces', () {
      expect(isNewerVersion('v2.3.0', '2.2.0'), isTrue);
      expect(isNewerVersion('2.3.0-rc1', '2.2.9'), isTrue);
      expect(isNewerVersion(' 2.3.0 ', '2.2.0'), isTrue);
      // Une préversion du même numéro n'est pas une mise à jour publiée.
      expect(isNewerVersion('2.2.0-rc1', '2.2.0'), isFalse);
    });

    test('NON-VACUITÉ : le piège de la comparaison de chaînes est réel', () {
      // Ce que ferait une comparaison lexicographique : elle déclare « à jour »
      // à partir de la 2.10 (2.10 < 2.9 en chaîne) et propose une mise à jour
      // qui n'existe pas. Les deux assertions ci-dessous échoueraient toutes
      // les deux si `isNewerVersion` comparait des chaînes.
      expect('2.10.0'.compareTo('2.9.0') < 0, isTrue);
      expect(isNewerVersion('2.10.0', '2.9.0'), isTrue);
      expect('2.2.10'.compareTo('2.2.9') < 0, isTrue);
      expect(isNewerVersion('2.2.10', '2.2.9'), isTrue);
    });
  });

  group('resolveLookupCountry — pays du lookup App Store', () {
    test('pays dérivé de la locale, en minuscules', () {
      expect(resolveLookupCountry('FR'), 'fr');
      expect(resolveLookupCountry('us'), 'us');
      expect(resolveLookupCountry('DE'), 'de');
    });

    test('locale sans pays ou absente → repli fr', () {
      expect(resolveLookupCountry(null), kAppStoreFallbackCountry);
      expect(resolveLookupCountry(''), kAppStoreFallbackCountry);
      expect(resolveLookupCountry('   '), kAppStoreFallbackCountry);
      expect(resolveLookupCountry('und'), kAppStoreFallbackCountry);
      expect(resolveLookupCountry('fr-FR'), kAppStoreFallbackCountry);
    });
  });

  group('fiches de store — URL de repli', () {
    test('Play Store : applicationId fr.botcreator.app', () {
      final uri = playStoreListingUri();
      expect(uri.host, 'play.google.com');
      expect(uri.queryParameters['id'], kStoreApplicationId);
      expect(kStoreApplicationId, 'fr.botcreator.app');
    });

    test('App Store : fiche reconstruite depuis le trackId', () {
      final uri = appStoreListingUri(trackId: '6760181193', country: 'fr');
      expect(uri.toString(), 'https://apps.apple.com/fr/app/id6760181193');
    });
  });
}
