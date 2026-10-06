import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_config_versions_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('versions-layout');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
    appManager = AppManager();
    await appManager.listAppCommands('layout-bot');
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  testWidgets('global preview and confirmed delete respect screen safe areas', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    const key = 'configs/layout-bot/versions/2026-10-03.json';
    var deleted = false;
    final requests = <http.Request>[];
    final client = MainApiClient(
      baseUrl: 'https://history-management.example',
      accessToken: 'test-token',
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.method == 'DELETE') {
          expect(request.url.queryParameters['key'], key);
          deleted = true;
          return http.Response('{"ok":true}', 200);
        }
        return http.Response(
          jsonEncode(
            request.url.path.endsWith('/content')
                ? {
                    'content': {
                      'commands': [
                        {
                          'id': 'cmd-1',
                          'name': 'saved-value',
                          'actions': [
                            {'content': 'private-script'},
                          ],
                        },
                      ],
                      'workflows': {
                        'wf-1': {
                          'name': 'Saved workflow',
                          'steps': [
                            {'secret': 'private-workflow'},
                          ],
                        },
                      },
                    },
                  }
                : {
                    'data': deleted
                        ? []
                        : [
                            {'key': key, 'size': 500},
                          ],
                  },
          ),
          200,
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
            viewPadding: const EdgeInsets.fromLTRB(18, 24, 18, 34),
            textScaler: const TextScaler.linear(1.5),
          ),
          child: child!,
        ),
        home: BotConfigVersionsPage(
          botId: 'layout-bot',
          botToken: 'test-token',
          resolveClient: (_, _) async => client,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.text(fr.history_preview);
    await tester.scrollUntilVisible(
      preview,
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getRect(preview).left, greaterThanOrEqualTo(18));
    expect(tester.getRect(preview).right, lessThanOrEqualTo(302));
    await tester.tap(preview);
    await tester.pumpAndSettle();
    expect(find.text('saved-value'), findsOneWidget);
    expect(find.text('Saved workflow'), findsOneWidget);
    expect(find.text('${fr.commands_title} (1)'), findsOneWidget);
    expect(find.text('${fr.workflows_title} (1)'), findsOneWidget);
    expect(find.textContaining('private-script'), findsNothing);
    expect(find.textContaining('private-workflow'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    expect(requests.where((r) => r.method != 'GET'), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(fr.common_close).last);
    await tester.pumpAndSettle();
    final delete = find.byTooltip(fr.common_delete);
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, fr.common_cancel));
    await tester.pumpAndSettle();
    expect(deleted, isFalse);
    await tester.tap(delete);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, fr.common_delete));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(requests.where((r) => r.method == 'DELETE'), hasLength(1));
    expect(
      requests.where(
        (r) => r.method == 'GET' && r.url.path.endsWith('/versions'),
      ),
      hasLength(1),
    );
    expect(find.text(fr.history_preview), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'deleting a scrolled version keeps the list and scroll position',
    (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      var reads = 0;
      String? deletedKey;
      final versions = List.generate(
        20,
        (index) => {
          'key': 'configs/layout-bot/versions/version-$index.json',
          'size': 500,
        },
      );
      final client = MainApiClient(
        baseUrl: 'https://history-scroll.example',
        accessToken: 'test-token',
        httpClient: MockClient((request) async {
          if (request.method == 'DELETE') {
            deletedKey = request.url.queryParameters['key'];
            return http.Response('{"ok":true}', 200);
          }
          reads++;
          return http.Response(jsonEncode({'data': versions}), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BotConfigVersionsPage(
            botId: 'layout-bot',
            botToken: 'test-token',
            resolveClient: (_, _) async => client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final list = find.byType(Scrollable).first;
      const key = 'configs/layout-bot/versions/version-8.json';
      final card = find.byKey(const ValueKey(key));
      await tester.scrollUntilVisible(card, 250, scrollable: list);
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      final position = tester.state<ScrollableState>(list).position;
      final before = position.pixels;
      expect(before, greaterThan(0));
      await tester.tap(
        find.descendant(of: card, matching: find.byTooltip(fr.common_delete)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, fr.common_delete));
      await tester.pumpAndSettle();
      expect(deletedKey, key);
      expect(card, findsNothing);
      expect(reads, 1);
      expect(tester.state<ScrollableState>(list).position, same(position));
      expect(position.pixels, closeTo(before, .1));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['en', 'fr', 'de', 'ja', 'pt', 'tr']) {
    testWidgets('restore preview fits a narrow screen in $language', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var restores = 0;
      final client = MainApiClient(
        baseUrl: 'https://manager.example',
        accessToken: 'test-token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/restore')) restores++;
          final Object result = request.url.path.endsWith('/versions')
              ? {
                  'data': [
                    {'key': '2026-10-01T00h00h00.json', 'size': 1000},
                  ],
                }
              : request.url.path.endsWith('/config')
              ? {'configUrl': 'https://manager.example/snapshot'}
              : {
                  'commands': List.generate(
                    10,
                    (i) => {'name': 'command_with_a_long_name_$i'},
                  ),
                };
          return http.Response(jsonEncode(result), 200);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: BotConfigVersionsPage(
            botId: 'layout-bot',
            botToken: 'test-token',
            resolveClient: (_, _) async => client,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byType(TextButton).last);
        await Future<void>.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(restores, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  }
}
