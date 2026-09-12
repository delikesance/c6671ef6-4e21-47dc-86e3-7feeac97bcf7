import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/notion_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Design System - Brand Gradient', () {
    test('AppTheme.brandGradient uses brandPrimary and brandSecondary', () {
      expect(AppTheme.brandGradient, isNotNull);
      expect(AppTheme.brandGradient.colors, [
        AppTheme.brandPrimary,
        AppTheme.brandSecondary,
      ]);
    });

    test('Card theme in light mode uses modern flat styling', () {
      final light = AppTheme.lightTheme();
      expect(light.cardTheme.elevation, 0.0);
      expect(light.cardTheme.color, light.colorScheme.surfaceContainer);
      final shape = light.cardTheme.shape! as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppTheme.radiusCard));
      expect(shape.side.color, light.colorScheme.outlineVariant);
    });
  });

  group('NotionFilterBar with trailingAction', () {
    testWidgets(
      'renders search field alongside trailingAction without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        var createTapped = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotionFilterBar(
                searchQuery: '',
                onSearchChanged: (_) {},
                searchHint: 'Rechercher des commandes...',
                trailingAction: Container(
                  key: const ValueKey('create_btn'),
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.brandGradient,
                  ),
                  child: TextButton(
                    onPressed: () => createTapped = true,
                    child: const Text('Créer'),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('create_btn')), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('create_btn')));
        expect(createTapped, isTrue);
      },
    );
  });
}
