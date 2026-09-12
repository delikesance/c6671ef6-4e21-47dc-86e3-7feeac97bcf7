// Tests de la carte « Apparence » des Paramètres
// (features/settings/presentation/appearance_settings_section.dart) : galerie
// des huit presets, sélecteur de mode, couleurs personnalisées (ratio de
// contraste affiché), badge « Personnalisé » et réinitialisation. Aucun preset
// ne doit JAMAIS déclencher l'alerte de contraste : chacun porte une variante
// d'accent par mode, garantie ≥ 4.5:1 sur la surface de ce mode.
//
// Le harnais reproduit le câblage réel de `main.dart` : un [ThemeProvider]
// partagé alimente `MaterialApp` (thèmes paramétrés + delegates i18n), donc
// chaque changement du provider reconstruit bien toute la page — c'est ce qui
// garantit que l'app se repeint sans redémarrage.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/settings/presentation/appearance_settings_section.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Câblage minimal identique à celui de l'app (provider → `MaterialApp`).
Widget _harness(ThemeProvider provider) {
  return ChangeNotifierProvider<ThemeProvider>.value(
    value: provider,
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme(appearance: themeProvider.appearance),
        darkTheme: AppTheme.darkTheme(appearance: themeProvider.appearance),
        themeMode: themeProvider.themeMode,
        home: const Scaffold(
          body: SingleChildScrollView(child: AppearanceSettingsSection()),
        ),
      ),
    ),
  );
}

/// Monte la carte dans une fenêtre assez haute pour que les huit presets, les
/// pastilles de couleur et le bouton de réinitialisation soient cliquables.
Future<ThemeProvider> _pumpSection(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final provider = ThemeProvider();
  // NB : jamais de `pumpEventQueue()` ici. Dans un `testWidgets`, son
  // `Future.delayed` est un timer FAKE qui ne s'exécute qu'au prochain `pump` :
  // l'attendre avant tout pump gèle le harnais. Le chargement du provider
  // (SharedPreferences mockées, accompli par microtâches) se termine pendant
  // le `pumpWidget` + `pumpAndSettle` ci-dessous.
  await tester.pumpWidget(_harness(provider));
  await tester.pumpAndSettle();
  return provider;
}

