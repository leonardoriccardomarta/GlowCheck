import 'package:flutter/foundation.dart';

import '../config/app_env.dart';
import '../state/glow_store.dart';
import 'glow_api.dart';
import 'glow_billing_types.dart';
import 'glow_purchases.dart';
import 'glow_web_nav.dart';

export 'glow_billing_types.dart';

class GlowBilling {
  GlowBilling._();

  static const entitlement = AppEnv.entitlement;
  static const lifetimeId = 'lifetime';

  static const fallbackPackages = [
    BillingPackage(
      id: lifetimeId,
      label: 'Lifetime',
      priceString: '9,99 €',
      bestValue: true,
      productId: 'glowcheck_lifetime',
    ),
  ];

  static bool get live => AppEnv.billingLive;

  static bool get showLiveCopy => live || (kIsWeb && !_localWeb);

  static Future<void> configure() async {
    await GlowPurchases.configure();
    if (kIsWeb) {
      AppEnv.stripeLive = await GlowApi.billingReady();
      await completeWebReturn();
    }
  }

  static Future<void> completeWebReturn() async {
    if (!kIsWeb) return;
    final uri = Uri.base;
    final flag = uri.queryParameters['stripe'];
    final sessionId = uri.queryParameters['session_id'];
    if (flag == 'success' && sessionId != null && sessionId.isNotEmpty) {
      await GlowStore.instance.setStripeSessionId(sessionId);
      final result = await GlowApi.confirmCheckout(sessionId);
      if (result.unlocked) {
        await _applyPaid(sessionId);
      }
      await GlowStore.instance.markHomeInstallHint();
      stripCheckoutQuery();
      return;
    }
    if (flag == 'cancel') {
      stripCheckoutQuery();
    }
  }

  static Future<List<BillingPackage>> packages() async {
    if (kIsWeb) return fallbackPackages;
    final store = await GlowPurchases.packages();
    if (store.isNotEmpty) return store;
    return fallbackPackages;
  }

  static bool get _localWeb {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  static Future<PurchaseOutcome> purchase(String packageId) async {
    if (GlowPurchases.enabled) {
      return GlowPurchases.purchase(packageId);
    }
    if (kIsWeb) {
      return _purchaseWeb();
    }
    if (live) {
      return PurchaseOutcome.needsStore;
    }
    await GlowStore.instance.unlockPro(plan: lifetimeId);
    return PurchaseOutcome.unlocked;
  }

  static Future<PurchaseOutcome> _purchaseWeb() async {
    if (AppEnv.stripeCheckoutUrl.startsWith('http')) {
      goToCheckout(AppEnv.stripeCheckoutUrl);
      return PurchaseOutcome.redirecting;
    }
    if (AppEnv.stripeLive) {
      final origin = Uri.base.origin;
      final url = await GlowApi.createCheckout(
        successUrl: '$origin/?stripe=success&session_id={CHECKOUT_SESSION_ID}',
        cancelUrl: '$origin/?stripe=cancel',
        locale: GlowStore.instance.localeCode,
      );
      goToCheckout(url);
      return PurchaseOutcome.redirecting;
    }
    if (_localWeb) {
      await GlowStore.instance.unlockPro(plan: lifetimeId);
      return PurchaseOutcome.unlocked;
    }
    return PurchaseOutcome.needsStore;
  }

  static Future<void> attachPaidToAccount() async {
    final sessionId = GlowStore.instance.stripeSessionId;
    if (sessionId == null || sessionId.isEmpty) return;
    if (!GlowStore.instance.hasAccount) return;
    final result = await GlowApi.confirmCheckout(sessionId);
    if (result.attached) {
      await GlowStore.instance.unlockPro(plan: lifetimeId, stripeSession: sessionId);
    }
  }

  static Future<void> _applyPaid(String sessionId) async {
    await GlowStore.instance.unlockPro(plan: lifetimeId, stripeSession: sessionId);
    if (GlowStore.instance.hasAccount) {
      await GlowApi.pullAndMergeShelf();
      return;
    }
    await GlowStore.instance.markNeedsAuthAfterPay();
  }

  static Future<PurchaseOutcome> restore() async {
    if (GlowPurchases.enabled) {
      return GlowPurchases.restore();
    }
    if (kIsWeb) {
      final sessionId = GlowStore.instance.stripeSessionId;
      if (sessionId != null && sessionId.isNotEmpty && AppEnv.stripeLive) {
        final result = await GlowApi.confirmCheckout(sessionId);
        if (result.unlocked) {
          await _applyPaid(sessionId);
          return PurchaseOutcome.unlocked;
        }
        return PurchaseOutcome.nothingToRestore;
      }
      if (GlowStore.instance.isPro) return PurchaseOutcome.unlocked;
      if (!AppEnv.stripeLive) return PurchaseOutcome.nothingToRestore;
      return PurchaseOutcome.nothingToRestore;
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
