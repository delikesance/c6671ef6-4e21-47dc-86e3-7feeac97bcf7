import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator/core/storage/database.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart' show CommandOptionBuilder, CommandOptionType;
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

  Future<void> seedLocalCommand({
    required String botId,
    required String commandId,
    required bool includeSubcommands,
    bool legacyModeEnabled = false,
  }) async {
    final options = includeSubcommands
        ? serializeCommandOptions(<CommandOptionBuilder>[
            CommandOptionBuilder(
                type: CommandOptionType.subCommandGroup,
                name: 'config',
                description: 'Configuration routes',
                isRequired: false,
              )
              ..options = <CommandOptionBuilder>[
                CommandOptionBuilder(
                  type: CommandOptionType.subCommand,
                  name: 'status',
                  description: 'Status route',
                  isRequired: false,
                ),
                CommandOptionBuilder(
                  type: CommandOptionType.subCommand,
                  name: 'logchannel',
                  description: 'Log route',
                  isRequired: false,
                ),
              ],
          ])
        : serializeCommandOptions(<CommandOptionBuilder>[
            CommandOptionBuilder(
              type: CommandOptionType.string,
              name: 'target',
              description: 'Target value',
              isRequired: false,
            ),
          ]);

    final workflow = <String, dynamic>{
      'workflowMode': 'visual',
      'autoDeferIfActions': true,
      'visibility': 'public',
      'conditional': <String, dynamic>{'enabled': false},
    };

    final payload = <String, dynamic>{
      'id': commandId,
      'name': 'settings',
      'description': 'Manage bot settings',
      'type': 'chatInput',
      'folder': 'moderation',
      'data': <String, dynamic>{
        'commandType': 'chatInput',
        'editorMode': 'advanced',
        'executionMode': 'workflow',
        'legacyModeEnabled': legacyModeEnabled,
        'defaultMemberPermissions': '',
        'options': options,
        'response': <String, dynamic>{
          'type': 'normal',
          'text': 'Root reply',
          'components': <String, dynamic>{},
          'modal': <String, dynamic>{},
          'workflow': workflow,
        },
        'actions': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'sendMessage',
            'payload': <String, dynamic>{'content': 'Root action'},
          },
        ],
        if (includeSubcommands)
          'subcommandWorkflows': <String, dynamic>{
            'config/status': <String, dynamic>{
              'response': <String, dynamic>{
                'type': 'normal',
                'text': 'Status reply',
                'components': <String, dynamic>{},
                'modal': <String, dynamic>{},
                'workflow': workflow,
              },
              'actions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'sendMessage',
                  'payload': <String, dynamic>{'content': 'Status action'},
                },
              ],
            },
            'config/logchannel': <String, dynamic>{
              'response': <String, dynamic>{
                'type': 'normal',
                'text': 'Log reply',
                'components': <String, dynamic>{},
                'modal': <String, dynamic>{},
                'workflow': workflow,
              },
              'actions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'sendMessage',
                  'payload': <String, dynamic>{'content': 'Log action'},
                },
              ],
            },
          },
        if (includeSubcommands) 'activeSubcommandRoute': 'config/status',
      },
    };

    final file = File('${documentsDir.path}/apps/$botId/$commandId.json');
    file.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(payload));
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

  group('CommandCreatePage editor', () {
    testWidgets('confirming nested action edits enables main save button', (
      tester,
    ) async {
      const botId = 'bot-nested-dirty';
      const commandId = 'local-nested-dirty';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );
      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Add embed').first);
      // Les blocs refondus sont plus hauts : laisser le défilement se matérialiser.
      await tester.pump();
      await tester.tap(find.text('Add embed').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add embed'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('OK'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save changes'), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('confirming an unchanged nested page keeps command saved', (
      tester,
    ) async {
      const botId = 'bot-nested-clean';
      const commandId = 'local-nested-clean';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );
      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );
      await tester.ensureVisible(find.text('Add embed').first);
      // Les blocs refondus sont plus hauts : laisser le défilement se matérialiser.
      await tester.pump();
      await tester.tap(find.text('Add embed').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('OK'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('All changes saved'), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
    });

    testWidgets('confirming command option edits enables main save button', (
      tester,
    ) async {
      const botId = 'bot-options-dirty';
      const commandId = 'local-options-dirty';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );
      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );
      await tester.tap(find.byTooltip('Command settings'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('target'));
      await tester.tap(find.text('target'));
      await tester.pumpAndSettle();
      final description = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField && widget.initialValue == 'Target value',
      );
      await tester.ensureVisible(description);
      await tester.enterText(description, 'Updated option description');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Save'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Save changes'), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('new command shows block editor', (tester) async {
      await pumpCreatePage(tester, page: const CommandCreatePage());

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('Command Trigger'), findsOneWidget);
      expect(find.text('Response'), findsNothing);
      expect(find.text('Add block'), findsOneWidget);
      expect(find.byTooltip('Import command'), findsOneWidget);
      expect(find.byTooltip('Save changes'), findsNothing);
    });

    testWidgets('existing local command renders block editor with save bar', (
      tester,
    ) async {
      const botId = 'bot-edit-shell';
      const commandId = 'local-edit-shell';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
        legacyModeEnabled: true,
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.textContaining('Command Trigger'), findsOneWidget);
      expect(find.text('Response'), findsNothing);
      expect(find.byTooltip('All changes saved'), findsOneWidget);
      expect(find.byTooltip('Import command'), findsNothing);
    });

    testWidgets('block editor shows metadata and entry point in order', (
      tester,
    ) async {
      const botId = 'bot-edit-order';
      const commandId = 'local-edit-order';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
        legacyModeEnabled: true,
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      final metadataY = tester.getTopLeft(find.text('Metadata')).dy;
      final entryPointY = tester
          .getTopLeft(find.textContaining('Command Trigger'))
          .dy;

      expect(metadataY, lessThan(entryPointY));
    });

    testWidgets('edit mode hides create-only controls', (tester) async {
      const botId = 'bot-edit-hide';
      const commandId = 'local-edit-hide';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      expect(find.byTooltip('Import command'), findsNothing);
      expect(find.byTooltip('Create command'), findsNothing);
      expect(find.text('Infos'), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(find.text('Quick starts'), findsNothing);
    });
  });
}
