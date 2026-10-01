import 'dart:io';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/widgets/reicon_material_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  test('all app icons use the Reicon renderer and have a mapping', () {
    final library = Directory(
      Directory('packages/app/lib').existsSync() ? 'packages/app/lib' : 'lib',
    );
    final mapping = File(
      '${library.path}/core/widgets/reicon_material_map.dart',
    ).readAsStringSync();
    final mapped = RegExp(
      r'Icons\.([A-Za-z0-9_]+):',
    ).allMatches(mapping).map((match) => match.group(1)!).toSet();
    // Flutter aliases this icon to content_copy_outlined (the same IconData).
    mapped.add('copy_outlined');

    for (final file in library.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.endsWith('reicon_material_map.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      expect(
        RegExp(r'(?<![A-Za-z])Icon\s*\(').hasMatch(source),
        isFalse,
        reason: 'Use AppIcon in ${file.path}',
      );
      for (final match in RegExp(
        r'\bIcons\.([A-Za-z0-9_]+)',
      ).allMatches(source)) {
        expect(
          mapped,
          contains(match.group(1)),
          reason: 'Missing Reicon mapping in ${file.path}',
        );
      }
    }
  });

  test('every mapped app icon has both Reicon weights', () {
    expect(reiconMaterialPaths.length, greaterThanOrEqualTo(440));
    for (final entry in reiconMaterialPaths.entries) {
      expect(entry.value.outline, isNotEmpty, reason: '${entry.key}');
      expect(entry.value.filled, isNotEmpty, reason: '${entry.key}');
    }
  });

  testWidgets('navigation and command icons render as Reicon SVGs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              AppIcon.fromMaterial(Icons.home_rounded, size: 24),
              AppIcon.fromMaterial(Icons.menu_book_outlined, size: 20),
              AppIcon.fromMaterial(Icons.settings_rounded, size: 28),
              AppIcon.fromMaterial(Icons.copy_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(SvgPicture), findsNWidgets(4));
    expect(tester.getSize(find.byType(SvgPicture).first), const Size(24, 24));
  });
}