/// Thème réellement appliqué par le `MaterialApp` du harnais.
ThemeData _appliedTheme(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(AppearanceSettingsSection)));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('la galerie liste les 8 presets et résout leurs libellés', (
    tester,
  ) async {
    await _pumpSection(tester);

    expect(
      AppAppearancePreset.values,
      hasLength(8),
      reason: 'la galerie doit couvrir tout le catalogue',
    );
    for (final preset in AppAppearancePreset.values) {
      final tile = find.byKey(AppearanceSettingsSection.presetKey(preset));
      expect(tile, findsOneWidget, reason: 'preset ${preset.id} absent');

      // Mapping `id → clé i18n` (les .arb n'ont pas de lookup dynamique) : le
      // libellé doit être traduit, jamais la clé brute ni une chaîne vide.
      final texts = tester.widgetList<Text>(
        find.descendant(of: tile, matching: find.byType(Text)),
      );
      final label = texts.first.data ?? '';
      expect(label.trim(), isNotEmpty, reason: preset.labelKey);
      expect(label, isNot(startsWith('appearance_preset_')), reason: preset.id);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('tap sur « Océan » : appliqué, repeint et persisté', (
    tester,
  ) async {
    final provider = await _pumpSection(tester);
    expect(provider.appearance.presetId, 'graphite');

    await tester.tap(
      find.byKey(
        AppearanceSettingsSection.presetKey(AppAppearancePreset.ocean),
      ),
    );
    await tester.pumpAndSettle();

    expect(provider.appearance.presetId, 'ocean');
    expect(provider.appearance.seedColor, AppAppearancePreset.ocean.seed);
    expect(
      provider.appearance.accentColor,
      AppAppearancePreset.ocean.accentLight,
    );
    expect(
      _appliedTheme(tester).colorScheme.surface,
      isNot(AppTheme.homeCard),
      reason: 'un preset de couleur teinte réellement les surfaces',
    );

    // Persistance : un nouveau provider relit la config enregistrée.
    final reloaded = ThemeProvider();
    // Un simple pump suffit à vider les microtâches du chargement.
    await tester.pumpAndSettle();
    expect(reloaded.appearance.presetId, 'ocean');
    expect(reloaded.appearance.seedColor, AppAppearancePreset.ocean.seed);
    expect(
      reloaded.appearance.accentColor,
      AppAppearancePreset.ocean.accentLight,
    );
  });

  testWidgets('les trois modes (sombre / clair / système) basculent', (
    tester,
  ) async {
    final provider = await _pumpSection(tester);

    // Les libellés sont lus depuis les segments : le test ne dépend pas des
    // traductions choisies.
    final segmented = tester.widget<SegmentedButton<ThemeMode>>(
      find.byKey(AppearanceSettingsSection.modeSelectorKey),
    );
    expect(segmented.segments, hasLength(3));
    final labels = <ThemeMode, String>{
      for (final segment in segmented.segments)
        segment.value: (segment.label! as Text).data!,
    };

    Future<void> selectMode(ThemeMode mode) async {
      await tester.tap(find.text(labels[mode]!));
      await tester.pumpAndSettle();
    }

    expect(provider.themeMode, ThemeMode.dark);
    await selectMode(ThemeMode.light);
    expect(provider.themeMode, ThemeMode.light);
    expect(
      _appliedTheme(tester).brightness,
      Brightness.light,
      reason: 'le thème clair est réellement appliqué',
    );

    await selectMode(ThemeMode.system);
    expect(provider.themeMode, ThemeMode.system);

    await selectMode(ThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);
    expect(_appliedTheme(tester).brightness, Brightness.dark);
  });

  testWidgets('« Réinitialiser » revient au preset graphite (défauts)', (
    tester,
  ) async {
    final provider = await _pumpSection(tester);

    await tester.tap(
      find.byKey(AppearanceSettingsSection.presetKey(AppAppearancePreset.rose)),
    );
    await tester.pumpAndSettle();
    await provider.setMode(ThemeMode.light);
    await tester.pumpAndSettle();
    expect(provider.appearance.presetId, 'rose');
    expect(provider.themeMode, ThemeMode.light);

    await tester.tap(find.byKey(AppearanceSettingsSection.resetButtonKey));
    await tester.pumpAndSettle();

    expect(provider.appearance, AppAppearanceConfig.defaults);
    expect(provider.appearance.presetId, 'graphite');
    expect(provider.themeMode, ThemeMode.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString('app_appearance'),
      isNull,
      reason: 'la réinitialisation efface la config persistée',
    );
  });

  testWidgets('accent trop proche de la surface : ratio affiché + alerte', (
    tester,
  ) async {
    final provider = await _pumpSection(tester);
    expect(find.byKey(AppearanceSettingsSection.customBadgeKey), findsNothing);

    // Le ratio est TOUJOURS affiché (informatif)…
    expect(
      find.byKey(AppearanceSettingsSection.contrastRatioKey),
      findsOneWidget,
    );
    expect(
      find.byKey(AppearanceSettingsSection.contrastWarningKey),
      findsNothing,
    );

    // …mais un accent ≈ la surface tombe sous 4.5:1 → avertissement, sans
    // blocage : la couleur reste appliquée.
    final surface = _appliedTheme(tester).colorScheme.surface;
    await provider.setAccent(surface);
    await tester.pumpAndSettle();

    expect(provider.appearance.accentColor, surface);
    final warning = tester.widget<Text>(
      find.byKey(AppearanceSettingsSection.contrastWarningKey),
    );
    expect(warning.data, contains('1.0:1'));
    expect(
      find.byKey(AppearanceSettingsSection.contrastRatioKey),
      findsOneWidget,
    );
    expect(
      find.byKey(AppearanceSettingsSection.customBadgeKey),
      findsOneWidget,
      reason: 'accent ≠ preset actif → badge « Personnalisé »',
    );

    // Un accent très contrasté (cyan Océan) retire l'avertissement.
    await provider.setAccent(
      AppAppearancePreset.ocean.accentFor(Brightness.dark),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(AppearanceSettingsSection.contrastWarningKey),
      findsNothing,
    );
  });

  testWidgets('la pastille accent ouvre le sélecteur de couleur', (
    tester,
  ) async {
    await _pumpSection(tester);

    await tester.tap(find.byKey(AppearanceSettingsSection.accentPickerKey));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(BlockPicker), findsOneWidget);

    // Ferme le dialogue par « Appliquer » (l'accent ne change pas).
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('aucun preset n\'affiche l\'alerte de contraste, dans les deux '
      'modes', (tester) async {
    final provider = await _pumpSection(tester);

    for (final preset in AppAppearancePreset.values) {
      for (final mode in const <ThemeMode>[ThemeMode.dark, ThemeMode.light]) {
        await provider.setPreset(preset);
        await provider.setMode(mode);
        await tester.pumpAndSettle();

        final label = '${preset.id} / ${mode.name}';
        expect(
          find.byKey(AppearanceSettingsSection.contrastWarningKey),
          findsNothing,
          reason: 'alerte de contraste affichée pour $label',
        );

        // Le ratio affiché est celui de la paire RÉELLEMENT peinte dans ce mode
        // (même calcul que la carte) : il doit rester ≥ 4.5:1.
        final text = tester
            .widget<Text>(
              find.byKey(AppearanceSettingsSection.contrastRatioKey),
            )
            .data!;
        final match = RegExp(r'([0-9]+\.[0-9]+):1').firstMatch(text);
        expect(match, isNotNull, reason: 'ratio illisible pour $label');
        final ratio = double.parse(match!.group(1)!);
        // ignore: avoid_print
        print('PRESET $label -> ${ratio.toStringAsFixed(2)}:1');
        expect(ratio, greaterThanOrEqualTo(4.5), reason: 'ratio pour $label');
      }
    }
  });
}
