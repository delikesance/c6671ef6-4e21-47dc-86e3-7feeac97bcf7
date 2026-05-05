import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('action detail page keeps its content inside a SafeArea', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ActionsBuilderPage(
          initialActions: const <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 'action_1',
              'type': 'sendMessage',
              'enabled': true,
              'key': 'action_1',
              'payload': <String, dynamic>{'content': 'Hello world'},
              'error': <String, dynamic>{'mode': 'stop'},
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.byType(ActionCard), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SafeArea && widget.top == false && widget.bottom == true,
      ),
      findsOneWidget,
    );
  });
}
