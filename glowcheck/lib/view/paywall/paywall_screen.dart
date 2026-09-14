import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/config/app_env.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/services/glow_api.dart';
import 'package:fitnessapp/services/glow_billing.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/legal/legal_screen.dart';
import 'package:flutter/material.dart';

class PaywallScreen extends StatefulWidget {
  static String routeName = "/PaywallScreen";
  const PaywallScreen({Key? key}) : super(key: key);

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    GlowApi.billingReady().then((ready) {
      AppEnv.stripeLive = ready;
    });
  }

  Future<void> _buy() async {
    setState(() {
      busy = true;
      error = null;
    });
    var stayBusy = false;
    try {
      if (!AppEnv.stripeLive) {
        AppEnv.stripeLive = await GlowApi.billingReady();
      }
      final outcome = await GlowBilling.purchase(GlowBilling.lifetimeId);
      if (!mounted) return;
      if (outcome == PurchaseOutcome.redirecting) {
        stayBusy = true;
        return;
      }
      if (outcome == PurchaseOutcome.cancelled) return;
      if (outcome == PurchaseOutcome.needsStore) {
        setState(() {
          error = GlowL10n.t('paywall_store_err');
        });
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !stayBusy) setState(() => busy = false);
    }
  }
    setState(() {
      busy = true;
      error = null;
    });
    var stayBusy = false;
    try {
      final outcome = await GlowBilling.purchase(GlowBilling.lifetimeId);
      if (!mounted) return;
      if (outcome == PurchaseOutcome.redirecting) {
        stayBusy = true;
        return;
      }
      if (outcome == PurchaseOutcome.cancelled) return;
      if (outcome == PurchaseOutcome.needsStore) {
        setState(() {
          error = GlowL10n.t('paywall_store_err');
        });
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && !stayBusy) setState(() => busy = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final outcome = await GlowBilling.restore();
      if (!mounted) return;
      if (outcome == PurchaseOutcome.needsStore) {
        setState(() {
          error = GlowL10n.t('paywall_restore_err');
        });
        return;
      }
      if (outcome == PurchaseOutcome.nothingToRestore) {
        setState(() => error = GlowL10n.t('paywall_nothing'));
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: Row(
                  children: [
                    GlowCircleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: busy ? null : _restore,
                      child: Text(
                        GlowL10n.t('paywall_restore'),
                        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.neon,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          GlowL10n.t('paywall_badge'),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      GlowL10n.t('paywall_title'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      GlowL10n.t('paywall_price_lifetime'),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 0.95,
                        letterSpacing: -1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      GlowL10n.t('paywall_once'),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      GlowL10n.t('paywall_contrast'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        children: [
                          _Feature(text: GlowL10n.t('paywall_f1')),
                          _Feature(text: GlowL10n.t('paywall_f2')),
                          _Feature(text: GlowL10n.t('paywall_f3')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  children: [
                    GlowPrimaryButton(
                      giant: true,
                      title: busy ? GlowL10n.t('paywall_working') : GlowL10n.t('paywall_cta'),
                      onPressed: busy ? () {} : _buy,
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.caution, fontSize: 13, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      GlowL10n.t('paywall_once'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      GlowL10n.t('paywall_apple'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.4),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, LegalScreen.termsRoute),
                          child: Text(
                            GlowL10n.t('paywall_terms'),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text('·', style: TextStyle(color: AppColors.muted)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, LegalScreen.privacyRoute),
                          child: Text(
                            GlowL10n.t('paywall_privacy'),
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      GlowBilling.showLiveCopy ? GlowL10n.t('paywall_live') : GlowL10n.t('paywall_sandbox'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted, fontSize: 11, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.neon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.card.withValues(alpha: 0.92), fontSize: 16, height: 1.3, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
