import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_export_import.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
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
  late AppManager appManager;
  const botId = '987654321098765432';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp('bot_integrity_test_');
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
      } catch (_) {}
    }
  });

  setUp(() async {
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'name': 'IntegrityBot',
      'runtimeEngine': runtimeEngineJavascript,
    });
    final existingCmds = await appManager.listAppCommands(botId);
    for (final cmd in existingCmds) {
      final cmdId = (cmd['id'] ?? '').toString();
      if (cmdId.isNotEmpty) {
        await appManager.deleteAppCommand(botId, cmdId);
      }
    }
  });

  group('Bug #1: Runtime Engine Immutability and Persistence', () {
    test('exportBot includes runtimeEngine in manifest.json', () async {
      await setBotRuntimeEngine(botId, runtimeEngineJavascript);

      final zipBytes = await exportBot(
        botId,
        sections: {ExportSection.commands},
      );

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final manifestFile = archive.findFile('manifest.json');
      expect(manifestFile, isNotNull);

      final manifestJson =
          jsonDecode(utf8.decode(manifestFile!.content as List<int>))
              as Map<String, dynamic>;
      expect(manifestJson['runtimeEngine'], runtimeEngineJavascript);
    });

    test(
      'parseExportZip reads runtimeEngine and importBot restores it',
      () async {
        // Create archive with JS engine
        final archive = Archive();
        final manifest = {
          'version': 1,
          'runtimeEngine': runtimeEngineJavascript,
          'sections': ['commands'],
        };
        archive.addFile(
          ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
        );
        archive.addFile(
          ArchiveFile.bytes(
            'commands/cmd1.json',
            utf8.encode(
              jsonEncode({
                'id': 'cmd1',
                'name': 'testjs',
                'executionMode': 'javascript',
                'jsScriptContent': 'console.log("hello");',
              }),
            ),
          ),
        );

        final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final preview = parseExportZip(zipBytes);
        expect(preview.runtimeEngine, runtimeEngineJavascript);

        // Target bot is currently Dart
        await setBotRuntimeEngine(botId, runtimeEngineDart);
        expect(await getBotRuntimeEngine(botId), runtimeEngineDart);

        // Importing restores JS
        await importBot(botId, preview: preview);
        expect(await getBotRuntimeEngine(botId), runtimeEngineJavascript);
      },
    );

    test(
      'parseExportZip heuristically detects JS if manifest lacks runtimeEngine',
      () {
        final archive = Archive();
        final manifest = {
          'version': 1,
          // No runtimeEngine
          'sections': ['commands'],
        };
        archive.addFile(
          ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
        );
        archive.addFile(
          ArchiveFile.bytes(
            'commands/cmd1.json',
            utf8.encode(
              jsonEncode({
                'id': 'cmd1',
                'name': 'testjs',
                'data': {
                  'executionMode': 'javascript',
                  'jsScriptContent': 'console.log("hello");',
                },
              }),
            ),
          ),
        );

        final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
        final preview = parseExportZip(zipBytes);
        expect(preview.runtimeEngine, runtimeEngineJavascript);
        // …mais c'est une DÉDUCTION, pas une déclaration : l'import doit
        // pouvoir le dire à l'utilisateur au lieu de l'appliquer en silence.
        expect(
          preview.runtimeEngineDeclared,
          isFalse,
          reason: 'sans runtimeEngine au manifeste, le moteur reste à choisir',
        );
      },
    );

    test('un ZIP muet ne bascule PAS le moteur du bot, même si le contenu '
        'est JavaScript', () async {
      final archive = Archive();
      final manifest = {
        'version': 1,
        // Pas de runtimeEngine : le ZIP ne dit rien du moteur.
        'sections': ['commands'],
      };
      archive.addFile(
        ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'commands/cmd1.json',
          utf8.encode(
            jsonEncode({
              'id': 'cmd1',
              'name': 'restore_me',
              'data': {
                'executionMode': 'javascript',
                'jsScriptContent': 'console.log("hello");',
              },
            }),
          ),
        ),
      );

      final preview = parseExportZip(
        Uint8List.fromList(ZipEncoder().encode(archive)),
      );

      await setBotRuntimeEngine(botId, runtimeEngineDart);
      // Aucun choix explicite : le moteur du bot doit rester celui qu'il est.
      await importBot(botId, preview: preview);

      expect(
        await getBotRuntimeEngine(botId),
        runtimeEngineDart,
        reason:
            'un moteur DÉDUIT du contenu ne doit jamais être appliqué tout '
            'seul : c\'est ce qui faisait redevenir Dart des bots JavaScript',
      );
    });

    test('un ZIP muet applique le moteur CHOISI par l\'utilisateur', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'manifest.json',
          utf8.encode(
            jsonEncode({
              'version': 1,
              'sections': ['commands'],
            }),
          ),
        ),
      );
      archive.addFile(
        ArchiveFile.bytes(
          'commands/cmd1.json',
          utf8.encode(
            jsonEncode({
              'id': 'cmd1',
              'name': 'from_js_zip',
              'data': {
                'executionMode': 'javascript',
                'jsScriptContent': 'console.log("hello");',
              },
            }),
          ),
        ),
      );

      final preview = parseExportZip(
        Uint8List.fromList(ZipEncoder().encode(archive)),
      );

      await setBotRuntimeEngine(botId, runtimeEngineDart);
      await importBot(
        botId,
        preview: preview,
        runtimeEngine: runtimeEngineJavascript,
      );

      expect(await getBotRuntimeEngine(botId), runtimeEngineJavascript);
    });

    test('un ZIP qui DÉCLARE son moteur s\'applique sans question', () async {
      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'manifest.json',
          utf8.encode(
            jsonEncode({
              'version': 1,
              'runtimeEngine': runtimeEngineJavascript,
              'sections': <String>[],
            }),
          ),
        ),
      );

      final preview = parseExportZip(
        Uint8List.fromList(ZipEncoder().encode(archive)),
      );
      expect(preview.runtimeEngineDeclared, isTrue);

      await setBotRuntimeEngine(botId, runtimeEngineDart);
      await importBot(botId, preview: preview);

      expect(
        await getBotRuntimeEngine(botId),
        runtimeEngineJavascript,
        reason: 'le manifeste reste la référence quand il déclare le moteur',
      );
    });

    test(
      'applyManagerConfigToLocal preserves local runtimeEngine when remote lacks it',
      () async {
        await setBotRuntimeEngine(botId, runtimeEngineJavascript);
        expect(await getBotRuntimeEngine(botId), runtimeEngineJavascript);

        // Remote config has no runtimeEngine
        final remoteConfig = <String, dynamic>{
          'id': botId,
          'name': 'Updated Remote Name',
          'commands': <dynamic>[],
          'workflows': <dynamic>[],
        };

        await applyManagerConfigToLocal(
          appManager: appManager,
          botId: botId,
          remoteConfig: remoteConfig,
          saveAppMetadata: true,
        );

        final updatedApp = await appManager.getApp(botId);
        expect(updatedApp['name'], 'Updated Remote Name');
        expect(updatedApp['runtimeEngine'], runtimeEngineJavascript);
        expect(await getBotRuntimeEngine(botId), runtimeEngineJavascript);
      },
    );
  });

  group('Bug #3: File Hierarchy and Folder Preservation', () {
    test('exportBot preserves nested folder hierarchy in ZIP paths', () async {
      await appManager.saveAppCommand(botId, 'cmd_nested', <String, dynamic>{
        'id': 'cmd_nested',
        'name': 'ban',
        'folder': 'admin/moderation',
        'type': 'chatInput',
        'data': <String, dynamic>{},
      });

      final zipBytes = await exportBot(
        botId,
        sections: {ExportSection.commands},
      );

      final archive = ZipDecoder().decodeBytes(zipBytes);
      final entry = archive.findFile(
        'commands/admin/moderation/cmd_nested.json',
      );
      expect(
        entry,
        isNotNull,
        reason: 'Command should be saved in nested folder path',
      );
    });

    test('parseExportZip extracts folder from ZIP path if missing in JSON', () {
      final archive = Archive();
      archive.addFile(
        ArchiveFile.bytes(
          'commands/tools/utilities/calc.json',
          utf8.encode(
            jsonEncode({
              'id': 'calc_id',
              'name': 'calculate',
              // No folder attribute
            }),
          ),
        ),
      );

      final zipBytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final preview = parseExportZip(zipBytes);
      expect(preview.commands, hasLength(1));
      expect(preview.commands.first['folder'], 'tools/utilities');
    });

    test(
      'applyManagerConfigToLocal preserves folder attribute on commands',
      () async {
        final remoteConfig = <String, dynamic>{
          'id': botId,
          'commands': [
            {
              'id': 'cmd_remote_folder',
              'name': 'mute',
              'folder': 'admin/moderation',
              'data': <String, dynamic>{},
            },
          ],
        };

        await applyManagerConfigToLocal(
          appManager: appManager,
          botId: botId,
          remoteConfig: remoteConfig,
          saveAppMetadata: false,
        );

        final localCmd = await appManager.getAppCommand(
          botId,
          'cmd_remote_folder',
        );
        expect(localCmd['folder'], 'admin/moderation');
      },
    );

    test(
      'applyManagerWorkflowsToLocal preserves workflow folder, executionMode, and script',
      () async {
        final remoteConfig = <String, dynamic>{
          'id': botId,
          'workflows': [
            {
              'name': 'auto_mod',
              'folder': 'security/automod',
              'executionMode': 'javascript',
              'jsScriptContent': 'processEvent();',
              'actions': <dynamic>[],
            },
          ],
        };

        await applyManagerWorkflowsToLocal(
          appManager: appManager,
          botId: botId,
          remoteConfig: remoteConfig,
        );

        final workflows = await appManager.getWorkflows(botId);
        final automod = workflows.firstWhere((w) => w['name'] == 'auto_mod');
        expect(automod['folder'], 'security/automod');
        expect(automod['executionMode'], 'javascript');
        expect(automod['jsScriptContent'], 'processEvent();');
      },
    );
  });
}
