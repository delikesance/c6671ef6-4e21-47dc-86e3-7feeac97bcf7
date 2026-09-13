// Verrou de mise en page : les sous-pages de l'éditeur de bot suivent le
// contrat commun `AppPageLayout` (widget `PageContent` = largeur maximale et
// marges partagées) au lieu du plein-cadre historique (100 % de la largeur,
// 12/16 px de marge).
//
// Mesures exigées : en 1600x1000 (zone large, seuil `AppTheme.desktopBreakpoint`
// = 720), la contrainte de contenu vaut `AppPageLayout.maxContentWidth` (1200)
// et le contenu est posé à `AppPageLayout.horizontalPadding` (24 px) du bord de
// cette zone.
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/emojis.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/guilds.page.dart';
import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _botId = '123456789012345678';
const String _guildsEndpoint = 'https://example.invalid/users/@me/guilds';

/// Deux serveurs : la page quitte l'état vide et rend sa liste réelle.
const String _guildsPayload =
    '[{"id":"1000000000000000001","name":"Alpha"},'
    '{"id":"1000000000000000002","name":"Bravo"}]';

/// Zone large de référence.
const Size _desktopSize = Size(1600, 1000);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    documentsDir = await Directory.systemTemp.createTemp('editor_pages_margin_');
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
        // Fichiers éventuellement verrouillés : sans importance pour le test.
      }
    }
  });

  /// Monte [page] en [_desktopSize] puis exécute [body].
  ///
  /// `pump` borné uniquement : ces pages lancent des chargements asynchrones
  /// qui ne se stabilisent pas (`pumpAndSettle` boucherait indéfiniment).
  Future<void> pumpDesktop(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = _desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: page,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Enveloppe commune : [PageContent] centré, contrainte 1200 et marge 24.
  void expectCommonEnvelope(WidgetTester tester) {
    expect(find.byType(PageContent), findsOneWidget);
    // L'enveloppe occupe toute la zone disponible (le contenu est centré dedans).
    expect(tester.getSize(find.byType(PageContent)).width, _desktopSize.width);

    final constrained = find
        .descendant(
          of: find.byType(PageContent),
          matching: find.byType(ConstrainedBox),
        )
        .first;
    final contentBox = tester.widget<ConstrainedBox>(constrained);
    expect(contentBox.constraints.maxWidth, AppPageLayout.maxContentWidth);
    expect(contentBox.constraints.maxWidth, 1200);

    // Centré horizontalement : 1600 de zone, 1200 de contenu ⇒ 200 px de chaque
    // côté, dont les 24 px de marge commune.
    expect(tester.getRect(constrained).left, (_desktopSize.width - 1200) / 2);
    expect(tester.getRect(constrained).width, 1200);

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
      const EdgeInsets.symmetric(horizontal: AppPageLayout.horizontalPadding),
    );
    expect(
      contentPadding.padding,
      AppPageLayout.paddingFor(_desktopSize.width),
    );
    expect(contentPadding.padding.horizontal / 2, 24);
  }

  testWidgets('emojis : enveloppe commune en zone large', (tester) async {
    await pumpDesktop(tester, const EmojisPage(botId: _botId));
    expectCommonEnvelope(tester);
  });

  testWidgets('serveurs : enveloppe commune en zone large, liste réelle '
      'à la largeur du contrat', (tester) async {
    final directory = GuildDirectory(
      guildsEndpoint: _guildsEndpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async => _guildsPayload,
    );

    await pumpDesktop(tester, GuildsPage(botId: _botId, directory: directory));
    expectCommonEnvelope(tester);

    // Rend réellement : la liste des serveurs est là, ancrée à 24 px de marge.
    final list = find
        .descendant(
          of: find.byType(PageContent),
          matching: find.byType(ListView),
        )
        .first;
    expect(find.text('Alpha'), findsOneWidget);
    expect(
      tester.getSize(list).width,
      AppPageLayout.maxContentWidth - 2 * AppPageLayout.horizontalPadding,
    );
    expect(
      tester.getRect(list).left,
      (_desktopSize.width - AppPageLayout.maxContentWidth) / 2 +
          AppPageLayout.horizontalPadding,
    );
  });

  testWidgets('emojis : zone compacte, repli sur la largeur et la marge '
      'compactes', (tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EmojisPage(botId: _botId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final contentBox = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byType(PageContent),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    expect(contentBox.constraints.maxWidth, AppPageLayout.compactMaxContentWidth);
    expect(
      tester
          .widget<Padding>(
            find
                .descendant(
                  of: find.byType(PageContent),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding,
      const EdgeInsets.symmetric(
        horizontal: AppPageLayout.compactHorizontalPadding,
      ),
    );
  });

  testWidgets('retour desktop : la sous-page autonome ne rend pas de seconde '
      'flèche (la barre de titre du shell la fournit)', (tester) async {
    // Contrôle de sensibilité : mobile ⇒ la page reste responsable du retour.
    for (final platform in <TargetPlatform>[
      TargetPlatform.linux,
      TargetPlatform.android,
    ]) {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (routeContext) => Scaffold(
                        appBar: AppBar(
                          automaticallyImplyLeading: false,
                          leading: editorSubPageLeading(routeContext),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Ouvrir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(
        find.byType(BackButton),
        platform == TargetPlatform.linux ? findsNothing : findsOneWidget,
        reason: 'retour en double sur $platform',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    debugDefaultTargetPlatformOverride = null;
  });
}
