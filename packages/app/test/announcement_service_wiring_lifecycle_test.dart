// Câblage RÉEL du service d'annonces in-app — volet CYCLE DE VIE et SESSION.
//
// Ce que cette suite prouve : une annonce publiée pendant que l'app était en
// arrière-plan apparaît au retour au premier plan — UNE fois, dans le budget de
// cadence — et l'absence de session (ou de client exploitable) ne déclenche
// aucune requête ni aucune erreur visible.
//
// Elle appartient à la suite de câblage, découpée par sujet ; le harnais commun
// (fixtures, charge utile, overlay, session simulée) vit dans
// `announcement_test_support.dart`, et nulle part ailleurs.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/features/announcements/logic/announcement_service.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';

import 'announcement_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpAnnouncementHarness);
  setUp(resetAnnouncementHarness);
  tearDown(disposeAnnouncementHarness);

  group('branche 6 — retour au premier plan', () {
    testWidgets(
      'l\'observateur relance UNE récupération, dans le budget de cadence',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        var fetches = 0;
        AnnouncementService.debugClientResolver = () async =>
            fakeAnnouncementClient();
        AnnouncementService.debugAnnouncementsFetcher = (_) async {
          fetches++;
          return bannerPayload();
        };

        await tester.pumpWidget(announcementHost(navigatorKey));

        // Même câblage que `main.dart` : la clé de navigation ET l'écoute du
        // cycle de vie sur le binding réel.
        AnnouncementService.install(key: navigatorKey, binding: tester.binding);

        // Premier retour au premier plan : aucun essai n'a encore eu lieu,
        // donc le budget laisse passer la requête.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        expect(
          fetches,
          1,
          reason: 'Le retour au premier plan relance une récupération.',
        );
        expect(find.byType(AnnouncementBanner), findsOneWidget);

        // Arrière-plan puis retour IMMÉDIAT : le budget de cadence refuse la
        // requête — on ne boucle pas sur chaque aller-retour.
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        await tester.pump();
        expect(
          fetches,
          1,
          reason:
              'Le budget (${AnnouncementService.nominalInterval.inMinutes} '
              'min) interdit un second appel immédiat.',
        );

        // Aucun observateur global ne reste derrière ce test.
        AnnouncementService.debugDetach(binding: tester.binding);
        expect(fetches, 1);
      },
    );
  });

  group('branche 7 — aucune session', () {
    testWidgets(
      'pas de session persistée : aucune requête, aucune erreur visible',
      (tester) async {
        // Le harnais a posé la charge utile sans jeton : pas de session.
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        var fetches = 0;
        var clientResolutions = 0;
        AnnouncementService.debugClientResolver = () async {
          clientResolutions++;
          return fakeAnnouncementClient();
        };
        AnnouncementService.debugAnnouncementsFetcher = (_) async {
          fetches++;
          return bannerPayload();
        };

        await tester.pumpWidget(announcementHost(navigatorKey));

        await AnnouncementService.refresh();
        await tester.pump();

        expect(fetches, 0, reason: 'Sans session, on ne parle pas au manager.');
        expect(
          clientResolutions,
          0,
          reason: 'Même la résolution du client est court-circuitée.',
        );
        expect(find.byType(AnnouncementBanner), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(tester.takeException(), isNull);

        final prefs = await SharedPreferences.getInstance();
        expect(seenIds(prefs), isEmpty);
      },
    );

    testWidgets(
      'session présente mais client introuvable : aucune requête, aucune '
      'erreur visible',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        var fetches = 0;
        AnnouncementService.debugClientResolver = () async => null;
        AnnouncementService.debugAnnouncementsFetcher = (_) async {
          fetches++;
          return bannerPayload();
        };

        await tester.pumpWidget(announcementHost(navigatorKey));

        await AnnouncementService.refresh();
        await tester.pump();

        expect(fetches, 0);
        expect(find.byType(AnnouncementBanner), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);

        final prefs = await SharedPreferences.getInstance();
        expect(seenIds(prefs), isEmpty);
      },
    );
  });
}
