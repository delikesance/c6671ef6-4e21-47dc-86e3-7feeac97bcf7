import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const Size _desktopSize = Size(1600, 1000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp(
      'command_desktop_layout_test_',
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
      } catch (_) {}
    }
  });

  tearDown(() {
    CommandCreatePage.debugDesktopLayoutOverride = null;
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    required Size size,
    required bool isDesktop,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    CommandCreatePage.debugDesktopLayoutOverride = isDesktop;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CommandCreatePage(),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        break;
      }
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets(
    'desktop: plein-cadre sans PageContent, utilise tout l\'espace disponible',
    (tester) async {
      await pumpPage(tester, size: _desktopSize, isDesktop: true);

      // Sur desktop, PageContent n'est pas utilisé pour laisser tout l'espace disponible
      expect(find.byType(PageContent), findsNothing);

      // La palette est ancrée à gauche (x = 0) avec une largeur de ~320 px
      final paletteFinder = find.byType(ScratchBlockPalette);
      expect(paletteFinder, findsOneWidget);
      expect(tester.getTopLeft(paletteFinder).dx, 0);
      expect(tester.getSize(paletteFinder).width, closeTo(320, 1.5));

      // Le switcher de vue (Blocs / Blueprint) est présent
      expect(find.text('Blueprint'), findsOneWidget);
      expect(find.text('Blocs'), findsOneWidget);
    },
  );

  testWidgets(
    'mobile: enveloppe PageContent active pour la mise en page compacte',
    (tester) async {
      await pumpPage(tester, size: const Size(400, 800), isDesktop: false);

      expect(find.byType(PageContent), findsOneWidget);
      expect(find.byType(ScratchBlockPalette), findsNothing);
    },
  );
}
