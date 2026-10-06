import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/screens/commands_page.dart';
import 'package:bot_creator_studio/src/screens/workflows_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

StudioApi _api() => StudioApi(
  baseUrl: 'https://api.test',
  client: MockClient(
    (_) async => http.Response.bytes(
      utf8.encode('{"workflows":[],"commands":[]}'),
      200,
      headers: {'content-type': 'application/json'},
    ),
  ),
)..accessToken = ({bool force = false}) async => 'tok';

Future<void> _pump(WidgetTester tester, Widget page, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        ...StudioLocalizations.localizationsDelegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
      theme: AppTheme.darkTheme(),
      home: Scaffold(body: page),
    ),
  );
  await tester.pumpAndSettle();
}

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

  // Un téléphone : le dialogue est plus étroit que ses 420 px de confort. Les
  // listes remplissent le champ et coupent leur texte (…), elles ne le
  // décalent pas et ne le font pas sortir de l'input.
  testWidgets('téléphone : les listes du nouveau workflow tiennent', (
    tester,
  ) async {
    final fr = lookupStudioLocalizations(const Locale('fr'));
    final trFr = lookupAppLocalizations(const Locale('fr'));
    await _pump(
      tester,
      WorkflowsPage(
        api: _api(),
        bot: const StudioBot(id: 'b1', name: 'Bot'),
      ),
      const Size(360, 800),
    );
    await tester.tap(find.byTooltip(fr.workflowNew));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(trFr.scratch_wizard_trigger_event_title).last);
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('téléphone : le nouveau dialogue de commande tient', (
    tester,
  ) async {
    final fr = lookupStudioLocalizations(const Locale('fr'));
    await _pump(
      tester,
      CommandsPage(
        api: _api(),
        bot: const StudioBot(id: 'b1', name: 'Bot'),
      ),
      const Size(360, 800),
    );
    await tester.tap(find.byTooltip(fr.commandNew));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
