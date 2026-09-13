// Verrou de chrome de la page Réglages (application), en desktop :
//   1. la page ne rend AUCUN bouton de retour — la barre de titre du shell
//      (`DesktopTitleBar`, au-dessus de la page) fournit déjà la flèche ;
//   2. plus d'icône héro `Icons.settings` en tête de page (le titre
//      « Backup and Restore » remonte en première position) ;
//   3. plus d'`IconButton` de bascule de thème dans l'AppBar : la carte
//      « Apparence » porte désormais la seule commande de mode
//      (Dark / Light / System) ;
//   4. le contenu suit la largeur et les marges communes (`PageContent`,
//      `AppPageLayout` : 1200 px centrés, 24 px de marge horizontale) au lieu
//      de ses anciennes bornes locales (600 px, padding 16/24).
//
// La page est POUSSÉE comme une route (comme `home_page.dart` le fait) : sans
// route poussée, l'AppBar n'aurait rien à dépiler et le verrou « pas de bouton
// retour » serait creux.
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
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

/// Fenêtre desktop de référence : assez large pour la mise en page commune
/// (1200 px de contenu centré).
const Size _desktopSize = Size(1600, 1000);

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
    documentsDir = await Directory.systemTemp.createTemp(
      'settings_chrome_test_',
    );
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

  /// Monte l'app en desktop 1600x1000 (locale fr) puis POUSSE la page Réglages
  /// sur le Navigator — c'est cette route poussée qui rend l'absence de bouton
  /// de retour significative (`ModalRoute.canPop` vrai).
  Future<void> pumpPushedSettings(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    try {
      tester.view.physicalSize = _desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final prefs = await SharedPreferences.getInstance();
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            Provider(create: (_) => OnboardingManager(prefs)),
          ],
          child: MaterialApp(
            navigatorKey: navigatorKey,
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: ThemeMode.dark,
            home: const Scaffold(body: Center(child: Text('accueil'))),
          ),
        ),
      );
      await tester.pump();

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const SettingPage()),
      );
      // `pump` borné (jamais `pumpAndSettle`) : la page lance des services
      // asynchrones (sauvegardes, abonnements, curseur clignotant) qui ne se
      // stabilisent pas.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await body();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('desktop : plus de bouton retour, plus d’icône héro, plus de switch '
      'de thème', (tester) async {
    await pumpPushedSettings(tester, () async {
      // La route poussée peut être dépilée : sans le correctif, l'AppBar
      // afficherait donc son bouton retour implicite (le test serait creux si
      // la page était la route racine).
      expect(
        ModalRoute.of(tester.element(find.byType(SettingPage)))?.canPop,
        isTrue,
        reason:
            'la page doit être poussée : c’est ce qui déclenche le bouton '
            'retour implicite de l’AppBar',
      );

      // (a) Aucune flèche de retour rendue par la page.
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

      // (c) Plus d'icône héro `Icons.settings` en tête de page.
      expect(
        find.descendant(
          of: find.byType(SettingPage),
          matching: find.byIcon(Icons.settings),
        ),
        findsNothing,
      );

      // (b) L'AppBar ne porte plus d'`IconButton` de bascule de thème.
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
      expect(
        find.descendant(of: appBar, matching: find.byType(IconButton)),
        findsNothing,
        reason:
            'la carte « Apparence » porte désormais la seule commande de mode',
      );
      expect(find.byIcon(Icons.light_mode), findsNothing);
      expect(find.byIcon(Icons.dark_mode), findsNothing);

      // (c bis) Le titre est remonté en tête de page (l'ancien héro de 60/80 px
      // plus son `SizedBox(height: 24)` le repoussaient nettement plus bas).
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final title = find.text(l10n.settings_backup_restore_title);
      expect(title, findsOneWidget);
      expect(
        tester.getTopLeft(title).dy,
        lessThan(150),
        reason: 'plus d’icône héro : le titre démarre juste sous l’AppBar',
      );
    });
  });

  testWidgets('desktop : largeur et marges communes (PageContent)', (
    tester,
  ) async {
    await pumpPushedSettings(tester, () async {
      expect(find.byType(PageContent), findsOneWidget);

      // L'enveloppe occupe toute la page (le contenu est centré dedans).
      expect(
        tester.getSize(find.byType(PageContent)).width,
        _desktopSize.width,
      );

      // (d) La borne locale de 600 px est remplacée par la largeur commune.
      final contentBox = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(PageContent),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(contentBox.constraints.maxWidth, 1200);
      expect(contentBox.constraints.maxWidth, AppPageLayout.maxContentWidth);

      // Marge horizontale commune (24 px en zone large), plus de 16/24 locaux.
      final contentPadding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(PageContent),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        contentPadding.padding,
        const EdgeInsets.symmetric(horizontal: 24),
      );
      expect(
        contentPadding.padding,
        AppPageLayout.paddingFor(_desktopSize.width),
      );

      // Rend réellement : la zone défilante fait la largeur commune moins les
      // deux marges, et plus jamais 600 px.
      final scrollView = tester.getSize(
        find
            .descendant(
              of: find.byType(PageContent),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );
      expect(scrollView.width, AppPageLayout.maxContentWidth - 2 * 24);
    });
  });
}
