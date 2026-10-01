import 'package:intl/intl.dart';

/// The API and ledger retain token units; only the app presents AI credits.
const int tokensPerAiCredit = 100000;

String formatAiCredits(Object? tokens, {String? locale}) {
  final amount = switch (tokens) {
    num value => value,
    String value => num.tryParse(value) ?? 0,
    _ => 0,
  };
  final formatter = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = 0
    ..maximumFractionDigits = 5;
  return formatter.format(amount / tokensPerAiCredit);
}
