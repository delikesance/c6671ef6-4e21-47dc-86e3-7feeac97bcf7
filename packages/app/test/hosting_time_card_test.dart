import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Carte « temps total » de la home d'un bot : le temps restant doit être
/// affiché en « mois, jours, heures, minutes » (façon carte de la page
/// « Emojis applicatifs »), avec les deux actions en icônes.
///
/// `HomeHostingTimeCard` est monté directement : `AppHomePage` exige un
/// `NyxxRest` non injectable.
void main() {
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
      home: Scaffold(body: Center(child: child)),
    );
  }

  HomeHostingTimeCard card({
    double width = 176,
    String totalLabel = '2 mois, 3 jours, 15 heures, 40 minutes',
    String statusLabel = 'Session active (en ligne)',
    String? detailLabel = "Expire demain à 15:30",
    bool isRunning = true,
    bool isAddingTime = false,
    VoidCallback? onAddTime,
    VoidCallback? onHistory,
  }) {
    return HomeHostingTimeCard(
      width: width,
      totalLabel: totalLabel,
      statusLabel: statusLabel,
      detailLabel: detailLabel,
      isRunning: isRunning,
      isAddingTime: isAddingTime,
      onAddTime: onAddTime ?? () {},
      onHistory: onHistory ?? () {},
    );
  }

  testWidgets('affiche le temps total, le statut et les deux actions (FR)', (
    tester,
  ) async {
    await tester.pumpWidget(hostApp(card()));
    await tester.pumpAndSettle();

    expect(find.text('2 mois, 3 jours, 15 heures, 40 minutes'), findsOneWidget);
    expect(find.text('Session active (en ligne)'), findsOneWidget);
    expect(find.text('Expire demain à 15:30'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
    expect(find.byTooltip('Ajouter du temps'), findsOneWidget);
    expect(find.byTooltip('Historique des pubs'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('les deux actions rappellent leurs callbacks', (tester) async {
    var addTime = 0;
    var history = 0;

    await tester.pumpWidget(
      hostApp(card(onAddTime: () => addTime++, onHistory: () => history++)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();

    expect(addTime, 1);
    expect(history, 1);
  });

  testWidgets('bot arrêté : réserve annoncée, action pub en attente', (
    tester,
  ) async {
    await tester.pumpWidget(
      hostApp(
        card(
          statusLabel: 'Réserve disponible (en pause)',
          detailLabel: 'Le temps est préservé tant que le bot est arrêté.',
          isRunning: false,
          isAddingTime: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Réserve disponible (en pause)'), findsOneWidget);
    expect(
      find.text('Le temps est préservé tant que le bot est arrêté.'),
      findsOneWidget,
    );
    // Pendant l'ajout de temps : loader dans l'action, action désactivée.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final actions = tester.widgetList<IconButton>(find.byType(IconButton));
    expect(actions.length, 2);
    expect(
      actions.where((button) => button.onPressed == null).length,
      1,
      reason:
          'seule l’action « ajouter du temps » est bloquée pendant le chargement',
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
        hostApp(card(width: 288), brightness: brightness),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // La carte ne dépasse jamais la largeur demandée.
      final size = tester.getSize(find.byType(HomeHostingTimeCard));
      expect(size.width, lessThanOrEqualTo(320));
    }
  });

  testWidgets('la couleur de la valeur suit la santé de la réserve', (
    tester,
  ) async {
    // Réserve critique : la home passe la couleur d'alerte.
    await tester.pumpWidget(
      hostApp(
        HomeHostingTimeCard(
          width: 176,
          totalLabel: '45 minutes',
          statusLabel: 'Session active (en ligne)',
          isRunning: true,
          timeColor: AppTheme.error,
          onAddTime: () {},
          onHistory: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('45 minutes')).style?.color,
      AppTheme.error,
    );

    // Sans couleur explicite : couleur d'état (en ligne = vert).
    await tester.pumpWidget(hostApp(card(totalLabel: '45 minutes')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.text('45 minutes')).style?.color,
      AppTheme.online,
    );
  });
}
