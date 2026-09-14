import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_settings_provider.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/settings/presentation/code_editor_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Waits (bounded) until [needle] shows up in the persisted settings blob.
  ///
  /// `CodeEditorSettingsProvider` persists asynchronously (fire and forget), so
  /// the write is not observable right after the mutation returns.
  Future<String> waitForPersisted(String needle) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(CodeEditorSettings.prefsKey) ?? '';
      if (raw.contains(needle)) return raw;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('Persisted settings never contained "$needle"');
  }

  group('CodeEditorSettings', () {
    test('defaults to Rosé Pine on a fresh install', () {
      const settings = CodeEditorSettings();
      expect(settings.theme, CodeEditorTheme.rosePine);
      expect(settings.fontFamily, CodeEditorFontFamily.monospace);
      expect(settings.fontSize, 13.0);
      expect(settings.lineHeight, 1.54);
      expect(settings.showLineNumbers, true);
      expect(settings.showIndentGuides, true);
      expect(settings.wordWrap, false);
      expect(settings.autoCloseBrackets, true);
      expect(settings.tabSize, 2);
      expect(settings.showQuickCharsBar, true);
    });

    test('Rosé Pine is the fallback for unknown or missing stored ids', () {
      expect(CodeEditorThemeExt.fromId(null), CodeEditorTheme.rosePine);
      expect(CodeEditorThemeExt.fromId(''), CodeEditorTheme.rosePine);
      expect(CodeEditorThemeExt.fromId('unknown'), CodeEditorTheme.rosePine);
      expect(CodeEditorThemeExt.fromId('rose_pine'), CodeEditorTheme.rosePine);
      expect(
        CodeEditorThemeExt.fromId('rose_pine_dawn'),
        CodeEditorTheme.rosePineDawn,
      );

      // A JSON payload without a theme key still yields Rosé Pine.
      final restored = CodeEditorSettings.fromJson(const {'fontSize': 18.0});
      expect(restored.theme, CodeEditorTheme.rosePine);
      expect(restored.fontSize, 18.0);
    });

    test('load() returns Rosé Pine when nothing was ever persisted', () async {
      await CodeEditorSettings().save();
      expect((await CodeEditorSettings.load()).theme, CodeEditorTheme.rosePine);

      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect((await CodeEditorSettings.load()).theme, CodeEditorTheme.rosePine);

      SharedPreferences.setMockInitialValues(<String, Object>{
        CodeEditorSettings.prefsKey: 'not-json',
      });
      expect((await CodeEditorSettings.load()).theme, CodeEditorTheme.rosePine);
    });

    test('load() restores a persisted theme', () async {
      await const CodeEditorSettings(theme: CodeEditorTheme.monokai).save();
      final loaded = await CodeEditorSettings.load();
      expect(loaded.theme, CodeEditorTheme.monokai);
      expect(loaded.theme.id, 'monokai');
    });

    test('theme extensions and JSON round-trip', () {
      expect(CodeEditorTheme.rosePine.id, 'rose_pine');
      expect(CodeEditorTheme.rosePineDawn.id, 'rose_pine_dawn');
      expect(CodeEditorTheme.vsCodeDark.id, 'vscode_dark');
      expect(CodeEditorTheme.githubDark.id, 'github_dark');
      expect(CodeEditorTheme.githubLight.id, 'github_light');
      expect(CodeEditorTheme.oneDark.id, 'one_dark');
      expect(CodeEditorTheme.monokai.id, 'monokai');
      expect(CodeEditorTheme.rosePine.isDark, true);
      expect(CodeEditorTheme.rosePineDawn.isDark, false);
      expect(CodeEditorTheme.githubLight.isDark, false);

      final settings = const CodeEditorSettings().copyWith(
        theme: CodeEditorTheme.rosePineDawn,
        fontFamily: CodeEditorFontFamily.firaCode,
        fontSize: 16.0,
        wordWrap: true,
      );

      final restored = CodeEditorSettings.fromJson(settings.toJson());
      expect(restored.theme, CodeEditorTheme.rosePineDawn);
      expect(restored.fontFamily, CodeEditorFontFamily.firaCode);
      expect(restored.fontSize, 16.0);
      expect(restored.wordWrap, true);
    });

    test('font family ids fall back to the system monospace', () {
      expect(
        CodeEditorFontFamilyExt.fromId(null),
        CodeEditorFontFamily.monospace,
      );
      expect(
        CodeEditorFontFamilyExt.fromId('nope'),
        CodeEditorFontFamily.monospace,
      );
      expect(
        CodeEditorFontFamily.jetbrainsMono.fontString,
        contains('JetBrains'),
      );
    });

    test('CodeEditorThemeColors provides valid palettes for all themes', () {
      for (final theme in CodeEditorTheme.values) {
        final colors = CodeEditorThemeColors.forTheme(theme);
        expect(colors.background, isNotNull);
        expect(colors.surface, isNotNull);
        expect(colors.text, isNotNull);
        expect(colors.function, isNotNull);
        expect(colors.string, isNotNull);
        expect(colors.bracket, isNotNull);
        expect(colors.gutterText, isNotNull);
        expect(colors.cursor, isNotNull);
        expect(colors.hljsTheme, isNotEmpty);
      }
    });
  });

  group('CodeEditorSettingsProvider', () {
    test('defaults to Rosé Pine and exposes the matching palette', () {
      final provider = CodeEditorSettingsProvider();
      expect(provider.settings.theme, CodeEditorTheme.rosePine);
      expect(
        provider.currentColors.background,
        CodeEditorThemeColors.forTheme(CodeEditorTheme.rosePine).background,
      );
    });

    test('init() loads the persisted settings', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        CodeEditorSettings.prefsKey: '{"theme":"one_dark","fontSize":15.0}',
      });
      final provider = await CodeEditorSettingsProvider.init();
      expect(provider.settings.theme, CodeEditorTheme.oneDark);
      expect(provider.settings.fontSize, 15.0);
    });

    test('updates notify listeners and are persisted', () async {
      final provider = CodeEditorSettingsProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.updateTheme(CodeEditorTheme.githubDark);
      provider.updateFontSize(20.0);
      provider.toggleWordWrap(true);
      provider.updateTabSize(4);

      expect(notifications, 4);
      expect(provider.settings.theme, CodeEditorTheme.githubDark);
      expect(provider.settings.fontSize, 20.0);
      expect(provider.settings.wordWrap, true);
      expect(provider.settings.tabSize, 4);

      // Attendre le DERNIER ecrit (fontSize 20 + tabSize 4) et non le premier
      // (theme seul) : les save() sont fire-and-forget, le 1er payload contient
      // encore fontSize 13 / tabSize 2 -> lire trop tot donnait un faux echec.
      await waitForPersisted('"fontSize":20.0');
      final persisted = await CodeEditorSettings.load();
      expect(persisted.theme, CodeEditorTheme.githubDark);
      expect(persisted.fontSize, 20.0);
      expect(persisted.tabSize, 4);
    });

    test('resetToDefaults goes back to Rosé Pine', () async {
      final provider = CodeEditorSettingsProvider();
      provider.updateTheme(CodeEditorTheme.monokai);
      await waitForPersisted('"theme":"monokai"');

      provider.resetToDefaults();
      expect(provider.settings.theme, CodeEditorTheme.rosePine);

      await waitForPersisted('"theme":"rose_pine"');
      expect((await CodeEditorSettings.load()).theme, CodeEditorTheme.rosePine);
    });
  });

  group('CodeEditorSettingsPage', () {
    Widget buildTestWidget({bool withProvider = true}) {
      const page = CodeEditorSettingsPage();
      if (!withProvider) {
        // The page must work standalone (no global provider registered yet).
        return MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: page,
        );
      }
      return ChangeNotifierProvider<CodeEditorSettingsProvider>(
        create: (_) => CodeEditorSettingsProvider(),
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: page,
        ),
      );
    }

    testWidgets(
      'renders preview, theme section and default Rosé Pine selection',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Code editor'), findsOneWidget);
        expect(find.text('Live preview'), findsOneWidget);
        expect(find.text('BDFD'), findsOneWidget);
        expect(find.text('JavaScript'), findsOneWidget);
        expect(find.text('Syntax highlighting theme'), findsOneWidget);

        // Rosé Pine is the default option and the selected radio value.
        expect(find.text('Rosé Pine (Dark)'), findsOneWidget);
        final group = tester.widget<RadioGroup<CodeEditorTheme>>(
          find.byType(RadioGroup<CodeEditorTheme>),
        );
        expect(group.groupValue, CodeEditorTheme.rosePine);

        // Light themes (like Rosé Pine Dawn) must have readable subtitles,
        // using onSurfaceVariant instead of hardcoded black.
        await tester.ensureVisible(find.text('Light mode').first);
        await tester.pumpAndSettle();
        final dawnSubtitle = tester.widget<Text>(find.text('Light mode').first);
        final expectedColor = Theme.of(
          tester.element(find.byType(CodeEditorSettingsPage)),
        ).colorScheme.onSurfaceVariant;
        expect(dawnSubtitle.style?.color, expectedColor);
      },
    );

    testWidgets('works without a provider in the tree', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(withProvider: false));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(CodeEditorSettingsPage), findsOneWidget);
      expect(find.text('Syntax highlighting theme'), findsOneWidget);
    });

    testWidgets('tab switching via TabBarView swipe on 360dp mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining(r'$nomention', findRichText: true),
        findsOneWidget,
      );

      await tester.drag(find.byType(TabBarView), const Offset(-250, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining(
          'Handler de commande Discord.js',
          findRichText: true,
        ),
        findsOneWidget,
      );

      await tester.drag(find.byType(TabBarView), const Offset(250, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.textContaining(r'$nomention', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('selecting another theme updates the provider', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = CodeEditorSettingsProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider<CodeEditorSettingsProvider>.value(
          value: provider,
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const CodeEditorSettingsPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Monokai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Monokai'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(provider.settings.theme, CodeEditorTheme.monokai);
      expect(
        provider.currentColors.background,
        CodeEditorThemeColors.forTheme(CodeEditorTheme.monokai).background,
      );
    });

    testWidgets('section headers do not overflow at 2x font scale on 280dp', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(280, 653);
      tester.view.devicePixelRatio = 1.0;
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Syntax highlighting theme'), findsOneWidget);
    });
  });
}
