import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/app_env.dart';
import '../l10n/glow_l10n.dart';
import '../state/glow_store.dart';
import 'glow_billing_types.dart';

class GlowPurchases {
  GlowPurchases._();

  static bool _listening = false;

  static bool get enabled =>
      AppEnv.revenueCatKey.trim().isNotEmpty &&
      (Platform.isIOS || Platform.isAndroid);

  static Future<void> configure() async {
    if (!enabled) return;
    final config = PurchasesConfiguration(AppEnv.revenueCatKey.trim())
      ..appUserID = GlowStore.instance.accountEmail;
    await Purchases.configure(config);
    if (!_listening) {
      _listening = true;
      Purchases.addCustomerInfoUpdateListener(_applyInfo);
    }
    await syncEntitlement();
  }

  static Future<void> syncEntitlement() async {
    if (!enabled) return;
    try {
      await _applyInfo(await Purchases.getCustomerInfo());
    } catch (_) {}
  }

  static Future<void> _applyInfo(CustomerInfo info) async {
    final entitlement = info.entitlements.all[AppEnv.entitlement];
    final active = entitlement?.isActive == true;
    final product = entitlement?.productIdentifier ?? '';
    final yearly = product.contains('year');
    await GlowStore.instance.applyStoreEntitlement(
      active: active,
      plan: active ? (yearly ? 'yearly' : 'weekly') : null,
    );
  }

  static Future<List<BillingPackage>> packages() async {
    if (!enabled) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      final found = <String, BillingPackage>{};
      for (final package in _allPackages(offerings)) {
        final id = package.storeProduct.identifier;
        final yearly = id.contains('year');
        found[id] = BillingPackage(
          id: yearly ? 'yearly' : 'weekly',
          label: yearly ? 'Yearly' : 'Weekly',
          priceString: package.storeProduct.priceString,
          bestValue: yearly,
          productId: id,
        );
      }
      return found.values.toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<PurchaseOutcome> purchase(String packageId) async {
    if (!enabled) return PurchaseOutcome.needsStore;
    try {
      final offerings = await Purchases.getOfferings();
      final target = _matchPackage(offerings, packageId);
      if (target == null) return PurchaseOutcome.needsStore;
      final info = await Purchases.purchasePackage(target);
      await _applyInfo(info);
      final active = GlowStore.instance.isPro;
      return active ? PurchaseOutcome.unlocked : PurchaseOutcome.needsStore;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      throw Exception(error.message ?? GlowL10n.t('paywall_store_err'));
    }
  }

  static Future<PurchaseOutcome> restore() async {
    if (!enabled) return PurchaseOutcome.needsStore;
    try {
      final info = await Purchases.restorePurchases();
      await _applyInfo(info);
      if (GlowStore.instance.isPro) return PurchaseOutcome.unlocked;
      return PurchaseOutcome.nothingToRestore;
    } on PlatformException catch (error) {
      throw Exception(error.message ?? GlowL10n.t('paywall_restore_err'));
    }
  }

  static List<Package> _allPackages(Offerings offerings) {
    final packages = <Package>[
      ...?offerings.current?.availablePackages,
    ];
    for (final offering in offerings.all.values) {
      packages.addAll(offering.availablePackages);
    }
    return packages;
  }

  static Package? _matchPackage(Offerings offerings, String packageId) {
    final yearly = packageId.contains('year');
    final productId = yearly ? AppEnv.yearlyProductId : AppEnv.weeklyProductId;
    for (final package in _allPackages(offerings)) {
      if (package.storeProduct.identifier == productId) return package;
    }
    if (yearly) return offerings.current?.annual;
    return offerings.current?.weekly;
  }
}
