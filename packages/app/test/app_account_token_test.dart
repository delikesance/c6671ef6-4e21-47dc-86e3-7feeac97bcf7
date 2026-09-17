import 'package:bot_creator/features/subscriptions/logic/app_account_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appAccountTokenForOwner', () {
    test('derives the stable UUIDv5 the backend resolves notifications with', () {
      // UUIDv5(namespace = DNS, name = "bot-creator:owner:123456789012345678").
      // Hard-coded on purpose: the backend derives nothing, it stores this exact
      // value on /billing/verify, so a change here silently breaks the mapping.
      expect(
        appAccountTokenForOwner('123456789012345678'),
        'c413c13b-1e0e-5113-9e5e-8027a871ccdc',
      );
    });

    test('is stable across calls and distinct per owner', () {
      expect(
        appAccountTokenForOwner('123456789012345678'),
        appAccountTokenForOwner('123456789012345678'),
      );
      expect(appAccountTokenForOwner('1'), isNot(appAccountTokenForOwner('2')));
    });

    test('ignores surrounding whitespace', () {
      expect(
        appAccountTokenForOwner(' 123456789012345678 '),
        appAccountTokenForOwner('123456789012345678'),
      );
    });

    test('is a parseable UUIDv5 (StoreKit2 drops anything else)', () {
      final token = appAccountTokenForOwner('42');

      expect(token, isNotNull);
      final v5 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(v5.hasMatch(token!), isTrue, reason: 'got $token');
    });

    test('returns null when there is no owner id', () {
      expect(appAccountTokenForOwner(null), isNull);
      expect(appAccountTokenForOwner(''), isNull);
      expect(appAccountTokenForOwner('   '), isNull);
    });
  });
}
