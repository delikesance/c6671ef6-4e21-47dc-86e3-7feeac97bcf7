import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/duration_formatter.dart';

void main() {
  group('formatHostingDuration', () {
    testWidgets('formats durations correctly in French', (
      WidgetTester tester,
    ) async {
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      // 0 or negative
      expect(formatHostingDuration(buildContext, 0), '0 minute');
      expect(formatHostingDuration(buildContext, -10), '0 minute');

      // Minutes only
      expect(formatHostingDuration(buildContext, 1), '1 minute');
      expect(formatHostingDuration(buildContext, 45), '45 minutes');

      // Hours only
      expect(formatHostingDuration(buildContext, 60), '1 heure');
      expect(formatHostingDuration(buildContext, 120), '2 heures');

      // Hours and minutes
      expect(formatHostingDuration(buildContext, 125), '2 heures, 5 minutes');

      // Days
      expect(formatHostingDuration(buildContext, 1440), '1 jour');
      expect(formatHostingDuration(buildContext, 2880), '2 jours');
      expect(
        formatHostingDuration(buildContext, 1440 + 60 + 5),
        '1 jour, 1 heure, 5 minutes',
      );

      // Months
      expect(formatHostingDuration(buildContext, 30 * 1440), '1 mois');
      expect(
        formatHostingDuration(
          buildContext,
          2 * 30 * 1440 + 3 * 1440 + 4 * 60 + 5,
        ),
        '2 mois, 3 jours, 4 heures, 5 minutes',
      );
    });

    testWidgets('formats durations correctly in English', (
      WidgetTester tester,
    ) async {
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      // 0 or negative
      expect(formatHostingDuration(buildContext, 0), '0 minutes');
      expect(formatHostingDuration(buildContext, -5), '0 minutes');

      // Minutes only
      expect(formatHostingDuration(buildContext, 1), '1 minute');
      expect(formatHostingDuration(buildContext, 30), '30 minutes');

      // Hours only
      expect(formatHostingDuration(buildContext, 60), '1 hour');
      expect(formatHostingDuration(buildContext, 180), '3 hours');

      // Hours and minutes
      expect(formatHostingDuration(buildContext, 125), '2 hours, 5 minutes');

      // Days
      expect(formatHostingDuration(buildContext, 1440), '1 day');
      expect(formatHostingDuration(buildContext, 2880), '2 days');

      // Large durations
      expect(formatHostingDuration(buildContext, 30 * 1440), '1 month');
      expect(
        formatHostingDuration(
          buildContext,
          2 * 30 * 1440 + 3 * 1440 + 4 * 60 + 5,
        ),
        '2 months, 3 days, 4 hours, 5 minutes',
      );
    });
  });

  group('formatSessionExpiration', () {
    testWidgets('formats session expiration correctly in French', (
      WidgetTester tester,
    ) async {
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(
        formatSessionExpiration(buildContext, today),
        'Expire aujourd\'hui à 14:30',
      );

      final tomorrow = DateTime(now.year, now.month, now.day + 1, 16, 45);
      expect(
        formatSessionExpiration(buildContext, tomorrow),
        'Expire demain à 16:45',
      );

      final futureDate = DateTime(2027, 5, 12, 10, 15);
      final result = formatSessionExpiration(buildContext, futureDate);
      expect(result.contains('Expire le'), isTrue);
      expect(result.contains('2027'), isTrue);
    });

    testWidgets('formats session expiration correctly in English', (
      WidgetTester tester,
    ) async {
      late BuildContext buildContext;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              buildContext = context;
              return const SizedBox();
            },
          ),
        ),
      );

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 14, 30);
      expect(
        formatSessionExpiration(buildContext, today),
        contains('Expires today at'),
      );

      final tomorrow = DateTime(now.year, now.month, now.day + 1, 16, 45);
      expect(
        formatSessionExpiration(buildContext, tomorrow),
        contains('Expires tomorrow at'),
      );

      final futureDate = DateTime(2027, 5, 12, 10, 15);
      final result = formatSessionExpiration(buildContext, futureDate);
      expect(result.contains('Expires'), isTrue);
      expect(result.contains('2027'), isTrue);
    });
  });
}
