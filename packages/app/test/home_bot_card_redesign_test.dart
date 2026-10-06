// Carte bot de l'accueil (refonte) : mobile (390 dp) et desktop (1100 dp).
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  HomeBotCard card(
    TickerProvider vsync, {
    required bool running,
    required bool expanded,
  }) => HomeBotCard(
    name: 'Mon bot',
    id: '1',
    avatar: null,
    guildCount: 2,
    isRunning: running,
    canToggle: true,
    isTogglingThisBot: false,
    initiallyExpanded: expanded,
    pulseController: AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 900),
    ),
    onManage: () {},
    onToggle: () {},
    onAddTime: () {},
    onLogs: running ? () {} : null,
    showPremiumLabels: false,
    freeMinutes: 90,
  );

  Future<void> size(WidgetTester t, double w) async {
    t.view.physicalSize = Size(w, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets(
    'mobile : bot actif déplié, menu « Plus d\'actions » avec les logs',
    (t) async {
      await size(t, 390);
      await t.pumpWidget(host(card(t, running: true, expanded: true)));
      await t.pumpAndSettle();
      expect(tester(t), isNull);
      expect(find.text('Actif sur 2 serveurs'), findsOneWidget);
      expect(find.text('Arrêter'), findsOneWidget);
      expect(find.text('Gérer'), findsOneWidget);
      expect(find.byTooltip("Plus d'actions"), findsOneWidget);
      await t.tap(find.byTooltip("Plus d'actions"));
      await t.pumpAndSettle();
      expect(find.text('Logs du bot'), findsOneWidget);
    },
  );

  testWidgets('mobile : bot arrêté replié garde « Lancer le bot » à portée', (
    t,
  ) async {
    await size(t, 390);
    FlutterError.onError = (d) => debugPrint(d.toString());
    await t.pumpWidget(host(card(t, running: false, expanded: false)));
    await t.pumpAndSettle();
    expect(tester(t), isNull);
    // AnimatedCrossFade garde aussi la version dépliée (hors écran).
    expect(find.text('Lancer le bot'), findsWidgets);
    expect(find.text('Arrêté'), findsOneWidget);
    expect(tester(t), isNull);
  });

  testWidgets('desktop : carte toujours dépliée, pas de chevron', (t) async {
    await size(t, 1100);
    await t.pumpWidget(host(card(t, running: false, expanded: true)));
    await t.pumpAndSettle();
    expect(tester(t), isNull);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    expect(find.text('Lancer le bot'), findsOneWidget);
    expect(find.text('Temps préservé'.toUpperCase()), findsOneWidget);
  });
}

Object? tester(WidgetTester t) {
  final e = t.takeException();
  if (e != null) {
    debugPrint((e as FlutterError).toStringDeep());
  }
  return e;
}
