import 'package:bot_creator/features/subscriptions/logic/consumable_purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a remembered pack is recognised, an unknown product is not', () async {
    SharedPreferences.setMockInitialValues({});
    expect(
      await ConsumablePurchaseService.isConsumableProduct('pack_12k'),
      isFalse,
    );
    await ConsumablePurchaseService.rememberProducts(['pack_12k', '']);
    expect(
      await ConsumablePurchaseService.isConsumableProduct('pack_12k'),
      isTrue,
    );
    expect(
      await ConsumablePurchaseService.isConsumableProduct('pro_monthly'),
      isFalse,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('consumable_product_ids_v1'), ['pack_12k']);
  });
}
