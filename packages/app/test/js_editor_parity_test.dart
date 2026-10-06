import 'package:bot_creator/core/code_editor/script_editor_diagnostics_bar.dart';
import 'package:bot_creator/core/code_editor/script_editor_editor_body.dart';
import 'package:bot_creator/core/code_editor/script_editor_overlays.dart';
import 'package:bot_creator/core/code_editor/script_editor_snippet.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/js_editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parité éditeur : l'éditeur JavaScript doit offrir tout ce que l'éditeur
/// BDFD offrait (numéros de ligne, autocomplete + emojis, signatures,
/// diagnostics temps réel, bascules, caractères rapides mobile), puisque les
/// deux pages partagent désormais le chrome `core/code_editor/`.
void main() {
  Future<void> pumpEditor(
    WidgetTester tester, {
    required Size size,
    String initialCode = '',
    List<AppEmoji> appEmojis = const <AppEmoji>[],
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        // Le chrome choisit sa variante bureau/mobile sur `Theme.platform` :
        // pas besoin de `debugDefaultTargetPlatformOverride`.
        theme: ThemeData(platform: platform),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        // Clé neuve à chaque montage : chaque appel repart d'un contrôleur
        // initialisé avec son propre [initialCode].
        home: JsEditorPage(
          key: UniqueKey(),
          initialCode: initialCode,
          appEmojis: appEmojis,
        ),
      ),
    );
    // L'éditeur possède un curseur clignotant : `pumpAndSettle` ne rend jamais
    // la main.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));
    // L'analyse des diagnostics est débouncée (250 ms) : on laisse passer la
    // pause d'inactivité pour que la barre du bas reflète le document initial.
    await tester.pump(const Duration(milliseconds: 300));
  }

  TextEditingController editorController(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).first).controller!;

  testWidgets('gouttière : les numéros de ligne du chrome sont affichés', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      size: const Size(900, 700),
      initialCode: 'const a = 1;\nconsole.log(a);',
    );

    // Le corps d'édition est bien celui du chrome partagé.
    expect(find.byType(ScriptEditorBody), findsOneWidget);
    // Une ligne ⇒ un numéro dans la gouttière.
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop 1400x900 : la zone de code remplit la fenêtre', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      size: const Size(1400, 900),
      initialCode: 'const a = 1;',
      platform: TargetPlatform.linux,
    );

    final field = tester.getSize(find.byType(TextField).first);
    final page = tester.getSize(find.byType(JsEditorPage));

    // ignore: avoid_print
    print('DESKTOP  page=$page  zone de code=$field');

    expect(field.width, greaterThanOrEqualTo(700));
    expect(
      field.height,
      greaterThan(page.height * 0.8),
      reason: 'la zone de code doit occuper toute la hauteur disponible',
    );
  });

  testWidgets('barre d\'outils : icônes ≥ 700 px, menu « ⋮ » en dessous', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      size: const Size(1400, 900),
      platform: TargetPlatform.linux,
    );

    final appBarIcons = find.descendant(
      of: find.byType(AppBar),
      matching: find.byType(IconButton),
    );
    final iconCount = tester.widgetList(appBarIcons).length;
    // ignore: avoid_print
    print('TOOLBAR 1400px  IconButton=$iconCount');

    // Palette, docs, wrap, diagnostics, guides, UX : les actions sont en icônes.
    expect(iconCount, greaterThanOrEqualTo(5));
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsOneWidget);
    expect(find.byIcon(Icons.tips_and_updates_outlined), findsOneWidget);
    expect(find.byIcon(Icons.format_align_left), findsOneWidget);
    expect(find.byIcon(Icons.bug_report), findsOneWidget);
    expect(find.byIcon(Icons.format_indent_increase), findsOneWidget);

    await pumpEditor(
      tester,
      size: const Size(500, 900),
      platform: TargetPlatform.linux,
    );

    expect(find.byType(PopupMenuButton<VoidCallback>), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.menu_book), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'mobile 360x640 : aucun débordement, caractères rapides visibles',
    (tester) async {
      await pumpEditor(
        tester,
        size: const Size(360, 640),
        initialCode: 'const a = 1;',
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ScriptEditorQuickCharsBar), findsOneWidget);
      expect(find.text('{'), findsWidgets);
      expect(find.text(';'), findsWidgets);
    },
  );

  testWidgets('diagnostics : script déséquilibré signalé, script sain propre', (
    tester,
  ) async {
    await pumpEditor(tester, size: const Size(900, 700), initialCode: '{');

    final l10n = AppLocalizations.of(tester.element(find.byType(JsEditorPage)));
    final bar = find.byType(ScriptEditorDiagnosticsBar);
    expect(bar, findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    expect(
      find.textContaining(l10n.js_diag_unclosed_opening('{', '1')),
      findsOneWidget,
    );
    // `analyzeJavaScript` classe une ouvrante non fermée en avertissement
    // (elle apparaît aussi en cours de frappe) ; une fermante orpheline est
    // une erreur certaine.
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await pumpEditor(tester, size: const Size(900, 700), initialCode: '}');

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.textContaining(l10n.js_diag_unexpected_closing('}')),
      findsOneWidget,
    );

    await pumpEditor(
      tester,
      size: const Size(900, 700),
      initialCode: 'const a = 1;',
    );

    expect(find.text(l10n.js_editor_diagnostics_clean), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets(
    'autocomplete emoji : <:bo propose et insère l\'emoji du serveur',
    (tester) async {
      await pumpEditor(
        tester,
        size: const Size(900, 700),
        appEmojis: const <AppEmoji>[
          AppEmoji(id: '1', name: 'botcreator', animated: false),
        ],
      );

      await tester.enterText(find.byType(TextField).first, '<:bo');
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('botcreator'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_emotions_outlined), findsOneWidget);

      await tester.tap(find.text('botcreator'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(editorController(tester).text, '<:botcreator:1>');
    },
  );

  testWidgets('signature : la bulle apparaît dans un appel connu', (
    tester,
  ) async {
    await pumpEditor(
      tester,
      size: const Size(900, 700),
      platform: TargetPlatform.linux,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'await interaction.reply(',
    );
    await tester.pump(const Duration(milliseconds: 50));

    final bubble = find.byType(ScriptSignatureHintOverlay);
    expect(bubble, findsOneWidget);
    final richText = tester.widget<RichText>(
      find.descendant(of: bubble, matching: find.byType(RichText)).first,
    );
    final rendered = richText.text.toPlainText();
    // ignore: avoid_print
    print('SIGNATURE  bulle=$rendered');

    expect(rendered, contains('interaction.reply'));
    expect(rendered, contains('content'));
  });
}
