// Câblage RÉEL du service d'annonces in-app — ce que ces suites prouvent :
// réseau, préférences, overlay, cycle de vie.
//
// Les tests des décisions pures (`announcement_policy_*_test.dart`) verrouillent
// QUELLE annonce s'affiche et sous quelle forme. Ils ne peuvent pas prouver ce
// qui arrive quand le service est branché sur ses vraies sources : une lecture
// refusée par le serveur, un appareil hors ligne, une session absente, une
// entrée illisible, un retour au premier plan. C'est ce que la suite de câblage
// exerce — avec, comme seuls juges, ce qui apparaît à l'écran et ce qui est
// réellement écrit dans `SharedPreferences`.
//
// Découpée par sujet, chaque morceau portant les mêmes noms de tests :
//   * ce fichier — la bannière affichée puis consommée, le dialogue critique et
//     ses sorties ;
//   * `announcement_service_wiring_network_test.dart` — entrées illisibles,
//     appareil hors ligne, serveur qui refuse la lecture ;
//   * `announcement_service_wiring_lifecycle_test.dart` — retour au premier
//     plan, session absente.
//
// Le harnais commun (fixtures, charge utile, overlay, session simulée) vit dans
// `announcement_test_support.dart`, et nulle part ailleurs.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/announcements/logic/announcement_presenter.dart';
import 'package:bot_creator/features/announcements/logic/announcement_service.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';

import 'announcement_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setUpAnnouncementHarness);
  setUp(resetAnnouncementHarness);
  tearDown(disposeAnnouncementHarness);

  group('branche 1 — bannière affichée, marquée vue, puis plus rien', () {
    testWidgets('une bannière s\'affiche, la clé « vue » est écrite, et le '
        'rafraîchissement suivant n\'affiche plus rien', (tester) async {
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

      await AnnouncementService.refresh();
      await tester.pump();

      // L'annonce est à l'écran : la charge utile a bien été décodée et
      // confiée à la bannière.
      expect(find.byType(AnnouncementBanner), findsOneWidget);
      expect(find.text(bannerTitle), findsOneWidget);
      expect(find.text(bannerBody), findsOneWidget);
      expect(fetches, 1);

      // L'annonce ne doit PAS être masquée avant l'action utilisateur :
      expect(
        AnnouncementPresenter.sessionDismissedIds,
        isNot(contains(bannerId)),
      );

      // Fermeture par la croix / bouton Compris :
      await tester.tap(find.byTooltip(tr.announcement_dismiss));
      await tester.pump();
      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(AnnouncementPresenter.sessionDismissedIds, contains(bannerId));

      // Second rafraîchissement dans la même session : la requête repart mais
      // l'annonce acquittée pour la session n'est plus réaffichée.
      await AnnouncementService.refresh(force: true);
      await tester.pump();
      expect(fetches, 2);
      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(find.text(bannerTitle), findsNothing);

      // Nouvelle session (fresh start) : l'annonce réapparaît tant que le serveur la sert !
      AnnouncementPresenter.reset();
      await AnnouncementService.refresh(force: true);
      await tester.pump();
      expect(find.byType(AnnouncementBanner), findsOneWidget);
      expect(find.text(bannerTitle), findsOneWidget);
    });
  });

  group('branche 2 — dialogue critique et ses sorties', () {
    testWidgets(
      'critique NON refermable : « Plus tard » disparaît, le tap extérieur '
      'ne ferme pas, l\'acquittement reste la sortie',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        AnnouncementService.debugClientResolver = () async =>
            fakeAnnouncementClient();
        AnnouncementService.debugAnnouncementsFetcher = (_) async =>
            criticalPayload(dismissible: false);

        await tester.pumpWidget(announcementHost(navigatorKey));

        // `refresh` rend la main après l'affichage ; c'est le DIALOGUE qui
        // attend l'utilisateur, et il est monté en `unawaited` par le service.
        unawaited(AnnouncementService.refresh());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(criticalTitle), findsOneWidget);
        expect(find.text(tr.announcement_later), findsNothing);
        expect(find.text(tr.announcement_acknowledge), findsOneWidget);

        // Tap hors du dialogue : interdit, le dialogue reste.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text(criticalTitle), findsOneWidget);

        // La sortie garantie : le bouton qui ferme n'est jamais conditionnel.
        await tester.tap(find.text(tr.announcement_acknowledge));
        await tester.pumpAndSettle();
        expect(find.text(criticalTitle), findsNothing);
        await tester.pump();
      },
    );

    testWidgets(
      'critique refermable : « Plus tard » est présent et le tap extérieur '
      'ferme le dialogue',
      (tester) async {
        useValidSession();
        final navigatorKey = GlobalKey<NavigatorState>();
        AnnouncementService.navigatorKey = navigatorKey;
        AnnouncementService.debugClientResolver = () async =>
            fakeAnnouncementClient();
        AnnouncementService.debugAnnouncementsFetcher = (_) async =>
            criticalPayload(dismissible: true);

        await tester.pumpWidget(announcementHost(navigatorKey));

        unawaited(AnnouncementService.refresh());
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.text(criticalTitle), findsOneWidget);
        expect(find.text(tr.announcement_later), findsOneWidget);
        expect(find.text(tr.announcement_acknowledge), findsOneWidget);

        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text(criticalTitle), findsNothing);
        await tester.pump();
      },
    );
  });
}
