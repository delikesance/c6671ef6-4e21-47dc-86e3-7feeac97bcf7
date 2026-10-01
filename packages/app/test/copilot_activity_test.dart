import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_activity.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'));
    await loader.load();
    if (Platform.environment['BC_CAPTURE_COPILOT'] == '1') {
      var directory = File(Platform.resolvedExecutable).parent;
      File? font;
      for (var i = 0; i < 8; i++) {
        final candidate = File(
          '${directory.path}/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        if (await candidate.exists()) {
          font = candidate;
          break;
        }
        directory = directory.parent;
      }
      if (font != null) {
        final material = FontLoader('MaterialIcons')
          ..addFont(
            font.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          );
        await material.load();
      }
    }
  });
  testWidgets(
    'activity is folded, updates in place and supports large mobile text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget page(bool running) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: CopilotActivity(
                key: const ValueKey('activity'),
                title: 'Recherche et vérifications',
                steps: [
                  CopilotActivityStep(
                    label: 'Recherche dans la documentation',
                    icon: Reicon.outline.bookOpen,
                    running: running,
                  ),
                  CopilotActivityStep(
                    label: 'Analyse',
                    detail:
                        'Vérification des paramètres de la commande et de ses interactions.',
                    icon: Reicon.outline.magicStar,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page(true));
      expect(find.text('Analyse'), findsNothing);
      await tester.tap(find.text('Recherche et vérifications'));
      await tester.pump();
      expect(find.text('Analyse'), findsOneWidget);
      await tester.pumpWidget(page(false));
      await tester.pumpAndSettle();
      expect(find.text('Analyse'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Recherche et vérifications'));
      await tester.pumpAndSettle();
      expect(find.text('Analyse'), findsNothing);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'history groups docs before final answer, approvals remain visible ($brightness)',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        rootBundle.evict('assets/copilot/tools.json');
        SharedPreferences.setMockInitialValues({});
        final catalog =
            jsonDecode(
                  (await tester.runAsync(
                    () => File('assets/copilot/tools.json').readAsString(),
                  ))!,
                )
                as List;
        Map<String, dynamic> call(String id, String name) => {
          'id': id,
          'type': 'function',
          'function': {'name': name, 'arguments': '{}'},
        };
        final search = call('search', 'docs_search');
        final read = call('read', 'docs_get');
        final stop = call('stop', 'remote_stop_bot');
        final chat = {
          'id': 'c',
          'title': 'Sélecteur de couleurs',
          'bot_id': '',
          'location': 'global',
          'archived': false,
          'revision': 1,
          'active_key': '',
          'messages': [
            {'role': 'user', 'content': 'Vérifie ma commande de couleurs.'},
            {
              'role': 'assistant',
              'content': 'Je vérifie le fonctionnement du sélecteur.',
              'tool_calls': [search],
            },
            {'role': 'tool', 'content': 'Private raw output'},
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [read],
            },
            {
              'role': 'assistant',
              'content':
                  'Le sélecteur est prêt.\n\n- Les deux couleurs sont prises en charge.\n- Le rôle est vérifié avant attribution.',
            },
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [stop],
            },
          ],
          'actions': [
            {'call_id': 'search', 'state': 'succeeded', 'call': search},
            {'call_id': 'read', 'state': 'failed', 'call': read},
            {'call_id': 'stop', 'state': 'pending', 'call': stop},
          ],
          'consumed_tokens': 12,
        };
        final api = MainApiClient(
          baseUrl: 'http://localhost',
          accessToken: 'test',
          httpClient: MockClient((request) async {
            final path = request.url.path;
            final result = switch (path) {
              '/gateway/ai/copilot/tools' => {'tools': catalog},
              '/gateway/ai/wallet' => {
                'balance': 10000,
                'reserved': 0,
                'available': 10000,
              },
              '/gateway/ai/conversations' => {'conversations': []},
              '/gateway/bots' => {'bots': []},
              '/gateway/ai/conversations/c' => chat,
              _ => throw StateError('Unexpected $path'),
            };
            return http.Response(
              jsonEncode(result),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        final captureKey = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ThemeData(brightness: brightness, fontFamily: 'Inter'),
            home: RepaintBoundary(
              key: captureKey,
              child: CopilotPage(api: api, initialConversationId: 'c'),
            ),
          ),
        );
        for (
          var i = 0;
          i < 100 && find.byType(CopilotActivity).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 50));
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(find.byType(CopilotActivity), findsOneWidget);
        expect(find.text('Recherche dans la documentation'), findsNothing);
        expect(find.text('Le sélecteur est prêt.'), findsOneWidget);
        expect(find.text('Private raw output'), findsNothing);
        expect(find.text('Valider'), findsOneWidget);
        await tester.ensureVisible(find.text('Recherche et vérifications'));
        await tester.tap(find.text('Recherche et vérifications'));
        await tester.pumpAndSettle();
        expect(find.text('Recherche dans la documentation'), findsOneWidget);
        expect(find.text('Lecture de la documentation'), findsOneWidget);
        expect(
          find.text('Je vérifie le fonctionnement du sélecteur.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        if (Platform.environment['BC_CAPTURE_COPILOT'] == '1') {
          await tester.ensureVisible(find.text('Recherche et vérifications'));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary =
                captureKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/bc-copilot-${brightness.name}.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
