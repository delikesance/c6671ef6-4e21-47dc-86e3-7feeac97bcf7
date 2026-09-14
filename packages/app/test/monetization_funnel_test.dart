import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/monetization_funnel.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Event {
  _Event(this.name, this.parameters);

  final String name;
  final Map<String, Object?> parameters;
}

class _Recorder {
  final List<_Event> events = <_Event>[];

  void install() {
    AppAnalytics.debugSetEventObserver(
      (name, parameters) =>
          events.add(_Event(name, parameters ?? const <String, Object?>{})),
    );
  }

  _Event get single => events.single;

  List<_Event> eventsNamed(String name) =>
      events.where((event) => event.name == name).toList(growable: false);
}

void main() {
  late _Recorder recorder;

  setUp(() {
    recorder = _Recorder()..install();
  });

  tearDown(() {
    AppAnalytics.debugResetObservers();
  });

  test('subscription_page_view logs event with no parameters', () async {
    await MonetizationFunnel.subscriptionPageView();

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'subscription_page_view');
    expect(recorder.single.parameters, isEmpty);
  });

  test('purchase_start normalizes product and logs event', () async {
    await MonetizationFunnel.purchaseStart(product: kAnnualSubscriptionId);

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'purchase_start');
    expect(recorder.single.parameters, {'product': 'annual'});
  });

  test('purchase_success logs normalized product', () async {
    await MonetizationFunnel.purchaseSuccess(product: kMonthlySubscriptionId);

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'purchase_success');
    expect(recorder.single.parameters, {'product': 'monthly'});
  });

  test('purchase_failed logs bounded reason and product', () async {
    await MonetizationFunnel.purchaseFailed(
      reason: PurchaseFailureReason.offerTokenMissing,
      product: kAnnualSubscriptionId,
    );

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'purchase_failed');
    expect(recorder.single.parameters, {
      'reason': 'offer_token_missing',
      'product': 'annual',
    });
  });

  test(
    'offer_token_missing is properly mapped from SubscriptionPurchaseFailureReason',
    () {
      final mapped = MonetizationFunnel.reasonFromPurchaseFailure(
        SubscriptionPurchaseFailureReason.offerTokenMissing,
      );

      expect(mapped, PurchaseFailureReason.offerTokenMissing);
      expect(mapped.wire, 'offer_token_missing');
    },
  );

  test(
    'raw error classification extracts offer_token_missing and cancellations',
    () {
      expect(
        MonetizationFunnel.classifyError(
          'Offer token null for product ... is not valid',
        ),
        PurchaseFailureReason.offerTokenMissing,
      );
      expect(
        MonetizationFunnel.classifyError('User canceled the purchase dialog'),
        PurchaseFailureReason.cancelled,
      );
      expect(
        MonetizationFunnel.classifyError('Billing unavailable on device'),
        PurchaseFailureReason.storeUnavailable,
      );
    },
  );

  test('product normalization covers all subscription products', () {
    expect(
      MonetizationFunnel.normalizeProductId(kAnnualSubscriptionId),
      'annual',
    );
    expect(
      MonetizationFunnel.normalizeProductId(kMonthlySubscriptionId),
      'monthly',
    );
    expect(MonetizationFunnel.normalizeProductId('host_one_app'), 'host_one');
    expect(MonetizationFunnel.normalizeProductId('host_two_app'), 'host_two');
  });
}
