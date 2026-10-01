import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_text_scale.dart';
import 'package:bot_creator/features/settings/presentation/text_scale_settings_section.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NonlinearSystemScale extends TextScaler {
  const _NonlinearSystemScale();

  @override
  double scale(double fontSize) => fontSize + 10 * fontSize / (fontSize + 10);

  @override
  double get textScaleFactor => scale(14) / 14;
}

Widget _harness(
  ThemeProvider provider, {
  TextScaler system = TextScaler.noScaling,
  Locale locale = const Locale('fr'),
}) => ChangeNotifierProvider<ThemeProvider>.value(
  value: provider,
  child: Consumer<ThemeProvider>(
    builder: (context, provider, _) => MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: system),
        child: AppTextScale(
          factor: provider.appearance.textScale,
          child: child!,
        ),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Page', key: ValueKey('page_probe')),
              const Padding(
                padding: EdgeInsets.all(16),
                child: TextScaleSettingsSection(),
              ),
              Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => const AlertDialog(
                      content: Text('Dialog', key: ValueKey('dialog_probe')),
                    ),
                  ),
                  child: const Text('Open dialog'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('text scale migrates old appearance and rejects malformed values', () {
    final old = AppAppearanceConfig.defaults.toJson()..remove('textScale');
    expect(AppAppearanceConfig.fromJson(old).textScale, 1.0);
    for (final value in ['small', null, double.nan, double.infinity]) {
      expect(
        AppAppearanceConfig.fromJson({...old, 'textScale': value}).textScale,
        1.0,
      );
    }
    expect(
      AppAppearanceConfig.fromJson({...old, 'textScale': 0.1}).textScale,
      0.75,
    );
    expect(
      AppAppearanceConfig.fromJson({...old, 'textScale': 8}).textScale,
      1.25,
    );
  });

  testWidgets('selection persists, preserves theme choices and can reset', (
    tester,
  ) async {
    final provider = ThemeProvider();
    await tester.pumpWidget(_harness(provider));
    await tester.pumpAndSettle();
    await provider.setPreset(AppAppearancePreset.ocean);

    final slider = tester.widget<Slider>(
      find.byKey(TextScaleSettingsSection.sliderKey),
    );
    slider.onChanged!(0.85);
    await tester.pumpAndSettle();
    expect(provider.appearance.textScale, 0.85);
    expect(provider.appearance.presetId, 'ocean');

    final reloaded = ThemeProvider();
    await tester.pumpAndSettle();
    expect(reloaded.appearance.textScale, 0.85);
    expect(reloaded.appearance.presetId, 'ocean');

    await tester.tap(find.byKey(TextScaleSettingsSection.resetKey));
    await tester.pumpAndSettle();
    expect(provider.appearance.textScale, 1.0);
    expect(provider.appearance.presetId, 'ocean');
    final prefs = await SharedPreferences.getInstance();
    expect(
      AppAppearanceConfig.decode(prefs.getString('app_appearance')).textScale,
      1.0,
    );
  });

  testWidgets('global adjustment preserves nonlinear system scale in dialogs', (
    tester,
  ) async {
    const system = _NonlinearSystemScale();
    final provider = ThemeProvider();
    await tester.pumpWidget(_harness(provider, system: system));
    await tester.pumpAndSettle();
    var context = tester.element(find.byKey(const ValueKey('page_probe')));
    expect(MediaQuery.textScalerOf(context), same(system));

    await provider.setTextScale(0.75);
    await tester.pumpAndSettle();
    context = tester.element(find.byKey(const ValueKey('page_probe')));
    for (final size in [14.0, 30.0]) {
      expect(
        MediaQuery.textScalerOf(context).scale(size),
        closeTo(system.scale(size) * 0.75, 0.00001),
      );
    }
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    context = tester.element(find.byKey(const ValueKey('dialog_probe')));
    expect(
      MediaQuery.textScalerOf(context).scale(30),
      closeTo(system.scale(30) * 0.75, 0.00001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact phone setting wraps across all supported languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in AppLocalizations.supportedLocales) {
      final provider = ThemeProvider();
      await tester.pumpWidget(
        _harness(
          provider,
          locale: locale,
          system: const TextScaler.linear(1.5),
        ),
      );
      await tester.pumpAndSettle();
      await provider.setTextScale(1.25);
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'compact layout overflow in ${locale.languageCode}',
      );
      expect(find.byKey(TextScaleSettingsSection.sliderKey), findsOneWidget);
      expect(find.byKey(TextScaleSettingsSection.previewKey), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    }
  });
}
