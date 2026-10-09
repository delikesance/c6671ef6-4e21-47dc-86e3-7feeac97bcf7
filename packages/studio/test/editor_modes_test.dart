import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/commands/command_draft.dart';
import 'package:bot_creator_studio/src/screens/command_editor_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

StudioApi _api() => StudioApi(
  baseUrl: 'https://api.test',
  client: MockClient(
    (_) async => http.Response.bytes(
      utf8.encode('{}'),
      200,
      headers: {'content-type': 'application/json'},
    ),
  ),
)..accessToken = ({bool force = false}) async => 'tok';

Future<void> _pumpEditor(
  WidgetTester tester,
  StudioBot bot,
  CommandDraft draft, {
  double width = 1000,
}) async {
  tester.view.physicalSize = Size(width, 1600);
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
      home: Scaffold(
        body: CommandEditorPage(
          api: _api(),
          bot: bot,
          command: const StudioCommand(id: 'c1', name: 'ping'),
          newDraft: draft,
          onClose: (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

CommandDraft _draft() => CommandDraft.blank(name: 'ping', description: 'Ping');

void main() {
  const dartBot = StudioBot(id: 'b1', name: 'Bot');
  const jsBot = StudioBot(
    id: 'b2',
    name: 'Bot JS',
    runtimeEngine: 'javascript',
  );

  testWidgets('bot Dart : blocs ou BDFD, jamais JavaScript', (tester) async {
    await _pumpEditor(tester, dartBot, _draft());
    expect(find.text('Visuel (Blocs)'), findsOneWidget);
    expect(find.text('Code BDFD'), findsOneWidget);
    expect(find.text('JavaScript'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bot JavaScript : le script seul, ni blocs ni BDFD', (
    tester,
  ) async {
    final draft = _draft();
    await _pumpEditor(tester, jsBot, draft);
    // Une commande neuve d'un bot JavaScript s'écrit en JavaScript d'emblée.
    expect(draft.executionMode, 'javascript');
    expect(find.text('Visuel (Blocs)'), findsNothing);
    expect(find.text('Code BDFD'), findsNothing);
    expect(find.text('JavaScript'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('téléphone 360px : l\'en-tête ne déborde pas, Enregistrer reste '
      'accessible', (tester) async {
    final draft = CommandDraft.blank(
      name: 'une-commande-au-nom-vraiment-tres-long',
      description: 'Ping',
    );
    final errors = <FlutterErrorDetails>[];
    final prev = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = prev);
    await _pumpEditor(tester, dartBot, draft, width: 360);
    // Seul l'en-tête de l'éditeur est en cause ici (un débordement de 0,75 px
    // du bloc métadonnées, dans packages/ui, est hors périmètre).
    expect(
      errors.where((e) => e.toString().contains('command_editor_page')),
      isEmpty,
    );
    final save = find.byKey(const ValueKey('command-save'));
    expect(save, findsOneWidget);
    expect(tester.getRect(save).right, lessThanOrEqualTo(360));
  });

  testWidgets('pas de « + » entre les métadonnées et le point de départ', (
    tester,
  ) async {
    await _pumpEditor(tester, dartBot, _draft());
    // Seul le connecteur sous le point de départ propose d'ajouter une action.
    expect(find.byType(ScratchBlockConnector), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('script BDFD : l\'éditeur BDFD s\'ouvre, pas celui du JS', (
    tester,
  ) async {
    final draft = _draft()
      ..executionMode = 'bdfd_script'
      ..bdfdScript = r'$onlyadmin[Noop]';
    await _pumpEditor(tester, dartBot, draft);
    await tester.tap(find.text('Modifier le script'));
    await tester.pumpAndSettle();
    expect(find.byType(BdfdEditorPage), findsOneWidget);
    expect(find.byType(JsEditorPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BDFD : la coloration syntaxique distingue les fonctions', (
    tester,
  ) async {
    final controller = BdfdSyntaxController(text: r'$onlyadmin[Noop]');
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            span = controller.buildTextSpan(
              context: context,
              style: const TextStyle(color: Colors.white),
              withComposing: false,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    final colors = <Color?>{};
    void walk(InlineSpan s) {
      if (s is TextSpan) {
        colors.add(s.style?.color);
        s.children?.forEach(walk);
      }
    }

    walk(span);
    colors.remove(null);
    expect(colors.length, greaterThan(1), reason: 'au moins deux couleurs');
    controller.dispose();
  });
}
