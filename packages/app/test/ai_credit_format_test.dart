import 'package:bot_creator/features/subscriptions/logic/ai_credit_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats AI credits without any decimal', () {
    expect(formatAiCredits(3000000, locale: 'fr'), '3 000');
    expect(formatAiCredits(97993500, locale: 'en'), '97,994');
    expect(formatAiCredits(1000, locale: 'en'), '1');
    expect(formatAiCredits(12000, locale: 'en'), '12');
    expect(formatAiCredits(100, locale: 'fr'), '<1');
    expect(formatAiCredits(-50000, locale: 'fr'), '-50');
    expect(formatAiCredits(0, locale: 'fr'), '0');
  });
}
