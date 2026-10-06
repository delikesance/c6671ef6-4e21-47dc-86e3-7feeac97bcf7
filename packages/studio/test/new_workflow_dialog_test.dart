import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/screens/workflows_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('nouveau workflow Événement : catégorie et événement en listes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final api = StudioApi(
      baseUrl: 'https://api.test',
      client: MockClient(
        (_) async => http.Response.bytes(
          utf8.encode('{"workflows":[]}'),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    )..accessToken = ({bool force = false}) async => 'tok';
    final fr = lookupStudioLocalizations(const Locale('fr'));
    final trFr = lookupAppLocalizations(const Locale('fr'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...StudioLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        theme: AppTheme.darkTheme(),
        home: Scaffold(
          body: WorkflowsPage(
            api: api,
            bot: const StudioBot(id: 'b1', name: 'Bot'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.workflowNew));
    await tester.pumpAndSettle();

    // Type « Événement Discord » : deux listes, aucun champ de saisie de plus.
    await tester.tap(find.text(fr.workflowTypeGeneral));
    await tester.pumpAndSettle();
    await tester.tap(find.text(trFr.scratch_wizard_trigger_event_title).last);
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    expect(find.byType(TextField), findsOneWidget); // le nom, seulement
    expect(find.text(fr.workflowCategory), findsOneWidget);

    // La liste des événements suit la catégorie choisie.
    await tester.tap(find.text('Messages').last);
    await tester.pumpAndSettle();
    expect(find.text('Message Create'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
