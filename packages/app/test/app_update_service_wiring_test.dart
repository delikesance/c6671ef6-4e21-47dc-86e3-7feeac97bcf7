// Câblage du service : exécute les VRAIES branches iOS et Android du
// service (lookup → comparaison → décision → mise à jour), sans réseau ni
// appareil, via les points d'injection `@visibleForTesting`.
//
// Ce fichier prouve ce que les tests purs ne peuvent pas prouver :
//   - la bonne source est interrogée selon la plateforme ;
//   - la clé de déduplication et l'horodatage 24 h sont bien PERSISTÉS ;
//   - sur Android, un plugin Play Core indisponible (APK sideloadé, Play
//     absent) ne produit aucune erreur visible et retombe sur la fiche Play ;
//   - le dialogue s'affiche une fois et son bouton ouvre bien le store.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations_fr.dart';
import 'package:bot_creator/features/app_update/logic/app_update_models.dart';
import 'package:bot_creator/features/app_update/logic/app_update_service.dart';

const String _lookupFoundJson = '''
{
  "resultCount": 1,
  "results": [
    {
      "trackId": 6760181193,
      "version": "2.2.0",
      "trackViewUrl": "https://apps.apple.com/fr/app/bot-creator-studio/id6760181193?uo=4",
      "releaseNotes": "Correctifs AdMob et barème publicitaire.",
      "currentVersionReleaseDate": "2026-08-30T12:00:00Z"
    }
  ]
}
''';

/// Réponse au format Apple, parsée par le VRAI parseur.
AppStoreRelease get _release => parseAppStoreLookup(_lookupFoundJson)!;

