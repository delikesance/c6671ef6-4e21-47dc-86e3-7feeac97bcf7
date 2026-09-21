// Câblage RÉEL du service d'annonces in-app — volet RÉSEAU.
//
// Ce que cette suite prouve, et que les décisions pures ne peuvent pas : une
// charge utile illisible n'affiche rien et ne plante rien, un appareil hors
// ligne n'est pas martelé, un serveur qui refuse la lecture reste muet côté
// utilisateur et aucun `Timer` de sondage n'est armé.
//
// Elle appartient à la suite de câblage, découpée par sujet ; le harnais commun
// (fixtures, charge utile, overlay, session simulée) vit dans
// `announcement_test_support.dart`, et nulle part ailleurs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/announcements/logic/announcement_presenter.dart';
import 'package:bot_creator/features/announcements/logic/announcement_service.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';

import 'announcement_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpAnnouncementHarness);
  setUp(resetAnnouncementHarness);
  tearDown(disposeAnnouncementHarness);

  group('branche 3 — entrées illisibles', () {
    testWidgets(
      'une seule entrée valide parmi des illisibles : seule la valide '
      's\'affiche',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        AnnouncementService.debugClientResolver = () async =>
            fakeAnnouncementClient();
        AnnouncementService.debugAnnouncementsFetcher = (_) async =>
            <Map<String, dynamic>>[
              // Gravité inconnue (manager plus récent que l'app) : ignorée.
              <String, dynamic>{
                'id': 'ann-gravite-inconnue',
                'title': 'Gravité inconnue',
                'severity': 'catastrophe',
              },
              // Sans identifiant : impossible à dédupliquer, donc à afficher.
              <String, dynamic>{
                'title': 'Sans identifiant',
                'severity': 'critical',
              },
              // Entrée valide : c'est la SEULE qui doit passer.
              ...bannerPayload(),
            ];

        await tester.pumpWidget(announcementHost(navigatorKey));

        await AnnouncementService.refresh();
        await tester.pump();

        expect(find.byType(AnnouncementBanner), findsOneWidget);
        expect(find.text(bannerTitle), findsOneWidget);
        expect(find.text('Gravité inconnue'), findsNothing);
        // L'annonce affichée n'est pas encore acquittée par l'utilisateur :
        expect(AnnouncementPresenter.sessionDismissedIds, isEmpty);

        // Fermeture par l'utilisateur :
        await tester.tap(find.byTooltip(tr.announcement_dismiss));
        await tester.pump();
        expect(AnnouncementPresenter.sessionDismissedIds, <String>{bannerId});
      },
    );

    testWidgets(
      'charge utile entièrement illisible : rien à l\'écran et aucun crash',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        var fetches = 0;
        AnnouncementService.debugClientResolver = () async =>
            fakeAnnouncementClient();
        AnnouncementService.debugAnnouncementsFetcher = (_) async {
          fetches++;
          return <Map<String, dynamic>>[
            // Type d'identifiant inattendu.
            <String, dynamic>{'id': <String>[], 'severity': 'info'},
            // Identifiant vide.
            <String, dynamic>{'id': '   ', 'title': 'X', 'severity': 'info'},
            // Titre vide : l'annonce n'a rien à dire.
            <String, dynamic>{
              'id': 'ann-sans-titre',
              'title': '  ',
              'severity': 'info',
            },
            // Aucune gravité du tout.
            <String, dynamic>{'id': 'ann-sans-gravite', 'title': 'Y'},
          ];
        };

        await tester.pumpWidget(announcementHost(navigatorKey));

        await AnnouncementService.refresh();
        await tester.pump();

        // La requête a bien eu lieu : c'est la charge utile qui ne donne rien.
        expect(fetches, 1);
        expect(find.byType(AnnouncementBanner), findsNothing);
        expect(find.text(bannerTitle), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);

        final prefs = await SharedPreferences.getInstance();
        expect(seenIds(prefs), isEmpty);
      },
    );
  });

  group('branche 4 — appareil hors ligne', () {
    testWidgets('aucune bannière, et l\'appel suivant ne repart PAS en requête '
        '(cooldown hors ligne)', (tester) async {
      useValidSession();
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      var fetches = 0;
      AnnouncementService.debugClientResolver = () async =>
          fakeAnnouncementClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async {
        fetches++;
        throw const SimulatedOfflineFailure();
      };

      await tester.pumpWidget(announcementHost(navigatorKey));

      await AnnouncementService.refresh();
      await tester.pump();
      expect(fetches, 1);
      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(tester.takeException(), isNull);

      // Démarrage + retour au premier plan : la seconde demande est
      // refusée AVANT le réseau — le compteur le prouve.
      await AnnouncementService.refresh();
      await tester.pump();
      expect(
        fetches,
        1,
        reason:
            'Hors ligne : ne pas retenter avant '
            '${AnnouncementService.offlineCooldown.inMinutes} min.',
      );
      expect(AnnouncementService.offlineCooldown, const Duration(minutes: 10));

      // `force` reste la sortie explicite (action utilisateur) : elle repart.
      await AnnouncementService.refresh(force: true);
      await tester.pump();
      expect(fetches, 2);
      expect(find.byType(AnnouncementBanner), findsNothing);
    });
  });

  group('branche 5 — le serveur refuse la lecture (4xx)', () {
    testWidgets('muet côté utilisateur, aucun timer de sondage armé, pas de '
        'martèlement du serveur', (tester) async {
      useValidSession();
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      var fetches = 0;
      AnnouncementService.debugClientResolver = () async =>
          fakeAnnouncementClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async {
        fetches++;
        throw const MainApiClientException(
          'Lecture des annonces refusée',
          statusCode: 403,
        );
      };

      await tester.pumpWidget(announcementHost(navigatorKey));

      // On enregistre tout `Timer` créé pendant la récupération : la
      // fonctionnalité n'a le droit d'en armer AUCUN (la cadence est
      // consultée à chaque déclenchement, elle ne boucle pas seule).
      final armed = <String>[];
      await runZoned(
        () async {
          await AnnouncementService.refresh();
        },
        zoneSpecification: ZoneSpecification(
          createTimer: (self, parent, zone, duration, function) {
            armed.add('Timer($duration)');
            return parent.createTimer(zone, duration, function);
          },
          createPeriodicTimer: (self, parent, zone, period, function) {
            armed.add('PeriodicTimer($period)');
            return parent.createPeriodicTimer(zone, period, function);
          },
        ),
      );
      await tester.pump();

      expect(fetches, 1);
      expect(
        armed,
        isEmpty,
        reason: 'Aucun Timer de sondage ne doit être armé.',
      );
      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);

      // Un serveur qui refuse n'est pas martelé : le budget de cadence
      // s'est espacé, la demande suivante n'atteint pas le réseau.
      await AnnouncementService.refresh();
      await tester.pump();
      expect(
        fetches,
        1,
        reason:
            'Après un refus, la prochaine requête attend '
            '${AnnouncementService.nominalInterval.inMinutes} min.',
      );
    });
  });
}
