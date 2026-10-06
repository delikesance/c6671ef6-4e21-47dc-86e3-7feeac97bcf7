import 'package:bot_creator/features/subscriptions/logic/commerce_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fixture() => {
  'published': true,
  'document': {
    'schema_version': 1,
    'default_locale': 'en',
    'offers': [
      {
        'id': 'pro',
        'kind': 'subscription',
        'enabled': true,
        'translations': {
          'en': {
            'title': 'Pro',
            'benefits': ['Four bots'],
          },
          'fr': {'title': 'Formule Pro'},
        },
        'bindings': [
          {'provider': 'apple', 'platform': 'ios', 'product_id': 'pro_ios'},
          {
            'provider': 'google',
            'platform': 'android',
            'product_id': 'pro_android',
            'base_plan_id': 'monthly',
          },
        ],
        'required_capabilities': ['commerce.subscription.v1'],
      },
    ],
  },
};

void main() {
  test('locale fallback and bindings preserve the provider product', () {
    final catalog = CommerceCatalog.fromJson(fixture());
    final offer = catalog.offers.single;
    expect(offer.text('fr-CA', catalog.defaultLocale)?.title, 'Formule Pro');
    expect(offer.text('de', catalog.defaultLocale)?.title, 'Pro');
    expect(offer.nativeBinding('ios')?.productId, 'pro_ios');
    expect(offer.nativeBinding('android')?.basePlanId, 'monthly');
    expect(offer.nativeBinding('desktop'), isNull);
  });
  test('unsupported capability and expired offer remain unavailable', () {
    final now = DateTime.now();
    final raw = fixture();
    var offer = CommerceCatalog.fromJson(raw).offers.single;
    expect(offer.visible(now, {}), isFalse);
    expect(offer.visible(now, {'commerce.subscription.v1'}), isTrue);
    raw['document']['offers'][0]['ends_at'] = now
        .subtract(const Duration(seconds: 1))
        .toIso8601String();
    offer = CommerceCatalog.fromJson(raw).offers.single;
    expect(offer.visible(now, {'commerce.subscription.v1'}), isFalse);
  });
  test('rejects incompatible schemas', () {
    final raw = fixture();
    raw['document']['schema_version'] = 99;
    expect(() => CommerceCatalog.fromJson(raw), throwsFormatException);
  });

  test(
    'AI packs: only visible offers with a native binding, credits from grants',
    () {
      final raw = fixture();
      final doc = raw['document'] as Map<String, dynamic>;
      (doc['offers'] as List).add({
        'id': 'pack-12k',
        'kind': 'ai_pack',
        'enabled': true,
        'translations': {
          'en': {'title': '12k credits'},
        },
        'bindings': [
          {
            'provider': 'google',
            'platform': 'android',
            'product_id': 'pack_12k',
          },
        ],
      });
      (doc['offers'] as List).add({
        'id': 'pack-off',
        'kind': 'ai_pack',
        'enabled': false,
        'translations': {
          'en': {'title': 'Disabled'},
        },
        'bindings': [
          {
            'provider': 'google',
            'platform': 'android',
            'product_id': 'pack_off',
          },
        ],
      });
      raw['grants'] = {
        'pack-12k': {'ai_credits_once': 12000000},
      };
      final catalog = CommerceCatalog.fromJson(raw);
      final now = DateTime.now();
      expect(catalog.aiPacks('android', now).map((o) => o.id), ['pack-12k']);
      expect(catalog.aiPacks('ios', now), isEmpty);
      expect(catalog.aiCreditsOnce('pack-12k'), 12000000);
      expect(catalog.aiCreditsOnce('pack-off'), 0);
    },
  );
  test('a server without grants still parses', () {
    final catalog = CommerceCatalog.fromJson(fixture());
    expect(catalog.grants, isEmpty);
    expect(catalog.aiCreditsOnce('pro'), 0);
  });
}