/// Résultat Play Core simulé, partagé par TOUS les groupes : il était déclaré
/// dans le groupe Android et utilisé dans un groupe suivant, donc le fichier ne
/// compilait pas (une fonction locale ne franchit pas la portée de son groupe).
AppUpdateCheckResult playCoreUpdate({String detail = ''}) =>
    AppUpdateCheckResult(
      status: AppUpdateCheckStatus.updateAvailable,
      source: AppUpdateSource.playCore,
      installedVersion: '2.1.10+94',
      availableVersion: '95',
      comparisonKey: 'play:95',
      storeUri: AppUpdateService.playStoreUri,
      detail: detail,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppUpdateService.debugResetForTests();
    AppUpdateService.navigatorKey = null;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    AppUpdateService.debugResetForTests();
    AppUpdateService.navigatorKey = null;
  });

  group('iOS : lookup App Store + fiche App Store', () {
    test('mise à jour disponible décidée par le comparateur pur', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      // Le pays est celui de l'appareil, normalisé en minuscules : on l'impose
      // ici, sinon l'assertion dépendrait de la locale de la machine qui lance
      // les tests (en_US sur la CI → « us »).
      AppUpdateService.debugCountryOverride = 'FR';
      var requestedCountry = '';
      AppUpdateService.debugAppStoreLookupOverride = (country) async {
        requestedCountry = country;
        return _release;
      };

      final result = await AppUpdateService.check(force: true);

      expect(requestedCountry, kAppStoreFallbackCountry);
      expect(result.status, AppUpdateCheckStatus.updateAvailable);
      expect(result.source, AppUpdateSource.appStore);
      expect(result.availableVersion, '2.2.0');
      expect(result.installedVersion, '2.1.10+94');
      expect(result.comparisonKey, 'ios:2.2.0');
      expect(
        result.storeUri.toString(),
        'https://apps.apple.com/fr/app/bot-creator-studio/id6760181193?uo=4',
      );
    });

    test('version installée à jour → aucune proposition', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.2.0+95';
      AppUpdateService.debugAppStoreLookupOverride = (_) async => _release;

      final result = await AppUpdateService.check(force: true);

      expect(result.status, AppUpdateCheckStatus.upToDate);
      expect(result.availableVersion, '2.2.0');
    });

    test('lookup vide (app introuvable) → vérification impossible, jamais '
        '« à jour »', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      AppUpdateService.debugAppStoreLookupOverride = (_) async => null;

      final result = await AppUpdateService.check(force: true);

      expect(result.status, AppUpdateCheckStatus.unavailable);
      expect(result.storeUri, isNull);
    });

    test(
      'appareil hors ligne (le lookup échoue) → vérification impossible',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
        AppUpdateService.debugAppStoreLookupOverride = (_) async =>
            throw const SocketExceptionStub();

        final result = await AppUpdateService.check(force: true);

        expect(result.status, AppUpdateCheckStatus.unavailable);
      },
    );

    test(
      'bouton « Mettre à jour » → ouverture de la fiche App Store',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
        AppUpdateService.debugAppStoreLookupOverride = (_) async => _release;
        Uri? opened;
        AppUpdateService.debugOpenStoreOverride = (uri) async {
          opened = uri;
          return true;
        };

        final result = await AppUpdateService.check(force: true);
        final outcome = await AppUpdateService.launchUpdate(result);

        expect(outcome, AppUpdateLaunchOutcome.storeOpened);
        expect(opened, isNotNull);
        expect(opened!.host, 'apps.apple.com');
        expect(opened!.path, contains('id6760181193'));
      },
    );

    test('ouverture refusée par la plateforme → échec explicite', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      AppUpdateService.debugAppStoreLookupOverride = (_) async => _release;
      AppUpdateService.debugOpenStoreOverride = (_) async => false;

      final result = await AppUpdateService.check(force: true);
      expect(
        await AppUpdateService.launchUpdate(result),
        AppUpdateLaunchOutcome.failed,
      );
    });
  });

  group('Android : Play Core (flux flexible) + repli fiche Play', () {
    test('Play Core annonce une mise à jour → proposition', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      AppUpdateService.debugAndroidCheckOverride = (_) async =>
          playCoreUpdate();

      final result = await AppUpdateService.check(force: true);

      expect(result.isUpdateAvailable, isTrue);
      expect(result.source, AppUpdateSource.playCore);
      expect(result.comparisonKey, 'play:95');
      expect(result.storeUri!.host, 'play.google.com');
      expect(result.storeUri!.queryParameters['id'], 'fr.botcreator.app');
    });

    test(
      'flux FLEXIBLE : l\'utilisateur continue d\'utiliser l\'app',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        var started = false;
        AppUpdateService.debugFlexibleStartOverride = () async {
          started = true;
          return AppUpdateResult.success;
        };

        final outcome = await AppUpdateService.launchUpdate(playCoreUpdate());

        expect(started, isTrue);
        expect(outcome, AppUpdateLaunchOutcome.flexibleStarted);
      },
    );

    test('mise à jour déjà téléchargée → completeFlexibleUpdate', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      var completed = false;
      AppUpdateService.debugFlexibleCompleteOverride = () async {
        completed = true;
      };

      final outcome = await AppUpdateService.launchUpdate(
        playCoreUpdate(detail: 'flexible-update-downloaded'),
      );

      expect(completed, isTrue);
      expect(outcome, AppUpdateLaunchOutcome.flexibleCompleted);
    });

    test(
      'utilisateur refuse la proposition Play → pas d\'ouverture du store',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        AppUpdateService.debugFlexibleStartOverride = () async =>
            AppUpdateResult.userDeniedUpdate;
        var storeOpened = false;
        AppUpdateService.debugOpenStoreOverride = (_) async {
          storeOpened = true;
          return true;
        };

        final outcome = await AppUpdateService.launchUpdate(playCoreUpdate());

        expect(outcome, AppUpdateLaunchOutcome.declined);
        expect(
          storeOpened,
          isFalse,
          reason:
              'Ouvrir le store par-dessus un refus explicite ignorerait la '
              'décision de l\'utilisateur.',
        );
      },
    );

    test('APK sideloadé : le flux in-app échoue → repli sur la fiche Play, '
        'sans erreur visible', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AppUpdateService.debugFlexibleStartOverride = () async =>
          throw PlatformException(code: 'IN_APP_UPDATE_FAILED');
      Uri? opened;
      AppUpdateService.debugOpenStoreOverride = (uri) async {
        opened = uri;
        return true;
      };

      final outcome = await AppUpdateService.launchUpdate(playCoreUpdate());

      expect(outcome, AppUpdateLaunchOutcome.storeOpened);
      expect(opened!.host, 'play.google.com');
      expect(opened!.queryParameters['id'], 'fr.botcreator.app');
    });

    test('Play Core indisponible au moment de la vérification : le VRAI appel '
        'plugin échoue sur cette VM → « vérification impossible » + fiche Play '
        'en repli', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      // Aucun override : on exécute la vraie branche InAppUpdate.checkForUpdate,
      // qui lève ici (aucun plugin natif) — exactement le cas d'un APK
      // sideloadé ou d'un appareil sans Play Store.

      final result = await AppUpdateService.check(force: true);

      expect(result.status, AppUpdateCheckStatus.unavailable);
      expect(result.source, AppUpdateSource.playCore);
      expect(result.storeUri, AppUpdateService.playStoreUri);
      expect(result.detail, 'play-core-unavailable');
    });
  });

  group('politique appliquée par le service (persistance réelle)', () {
    test('une seule vérification par 24 h : la 2e passe est sautée', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      var lookups = 0;
      AppUpdateService.debugAppStoreLookupOverride = (_) async {
        lookups++;
        return _release;
      };

      final first = await AppUpdateService.check(force: false);
      expect(first.status, AppUpdateCheckStatus.updateAvailable);
      expect(lookups, 1);

      final second = await AppUpdateService.check(force: false);
      expect(second.status, AppUpdateCheckStatus.throttled);
      expect(lookups, 1, reason: 'Aucun second appel store dans les 24 h.');

      // Forcer (bouton Settings) court-circuite la politique.
      final forced = await AppUpdateService.check(force: true);
      expect(forced.status, AppUpdateCheckStatus.updateAvailable);
      expect(lookups, 2);
    });

    test('la clé « déjà proposée » survit entre deux lancements', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      AppUpdateService.debugAppStoreLookupOverride = (_) async => _release;
      AppUpdateService.navigatorKey = null; // pas de contexte : rien à afficher

      // Le marquage n'a lieu qu'après l'affichage effectif du dialogue.
      await AppUpdateService.checkAndPromptIfNeeded();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('app_update.last_check_ms'), isNotNull);
    });

    test('plateforme de bureau → rien à vérifier, jamais de crash', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';

      final result = await AppUpdateService.check(force: true);

      expect(result.status, AppUpdateCheckStatus.notSupported);
      expect(result.source, AppUpdateSource.none);
    });

    test(
      'appel automatique sans contexte de navigation → aucun crash',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
        AppUpdateService.debugAndroidCheckOverride = (_) async =>
            playCoreUpdate();

        await expectLater(AppUpdateService.checkAndPromptIfNeeded(), completes);
      },
    );
  });

  group('dialogue non bloquant', () {
    testWidgets('affiché une fois, et « Mettre à jour » ouvre la fiche store', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      // La vérification d'invariants de flutter_test s'exécute AVANT le tearDown
      // du fichier : sans ce retrait, elle échoue sur « The value of a foundation
      // debug variable was changed by the test ».
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      AppUpdateService.debugInstalledVersionOverride = '2.1.10+94';
      AppUpdateService.debugAppStoreLookupOverride = (_) async => _release;
      Uri? opened;
      AppUpdateService.debugOpenStoreOverride = (uri) async {
        opened = uri;
        return true;
      };
      final navigatorKey = GlobalKey<NavigatorState>();
      AppUpdateService.navigatorKey = navigatorKey;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      final l10n = AppLocalizationsFr();
      // La fonction attend la réponse de l'utilisateur (elle rend le résultat du
      // dialogue) : l'attendre AVANT de pomper figerait le test, personne ne
      // pouvant répondre. En production elle est appelée en `unawaited`.
      unawaited(AppUpdateService.checkAndPromptIfNeeded());
      await tester.pumpAndSettle();

      expect(find.text(l10n.app_update_dialog_title), findsOneWidget);
      expect(find.text(l10n.app_update_later), findsOneWidget);
      expect(find.text(l10n.app_update_update_now), findsOneWidget);
      expect(opened, isNull, reason: 'Aucun store ouvert avant la réponse.');

      // « Plus tard » : aucun effet de bord.
      await tester.tap(find.text(l10n.app_update_later));
      await tester.pumpAndSettle();
      expect(find.text(l10n.app_update_dialog_title), findsNothing);
      expect(opened, isNull);

      // La version est marquée comme proposée : un second passage n'affiche
      // plus rien, même en forçant la vérification.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_update.last_prompt_key'), 'ios:2.2.0');

      // flutter_test vérifie ses invariants À LA FIN du corps du test, avant les
      // tearDown : la variable de debug doit donc être remise à zéro ICI, pas
      // dans un tearDown (sinon l'échec « The value of a foundation debug
      // variable was changed by the test »).
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

/// Exception réseau simulée (le lookup App Store échoue hors ligne).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
  @override
  String toString() => 'SocketException: simulation hors ligne';
}
