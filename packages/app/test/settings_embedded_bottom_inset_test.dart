// Verrou de mise en page : la page Paramètres embarquée dans le shell compact
// ne doit PAS réserver une seconde fois l'inset bas du système.
//
// Le shell (`main.dart`) réserve déjà, sous le contenu, toute la zone de la
// barre flottante — inset système compris :
// `FloatingGlassNavBar.contentClearanceOf` = marge 16 + inset bas + hauteur 64.
// Le `SafeArea` bas interne de la page en ajoutait un second : il se traduisait
// par un vide de [24 + inset] px entre la dernière carte et la barre (capture du
// 13/09/2026, page Paramètres scrollée en bas).
//
// Mesure : écart entre le bas de la page et le bas de son viewport scrollable.
// Nul quand la page est embarquée (le shell a déjà tout réservé), égal à l'inset
// système quand elle est autonome.
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Inset bas du système simulé (px physiques = px logiques, dpr 1).
const double _systemBottomInset = 24;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const <String, Object>{
      // Rich presence Discord DÉSACTIVÉE : montée activée, la page déclenche une
      // connexion qui échoue en test et programme un timer de reconnexion de
      // 10 s — flutter_test échoue alors au démontage sur
      // « A Timer is still pending even after the widget tree was disposed ».
      'discord_rpc_config': '{"enabled":false,"clientId":""}',
    });
    documentsDir = await Directory.systemTemp.createTemp('settings_inset_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Fichiers SQLite verrouillés : sans importance pour le test.
      }
    }
  });

  /// Monte la page Paramètres avec l'inset bas système renseigné.
  Future<void> pumpSettings(
    WidgetTester tester, {
    required bool embedded,
    required Future<void> Function() body,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: _systemBottomInset);
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            Provider(create: (_) => OnboardingManager(prefs)),
          ],
          child: MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.dark,
            home: SettingPage(embedded: embedded),
          ),
        ),
      );
      // `pump` borné (jamais `pumpAndSettle`) : la page lance des services
      // asynchrones (sauvegardes, abonnements) qui ne se stabilisent pas.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await body();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// Écart entre le bas de la page et le bas de son viewport scrollable.
  double bottomVoid(WidgetTester tester) {
    final page = tester.getRect(find.byType(SettingPage));
    final viewport = tester.getRect(
      find
          .descendant(
            of: find.byType(SettingPage),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    return page.bottom - viewport.bottom;
  }

  testWidgets('page Paramètres embarquée : aucun inset bas en double', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      embedded: true,
      body: () async {
        expect(
          bottomVoid(tester),
          0,
          reason:
              'le shell réserve déjà l’inset système sous la barre flottante '
              '(contentClearanceOf) : la page ne doit rien ajouter',
        );
      },
    );
  });

  testWidgets('page Paramètres autonome : l’inset système est bien réservé', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      embedded: false,
      body: () async {
        expect(
          bottomVoid(tester),
          _systemBottomInset,
          reason:
              'route poussée sans barre flottante : l’inset bas doit être '
              'évité par la page elle-même',
        );
      },
    );
  });
}
