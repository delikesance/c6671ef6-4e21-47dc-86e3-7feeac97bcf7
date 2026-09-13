import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/desktop_title_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopTitleBarNotifier & Navigation', () {
    setUp(() {
      DesktopTitleBarNotifier.instance.updateManagingBot(
        name: null,
        id: null,
        onExit: null,
      );
    });

    tearDown(() {
      DesktopTitleBarNotifier.instance.updateManagingBot(
        name: null,
        id: null,
        onExit: null,
      );
    });

    test('initial state has no managing bot and cannot go back', () {
      final notifier = DesktopTitleBarNotifier.instance;
      expect(notifier.title, isNull);
      expect(notifier.subtitle, isNull);
      expect(notifier.canGoBack, isFalse);
    });

    test('updateManagingBot updates title, subtitle and canGoBack', () {
      final notifier = DesktopTitleBarNotifier.instance;
      var exited = false;

      notifier.updateManagingBot(
        name: 'Mon Bot Test',
        id: 42,
        onExit: () => exited = true,
      );

      expect(notifier.title, 'Mon Bot Test');
      expect(notifier.subtitle, 'ID 42');
      expect(notifier.canGoBack, isTrue);

      notifier.handleBack();
      expect(exited, isTrue);
    });

    testWidgets(
      'DesktopAppShell displays DesktopTitleBar and propagates bot state',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          final navKey = GlobalKey<NavigatorState>();
          DesktopTitleBarNotifier.instance.navigatorKey = navKey;

          await tester.pumpWidget(
            MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              navigatorKey: navKey,
              navigatorObservers: [DesktopTitleBarNotifier.instance],
              theme: AppTheme.darkTheme(),
              home: const DesktopAppShell(
                child: Scaffold(body: Text('Child Screen Body')),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Child Screen Body'), findsOneWidget);
          expect(find.byType(DesktopTitleBar), findsOneWidget);
          expect(find.text('Bot Creator'), findsOneWidget);
          // Les contrôles de fenêtre remplacent la barre native : leurs libellés
          // doivent passer par le catalogue i18n (aucun littéral en dur).
          expect(find.byTooltip('Minimize'), findsOneWidget);
          expect(find.byTooltip('Maximize'), findsOneWidget);
          expect(find.byTooltip('Close'), findsOneWidget);

          // Update notifier to simulate managing a bot
          DesktopTitleBarNotifier.instance.updateManagingBot(
            name: 'Alpha Bot',
            id: 101,
            onExit: () {},
          );
          await tester.pumpAndSettle();

          expect(find.text('Alpha Bot'), findsOneWidget);
          expect(find.text('ID 101'), findsOneWidget);
          expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      },
    );

    testWidgets('Pushed route activates canGoBack and handleBack pops it', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final navKey = GlobalKey<NavigatorState>();
        DesktopTitleBarNotifier.instance.navigatorKey = navKey;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorKey: navKey,
            navigatorObservers: [DesktopTitleBarNotifier.instance],
            theme: AppTheme.darkTheme(),
            builder: (context, child) => DesktopAppShell(child: child!),
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('push_button'),
                  onPressed: () {
                    navKey.currentState!.push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            const Scaffold(body: Text('Sub Page Content')),
                      ),
                    );
                  },
                  child: const Text('Push SubPage'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // At home with no bot managed: no back button
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);

        // Tap push button
        await tester.tap(find.byKey(const ValueKey('push_button')));
        await tester.pumpAndSettle();

        // Sub page is visible
        expect(find.text('Sub Page Content'), findsOneWidget);
        // DesktopTitleBar is STILL present at the top of the window!
        expect(find.byType(DesktopTitleBar), findsOneWidget);
        // Back button is now available in DesktopTitleBar
        expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

        // Tap back button in DesktopTitleBar
        await tester.tap(find.byIcon(Icons.arrow_back_rounded));
        await tester.pumpAndSettle();

        // Popped back to home
        expect(find.text('Sub Page Content'), findsNothing);
        expect(find.text('Push SubPage'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
