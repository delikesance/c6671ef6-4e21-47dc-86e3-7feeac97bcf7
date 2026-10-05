import 'package:intl/intl.dart';

/// The API and ledger retain token units; only the app presents AI credits.
const int tokensPerAiCredit = 1000;

String formatAiCredits(Object? tokens, {String? locale}) {
  final amount = switch (tokens) {
    num value => value,
    String value => num.tryParse(value) ?? 0,
    _ => 0,
  };
  final credits = amount / tokensPerAiCredit;
  // Never show decimals; a non-zero amount below half a credit reads "<1".
  if (credits != 0 && credits.abs() < 0.5) return credits < 0 ? '-<1' : '<1';
  final formatter = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 0;
  return formatter.format(credits.round());
}
