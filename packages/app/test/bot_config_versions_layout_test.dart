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
