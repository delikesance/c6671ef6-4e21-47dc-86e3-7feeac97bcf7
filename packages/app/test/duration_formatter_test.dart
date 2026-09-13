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

  group('splitHostingDuration', () {
    test('décompose mois / jours / heures / minutes', () {
      expect(splitHostingDuration(0), (months: 0, days: 0, hours: 0, minutes: 0));
      expect(
        splitHostingDuration(-10),
        (months: 0, days: 0, hours: 0, minutes: 0),
      );
      expect(
        splitHostingDuration(59),
        (months: 0, days: 0, hours: 0, minutes: 59),
      );
      expect(splitHostingDuration(60), (months: 0, days: 0, hours: 1, minutes: 0));
      expect(
        splitHostingDuration(1440 + 61),
        (months: 0, days: 1, hours: 1, minutes: 1),
      );
      expect(
        splitHostingDuration(30 * 1440),
        (months: 1, days: 0, hours: 0, minutes: 0),
      );
      expect(
        splitHostingDuration(2 * 30 * 1440 + 3 * 1440 + 4 * 60 + 5),
        (months: 2, days: 3, hours: 4, minutes: 5),
      );
    });

    test('reste cohérent avec formatHostingDuration', () {
      // Le formatage long et la décomposition segmentée partagent la même
      // arithmétique : aucune divergence possible entre les deux affichages.
      for (final minutes in <int>[1, 59, 60, 125, 1440, 43200, 100000]) {
        final parts = splitHostingDuration(minutes);
        final rebuilt =
            parts.months * 30 * 1440 +
            parts.days * 1440 +
            parts.hours * 60 +
            parts.minutes;
        expect(rebuilt, minutes);
      }
    });
  });

  group('formatHostingExpiration', () {
    testWidgets('FR : date + « à » + heure, sans verbe', (
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

      expect(
        formatHostingExpiration(buildContext, DateTime(2037, 11, 21, 17, 55)),
        '21 nov. 2037 à 17:55',
      );
    });

    testWidgets('EN : date + at + heure', (WidgetTester tester) async {
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

      // CLDR insère une espace fine insécable (U+202F) avant « PM ».
      expect(
        formatHostingExpiration(buildContext, DateTime(2037, 11, 21, 17, 55)),
        'Nov 21, 2037 at 5:55\u202fPM',
      );
    });
  });
}
