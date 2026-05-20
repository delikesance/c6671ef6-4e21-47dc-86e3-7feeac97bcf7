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
import 'package:nyxx/nyxx.dart'
    show CommandOptionBuilder, CommandOptionType, Snowflake;
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
  }) async {
    final options =
        includeSubcommands
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

  Future<Map<String, dynamic>> readLocalCommand({
    required String botId,
    required String commandId,
  }) async {
    final file = File('${documentsDir.path}/apps/$botId/$commandId.json');
    final content = file.readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
  }

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

  group('CommandCreatePage', () {
    testWidgets('new command shows block editor', (tester) async {
      await pumpCreatePage(tester, page: const CommandCreatePage());

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('Command Trigger'), findsOneWidget);
      expect(find.text('Response'), findsOneWidget);
      expect(find.text('Add block'), findsOneWidget);
      expect(find.byTooltip('Import command'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
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
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      expect(find.text('Metadata'), findsOneWidget);
      expect(find.text('Command Trigger'), findsOneWidget);
      expect(find.text('Response'), findsOneWidget);
      expect(find.text('All changes saved'), findsOneWidget);
      expect(find.byTooltip('Import command'), findsNothing);
    });

    testWidgets('block editor shows metadata and entry point before response', (
      tester,
    ) async {
      const botId = 'bot-edit-order';
      const commandId = 'local-edit-order';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      final metadataY = tester.getTopLeft(find.text('Metadata')).dy;
      final entryPointY = tester.getTopLeft(find.text('Command Trigger')).dy;
      final responseY = tester.getTopLeft(find.text('Response')).dy;

      expect(metadataY, lessThan(entryPointY));
      expect(entryPointY, lessThan(responseY));
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

    testWidgets(
      'incomplete existing command stays in read-only warning state',
      (tester) async {
        await pumpCreatePage(
          tester,
          page: CommandCreatePage(
            botId: 'bot-incomplete',
            id: Snowflake(424242),
          ),
        );

        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('Reply summary'), findsNothing);
        expect(find.text('Infos'), findsNothing);
      },
    );

    testWidgets('subcommand route switching updates reply and action context', (
      tester,
    ) async {
      const botId = 'bot-edit-routes';
      const commandId = 'local-edit-routes';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: true,
      );

      await pumpCreatePage(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      // Verify route chips are shown
      expect(find.text('/settings config status'), findsOneWidget);
      expect(find.text('/settings config logchannel'), findsOneWidget);

      // Tap the logchannel route chip
      await tester.tap(find.text('/settings config logchannel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify the logchannel chip is now selected
      final statusChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('/settings config status'),
          matching: find.byType(ChoiceChip),
        ),
      );
      final logchannelChip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('/settings config logchannel'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(statusChip.selected, isFalse);
      expect(logchannelChip.selected, isTrue);
    });

    testWidgets('back navigation from dirty edit state prompts for discard', (
      tester,
    ) async {
      const botId = 'bot-edit-dirty';
      const commandId = 'local-edit-dirty';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );

      await openPageFromHost(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      // Edit the command name to make the page dirty
      await tester.enterText(find.byType(TextFormField).first, 'updated-name');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Unsaved changes'), findsAtLeastNWidgets(1));
      expect(find.text('Keep editing'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
    });

    testWidgets('saving an existing local command keeps its identity', (
      tester,
    ) async {
      const botId = 'bot-edit-save';
      const commandId = 'local-edit-save';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );

      await openPageFromHost(
        tester,
        page: const CommandCreatePage(botId: botId, localCommandId: commandId),
      );

      // Make the page dirty by editing the command name
      await tester.enterText(
        find.byType(TextFormField).first,
        'settingsmodified',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger save inside runAsync so async I/O can complete
      await tester.runAsync(() async {
        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save changes'),
        );
        saveButton.onPressed?.call();
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (DateTime.now().isBefore(deadline)) {
          await tester.pump();
          try {
            final saved = await readLocalCommand(
              botId: botId,
              commandId: commandId,
            );
            if (saved.containsKey('updatedAt')) {
              return;
            }
          } catch (_) {}
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump(const Duration(milliseconds: 800));

      final saved = await readLocalCommand(botId: botId, commandId: commandId);
      expect(saved['id'], commandId);
      expect(saved.containsKey('updatedAt'), isTrue);
    });

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
          final createButton = tester.widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Create command'),
              matching: find.byType(IconButton),
            ),
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
          final createButton = tester.widget<IconButton>(
            find.ancestor(
              of: find.byTooltip('Create command'),
              matching: find.byType(IconButton),
            ),
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
