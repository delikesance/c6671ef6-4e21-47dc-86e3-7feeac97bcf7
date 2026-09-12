import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le bandeau d'onglets de l'éditeur (`_SettingsTabsNav` dans
/// `bot_sub_pages/settings.dart`) passe ces libellés réels au composant
/// partagé en variante inline `scrollable`. Un libellé long ne doit JAMAIS
/// être rogné : soit il tient, soit le bandeau défile.
void main() {
  // Libellés réels de `bot_settings_tab_*` (fr), tels que rendus dans l'app.
  const labels = <String>[
    'Général',
    'Présence & Statut',
    'Lavalink',
    'Base de données',
    'Avancé',
  ];

  Future<void> pumpStrip(WidgetTester tester, double width) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Personnaliser le bot'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(
                FloatingGlassNavBar.inlinePreferredHeight,
              ),
              child: SizedBox(
                width: width,
                child: FloatingGlassNavBar.inline(
                  scrollable: true,
                  items: [
                    for (var i = 0; i < labels.length; i++)
                      FloatingGlassNavItem(
                        icon: Icons.settings,
                        label: labels[i],
                        selected: i == 0,
                        onTap: () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  for (final width in <double>[360, 541, 800]) {
    testWidgets('libellés intacts à ${width.round()} dp (aucun rognage)', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await pumpStrip(tester, width);
      expect(tester.takeException(), isNull);

      // Largeur intrinsèque de chaque libellé dans le style réel du composant.
      final intrinsic = <String, double>{};
      for (final label in labels) {
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        intrinsic[label] = painter.width;
      }

      final measured = <String>[];
      for (final label in labels) {
        final rendered = tester.getSize(find.text(label)).width;
        measured.add(
          '$label: rendu=${rendered.toStringAsFixed(1)} '
          'intrinsèque=${intrinsic[label]!.toStringAsFixed(1)}',
        );
        expect(
          rendered,
          greaterThanOrEqualTo(intrinsic[label]! - 0.5),
          reason:
              'le libellé « $label » est rogné à ${width.round()} dp '
              '(rendu $rendered < intrinsèque ${intrinsic[label]})',
        );
      }
      // ignore: avoid_print
      print('STRIP ${width.round()}dp -> ${measured.join(' | ')}');
    });
  }
}
