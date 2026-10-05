import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/option_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart' hide Locale;

void main() {
  testWidgets('an expanded option fits a 320px phone with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: OptionWidget(
              onChange: (_) {},
              initialOptions: [
                CommandOptionBuilder(
                  type: CommandOptionType.string,
                  name: 'option1',
                  description: "Description de l'option 1",
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('option1').last);
    await tester.pumpAndSettle();

    // Type chips (one per allowed type) replace the old dropdown.
    expect(find.text('Pièce jointe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Future<List<CommandOptionBuilder>> pumpList(
    WidgetTester tester,
    List<List<CommandOptionBuilder>> changes,
  ) async {
    final options = [
      CommandOptionBuilder(
        type: CommandOptionType.string,
        name: 'cible',
        description: 'Le membre',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: OptionWidget(
              onChange: (o) => changes.add(List.of(o)),
              initialOptions: options,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return options;
  }

  testWidgets('editing on the option screen updates the list summary', (
    tester,
  ) async {
    final changes = <List<CommandOptionBuilder>>[];
    await pumpList(tester, changes);
    expect(find.text('Texte'), findsOneWidget);

    await tester.tap(find.text('cible').last);
    await tester.pumpAndSettle();
    // Own screen: the AppBar shows the option name and an OK button.
    expect(find.widgetWithText(AppBar, 'cible'), findsOneWidget);
    await tester.tap(find.text('Utilisateur'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Utilisateur'), findsOneWidget);
    expect(changes.last.single.type, CommandOptionType.user);
  });

  testWidgets('deleting from the option screen closes it and removes it', (
    tester,
  ) async {
    final changes = <List<CommandOptionBuilder>>[];
    await pumpList(tester, changes);

    await tester.tap(find.text('cible').last);
    await tester.pumpAndSettle();
    // Bottom of a long screen: scroll it into view first.
    await tester.ensureVisible(
      find.text("Supprimer l'option", skipOffstage: false),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text("Supprimer l'option"));
    await tester.pumpAndSettle();
    // Confirm the destructive dialog.
    await tester.tap(find.widgetWithText(FilledButton, 'Supprimer').last);
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('cible'), findsNothing);
    expect(changes.last, isEmpty);
  });
}
