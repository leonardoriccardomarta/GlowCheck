import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/view/login/login_sheet.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

class GlowFunnel {
  GlowFunnel._();

  static Future<bool> ensureSignedIn(BuildContext context) async {
    if (GlowStore.instance.hasAccount) return true;
    final ok = await showGlowLoginSheet(
      context,
      required: GlowStore.instance.mustClaimPurchase,
    );
    return ok == true && GlowStore.instance.hasAccount;
  }

  static Future<bool> ensureCanScan(BuildContext context) async {
    if (!GlowStore.instance.canScan) {
      if (!context.mounted) return false;
      await Navigator.of(context, rootNavigator: true).pushNamed(PaywallScreen.routeName);
    }
    if (!context.mounted) return GlowStore.instance.canScan && GlowStore.instance.hasAccount;
    if (GlowStore.instance.mustClaimPurchase) {
      final ok = await ensureSignedIn(context);
      if (!ok) return false;
    }
    return GlowStore.instance.canScan;
  }
}
