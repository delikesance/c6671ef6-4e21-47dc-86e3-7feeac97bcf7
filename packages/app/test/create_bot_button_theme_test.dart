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
        // Refonte : icône d'accent éclairci (violet doux #A78BFA si l'accent est
        // le violet d'action) dans une pastille teintée à 16 %.
        expect(
          icon.color,
          Color.alphaBlend(Colors.white.withValues(alpha: 0.35), tokens.accent),
          reason: 'Icon should be the lightened accent in Dark mode',
        );

        final containerFinder = find
            .ancestor(of: iconFinder, matching: find.byType(Container))
            .first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          tokens.accent.withValues(alpha: 0.16),
          reason: 'Pastille should be a 16% tint of tokens.accent',
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
        expect(icon.color, isNotNull);

        final containerFinder = find
            .ancestor(of: iconFinder, matching: find.byType(Container))
            .first;
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(
          decoration.color,
          tokens.accent.withValues(alpha: 0.16),
          reason: 'Pastille should be a 16% tint of tokens.accent',
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
          expect(icon.color, isNot(Colors.white));

          final containerFinder = find
              .ancestor(of: iconFinder, matching: find.byType(Container))
              .first;
          final container = tester.widget<Container>(containerFinder);
          final decoration = container.decoration! as BoxDecoration;
          expect(decoration.color, tokens.accent.withValues(alpha: 0.16));
        }
      },
    );
  });
}
