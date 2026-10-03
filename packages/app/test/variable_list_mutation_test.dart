import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/storage/runtime_preferences.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VariableStorage implements AppManager {
  final deletion = Completer<void>();
  final loaded = Completer<void>();
  int reads = 0;

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String botId) async {
    reads++;
    if (!loaded.isCompleted) loaded.complete();
    return {'remove_me': 1, 'keep_me': 2};
  }

  @override
  Future<List<Map<String, dynamic>>> getScopedVariableDefinitions(
    String botId,
  ) async => [];

  @override
  Future<Map<String, Map<String, Map<String, dynamic>>>> exportScopedVariables(
    String botId,
  ) async => {};

  @override
  Future<void> removeGlobalVariable(String botId, String key) =>
      deletion.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDirectory;
  setUpAll(() async {
    storageDirectory = await Directory.systemTemp.createTemp('variable_list_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => storageDirectory.path,
        );
  });
  tearDownAll(() => storageDirectory.delete(recursive: true));

  for (final fails in [false, true]) {
    testWidgets('global deletion preserves visible list; failure=$fails', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await RuntimePreferences.setMobileLocalHostingEnabled(true);
      final previous = appManager;
      final storage = _VariableStorage();
      appManager = storage;
      addTearDown(() => appManager = previous);
      final tr = await AppLocalizations.delegate.load(const Locale('en'));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const GlobalVariablesPage(botId: '123456789012345'),
        ),
      );
      for (
        var attempt = 0;
        attempt < 30 && !storage.loaded.isCompleted;
        attempt++
      ) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
      }
      expect(storage.loaded.isCompleted, true);
      await tester.pumpAndSettle();
      expect(find.text('keep_me'), findsOneWidget);
      final row = find.byKey(const ValueKey('remove_me'));
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, tr.delete));
      await tester.pumpAndSettle();
      expect(find.text('keep_me'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      if (fails) {
        storage.deletion.completeError(StateError('Storage unavailable'));
      } else {
        storage.deletion.complete();
      }
      await tester.pumpAndSettle();
      expect(find.text('remove_me'), fails ? findsOneWidget : findsNothing);
      expect(find.text('keep_me'), findsOneWidget);
      expect(storage.reads, 1);
      expect(tester.takeException(), isNull);
    });
  }
}
