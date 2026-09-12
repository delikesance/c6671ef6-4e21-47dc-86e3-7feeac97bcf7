import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_settings_provider.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/js_editor/editor_theme_scope.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bdfd_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The BDFD script editor is reachable from three call sites (`command.create
/// .bdfd`, `command.create.block_editor`, `builder/action_card`) and always as
/// a pushed route. It must therefore paint itself entirely from the selected
/// code editor palette — never mix a light page with a dark code area, and
/// never leave the code area capped to a fraction of a desktop window.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sampleScript =
      r'$onlyadmin [Neop]'
      '\n'
      r'$eval [$message]';

  Future<CodeEditorThemeColors> pumpEditor(
    WidgetTester tester, {
    required Size size,
    CodeEditorTheme theme = CodeEditorTheme.rosePine,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final provider = CodeEditorSettingsProvider();
    await provider.load();
    provider.updateTheme(theme);

    await tester.pumpWidget(
      ChangeNotifierProvider<CodeEditorSettingsProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          // `AppLocalizations.of` is strict: every page needs the real
          // delegates, exactly like `main.dart` wires them.
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: const BdfdEditorPage(initialCode: sampleScript),
        ),
      ),
    );
    // The editor owns a blinking cursor: `pumpAndSettle` never returns.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    return CodeEditorThemeColors.forTheme(theme);
  }

  Scaffold pageScaffold(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold).first);

  testWidgets('palette Rosé Pine : la page entière est SOMBRE (pas de fond '
      'clair sous un éditeur sombre)', (tester) async {
    final colors = await pumpEditor(tester, size: const Size(1600, 1000));

    final scaffold = pageScaffold(tester);
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);

    // ignore: avoid_print
    print(
      'ROSE PINE  scaffold=${scaffold.backgroundColor} '
      'appBar=${appBar.backgroundColor} '
      'attendu background=${colors.background} surface=${colors.surface}',
    );

    expect(scaffold.backgroundColor, colors.background);
    expect(appBar.backgroundColor, colors.surface);
  });

  testWidgets('palette Rosé Pine Dawn : la page entière est CLAIRE', (
    tester,
  ) async {
    final colors = await pumpEditor(
      tester,
      size: const Size(1600, 1000),
      theme: CodeEditorTheme.rosePineDawn,
    );

    final scaffold = pageScaffold(tester);
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);

    // ignore: avoid_print
    print(
      'DAWN  scaffold=${scaffold.backgroundColor} '
      'appBar=${appBar.backgroundColor} '
      'attendu background=${colors.background} surface=${colors.surface}',
    );

    expect(scaffold.backgroundColor, colors.background);
    expect(appBar.backgroundColor, colors.surface);
  });

  testWidgets('desktop : la zone de code occupe la largeur ET la hauteur '
      'disponibles (pas 40 % de la fenêtre)', (tester) async {
    await pumpEditor(tester, size: const Size(1600, 1000));

    final field = tester.getSize(find.byType(TextField).first);
    final body = tester.getSize(find.byType(BdfdEditorPage));

    // ignore: avoid_print
    print('DESKTOP  fenêtre=$body  zone de code=$field');

    // Assertion SERRÉE : la zone de code est bord à bord (edge-to-edge) :
    // largeur fenêtre − gouttière des numéros de ligne (40).
    expect(
      field.width,
      closeTo(body.width - 40, 1.0),
      reason:
          'la zone de code doit remplir toute la largeur (fenêtre − gouttière), '
          'sans marges superflues',
    );
    expect(
      field.height,
      greaterThan(body.height * 0.8),
      reason: 'la zone de code doit remplir la hauteur disponible',
    );
  });

  testWidgets('barre d\'outils : menu « ⋮ » sous 700 px, icônes au-dessus', (
    tester,
  ) async {
    // Le seuil doit basculer EXACTEMENT à 700 px, et aucun des deux états ne
    // doit déborder. À 360 dp, 5 icônes + l'action principale débordaient de
    // 17 px : d'où le menu.
    final expectations = <double, bool>{
      360: true, // menu
      699: true, // menu
      700: false, // icônes
      1200: false, // icônes
    };

    for (final entry in expectations.entries) {
      await pumpEditor(tester, size: Size(entry.key, 720));
      final usesMenu = entry.value;

      expect(
        find.byIcon(Icons.more_vert),
        usesMenu ? findsOneWidget : findsNothing,
        reason:
            'à ${entry.key.round()} px le menu doit ${usesMenu ? '' : 'ne pas '}être affiché',
      );
      expect(
        find.byIcon(Icons.menu_book),
        usesMenu ? findsNothing : findsOneWidget,
        reason:
            'à ${entry.key.round()} px les icônes doivent ${usesMenu ? 'être masquées' : 'être visibles'}',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'débordement de la barre d\'outils à ${entry.key.round()} px',
      );
    }
  });

  testWidgets('mobile 360 dp : aucun débordement, la zone de code défile', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(360, 720));

    // Le retour à la ligne est désactivé par défaut : la zone de code est donc
    // plus large que la fenêtre et défile horizontalement. Ce qui doit tenir
    // dans la fenêtre, c'est la VUE du défilement — et rien ne doit déborder.
    expect(tester.takeException(), isNull);

    final viewport = find
        .ancestor(
          of: find.byType(TextField).first,
          matching: find.byType(SingleChildScrollView),
        )
        .first;
    final viewportWidth = tester.getSize(viewport).width;
    // ignore: avoid_print
    print(
      'MOBILE  vue défilante=$viewportWidth '
      'contenu=${tester.getSize(find.byType(TextField).first).width}',
    );
    expect(viewportWidth, lessThanOrEqualTo(360));
  });

  test(
    'resolveCodeEditorTheme mappe les thèmes sombres vers clair en mode clair',
    () {
      expect(
        resolveCodeEditorTheme(CodeEditorTheme.rosePine, isLight: true),
        CodeEditorTheme.rosePineDawn,
      );
      expect(
        resolveCodeEditorTheme(CodeEditorTheme.githubDark, isLight: true),
        CodeEditorTheme.githubLight,
      );
      expect(
        resolveCodeEditorTheme(CodeEditorTheme.rosePineDawn, isLight: true),
        CodeEditorTheme.rosePineDawn,
      );
      expect(
        resolveCodeEditorTheme(CodeEditorTheme.rosePine, isLight: false),
        CodeEditorTheme.rosePine,
      );
    },
  );

  testWidgets(
    'barre de touches rapides mobile : boutons présents et pas de badge EDITOR UX',
    (tester) async {
      await pumpEditor(tester, size: const Size(360, 720));

      expect(find.text('EDITOR UX'), findsNothing);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text(r'$'), findsWidgets);
      expect(find.text('['), findsWidgets);
      expect(find.text(']'), findsWidgets);
    },
  );
}
