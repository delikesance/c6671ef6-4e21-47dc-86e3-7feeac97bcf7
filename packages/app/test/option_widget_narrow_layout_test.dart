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
}
