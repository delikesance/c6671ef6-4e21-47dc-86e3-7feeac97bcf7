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
    bool legacyModeEnabled = false,
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

  Future<Map<String, dynamic>> readLocalCommand({
    required String botId,
    required String commandId,
  }) async {
    final file = File('${documentsDir.path}/apps/$botId/$commandId.json');
    final content = file.readAsStringSync();
    return Map<String, dynamic>.from(jsonDecode(content) as Map);
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

  group('CommandCreatePage save workflow', () {
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

    for (final discordId in [Snowflake.zero, Snowflake(777)]) {
    testWidgets('saving keeps the storage identity ($discordId)', (
      tester,
    ) async {
      final botId = 'bot-edit-save-$discordId';
      const commandId = 'local-edit-save';
      await seedLocalCommand(
        botId: botId,
        commandId: commandId,
        includeSubcommands: false,
      );

      await openPageFromHost(
        tester,
        page: CommandCreatePage(botId: botId, localCommandId: commandId, id: discordId),
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
        final saveButton = tester.widget<FloatingActionButton>(
          find.byType(FloatingActionButton),
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
      if (!discordId.isZero) {
        expect(saved['discordId'], discordId.toString());
      }
      expect(saved.containsKey('updatedAt'), isTrue);
    });

    }

    testWidgets(
      'saving a legacy prefix command saves locally and enforces legacyLocalOnly',
      (tester) async {
        const botId = 'bot-legacy-save';
        const commandId = 'local-legacy-save';
        await seedLocalCommand(
          botId: botId,
          commandId: commandId,
          includeSubcommands: false,
          legacyModeEnabled: true,
        );

        await openPageFromHost(
          tester,
          page: const CommandCreatePage(
            botId: botId,
            localCommandId: commandId,
          ),
        );

        // Make the page dirty by editing the command name
        await tester.enterText(
          find.byType(TextFormField).first,
          'prefixcommand',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Trigger save inside runAsync so async I/O can complete
        await tester.runAsync(() async {
          final saveButton = tester.widget<FloatingActionButton>(
            find.byType(FloatingActionButton),
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

        final saved = await readLocalCommand(
          botId: botId,
          commandId: commandId,
        );
        expect(saved['id'], commandId);
        expect(saved.containsKey('updatedAt'), isTrue);
        final data = saved['data'] as Map<String, dynamic>;
        expect(data['legacyModeEnabled'], isTrue);
        expect(data['legacyLocalOnly'], isTrue);
      },
    );
  });
}
