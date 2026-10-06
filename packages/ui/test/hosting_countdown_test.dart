import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:bot_creator_ui/src/widgets/hosting_countdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('décompte : unités à partir de la plus grande non nulle', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 12);
    await tester.pumpWidget(
      _host(
        HostingCountdown(
          // 1 mois (30 j) + 2 j + 3 h + 4 min + 5 s.
          deadline: now.add(
            const Duration(days: 32, hours: 3, minutes: 4, seconds: 5),
          ),
          expiredLabel: 'Expiré',
          summary: 'résumé',
          now: () => now,
        ),
      ),
    );
    expect(find.text('01'), findsOneWidget); // mois
    expect(find.text('02'), findsOneWidget); // jours
    expect(find.text('03'), findsOneWidget); // heures
    expect(find.text('04'), findsOneWidget); // minutes
    expect(find.text('05'), findsOneWidget); // secondes
    expect(find.text('MOIS'), findsOneWidget);
    expect(find.text('SEC'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('décompte : min et s restent affichées, le reste est masqué', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 12);
    await tester.pumpWidget(
      _host(
        HostingCountdown(
          deadline: now.add(const Duration(seconds: 42)),
          expiredLabel: 'Expiré',
          summary: 'résumé',
          now: () => now,
        ),
      ),
    );
    expect(find.text('00'), findsOneWidget); // minutes
    expect(find.text('42'), findsOneWidget); // secondes
    expect(find.text('MOIS'), findsNothing);
    expect(find.text('HEURES'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('décompte : passé l\'échéance, le libellé « expiré »', (
    tester,
  ) async {
    final now = DateTime(2026, 1, 1, 12);
    await tester.pumpWidget(
      _host(
        HostingCountdown(
          deadline: now.subtract(const Duration(seconds: 1)),
          expiredLabel: 'Expiré',
          summary: 'résumé',
          now: () => now,
        ),
      ),
    );
    expect(find.text('Expiré'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
