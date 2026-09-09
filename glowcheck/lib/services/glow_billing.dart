import '../config/app_env.dart';
import '../state/glow_store.dart';
import 'glow_billing_types.dart';
import 'glow_purchases.dart';

export 'glow_billing_types.dart';

class GlowBilling {
  GlowBilling._();

  static const entitlement = AppEnv.entitlement;

  static const fallbackPackages = [
    BillingPackage(
      id: 'weekly',
      label: 'Weekly',
      priceString: '\$4.99 / week',
      bestValue: false,
      productId: AppEnv.weeklyProductId,
    ),
    BillingPackage(
      id: 'yearly',
      label: 'Yearly',
      priceString: '\$39.99 / year',
      bestValue: true,
      productId: AppEnv.yearlyProductId,
    ),
  ];

  static bool get live => AppEnv.billingLive;

  static Future<void> configure() async {
    await GlowPurchases.configure();
  }

  static Future<List<BillingPackage>> packages() async {
    final store = await GlowPurchases.packages();
    if (store.isNotEmpty) return store;
    return fallbackPackages;
  }

  static Future<PurchaseOutcome> purchase(String packageId) async {
    if (GlowPurchases.enabled) {
      return GlowPurchases.purchase(packageId);
    }
    if (live) {
      return PurchaseOutcome.needsStore;
    }
    final yearly = packageId.contains('year');
    await GlowStore.instance.unlockPro(plan: yearly ? 'yearly' : 'weekly');
    return PurchaseOutcome.unlocked;
  }

  static Future<PurchaseOutcome> restore() async {
    if (GlowPurchases.enabled) {
      return GlowPurchases.restore();
    }
    if (live) {
      return PurchaseOutcome.needsStore;
    }
    if (GlowStore.instance.isPro) {
      return PurchaseOutcome.unlocked;
    }
    return PurchaseOutcome.nothingToRestore;
  }
}
