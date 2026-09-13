import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carte « temps total » de la home d'un bot : pastille d'état, badge d'équipe,
/// expiration prévue (surtitre + date), décomposition mois / jours / heures /
/// minutes puis action « Ajouter du temps ».
///
/// `HomeHostingTimeCard` est montée directement : `AppHomePage` exige un
/// `NyxxRest` non injectable.
void main() {
  const segments = <({String value, String label})>[
    (value: '136', label: 'Mois'),
    (value: '07', label: 'Jours'),
    (value: '05', label: 'Heures'),
    (value: '53', label: 'Min'),
  ];

  Widget hostApp(
    Widget child, {
    Locale locale = const Locale('fr'),
    Brightness brightness = Brightness.dark,
  }) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: brightness),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  HomeHostingTimeCard card({
    String statusLabel = 'Session active',
    Color statusColor = AppTheme.online,
    String overline = 'Expiration prévue',
    String headline = '21 nov. 2037 à 17:55',
    List<({String value, String label})> segments = segments,
    bool showTeamBadge = false,
    bool isAddingTime = false,
    bool emphasizeBorder = false,
    VoidCallback? onAddTime,
  }) {
    return HomeHostingTimeCard(
      statusLabel: statusLabel,
      statusColor: statusColor,
      overline: overline,
      headline: headline,
      segments: segments,
      showTeamBadge: showTeamBadge,
      isAddingTime: isAddingTime,
      emphasizeBorder: emphasizeBorder,
      onAddTime: onAddTime ?? () {},
    );
  }

  testWidgets('bot en ligne : pastille, expiration, décomposition et action', (
    tester,
  ) async {
    await tester.pumpWidget(hostApp(card()));
    await tester.pumpAndSettle();

    // Pastille d'état (sans le « (en ligne) » des libellés longs).
    expect(find.text('Session active'), findsOneWidget);
    // Surtitre et libellés d'unités rendus en majuscules.
    expect(find.text('EXPIRATION PRÉVUE'), findsOneWidget);
    expect(find.text('MOIS'), findsOneWidget);
    expect(find.text('JOURS'), findsOneWidget);
    expect(find.text('HEURES'), findsOneWidget);
    expect(find.text('MIN'), findsOneWidget);
    // Valeurs sur deux chiffres + valeur principale.
    expect(find.text('136'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('53'), findsOneWidget);
    expect(find.text('21 nov. 2037 à 17:55'), findsOneWidget);
    // Action principale, sur toute la largeur.
    expect(find.widgetWithText(FilledButton, 'Ajouter du temps'), findsOneWidget);
    // Pas de badge équipe quand le bot n'est pas rattaché à une équipe.
    expect(find.text('Team'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bot en pause : réserve et temps préservé', (tester) async {
    await tester.pumpWidget(
      hostApp(
        card(
          statusLabel: 'Réserve disponible',
          statusColor: AppTheme.warning,
          overline: 'Temps préservé',
          headline: '136 mois, 7 jours, 5 heures, 53 minutes',
          showTeamBadge: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Réserve disponible'), findsOneWidget);
    expect(find.text('TEMPS PRÉSERVÉ'), findsOneWidget);
    expect(find.text('136 mois, 7 jours, 5 heures, 53 minutes'), findsOneWidget);
    expect(find.text('Team'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('l’action « Ajouter du temps » déclenche son callback', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(hostApp(card(onAddTime: () => taps++)));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Ajouter du temps'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('pendant l’ajout de temps : loader et action désactivée', (
    tester,
  ) async {
    await tester.pumpWidget(hostApp(card(isAddingTime: true)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Ajouter du temps'),
          )
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('aucun débordement à 320 dp, en clair comme en sombre', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        hostApp(
          card(
            headline: '21 novembre 2037 à 17:55',
            statusLabel: 'Réserve disponible',
          ),
          brightness: brightness,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(HomeHostingTimeCard));
      expect(size.width, lessThanOrEqualTo(320));
    }
  });

  testWidgets('réserve critique : la bordure passe en rouge', (tester) async {
    await tester.pumpWidget(hostApp(card(emphasizeBorder: true)));
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HomeHostingTimeCard),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(
      decoration.border!.top.color.toARGB32(),
      AppTheme.error.withValues(alpha: 0.9).toARGB32(),
    );
  });
}
