import '../config/app_env.dart';
import '../state/glow_store.dart';

class BillingPackage {
  const BillingPackage({
    required this.id,
    required this.label,
    required this.priceString,
    required this.bestValue,
    required this.productId,
  });

  final String id;
  final String label;
  final String priceString;
  final bool bestValue;
  final String productId;
}

enum PurchaseOutcome { unlocked, needsStore, nothingToRestore }

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

  static Future<List<BillingPackage>> packages() async {
    return fallbackPackages;
  }

  static Future<PurchaseOutcome> purchase(String packageId) async {
    if (live) {
      return PurchaseOutcome.needsStore;
    }
    final yearly = packageId.contains('year');
    await GlowStore.instance.unlockPro(plan: yearly ? 'yearly' : 'weekly');
    return PurchaseOutcome.unlocked;
  }

  static Future<PurchaseOutcome> restore() async {
    if (live) {
      return PurchaseOutcome.needsStore;
    }
    if (GlowStore.instance.isPro) {
      return PurchaseOutcome.unlocked;
    }
    return PurchaseOutcome.nothingToRestore;
  }
}
