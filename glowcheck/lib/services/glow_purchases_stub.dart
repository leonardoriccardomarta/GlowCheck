import 'glow_billing_types.dart';

class GlowPurchases {
  GlowPurchases._();

  static bool get enabled => false;

  static Future<void> configure() async {}

  static Future<List<BillingPackage>> packages() async => const [];

  static Future<PurchaseOutcome> purchase(String packageId) async {
    return PurchaseOutcome.needsStore;
  }

  static Future<PurchaseOutcome> restore() async {
    return PurchaseOutcome.needsStore;
  }

  static Future<void> syncEntitlement() async {}
}
