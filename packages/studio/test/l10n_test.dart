import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_studio/src/auth/auth_controller.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/l10n_ext.dart';
import 'package:bot_creator_studio/src/locale_controller.dart';
import 'package:bot_creator_studio/src/studio_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _arb(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

const _locales = ['de', 'en', 'fr', 'ja', 'pt', 'tr'];

Set<String> _keys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

Set<String> _placeholders(String message) =>
    RegExp(r'\{(\w+)').allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final template = _arb('lib/l10n/app_en.arb');

  group('fichiers ARB', () {
    test('anglais et français définissent exactement les mêmes clés', () {
      expect(_keys(_arb('lib/l10n/app_fr.arb')), _keys(template));
    });

    test('aucune langue ne définit une clé inconnue du modèle', () {
      for (final l in _locales) {
        final extra = _keys(
          _arb('lib/l10n/app_$l.arb'),
        ).difference(_keys(template));
        expect(extra, isEmpty, reason: 'clés orphelines en $l');
      }
    });

    test('les paramètres sont les mêmes dans toutes les langues', () {
      for (final l in _locales) {
        final arb = _arb('lib/l10n/app_$l.arb');
        for (final key in _keys(arb)) {
          expect(
            _placeholders(arb[key] as String),
            _placeholders(template[key] as String),
            reason: '$l / $key',
          );
        }
      }
    });

    test('les clés avec paramètres déclarent leurs types dans le modèle', () {
      for (final key in _keys(template)) {
        final ph = _placeholders(template[key] as String);
        if (ph.isEmpty) continue;
        final meta = template['@$key'] as Map<String, dynamic>?;
        expect(meta, isNotNull, reason: key);
        expect((meta!['placeholders'] as Map).keys.toSet(), ph, reason: key);
      }
    });

    test('clés copiées de l\'app : valeur identique dans chaque langue', () {
      final shared =
          (jsonDecode(File('tool/l10n_shared.json').readAsStringSync()) as Map)
              .cast<String, String>();
      expect(shared, isNotEmpty);
      for (final l in _locales) {
        final studio = _arb('lib/l10n/app_$l.arb');
        final app = _arb('../ui/lib/src/l10n/app_$l.arb');
        shared.forEach((studioKey, appKey) {
          expect(
            studio[studioKey],
            app[appKey],
            reason:
                '$l : $studioKey devrait valoir $appKey de l\'app '
                '(lancez `dart run tool/l10n_sync.dart`)',
          );
        });
      }
    });
  });

  group('langue de l\'interface', () {
    Future<AuthController> signedOut() async {
      SharedPreferences.setMockInitialValues({});
      return AuthController(
        api: StudioApi(
          baseUrl: 'https://api.test',
          client: MockClient((_) async => http.Response('{}', 200)),
        ),
      );
    }

    testWidgets('la langue choisie change les textes', (tester) async {
      final locale = LocaleController();
      await tester.pumpWidget(
        StudioApp(auth: await signedOut(), locale: locale),
      );
      await tester.pumpAndSettle();

      await locale.set(const Locale('fr'));
      await tester.pumpAndSettle();
      expect(find.text('Se connecter avec Discord'), findsOneWidget);

      await locale.set(const Locale('en'));
      await tester.pumpAndSettle();
      // Ce texte vient de l'app : on compare à SON anglais, pas à une phrase écrite ici.
      final appEn = _arb('../ui/lib/src/l10n/app_en.arb');
      expect(
        find.text(appEn['marketplace_connect_discord'] as String),
        findsOneWidget,
      );
      expect(find.text('Se connecter avec Discord'), findsNothing);
    });

    testWidgets('texte repris de l\'app : traduit dans la langue de l\'app', (
      tester,
    ) async {
      // « Se connecter avec Discord » vient de l'app (marketplace_connect_discord).
      final appJa = _arb(
        '../ui/lib/src/l10n/app_ja.arb',
      )['marketplace_connect_discord'];
      final locale = LocaleController();
      await locale.set(const Locale('ja'));
      await tester.pumpWidget(
        StudioApp(auth: await signedOut(), locale: locale),
      );
      await tester.pumpAndSettle();
      expect(find.text(appJa as String), findsOneWidget);
    });

    testWidgets('clé propre au Studio sans traduction : repli sur l\'anglais', (
      tester,
    ) async {
      final locale = LocaleController();
      await locale.set(const Locale('ja'));
      await tester.pumpWidget(
        StudioApp(auth: await signedOut(), locale: locale),
      );
      await tester.pumpAndSettle();
      // loginSubtitle est propre au Studio : pas encore traduit en japonais.
      expect(
        find.text(
          'Sign in with Discord to access your bots. Studio always requires a valid sign-in.',
        ),
        findsOneWidget,
      );
    });

    test(
      'la langue est mémorisée, et une valeur inconnue est ignorée',
      () async {
        SharedPreferences.setMockInitialValues({'studio_locale_v1': 'tr'});
        final a = LocaleController();
        await a.load();
        expect(a.locale, const Locale('tr'));

        SharedPreferences.setMockInitialValues({'studio_locale_v1': 'xx'});
        final b = LocaleController();
        await b.load();
        expect(b.locale, isNull);

        await a.set(const Locale('de'));
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('studio_locale_v1'), 'de');
        await a.set(null);
        expect(prefs.getString('studio_locale_v1'), isNull);
      },
    );
  });

  test('chaque clé du Studio a un getter généré', () {
    // Évite d'oublier `flutter gen-l10n` après l'ajout d'une clé.
    final generated = File(
      'lib/l10n/app_localizations.dart',
    ).readAsStringSync();
    for (final key in _keys(template)) {
      expect(
        RegExp(r'\b' + key + r'\b').hasMatch(generated),
        isTrue,
        reason: key,
      );
    }
    expect(const [Locale('fr')], isNotEmpty);
    expect(StudioLocalizations.supportedLocales.length, 6);
  });
}
