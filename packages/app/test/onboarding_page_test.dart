import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/onboarding/presentation/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: OnboardingPage(onComplete: () {}),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(const {}));

  testWidgets(
    'the welcome screen has no Material app bar and one primary action',
    (tester) async {
      await _pump(tester);
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Welcome to Bot Creator'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets('the token step counts "Step 1 of 3" and carries no emoji', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    final emoji = RegExp(
      '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true,
    );
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      expect(emoji.hasMatch(text.data ?? ''), isFalse, reason: text.data);
    }
  });

  testWidgets('wide screens get the step rail instead of the segmented bar', (
    tester,
  ) async {
    await _pump(tester, size: const Size(1280, 800));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 3'), findsNothing);
    expect(find.text('Skip onboarding'), findsOneWidget);
  });

  testWidgets('the whole flow renders on a small phone without overflow', (
    tester,
  ) async {
    await _pump(tester, size: const Size(360, 640));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    for (final label in ['Step 1 of 3', 'Step 2 of 3', 'Step 3 of 3']) {
      expect(find.text(label), findsOneWidget);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Congratulations!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
