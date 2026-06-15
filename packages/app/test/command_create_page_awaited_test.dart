import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
import 'package:bot_creator/core/storage/database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp(
      'command_create_page_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Ignore PathAccessException on Windows caused by locked SQLite db files
      }
    }
  });

  List<Map<String, dynamic>> readAllLocalCommands(String botId) {
    final directory = Directory('${documentsDir.path}/apps/$botId');
    if (!directory.existsSync()) {
      return const <Map<String, dynamic>>[];
    }

    return directory
        .listSync()
        .whereType<File>()
        .map(
          (file) => Map<String, dynamic>.from(
            jsonDecode(file.readAsStringSync()) as Map,
          ),
        )
        .toList(growable: false);
  }

  Future<void> pumpCreatePage(
    WidgetTester tester, {
    required Widget page,
  }) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: page,
      ),
    );
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> openPageFromHost(
    WidgetTester tester, {
    required Widget page,
  }) async {
    await pumpCreatePage(
      tester,
      page: Builder(
        builder:
            (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => page),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('CommandCreatePage awaited callback', () {
    testWidgets(
      'awaited callback legacy commands can be created locally without a description',
      (tester) async {
        const botId = 'bot-awaited-callback-create';

        await openPageFromHost(
          tester,
          page: const CommandCreatePage(botId: botId),
        );

        // Expand "Advanced settings" before switching to prefix mode
        await tester.ensureVisible(find.text('Advanced settings'));
        await tester.pump();
        await tester.tap(find.text('Advanced settings'));
        await tester.pumpAndSettle();

        // Switch to legacy/prefix command type via SegmentedButton
        await tester.tap(find.text('Prefix command'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Enable local-only mode
        await tester.tap(
          find.text('Local Command (Do not register on Discord)'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Enter the awaited command name
        await tester.enterText(
          find.byType(TextFormField).first,
          r'$awaitedCommand[say;<numeric>]',
        );
        await tester.pump();

        // Create the command inside runAsync so async I/O can complete
        await tester.runAsync(() async {
          final createButton = tester.widget<FloatingActionButton>(
            find.byType(FloatingActionButton),
          );
          createButton.onPressed?.call();
          final deadline = DateTime.now().add(const Duration(seconds: 2));
          while (DateTime.now().isBefore(deadline)) {
            await tester.pump();
            try {
              final savedCommands = readAllLocalCommands(botId);
              if (savedCommands.isNotEmpty) {
                return;
              }
            } catch (_) {}
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pump(const Duration(milliseconds: 800));

        final savedCommands = readAllLocalCommands(botId);
        expect(savedCommands, hasLength(1));
        expect(savedCommands.single['name'], r'$awaitedCommand[say;<numeric>]');
        expect(savedCommands.single['description'], isEmpty);

        final data = Map<String, dynamic>.from(savedCommands.single['data']);
        expect(data['legacyModeEnabled'], isTrue);
        expect(data['legacyLocalOnly'], isTrue);
      },
    );

    testWidgets(
      'awaited callback preset generates the trigger syntax automatically',
      (tester) async {
        const botId = 'bot-awaited-preset-create';

        await openPageFromHost(
          tester,
          page: const CommandCreatePage(botId: botId),
        );

        // Expand "Advanced settings" in MetadataBlock to reach the preset UI
        await tester.ensureVisible(find.text('Advanced settings'));
        await tester.pump();
        await tester.tap(find.text('Advanced settings'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('awaited-preset-enable')),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('awaited-preset-enable')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('awaited-preset-name')),
          'odd',
        );
        await tester.pump();
        await tester.enterText(
          find.byKey(const ValueKey('awaited-preset-filter')),
          '<yes/no/cancel>',
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('awaited-preset-preview')),
            matching: find.text(r'$awaitedCommand[odd;<yes/no/cancel>]'),
          ),
          findsOneWidget,
        );

        // Create the command inside runAsync so async I/O can complete
        await tester.runAsync(() async {
          final createButton = tester.widget<FloatingActionButton>(
            find.byType(FloatingActionButton),
          );
          createButton.onPressed?.call();
          final deadline = DateTime.now().add(const Duration(seconds: 2));
          while (DateTime.now().isBefore(deadline)) {
            await tester.pump();
            try {
              final savedCommands = readAllLocalCommands(botId);
              if (savedCommands.isNotEmpty) {
                return;
              }
            } catch (_) {}
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }
        });
        await tester.pump(const Duration(milliseconds: 800));

        final savedCommands = readAllLocalCommands(botId);
        expect(savedCommands, hasLength(1));
        expect(
          savedCommands.single['name'],
          r'$awaitedCommand[odd;<yes/no/cancel>]',
        );

        final data = Map<String, dynamic>.from(savedCommands.single['data']);
        expect(data['legacyModeEnabled'], isTrue);
        expect(data['legacyLocalOnly'], isTrue);
      },
    );
  });
}
