import 'dart:io';
import 'dart:ui' as ui;
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/inter/Inter-Regular.ttf'));
    await loader.load();
  });
  for (final width in [320.0, 600.0, 1280.0]) {
    testWidgets(
      'creation form fits $width and keeps token when switching engine',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        var javascript = false;
        var saves = 0;
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.darkTheme(),
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: SafeArea(
                  child: PageContent(
                    child: SingleChildScrollView(
                      child: StatefulBuilder(
                        builder: (context, setState) => BotCreateSetup(
                          javascript: javascript,
                          onEngineChanged: (value) =>
                              setState(() => javascript = value),
                          tokenController: controller,
                          obscureToken: true,
                          onToggleToken: () {},
                          onTokenChanged: (_) {},
                          saving: false,
                          onSave: () => saves++,
                          onBack: () {},
                          showBack: width < 1000,
                          onPortal: () {},
                          onGuide: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Créer un bot'), findsOneWidget);
        expect(find.text('Bot Clé en main'), findsNothing);
        await tester.enterText(find.byType(TextField), 'fixture-token');
        await tester.tap(find.text('JavaScript'));
        await tester.pumpAndSettle();
        expect(javascript, isTrue);
        expect(controller.text, 'fixture-token');
        expect(
          tester.widget<TextField>(find.byType(TextField)).obscureText,
          isTrue,
        );
        await tester.ensureVisible(find.byType(FilledButton));
        await tester.tap(find.byType(FilledButton));
        expect(saves, 1);
        expect(tester.takeException(), isNull);
        if (width == 1280) {
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '/tmp/claude-1000/-home-jeremy-Code-bc/c2520480-9b3f-44b4-a423-2e0fd802d2da/scratchpad/r4/tmp/bc-create-redesign.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
