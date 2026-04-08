import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/routes/app/command.create.dart';
import 'package:bot_creator/routes/app/command_option_serialization.dart';
import 'package:bot_creator/utils/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart'
    show CommandOptionBuilder, CommandOptionType, Snowflake;
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
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
      await documentsDir.delete(recursive: true);
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

    await tester.pumpWidget(MaterialApp(home: page));
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
    testWidgets('new command keeps the wizard flow', (tester) async {
      await pumpCreatePage(tester, page: const CommandCreatePage());

      expect(find.text('Infos'), findsOneWidget);
      expect(find.text('Trigger & Inputs'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.byTooltip('Import command payload'), findsOneWidget);
      expect(find.text('Save changes'), findsNothing);
    });

    testWidgets('existing local command renders edit shell instead of wizard', (
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

      expect(find.text('settings'), findsOneWidget);
      expect(find.text('Reply summary'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);
      expect(find.text('Trigger & Inputs'), findsOneWidget);
      expect(find.text('Command settings'), findsOneWidget);
      expect(find.text('Infos'), findsNothing);
      expect(find.byTooltip('Import command payload'), findsNothing);
    });

    testWidgets(
      'edit mode prioritizes reply and actions before lower sections',
      (tester) async {
        const botId = 'bot-edit-order';
        const commandId = 'local-edit-order';
        await seedLocalCommand(
          botId: botId,
          commandId: commandId,
          includeSubcommands: false,
        );

        await pumpCreatePage(
          tester,
          page: const CommandCreatePage(
            botId: botId,
            localCommandId: commandId,
          ),
        );

        final replyY = tester.getTopLeft(find.text('Reply summary')).dy;
        final actionsY = tester.getTopLeft(find.text('Actions')).dy;
        final triggerY = tester.getTopLeft(find.text('Trigger & Inputs')).dy;
        final settingsY = tester.getTopLeft(find.text('Command settings')).dy;

        expect(replyY, lessThan(actionsY));
        expect(actionsY, lessThan(triggerY));
        expect(triggerY, lessThan(settingsY));
      },
    );

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

      expect(find.text('Infos'), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(find.text('Quick starts'), findsNothing);
      expect(find.byTooltip('Import command payload'), findsNothing);
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

      expect(
        find.text('Active route: /settings config status'),
        findsOneWidget,
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('/settings config logchannel').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Active route: /settings config logchannel'),
        findsOneWidget,
      );
      expect(find.text('Active route: /settings config status'), findsNothing);
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

      await tester.tap(find.text('Command settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, 'updated-folder');
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

      await tester.runAsync(() async {
        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save changes'),
        );
        saveButton.onPressed?.call();
        final deadline = DateTime.now().add(const Duration(seconds: 2));
        while (DateTime.now().isBefore(deadline)) {
          final saved = await readLocalCommand(
            botId: botId,
            commandId: commandId,
          );
          if (saved.containsKey('updatedAt')) {
            return;
          }
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

        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Legacy Command').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.enterText(
          find.byType(TextFormField).first,
          r'$awaitedCommand[say;<numeric>]',
        );
        await tester.pump();

        for (var i = 0; i < 4; i++) {
          await tester.tap(find.widgetWithText(FilledButton, 'Next'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }

        await tester.runAsync(() async {
          final createButton = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create command'),
          );
          createButton.onPressed?.call();
          final deadline = DateTime.now().add(const Duration(seconds: 2));
          while (DateTime.now().isBefore(deadline)) {
            final savedCommands = readAllLocalCommands(botId);
            if (savedCommands.isNotEmpty) {
              return;
            }
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

        await tester.tap(find.byKey(const ValueKey('awaited-preset-enable')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

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

        for (var i = 0; i < 4; i++) {
          await tester.tap(find.widgetWithText(FilledButton, 'Next'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }

        await tester.runAsync(() async {
          final createButton = tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create command'),
          );
          createButton.onPressed?.call();
          final deadline = DateTime.now().add(const Duration(seconds: 2));
          while (DateTime.now().isBefore(deadline)) {
            final savedCommands = readAllLocalCommands(botId);
            if (savedCommands.isNotEmpty) {
              return;
            }
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
