// Tests des briques de la refonte : BlockFamily, StatusPill, FlatNavBar/Rail.
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/core/widgets/flat_nav_bar.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/status_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(brightness: Brightness.dark),
  home: Scaffold(
    body: Align(alignment: Alignment.bottomCenter, child: child),
  ),
);

List<FloatingGlassNavItem> _items(List<String> taps) => [
  for (final l in ['Accueil', 'Bots'])
    FloatingGlassNavItem(
      icon: Icons.circle_outlined,
      selectedIcon: Icons.circle,
      label: l,
      selected: l == 'Accueil',
      onTap: () => taps.add(l),
    ),
];

void main() {
  group('BlockFamily', () {
    test('couleurs de la charte', () {
      expect(BlockFamily.http.color, const Color(0xFF38BDF8));
      expect(BlockFamily.logic.color, const Color(0xFFFB7185));
      expect(BlockFamily.messages.color, const Color(0xFFA78BFA));
      expect(BlockFamily.moderation.color, const Color(0xFF4ADE80));
      expect(BlockFamily.data.color, const Color(0xFFFBBF24));
      expect(BlockFamily.events.color, const Color(0xFFFB923C));
    });

    test('pastille : teinte 14 %, anneau 32 %', () {
      final d = BlockFamily.http.pastilleDecoration();
      final c = BlockFamily.http.color;
      expect(d.color, c.withValues(alpha: 0.14));
      expect((d.border! as Border).top.color, c.withValues(alpha: 0.32));
    });

    test('mapping des catégories existantes + repli', () {
      expect(BlockFamily.fromCategoryName('Messages'), BlockFamily.messages);
      expect(
        BlockFamily.fromCategoryName('Moderation'),
        BlockFamily.moderation,
      );
      expect(
        BlockFamily.fromCategoryName('HTTP & Variables'),
        BlockFamily.http,
      );
      expect(BlockFamily.fromCategoryName('Logic & Flow'), BlockFamily.logic);
      expect(BlockFamily.fromCategoryName('Interactions'), BlockFamily.events);
      expect(BlockFamily.fromCategoryName('Music'), BlockFamily.data);
      expect(BlockFamily.fromCategoryName('???'), BlockFamily.logic);
      expect(BlockFamily.fromCategoryName(null), BlockFamily.logic);
    });

    test('surtitre coloré', () {
      expect(BlockFamily.data.overlineStyle().color, BlockFamily.data.color);
    });
  });

  group('StatusPill', () {
    testWidgets('26 px de haut, libellé affiché', (tester) async {
      await tester.pumpWidget(
        _host(const StatusPill.online(label: 'En ligne')),
      );
      expect(find.text('En ligne'), findsOneWidget);
      expect(tester.getSize(find.byType(StatusPill)).height, 26);
    });

    test('couleurs par variante', () {
      expect(
        StatusPill.dotColorOf(StatusPillVariant.online),
        AppTheme.statusOnline,
      );
      expect(
        StatusPill.textColorOf(StatusPillVariant.error),
        AppTheme.statusErrorText,
      );
      expect(
        StatusPill.dotColorOf(StatusPillVariant.warning),
        AppTheme.statusWarning,
      );
    });
  });

  group('FlatNavBar', () {
    testWidgets('84 px, libellés (sans tooltip), tap', (tester) async {
      final taps = <String>[];
      await tester.pumpWidget(_host(FlatNavBar(items: _items(taps))));
      expect(tester.getSize(find.byType(FlatNavBar)).height, 84);
      expect(find.text('Bots'), findsOneWidget);
      await tester.tap(find.text('Bots'));
      expect(taps, ['Bots']);
    });

    testWidgets('rail : 84 px de large', (tester) async {
      await tester.pumpWidget(
        _host(SizedBox(height: 400, child: FlatNavRail(items: _items([])))),
      );
      expect(tester.getSize(find.byType(FlatNavRail)).width, 84);
      expect(find.text('Accueil'), findsOneWidget);
    });
  });
}
