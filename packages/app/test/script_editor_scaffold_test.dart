import 'dart:ui' as ui;

import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_settings_provider.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/code_editor/script_editor_diagnostics_bar.dart';
import 'package:bot_creator/core/code_editor/script_editor_editor_body.dart';
import 'package:bot_creator/core/code_editor/script_editor_indent_guides.dart';
import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/code_editor/script_editor_overlays.dart';
import 'package:bot_creator/core/code_editor/script_editor_scaffold.dart';
import 'package:bot_creator/core/code_editor/script_editor_snippet.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/js_editor/editor_theme_scope.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux langage local au test : trois complétions `$…`, une signature `$call(`
/// et trois mots-clés déclencheurs de diagnostics. Tout est déterministe, et le
/// chrome ne doit rien savoir du langage réel pour fonctionner.
class _FakeLanguage implements ScriptEditorLanguage {
  const _FakeLanguage();

  /// Complétion sans `cursorOffset` (caret après le premier ouvrant) puis avec
  /// `cursorOffset` explicite (caret au milieu de l'insertion).
  static const List<ScriptCompletionEntry> entries = <ScriptCompletionEntry>[
    ScriptCompletionEntry(
      label: r'$reply',
      insert: r'$reply[]',
      kind: ScriptCompletionKind.callable,
    ),
    ScriptCompletionEntry(
      label: r'$replyFile',
      insert: r'$replyFile[]',
      cursorOffset: 11,
    ),
    ScriptCompletionEntry(label: r'$reset', insert: r'$reset()'),
  ];

  @override
  List<String> get quickChars => const <String>['§', '¶', '€'];

  @override
  int indentIncreaseFor(String previousLine) => 0;

  @override
  String indentUnit() => '  ';

  @override
  ScriptCompletionResult? completionAt(String text, int caretOffset) {
    final caret = caretOffset.clamp(0, text.length);
    var start = caret;
    while (start > 0 && _isTokenChar(text.codeUnitAt(start - 1))) {
      start--;
    }
    final token = text.substring(start, caret);
    if (!token.startsWith(r'$') || token.length > 9) {
      return null;
    }
    final matches = entries
        .where((entry) => entry.label.startsWith(token))
        .toList(growable: false);
    if (matches.isEmpty) {
      return null;
    }
    return ScriptCompletionResult(replaceStart: start, entries: matches);
  }

  static bool _isTokenChar(int unit) =>
      (unit >= 0x30 && unit <= 0x39) || // 0-9
      (unit >= 0x61 && unit <= 0x7A) || // a-z
      unit == 0x24 || // $
      unit == 0x5F; // _

  @override
  ScriptSignatureHint? signatureAt(String text, int caretOffset) {
    final before = text.substring(0, caretOffset.clamp(0, text.length));
    const call = r'$call(';
    final open = before.lastIndexOf(call);
    if (open < 0 || before.lastIndexOf(')') > open) {
      return null;
    }
    return ScriptSignatureHint(
      name: r'$call',
      parameters: const <String>['cible', 'raison'],
      activeIndex: before.substring(open + call.length).split(',').length - 1,
    );
  }

  @override
  List<ScriptDiagnostic> diagnosticsFor(String text) {
    final found = <ScriptDiagnostic>[];
    if (text.contains('BOOM')) {
      found.add(
        const ScriptDiagnostic(
          code: ScriptDiagnosticCode.unexpectedClosing,
          severity: ScriptDiagnosticSeverity.error,
          line: 2,
          column: 3,
          detail: '}',
        ),
      );
    }
    if (text.contains('HMM')) {
      found.add(
        const ScriptDiagnostic(
          code: ScriptDiagnosticCode.unclosedOpening,
          severity: ScriptDiagnosticSeverity.warning,
          line: 1,
          column: 1,
          detail: '{',
        ),
      );
    }
    if (text.contains('RAW')) {
      found.add(
        const ScriptDiagnostic(
          code: ScriptDiagnosticCode.unterminatedString,
          severity: ScriptDiagnosticSeverity.error,
          message: 'message brut du compilateur',
        ),
      );
    }
    return found;
  }
}

/// Variante du faux langage dont les blocs augmentent l'indentation (cas des
/// langages à accolades) : elle prouve que l'auto-indentation s'appuie bien sur
/// `indentIncreaseFor`/`indentUnit` du langage.
class _IndentedLanguage extends _FakeLanguage {
  const _IndentedLanguage();

