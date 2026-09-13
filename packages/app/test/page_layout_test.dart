// Verrou du contrat de mise en page commun à toutes les pages de l'app :
// `AppPageLayout` (largeur de contenu et marges) et `PageContent` (l'enveloppe
// qui les applique). Ces valeurs sont la SEULE source de vérité de la
// respiration de l'interface : les pages ne doivent plus coder leurs propres
// bornes (600 / 760 / 1000 / 1200, paddings 12/16/28…), sinon la même fenêtre
// affiche des marges de 12 px sur une page et de 660 px sur la suivante.
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finder scopé au contenu de l'enveloppe : `MaterialApp`/`Scaffold` posent
/// leurs propres `ConstrainedBox`/`Padding`/`SizedBox`, un finder global
/// ramasserait les leurs.
Finder inPageContent(Finder matching) =>
    find.descendant(of: find.byType(PageContent), matching: matching);

/// Monte [PageContent] dans une surface de largeur [width] et rend les
/// contraintes réellement appliquées au contenu.
Future<({BoxConstraints constraints, EdgeInsets padding})> pumpPageContent(
  WidgetTester tester,
  double width, {
  double? maxWidth,
  EdgeInsets? padding,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PageContent(
          maxWidth: maxWidth,
          padding: padding,
          child: const SizedBox(height: 10, width: double.infinity),
        ),
      ),
    ),
  );
  await tester.pump();

  final box = tester.widget<ConstrainedBox>(
    inPageContent(find.byType(ConstrainedBox)).first,
  );
  final pad = tester.widget<Padding>(inPageContent(find.byType(Padding)).first);
  return (
    constraints: box.constraints,
    padding: pad.padding.resolve(TextDirection.ltr),
  );
}

void main() {
  group('AppPageLayout : valeurs communes', () {
    test('largeur de contenu : 1200 en large, 640 en compact', () {
      expect(AppPageLayout.maxContentWidth, 1200);
      expect(AppPageLayout.compactMaxContentWidth, 640);
      expect(AppPageLayout.contentMaxWidthFor(1600), 1200);
      expect(AppPageLayout.contentMaxWidthFor(800), 1200);
      expect(AppPageLayout.contentMaxWidthFor(400), 640);
    });

    test('marges horizontales : 24 en large, 16 en compact', () {
      expect(AppPageLayout.horizontalPadding, 24);
      expect(AppPageLayout.compactHorizontalPadding, 16);
      expect(AppPageLayout.horizontalPaddingFor(1600), 24);
      expect(AppPageLayout.horizontalPaddingFor(400), 16);
      expect(
        AppPageLayout.paddingFor(1600),
        const EdgeInsets.symmetric(horizontal: 24),
      );
      expect(
        AppPageLayout.paddingFor(400),
        const EdgeInsets.symmetric(horizontal: 16),
      );
    });

    test('le seuil large/compact est celui de l’app', () {
      expect(AppPageLayout.isWide(AppTheme.desktopBreakpoint), isTrue);
      expect(AppPageLayout.isWide(AppTheme.desktopBreakpoint - 1), isFalse);
      expect(AppPageLayout.isWide(1600), isTrue);
      expect(AppPageLayout.isWide(360), isFalse);
    });
  });

  group('PageContent', () {
    testWidgets('fenêtre large : 1200 px centrés avec 24 px de marge', (
      tester,
    ) async {
      final applied = await pumpPageContent(tester, 1600);

      expect(applied.constraints.maxWidth, AppPageLayout.maxContentWidth);
      expect(
        applied.padding,
        const EdgeInsets.symmetric(horizontal: AppPageLayout.horizontalPadding),
      );

      // Le rendu réel suit la contrainte (et non la largeur de la fenêtre).
      final content = tester.getSize(
        inPageContent(find.byType(SizedBox)).first,
      );
      expect(content.width, AppPageLayout.maxContentWidth - 2 * 24);
      // … et reste centré.
      final left = tester
          .getTopLeft(inPageContent(find.byType(SizedBox)).first)
          .dx;
      expect(left, 200 + 24);
    });

    testWidgets(
      'fenêtre compacte : largeur commune compacte et 16 px de marge',
      (tester) async {
        final applied = await pumpPageContent(tester, 500);

        expect(
          applied.constraints.maxWidth,
          AppPageLayout.compactMaxContentWidth,
        );
        expect(
          applied.padding,
          const EdgeInsets.symmetric(
            horizontal: AppPageLayout.compactHorizontalPadding,
          ),
        );
        expect(
          tester.getSize(inPageContent(find.byType(SizedBox)).first).width,
          500 - 2 * 16,
        );
      },
    );

    testWidgets('se base sur la largeur DISPONIBLE, pas celle de la fenêtre', (
      tester,
    ) async {
      // 1600 px de fenêtre, mais 500 px disponibles (barre latérale) ⇒ compact.
      tester.view.physicalSize = const Size(1600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                const SizedBox(width: 1100),
                SizedBox(
                  width: 500,
                  child: PageContent(
                    child: const SizedBox(height: 10, width: double.infinity),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final box = tester.widget<ConstrainedBox>(
        inPageContent(find.byType(ConstrainedBox)).first,
      );
      expect(box.constraints.maxWidth, AppPageLayout.compactMaxContentWidth);
    });

    testWidgets('surcharges maxWidth / padding respectées', (tester) async {
      final applied = await pumpPageContent(
        tester,
        1600,
        maxWidth: 560,
        padding: const EdgeInsets.only(top: 8, bottom: 88),
      );
      expect(applied.constraints.maxWidth, 560);
      expect(applied.padding.top, 8);
      expect(applied.padding.bottom, 88);
      expect(applied.padding.left, 0);
    });
  });

  group('windowChromeOwnsBackButton', () {
    test('suit la plateforme desktop : vrai en desktop, faux sur mobile', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      expect(windowChromeOwnsBackButton(), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(windowChromeOwnsBackButton(), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      expect(windowChromeOwnsBackButton(), isTrue);
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(windowChromeOwnsBackButton(), isFalse);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(windowChromeOwnsBackButton(), isFalse);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
