// Bannière et dialogue d'annonce, au niveau du widget.
//
// Ce que ces tests verrouillent : ce qui est montré (titre, corps, lien), ce
// qui est fermable, et — pour une annonce critique non refermable — qu'on ne
// peut PAS la faire disparaître sans action, tout en ayant TOUJOURS un bouton
// qui ferme.
//
// Aucun `debugDefaultTargetPlatformOverride` ici : la fonctionnalité ne dépend
// d'aucune plateforme, donc rien à remettre à zéro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations_fr.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_dialog.dart';

final AppLocalizationsFr tr = AppLocalizationsFr();

Announcement buildAnnouncement({
  String id = 'a-1',
  AnnouncementSeverity severity = AnnouncementSeverity.info,
  bool dismissible = true,
  String? linkUrl,
}) {
  return Announcement(
    id: id,
    title: 'Maintenance planifiée',
    body: 'Le service sera indisponible 10 minutes.',
    severity: severity,
    dismissible: dismissible,
    linkUrl: linkUrl == null ? null : Announcement.safeLinkUri(linkUrl),
  );
}

Widget host(Widget child) {
  return MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  group('bannière (info / important)', () {
    testWidgets('affiche le titre et le corps, et la croix ferme', (
      tester,
    ) async {
      var dismissed = false;
      await tester.pumpWidget(
        host(
          AnnouncementBanner(
            announcement: buildAnnouncement(),
            onDismiss: () => dismissed = true,
          ),
        ),
      );

      expect(find.text('Maintenance planifiée'), findsOneWidget);
      expect(
        find.text('Le service sera indisponible 10 minutes.'),
        findsOneWidget,
      );
      expect(find.byTooltip(tr.announcement_dismiss), findsOneWidget);

      await tester.tap(find.byTooltip(tr.announcement_dismiss));
      await tester.pump();

      expect(dismissed, isTrue);
    });

    testWidgets('annonce non refermable : aucune croix, mais bannière visible',
        (tester) async {
      await tester.pumpWidget(
        host(
          AnnouncementBanner(
            announcement: buildAnnouncement(dismissible: false),
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text('Maintenance planifiée'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byTooltip(tr.announcement_dismiss), findsNothing);
    });

    testWidgets('sans lien, pas de bouton « En savoir plus »', (tester) async {
      await tester.pumpWidget(
        host(
          AnnouncementBanner(
            announcement: buildAnnouncement(),
            onDismiss: () {},
          ),
        ),
      );

      expect(find.text(tr.announcement_see_more), findsNothing);
    });

    testWidgets('avec lien, « En savoir plus » ouvre l\'URL validée', (
      tester,
    ) async {
      Uri? opened;
      await tester.pumpWidget(
        host(
          AnnouncementBanner(
            announcement: buildAnnouncement(
              linkUrl: 'https://status.example.com/incident',
            ),
            onDismiss: () {},
            openLink: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );

      await tester.tap(find.text(tr.announcement_see_more));
      await tester.pump();

      expect(opened, Uri.parse('https://status.example.com/incident'));
    });

    testWidgets('un lien qui refuse de s\'ouvrir ne casse rien', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          AnnouncementBanner(
            announcement: buildAnnouncement(
              linkUrl: 'https://status.example.com/incident',
            ),
            onDismiss: () {},
            openLink: (_) async => false,
          ),
        ),
      );

      await tester.tap(find.text(tr.announcement_see_more));
      await tester.pump();

      expect(find.text(tr.announcement_link_open_failed), findsOneWidget);
    });
  });

  group('dialogue (critical)', () {
    testWidgets('affiche titre, corps, lien et les deux sorties', (
      tester,
    ) async {
      var opened = 0;
      late BuildContext captured;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final pending = showAnnouncementDialog(
        captured,
        announcement: buildAnnouncement(
          severity: AnnouncementSeverity.critical,
          linkUrl: 'https://status.example.com/incident',
        ),
        openLink: (_) async {
          opened++;
          return true;
        },
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Maintenance planifiée'), findsOneWidget);
      expect(
        find.text('Le service sera indisponible 10 minutes.'),
        findsOneWidget,
      );
      expect(find.text(tr.announcement_later), findsOneWidget);
      expect(find.text(tr.announcement_acknowledge), findsOneWidget);

      await tester.tap(find.text(tr.announcement_see_more));
      await tester.pump();
      expect(opened, 1);

      // « Plus tard » ferme : une annonce refermable n'insiste pas.
      await tester.tap(find.text(tr.announcement_later));
      await tester.pumpAndSettle();
      expect(find.text('Maintenance planifiée'), findsNothing);

      await pending;
    });

    testWidgets('le tap hors du dialogue le ferme quand c\'est permis', (
      tester,
    ) async {
      late BuildContext captured;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              captured = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final pending = showAnnouncementDialog(
        captured,
        announcement: buildAnnouncement(
          severity: AnnouncementSeverity.critical,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Maintenance planifiée'), findsOneWidget);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Maintenance planifiée'), findsNothing);
      await pending;
    });

    testWidgets(
      'annonce non refermable : ni « Plus tard », ni tap extérieur, ni retour '
      '— mais le bouton qui ferme est là',
      (tester) async {
        late BuildContext captured;
        await tester.pumpWidget(
          host(
            Builder(
              builder: (context) {
                captured = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final pending = showAnnouncementDialog(
          captured,
          announcement: buildAnnouncement(
            severity: AnnouncementSeverity.critical,
            dismissible: false,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Maintenance planifiée'), findsOneWidget);
        expect(find.text(tr.announcement_later), findsNothing);

        // Tap hors du dialogue : sans effet.
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(find.text('Maintenance planifiée'), findsOneWidget);

        // Retour système : sans effet non plus (c'est `maybePop`, donc le même
        // chemin que le bouton retour de la plateforme).
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).first,
        );
        await navigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.text('Maintenance planifiée'), findsOneWidget);

        // Le bouton d'acquittement, lui, n'est JAMAIS conditionnel : c'est la
        // sortie garantie.
        expect(find.text(tr.announcement_acknowledge), findsOneWidget);
        await tester.tap(find.text(tr.announcement_acknowledge));
        await tester.pumpAndSettle();
        expect(find.text('Maintenance planifiée'), findsNothing);

        await pending;
      },
    );
  });
}
