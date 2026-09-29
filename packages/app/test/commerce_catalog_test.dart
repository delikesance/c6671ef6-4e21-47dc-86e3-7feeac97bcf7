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
}
