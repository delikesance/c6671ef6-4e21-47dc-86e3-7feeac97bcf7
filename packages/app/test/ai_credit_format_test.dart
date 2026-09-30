import 'package:bot_creator/features/subscriptions/logic/ai_credit_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats wallet amounts and small ledger movements as AI credits', () {
    expect(formatAiCredits(3000000, locale: 'fr'), '30');
    expect(formatAiCredits(1000, locale: 'fr'), '0,01');
    expect(formatAiCredits(-50000, locale: 'fr'), '-0,5');
    expect(formatAiCredits(1, locale: 'fr'), '0,00001');
    expect(formatAiCredits(125000, locale: 'en'), '1.25');
  });
}
