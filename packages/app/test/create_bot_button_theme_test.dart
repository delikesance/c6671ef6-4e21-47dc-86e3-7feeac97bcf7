import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildCardWithTheme({required ThemeData theme}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme,
      home: Scaffold(body: CreateBotCard(onTap: () {})),
    );
  }

  group('CreateBotCard theme colors', () {
    testWidgets(
      'button is colored with theme accent and onAccent in Dark mode',
      (tester) async {
        final theme = AppTheme.darkTheme();
        final tokens = theme.extension<HomeTokens>()!;

        await tester.pumpWidget(buildCardWithTheme(theme: theme));
        await tester.pumpAndSettle();

        final iconFinder = find.byIcon(Icons.add_rounded);
        expect(iconFinder, findsOneWidget);

        final icon = tester.widget<Icon>(iconFinder);
        expect(
          icon.color,
          Colors.white,
          reason: 'Icon should be white in Dark mode',
        );

        final containerFinder = find
            .ancestor(of: iconFinder, matching: find.byType(Container))
            .first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          tokens.accent,
          reason: 'Button background should use tokens.accent',
        );
      },
    );

    testWidgets(
      'button is colored with theme accent and onAccent in Light mode',
      (tester) async {
        final theme = AppTheme.lightTheme();
        final tokens = theme.extension<HomeTokens>()!;

        await tester.pumpWidget(buildCardWithTheme(theme: theme));
        await tester.pumpAndSettle();

        final iconFinder = find.byIcon(Icons.add_rounded);
        expect(iconFinder, findsOneWidget);

        final icon = tester.widget<Icon>(iconFinder);
        expect(
          icon.color,
          tokens.onAccent,
          reason: 'Icon should use tokens.onAccent',
        );

        final containerFinder = find
            .ancestor(of: iconFinder, matching: find.byType(Container))
            .first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          tokens.accent,
          reason: 'Button background should use tokens.accent',
        );
      },
    );

    testWidgets(
      'button follows custom preset (e.g. Discord, Ocean) in Dark mode',
      (tester) async {
        for (final preset in [
          AppAppearancePreset.discord,
          AppAppearancePreset.ocean,
        ]) {
          final config = AppAppearanceConfig.defaults.copyWith(
            presetId: preset.id,
            seedColor: preset.seed,
            accentColor: preset.accentLight,
          );
          final theme = AppTheme.darkTheme(appearance: config);
          final tokens = theme.extension<HomeTokens>()!;

          await tester.pumpWidget(buildCardWithTheme(theme: theme));
          await tester.pumpAndSettle();

          final iconFinder = find.byIcon(Icons.add_rounded);
          final icon = tester.widget<Icon>(iconFinder);
          expect(icon.color, Colors.white);

          final containerFinder = find
              .ancestor(of: iconFinder, matching: find.byType(Container))
              .first;
          final container = tester.widget<Container>(containerFinder);
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.color, tokens.accent);
        }
      },
    );
  });
}