  @override
  int indentIncreaseFor(String previousLine) =>
      previousLine.trimRight().endsWith('{') ? 4 : 0;

  @override
  String indentUnit() => '    ';
}

/// Faux langage instrumenté : il compte ses appels et marque chaque diagnostic
/// avec le texte EXACT qu'il a analysé. Le test peut donc affirmer à la fois
/// combien de fois l'analyse lourde a tourné et quel document a produit les
/// diagnostics affichés (aucun résultat périmé appliqué).
class _CountingLanguage implements ScriptEditorLanguage {
  final List<String> analysedTexts = <String>[];
  int completionCalls = 0;
  int signatureCalls = 0;

  @override
  List<String> get quickChars => const <String>[];

  @override
  int indentIncreaseFor(String previousLine) => 0;

  @override
  String indentUnit() => '  ';

  @override
  ScriptCompletionResult? completionAt(String text, int caretOffset) {
    completionCalls += 1;
    return null;
  }

  @override
  ScriptSignatureHint? signatureAt(String text, int caretOffset) {
    signatureCalls += 1;
    return null;
  }

  @override
  List<ScriptDiagnostic> diagnosticsFor(String text) {
    analysedTexts.add(text);
    return <ScriptDiagnostic>[
      ScriptDiagnostic(
        code: ScriptDiagnosticCode.unclosedOpening,
        severity: ScriptDiagnosticSeverity.warning,
        message: 'ANALYSED[$text]',
      ),
    ];
  }
}

/// Traduction de test : elle doit être appelée pour chaque diagnostic sans
/// `message`, et ignorée dès qu'un `message` est fourni.
String _testMessage(ScriptDiagnostic diagnostic) =>
    'DIAG:${diagnostic.code.name}:${diagnostic.line ?? '-'}:'
    '${diagnostic.column ?? '-'}:${diagnostic.detail}';

/// Palettes employées par le test, résolues comme le fait `editor_theme_scope`.
CodeEditorThemeColors _colorsOf(CodeEditorTheme theme, ThemeData appTheme) =>
    CodeEditorThemeColors.forTheme(
      resolveCodeEditorTheme(
        theme,
        isLight: appTheme.brightness == Brightness.light,
      ),
    );

Future<CodeEditorThemeColors> pumpChrome(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
  CodeEditorTheme theme = CodeEditorTheme.rosePine,
  ThemeData? appTheme,
  TargetPlatform platform = TargetPlatform.linux,
  String initialCode = '',
  CodeEditorSettingsProvider? provider,
  List<ScriptEditorSnippet> snippets = const <ScriptEditorSnippet>[],
  bool enableAutocomplete = true,
  bool prefersWordWrap = false,
  String? emptyLabel,
  String? cleanLabel,
  TextEditingController? controller,
  String Function(ScriptDiagnostic diagnostic) messageBuilder = _testMessage,
  ScriptEditorLanguage language = const _FakeLanguage(),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final effectiveProvider =
      provider ?? CodeEditorSettingsProvider(CodeEditorSettings(theme: theme));
  final baseTheme = appTheme ?? AppTheme.darkTheme();

  await tester.pumpWidget(
    ChangeNotifierProvider<CodeEditorSettingsProvider>.value(
      value: effectiveProvider,
      child: MaterialApp(
        // Une clé neuve à chaque pump : deux `pumpChrome` dans le même test
        // doivent repartir d'un éditeur vierge, sans réutiliser l'état.
        key: UniqueKey(),
        theme: baseTheme.copyWith(platform: platform),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: ScriptEditorScaffold(
          title: 'Titre de test',
          initialCode: initialCode,
          language: language,
          hintText: 'indice',
          uxSheetTitle: 'UX de test',
          uxSheetBullets: const <String>['puce'],
          onOpenDocs: () {},
          messageBuilder: messageBuilder,
          snippets: snippets,
          enableAutocomplete: enableAutocomplete,
          prefersWordWrap: prefersWordWrap,
          controller: controller,
          emptyLabel: emptyLabel,
          cleanLabel: cleanLabel,
        ),
      ),
    ),
  );
  // Le curseur clignote : jamais de `pumpAndSettle`, des durées explicites.
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  // L'analyse des diagnostics est débouncée (250 ms) : on laisse passer la
  // pause d'inactivité pour que la barre du bas reflète le document initial.
  await tester.pump(const Duration(milliseconds: 300));
  return _colorsOf(theme, baseTheme);
}

