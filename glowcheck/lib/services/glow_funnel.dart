import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/view/login/login_sheet.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

class GlowFunnel {
  GlowFunnel._();

  static Future<bool> ensureSignedIn(BuildContext context) async {
    if (GlowStore.instance.hasAccount) return true;
    final ok = await showGlowLoginSheet(context);
    return ok == true && GlowStore.instance.hasAccount;
  }

  static Future<bool> ensureCanScan(BuildContext context) async {
    if (GlowStore.instance.canScan) return true;
    if (!context.mounted) return false;
    await Navigator.of(context, rootNavigator: true).pushNamed(PaywallScreen.routeName);
    if (!context.mounted) return GlowStore.instance.canScan;
    if (GlowStore.instance.canScan && !GlowStore.instance.hasAccount) {
      await ensureSignedIn(context);
    }
    return GlowStore.instance.canScan;
  }
}
