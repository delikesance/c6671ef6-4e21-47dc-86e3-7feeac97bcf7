import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/commands/workflow_draft.dart';
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
      utf8.encode('{"workflows":[]}'),
      200,
      headers: {'content-type': 'application/json'},
    ),
  ),
)..accessToken = ({bool force = false}) async => 'tok';

Future<void> _pump(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(1000, 1600);
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
  const jsBot = StudioBot(
    id: 'b2',
    name: 'Bot JS',
    runtimeEngine: 'javascript',
  );

  testWidgets('bot JavaScript : nouveau workflow = événement en JavaScript', (
    tester,
  ) async {
    final fr = lookupStudioLocalizations(const Locale('fr'));
    await _pump(tester, WorkflowsPage(api: _api(), bot: jsBot));
    await tester.tap(find.text(fr.workflowNew));
    await tester.pumpAndSettle();
    // Pas de choix « Général / Événement » : un bot JS n'a que des événements.
    expect(find.text(fr.workflowTypeGeneral), findsNothing);
    expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(2));

    await tester.enterText(find.byType(TextField), 'bienvenue');
    await tester.tap(
      find.text(lookupAppLocalizations(const Locale('fr')).create),
    );
    await tester.pumpAndSettle();

    // L'éditeur propose le script, ni blocs ni BDFD, et l'enregistrement.
    expect(find.text('JavaScript'), findsWidgets);
    expect(find.text(fr.scriptEdit), findsOneWidget);
    expect(find.text('Code BDFD'), findsNothing);
    expect(find.text('Visuel (Blocs)'), findsNothing);
    expect(find.byType(ScratchBlockConnector), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('un workflow JavaScript est modifiable, un BDFD reste en lecture', () {
    final js = WorkflowDraft.blank(name: 'a', executionMode: 'javascript')
      ..jsScript = 'console.log(1)';
    expect(js.visual, isFalse);
    expect(js.editable, isTrue);
    expect(js.toRaw()['jsScriptContent'], 'console.log(1)');
    expect(js.toRaw()['actions'], isEmpty);

    final bdfd = WorkflowDraft({'name': 'b', 'executionMode': 'bdfd_script'});
    expect(bdfd.editable, isFalse);
  });
}