/// Le viewport horizontal du code (absent en mode habillage).
Finder horizontalViewport() => find.ancestor(
  of: find.byType(TextField),
  matching: find.byType(SingleChildScrollView),
);

int guidePainters(WidgetTester tester) => tester
    .widgetList<CustomPaint>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint &&
            widget.painter is ScriptIndentGuidesPainter,
      ),
    )
    .length;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('thème sombre : page et barre d\'application peintes par la '
      'palette Rosé Pine', (tester) async {
    final colors = await pumpChrome(tester, theme: CodeEditorTheme.rosePine);

    expect(
      colors.background.computeLuminance(),
      lessThan(0.2),
      reason: 'Rosé Pine est un thème sombre',
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);

    // ignore: avoid_print
    print(
      'SOMBRE  scaffold=${scaffold.backgroundColor} appBar=${appBar.backgroundColor} '
      'attendu fond=${colors.background} surface=${colors.surface}',
    );

    expect(scaffold.backgroundColor, colors.background);
    expect(appBar.backgroundColor, colors.surface);
    // La zone de code elle-même est peinte avec le fond de la palette.
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == colors.background,
      ),
      findsWidgets,
    );
  });

  testWidgets('thème clair : la page entière est CLAIRE (Rosé Pine Dawn)', (
    tester,
  ) async {
    final colors = await pumpChrome(
      tester,
      theme: CodeEditorTheme.rosePineDawn,
      appTheme: AppTheme.lightTheme(),
    );

    expect(
      colors.background.computeLuminance(),
      greaterThan(0.5),
      reason: 'Rosé Pine Dawn est un thème clair',
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    final appBar = tester.widget<AppBar>(find.byType(AppBar).first);

    // ignore: avoid_print
    print(
      'CLAIR  scaffold=${scaffold.backgroundColor} appBar=${appBar.backgroundColor} '
      'attendu fond=${colors.background} surface=${colors.surface}',
    );

    expect(scaffold.backgroundColor, colors.background);
    expect(appBar.backgroundColor, colors.surface);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == colors.background,
      ),
      findsWidgets,
    );
  });

  testWidgets('desktop : la zone de code remplit la largeur ET la hauteur '
      'disponibles', (tester) async {
    await pumpChrome(tester, size: const Size(1400, 900), initialCode: 'a\nb');

    final body = tester.getSize(find.byType(ScriptEditorBody));
    final field = tester.getSize(find.byType(TextField));

    // ignore: avoid_print
    print('DESKTOP  corps=$body champ=$field');

    // Bord à bord : largeur du corps − gouttière des numéros (40 px pour deux
    // lignes), et même hauteur que le corps.
    expect(field.width, closeTo(body.width - 40, 1.0));
    expect(field.height, closeTo(body.height, 1.0));
  });

  testWidgets('barre d\'outils : icônes ≥ 700 px, menu « ⋮ » en dessous', (
    tester,
  ) async {
    final expectations = <double, bool>{
      360: true, // menu
      699: true, // menu
      700: false, // icônes
      1200: false, // icônes
    };

    for (final entry in expectations.entries) {
      await pumpChrome(
        tester,
        size: Size(entry.key, 720),
        platform: TargetPlatform.android,
      );
      final usesMenu = entry.value;
      final toolbarIcons = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      );

      expect(
        find.byIcon(Icons.more_vert),
        usesMenu ? findsOneWidget : findsNothing,
        reason:
            'à ${entry.key.round()} px le menu doit '
            '${usesMenu ? '' : 'ne pas '}être affiché',
      );
      expect(
        find.byIcon(Icons.menu_book),
        usesMenu ? findsNothing : findsOneWidget,
        reason:
            'à ${entry.key.round()} px les icônes doivent '
            '${usesMenu ? 'être masquées' : 'être visibles'}',
      );
      // Le bouton « ⋮ » est lui-même un IconButton : sous 700 px il doit être
      // le seul, au-delà les 5 réglages s'affichent en icônes.
      expect(
        tester.widgetList(toolbarIcons).length,
        usesMenu ? 1 : greaterThanOrEqualTo(5),
        reason: 'au-delà de 700 px les réglages tiennent en icônes',
      );
      expect(
        find.byIcon(Icons.format_align_left),
        usesMenu ? findsNothing : findsOneWidget,
        reason: 'les bascules ne doivent pas doubler le menu « ⋮ »',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'débordement de la barre d\'outils à ${entry.key.round()} px',
      );
    }
  });

  testWidgets('mobile 360x640 : aucun débordement et zone de code utilisable', (
    tester,
  ) async {
    await pumpChrome(
      tester,
      size: const Size(360, 640),
      platform: TargetPlatform.android,
      initialCode: 'BOOM \$longueLigne',
    );

    expect(tester.takeException(), isNull);

    final viewport = horizontalViewport().first;
    // ignore: avoid_print
    print(
      'MOBILE  vue défilante=${tester.getSize(viewport).width} '
      'contenu=${tester.getSize(find.byType(TextField)).width}',
    );
    expect(tester.getSize(viewport).width, lessThanOrEqualTo(360));

    // La zone de code reste éditable : la frappe notifie et se reflète.
    await tester.enterText(find.byType(TextField), 'nouveau');
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('nouveau'), findsOneWidget);
  });

  testWidgets('barre de diagnostics : message de messageBuilder + couleur '
      'de sévérité', (tester) async {
    await pumpChrome(tester, initialCode: 'ligne\nBOOM');

    expect(find.byType(ScriptEditorDiagnosticsBar), findsOneWidget);
    expect(find.textContaining('DIAG:unexpectedClosing:2:3:}'), findsOneWidget);
    expect(find.textContaining('L2:C3'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.error_outline)).color,
      AppTheme.error,
    );
  });

  testWidgets('barre de diagnostics : un avertissement est orange, pas rouge', (
    tester,
  ) async {
    await pumpChrome(tester, initialCode: 'HMM');

    expect(
      tester.widget<Icon>(find.byIcon(Icons.warning_amber_rounded)).color,
      AppTheme.warning,
    );
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('barre de diagnostics : document vide ⇒ emptyLabel, aucun '
      'diagnostic ⇒ cleanLabel', (tester) async {
    await pumpChrome(
      tester,
      initialCode: '  \n ',
      emptyLabel: 'VIDE',
      cleanLabel: 'PROPRE',
    );
    expect(find.text('VIDE'), findsOneWidget);
    expect(find.text('PROPRE'), findsNothing);

    await pumpChrome(
      tester,
      initialCode: 'document sain',
      emptyLabel: 'VIDE',
      cleanLabel: 'PROPRE',
    );
    expect(find.text('PROPRE'), findsOneWidget);
    expect(find.text('VIDE'), findsNothing);
  });

  testWidgets('barre de diagnostics : libellés par défaut issus de l\'i18n '
      'existante', (tester) async {
    await pumpChrome(tester, initialCode: '');

    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(fr.bdfd_editor_empty), findsOneWidget);

    await pumpChrome(tester, initialCode: 'document sain');
    expect(find.text(fr.cmd_bdfd_diagnostics_clean), findsOneWidget);
  });

  testWidgets('barre de diagnostics : un message déjà rédigé prime sur le '
      'mapping de la page', (tester) async {
    await pumpChrome(tester, initialCode: 'RAW');

    expect(find.textContaining('message brut du compilateur'), findsOneWidget);
    expect(find.textContaining('DIAG:'), findsNothing);
  });

  group('analyse des diagnostics débouncée', () {
    final field = find.byType(TextField);

    testWidgets('la frappe est analysée APRÈS la pause, jamais pendant, et le '
        'caret/la signature restent synchrones', (tester) async {
      final language = _CountingLanguage();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpChrome(tester, controller: controller, language: language);

      expect(language.analysedTexts, isEmpty);

      await tester.enterText(field, 'BOOM');
      await tester.pump(const Duration(milliseconds: 50));

      // La frappe est immédiatement servie : complétion et signature sont
      // calculées sur l'isolate UI, sans attendre le débounce.
      expect(
        language.completionCalls,
        greaterThan(0),
        reason: "l'autocomplete doit rester synchrone",
      );
      expect(
        language.signatureCalls,
        greaterThan(0),
        reason: 'la signature doit rester synchrone',
      );
      // L'analyse lourde, elle, n'a pas encore tourné.
      expect(
        language.analysedTexts,
        isEmpty,
        reason: "l'analyse lourde ne doit pas bloquer la frappe",
      );
      expect(find.textContaining('ANALYSED['), findsNothing);

      await tester.pump(const Duration(milliseconds: 300));

      expect(language.analysedTexts, <String>['BOOM']);
      expect(find.textContaining('ANALYSED[BOOM]'), findsOneWidget);
    });

    testWidgets('plusieurs frappes rapprochées : une seule analyse finale', (
      tester,
    ) async {
      final language = _CountingLanguage();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpChrome(tester, controller: controller, language: language);

      for (final text in <String>['A', 'AB', 'ABC']) {
        await tester.enterText(field, text);
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(
        language.analysedTexts,
        isEmpty,
        reason: 'le délai de 250 ms n’a jamais été laissé s’écouler',
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(
        language.analysedTexts,
        <String>['ABC'],
        reason: 'seul le dernier document doit être analysé',
      );
      expect(find.textContaining('ANALYSED[ABC]'), findsOneWidget);
    });

    testWidgets('un résultat périmé n’est jamais appliqué', (tester) async {
      final language = _CountingLanguage();
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpChrome(tester, controller: controller, language: language);

      // « BOOM » programme une analyse, « HMM » la remplace avant l'échéance :
      // la barre ne doit jamais montrer le document abandonné.
      controller.text = 'BOOM';
      await tester.pump(const Duration(milliseconds: 100));
      controller.text = 'HMM';
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(language.analysedTexts, <String>['HMM']);
      expect(find.textContaining('ANALYSED[BOOM]'), findsNothing);
      expect(find.textContaining('ANALYSED[HMM]'), findsOneWidget);
    });

    testWidgets(
      'dispose pendant le délai : le timer est annulé, aucun setState '
      'après dispose',
      (tester) async {
        final language = _CountingLanguage();
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        await pumpChrome(tester, controller: controller, language: language);

        await tester.enterText(field, 'BOOM');
        await tester.pump(const Duration(milliseconds: 50));
        expect(language.analysedTexts, isEmpty);

        // L'écran quitte la pile alors que le délai court encore.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(
          language.analysedTexts,
          isEmpty,
          reason: 'le timer annulé ne doit pas analyser après dispose',
        );
      },
    );
  });

  for (final platform in <TargetPlatform>[
    TargetPlatform.linux,
    TargetPlatform.android,
  ]) {
    testWidgets('autocomplete ($platform) : le panneau s\'ouvre, les flèches '
        'changent la sélection, Entrée insère au caret calculé', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpChrome(tester, controller: controller, platform: platform);

      await tester.enterText(find.byType(TextField), r'$re');
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ScriptAutocompleteOverlay), findsOneWidget);
      expect(find.text(r'$reply'), findsOneWidget);
      expect(
        tester
            .widget<ScriptAutocompleteOverlay>(
              find.byType(ScriptAutocompleteOverlay),
            )
            .selectedIndex,
        0,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<ScriptAutocompleteOverlay>(
              find.byType(ScriptAutocompleteOverlay),
            )
            .selectedIndex,
        1,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<ScriptAutocompleteOverlay>(
              find.byType(ScriptAutocompleteOverlay),
            )
            .selectedIndex,
        0,
      );

      // Entrée insère la sélection et referme le panneau.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.text, r'$reply[]');
      expect(
        controller.selection.baseOffset,
        7,
        reason: 'le caret doit atterrir juste après le premier ouvrant',
      );
      expect(find.byType(ScriptAutocompleteOverlay), findsNothing);
    });
  }

  testWidgets('autocomplete : cursorOffset explicite place le caret à '
      'l\'intérieur de l\'insertion', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpChrome(tester, controller: controller);

    await tester.enterText(find.byType(TextField), r'$re');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, r'$replyFile[]');
    expect(controller.selection.baseOffset, 11);
  });

  testWidgets('autocomplete : Échap referme le panneau sans rien insérer', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpChrome(tester, controller: controller);

    await tester.enterText(find.byType(TextField), r'$re');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(ScriptAutocompleteOverlay), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ScriptAutocompleteOverlay), findsNothing);
    expect(controller.text, r'$re');
    // Le panneau est fermé : Entrée n'insère plus rien.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.text, r'$re');
  });

  testWidgets('autocomplete désactivé : le panneau ne s\'ouvre jamais', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpChrome(tester, controller: controller, enableAutocomplete: false);

    await tester.enterText(find.byType(TextField), r'$re');
    await tester.pump(const Duration(milliseconds: 50));

    // Le mot-clé `$re` ne produit pas de diagnostic : c'est bien la seule
    // absence d'autocomplete qu'on vérifie ici.
    expect(find.byType(ScriptAutocompleteOverlay), findsNothing);
    expect(controller.text, r'$re');
  });

  testWidgets('caractères rapides : insérés au caret sur mobile', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'ab');
    addTearDown(controller.dispose);
    await pumpChrome(
      tester,
      size: const Size(360, 640),
      platform: TargetPlatform.android,
      controller: controller,
    );

    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byIcon(Icons.tune), findsOneWidget);
    await tester.tap(find.text('§'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, 'a§b');
    expect(controller.selection.baseOffset, 2);
  });

  testWidgets('caractères rapides : barre absente sur desktop ou quand le '
      'réglage la désactive', (tester) async {
    await pumpChrome(
      tester,
      size: const Size(1200, 800),
      platform: TargetPlatform.linux,
      initialCode: 'ab',
    );
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.text('§'), findsNothing);

    await pumpChrome(
      tester,
      size: const Size(360, 640),
      platform: TargetPlatform.android,
      initialCode: 'ab',
      provider: CodeEditorSettingsProvider(
        const CodeEditorSettings(showQuickCharsBar: false),
      ),
    );
    expect(find.byIcon(Icons.tune), findsNothing);
    expect(find.text('§'), findsNothing);
  });

  testWidgets(
    'bulle de signature : desktop uniquement, paramètre actif suivi',
    (tester) async {
      await pumpChrome(
        tester,
        initialCode: r'$call("salut"',
        platform: TargetPlatform.linux,
      );
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(ScriptSignatureHintOverlay), findsOneWidget);
      final overlay = tester.widget<ScriptSignatureHintOverlay>(
        find.byType(ScriptSignatureHintOverlay),
      );
      expect(overlay.hint.name, r'$call');
      expect(overlay.hint.activeIndex, 0);

      await pumpChrome(
        tester,
        initialCode: r'$call("salut"',
        platform: TargetPlatform.android,
      );
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(ScriptSignatureHintOverlay), findsNothing);
    },
  );

  testWidgets('bascule habillage : le défilement horizontal disparaît', (
    tester,
  ) async {
    await pumpChrome(tester, initialCode: 'une ligne courte');

    expect(horizontalViewport(), findsOneWidget);
    expect(find.byIcon(Icons.format_align_left), findsOneWidget);

    await tester.tap(find.byIcon(Icons.format_align_left));
    await tester.pump(const Duration(milliseconds: 50));

    expect(horizontalViewport(), findsNothing);
    expect(find.byIcon(Icons.wrap_text), findsOneWidget);

    // Retour à l'état initial : le défilement horizontal revient.
    await tester.tap(find.byIcon(Icons.wrap_text));
    await tester.pump(const Duration(milliseconds: 50));
    expect(horizontalViewport(), findsOneWidget);
  });

  testWidgets('bascule guides : le peintre de guides apparaît/disparaît', (
    tester,
  ) async {
    await pumpChrome(tester, initialCode: '  indente\n    encore');

    expect(guidePainters(tester), 1);

    await tester.tap(find.byIcon(Icons.format_indent_increase));
    await tester.pump(const Duration(milliseconds: 50));

    expect(guidePainters(tester), 0);
    expect(find.byIcon(Icons.format_indent_decrease), findsOneWidget);
  });

  testWidgets('bascule diagnostics : la barre du bas se masque', (
    tester,
  ) async {
    await pumpChrome(tester, initialCode: 'document sain');

    expect(find.byType(ScriptEditorDiagnosticsBar), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bug_report));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ScriptEditorDiagnosticsBar), findsNothing);
    expect(find.byIcon(Icons.bug_report_outlined), findsOneWidget);
  });

  testWidgets('gouttière : masquée quand showLineNumbers est faux, la zone de '
      'code reprend la largeur', (tester) async {
    await pumpChrome(
      tester,
      initialCode: 'a\nb',
      provider: CodeEditorSettingsProvider(
        const CodeEditorSettings(showLineNumbers: false),
      ),
    );

    expect(find.byType(ListView), findsNothing);

    final body = tester.getSize(find.byType(ScriptEditorBody));
    final field = tester.getSize(find.byType(TextField));
    expect(field.width, closeTo(body.width, 1.0));
  });

  testWidgets('gouttière : défilement synchronisé avec la zone de code', (
    tester,
  ) async {
    final longScript = List<String>.generate(
      200,
      (index) => 'ligne $index',
    ).join('\n');

    await pumpChrome(tester, initialCode: longScript);

    final editorScroll = tester
        .widget<TextField>(find.byType(TextField))
        .scrollController!;
    final gutterController = tester
        .widget<ListView>(find.byType(ListView))
        .controller!;

    expect(editorScroll.offset, 0);
    expect(gutterController.offset, 0);

    editorScroll.jumpTo(140);
    await tester.pump(const Duration(milliseconds: 50));

    // ignore: avoid_print
    print(
      'GOUTTIÈRE  code=${editorScroll.offset} numéros=${gutterController.offset}',
    );
    expect(gutterController.offset, closeTo(editorScroll.offset, 0.5));
  });

  testWidgets('barre d\'extraits : un extrait s\'insère au caret', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'ab');
    addTearDown(controller.dispose);
    await pumpChrome(
      tester,
      controller: controller,
      snippets: const <ScriptEditorSnippet>[
        ScriptEditorSnippet(label: 'EXTRAIT', insert: '()', cursorOffset: 1),
      ],
    );

    controller.selection = const TextSelection.collapsed(offset: 1);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('EXTRAIT'));
    await tester.pump(const Duration(milliseconds: 50));

    expect(controller.text, 'a()b');
    expect(controller.selection.baseOffset, 2);
    expect(tester.takeException(), isNull);
    // ignore: avoid_print
    print(
      'CHIP  taille=${tester.getSize(find.byType(ActionChip))} '
      'barre=${tester.getSize(find.byType(ScriptEditorSnippetBar))}',
    );
  });

  testWidgets("barre d'extraits : la chip n'est pas écrasée par la barre", (
    tester,
  ) async {
    await pumpChrome(
      tester,
      snippets: const <ScriptEditorSnippet>[
        ScriptEditorSnippet(label: 'EXTRAIT', insert: '()'),
      ],
    );
    final inBar = tester.getSize(find.byType(ActionChip));

    // Référence : la même chip dans un parent qui ne borne pas sa hauteur.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionChip(
                label: const Text('EXTRAIT', style: TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    final natural = tester.getSize(find.byType(ActionChip));

    // ignore: avoid_print
    print('CHIP  barre=$inBar référence=$natural');
    expect(inBar.height, greaterThanOrEqualTo(natural.height));
    expect(inBar.width, greaterThan(0));
  });

  testWidgets(
    "auto-indentation : Entrée recopie l'indentation et applique celle du "
    'langage',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpChrome(
        tester,
        controller: controller,
        language: const _IndentedLanguage(),
      );

      await tester.enterText(find.byType(TextField), '  bloc {');
      await tester.pump(const Duration(milliseconds: 50));
      // Un seul caractère inséré : la forme que traite l'input formatter.
      await tester.enterText(find.byType(TextField), '  bloc {\n');
      await tester.pump(const Duration(milliseconds: 50));

      expect(controller.text, '  bloc {\n      ');
      expect(controller.selection.baseOffset, controller.text.length);
    },
  );

  testWidgets("mobile : le panneau d'autocomplete ne sort pas de la zone de "
      'code quand le caret est en bas', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpChrome(
      tester,
      size: const Size(360, 420),
      platform: TargetPlatform.android,
      controller: controller,
    );

    // Caret sur la dernière ligne d'un document déjà haut : le panneau doit se
    // replacer dans la zone d'édition, pas la déborder par le bas.
    final lines = List<String>.generate(12, (index) => 'ligne $index');
    await tester.enterText(
      find.byType(TextField),
      '${lines.join('\n')}\n${r'$re'}',
    );
    await tester.pump(const Duration(milliseconds: 50));

    final panel = find.byType(ScriptAutocompleteOverlay);
    expect(panel, findsOneWidget);

    final panelRect = tester.getRect(panel);
    final bodyRect = tester.getRect(find.byType(ScriptEditorBody));
    // ignore: avoid_print
    print('PANNEAU BAS  panneau=$panelRect corps=$bodyRect');

    expect(panelRect.top, greaterThanOrEqualTo(bodyRect.top - 0.5));
    expect(panelRect.bottom, lessThanOrEqualTo(bodyRect.bottom + 0.5));
  });

  testWidgets("mobile : le panneau d'autocomplete reste dans la fenêtre", (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await pumpChrome(
      tester,
      size: const Size(360, 640),
      platform: TargetPlatform.android,
      controller: controller,
    );

    await tester.enterText(find.byType(TextField), '${'  ' * 20}${r'$re'}');
    await tester.pump(const Duration(milliseconds: 50));

    final panel = find.byType(ScriptAutocompleteOverlay);
    expect(panel, findsOneWidget);

    final topLeft = tester.getTopLeft(panel);
    final size = tester.getSize(panel);
    // ignore: avoid_print
    print('PANNEAU  coin=$topLeft taille=$size');

    expect(topLeft.dx, greaterThanOrEqualTo(0));
    expect(topLeft.dy, greaterThanOrEqualTo(0));
    expect(topLeft.dx + size.width, lessThanOrEqualTo(360));
    expect(topLeft.dy + size.height, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  group('contrat de la couche langage', () {
    test('scriptCaretOffsetAfterInsert : explicite, ouvrant, puis fin', () {
      expect(
        scriptCaretOffsetAfterInsert(
          const ScriptCompletionEntry(
            label: r'$a',
            insert: r'$a[]',
            cursorOffset: 3,
          ),
          10,
        ),
        13,
      );
      expect(
        scriptCaretOffsetAfterInsert(
          const ScriptCompletionEntry(label: r'$a', insert: r'$a[]'),
          10,
        ),
        13,
        reason:
            'sans cursorOffset, le caret se place DANS la paire ouvrante '
            '(juste après le « [ »), comme le faisait l\'éditeur BDFD '
            'historique (`start + indexOf("[") + 1`) et comme l\'attend '
            'l\'éditeur JS (`interaction.reply(|)`)',
      );
      expect(
        scriptCaretOffsetAfterInsert(
          const ScriptCompletionEntry(label: r'$a', insert: r'$a'),
          10,
        ),
        12,
      );
    });

    test('scriptClampedCaret : sélection invalide ⇒ fin du document', () {
      expect(
        scriptClampedCaret('abc', const TextSelection.collapsed(offset: 1)),
        1,
      );
      expect(
        scriptClampedCaret('abc', const TextSelection.collapsed(offset: -1)),
        3,
      );
      expect(
        scriptClampedCaret('abc', const TextSelection.collapsed(offset: 99)),
        3,
      );
    });

    test('scriptInsertText : remplace la sélection et place le caret', () {
      final controller = TextEditingController(text: 'abcdef');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection(
        baseOffset: 1,
        extentOffset: 4,
      );
      scriptInsertText(controller, 'XY', caretOffset: 1);
      expect(controller.text, 'aXYef');
      expect(controller.selection.baseOffset, 2);
    });

    test(
      'scriptInsertText : sélection invalide ⇒ insertion en fin de document',
      () {
        final controller = TextEditingController(text: 'abc');
        addTearDown(controller.dispose);
        scriptInsertText(controller, 'Z');
        expect(controller.text, 'abcZ');
        expect(controller.selection.baseOffset, 4);
      },
    );

    test('scriptInsertCompletion : replaceStart aberrant ramené au caret', () {
      final controller = TextEditingController(text: r'$re');
      addTearDown(controller.dispose);
      controller.selection = const TextSelection.collapsed(offset: 1);
      scriptInsertCompletion(
        controller,
        const ScriptCompletionResult(
          replaceStart: 5,
          entries: <ScriptCompletionEntry>[],
        ),
        const ScriptCompletionEntry(label: r'$reply', insert: r'$reply[]'),
      );
      // `replaceStart` (5) est au-delà du caret (1) : il est ramené au caret,
      // donc la plage remplacée est vide et le texte déjà présent après le
      // caret (`re`) est conservé — la garantie testée est qu'aucune exception
      // n'est levée et que le caret retombe dans les bornes du document.
      expect(controller.text, r'$$reply[]re');
      expect(controller.selection.baseOffset, 8);
    });
  });

  test('peintre des guides : peint les lignes visibles et se répaint à bon '
      'escient', () {
    const painter = ScriptIndentGuidesPainter(
      source: '  a\n\tb\n      c',
      activeLine: 2,
      lineNumberGutterWidth: 40,
      scrollX: 0,
      scrollY: 0,
      showHorizontalOffset: false,
    );
    final recorder = ui.PictureRecorder();
    painter.paint(Canvas(recorder), const Size(400, 300));
    recorder.endRecording().dispose();

    expect(
      painter.shouldRepaint(
        const ScriptIndentGuidesPainter(
          source: 'autre',
          activeLine: 2,
          lineNumberGutterWidth: 40,
          scrollX: 0,
          scrollY: 0,
          showHorizontalOffset: false,
        ),
      ),
      isTrue,
    );
    expect(
      painter.shouldRepaint(
        const ScriptIndentGuidesPainter(
          source: '  a\n\tb\n      c',
          activeLine: 2,
          lineNumberGutterWidth: 40,
          scrollX: 0,
          scrollY: 0,
          showHorizontalOffset: false,
        ),
      ),
      isFalse,
    );
  });
}
