import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/widgets/notion_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

    testWidgets(
      'renders circular filter button to the left of trailingAction',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NotionFilterBar(
                searchQuery: '',
                onSearchChanged: (_) {},
                searchHint: 'Rechercher...',
                filters: const [
                  NotionFilter(
                    id: 'type',
                    label: 'Type',
                    icon: Icons.category,
                    options: {'': 'All', 'slash': 'Slash'},
                  ),
                ],
                trailingAction: const SizedBox(
                  key: ValueKey('trailing_action'),
                  width: 80,
                  height: 40,
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey('trailing_action')), findsOneWidget);

        // Find tooltip or Material with CircleBorder
        final materialFinder = find.byWidgetPredicate(
          (w) => w is Material && w.shape is CircleBorder,
        );
        expect(materialFinder, findsOneWidget);

        // Verify the filter button sits to the left of the trailing action
        final filterButtonTopLeft = tester.getTopLeft(materialFinder);
        final trailingTopLeft = tester.getTopLeft(
          find.byKey(const ValueKey('trailing_action')),
        );
        expect(filterButtonTopLeft.dx, lessThan(trailingTopLeft.dx));
      },
    );
  });

  group('AppIcon sizing and search constraints', () {
    testWidgets(
      'AppIcon does not expand to fill large parent constraints (stays clamped)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
                child: const AppIcon.fromMaterial(Icons.search, size: 18),
              ),
            ),
          ),
        );

        final svgFinder = find.byType(SvgPicture);
        expect(svgFinder, findsOneWidget);
        final svgSize = tester.getSize(svgFinder);
        expect(svgSize.width, 18.0);
        expect(svgSize.height, 18.0);
      },
    );

    testWidgets('AppIcon defaults Icons.search to 18.0 when size is omitted', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppIcon.fromMaterial(Icons.search)),
        ),
      );

      final svgFinder = find.byType(SvgPicture);
      expect(svgFinder, findsOneWidget);
      final svgSize = tester.getSize(svgFinder);
      expect(svgSize.width, 18.0);
      expect(svgSize.height, 18.0);
    });
  });
}
