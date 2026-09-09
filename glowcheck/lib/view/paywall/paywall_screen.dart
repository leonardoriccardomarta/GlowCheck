import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
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
  late List<BillingPackage> packages;
  late String selected;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    packages = GlowBilling.fallbackPackages;
    selected = _preferWeekly(packages);
    _load();
  }

  String _preferWeekly(List<BillingPackage> pkgs) {
    final weekly = pkgs.where((pkg) => pkg.id.contains('week'));
    return weekly.isEmpty ? pkgs.first.id : weekly.first.id;
  }

  Future<void> _load() async {
    final next = await GlowBilling.packages();
    if (!mounted || next.isEmpty) return;
    setState(() {
      packages = next;
      if (!next.any((pkg) => pkg.id == selected)) {
        selected = _preferWeekly(next);
      }
    });
  }

  bool get _weeklySelected => selected.contains('week');

  Future<void> _buy() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final outcome = await GlowBilling.purchase(selected);
      if (!mounted) return;
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
      if (mounted) setState(() => busy = false);
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

  String _planLabel(BillingPackage pkg) {
    if (pkg.id.contains('year')) return GlowL10n.t('paywall_yearly');
    return GlowL10n.t('paywall_weekly');
  }

  String _planPrice(BillingPackage pkg) {
    if (pkg.id.contains('year')) return GlowL10n.t('paywall_price_year');
    return GlowL10n.t('paywall_price_week_trial');
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
                    Text(
                      GlowL10n.t('paywall_title'),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      GlowL10n.t('paywall_sub'),
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
                    const SizedBox(height: 18),
                    for (final pkg in packages) ...[
                      _PlanTile(
                        pkg: pkg,
                        label: _planLabel(pkg),
                        price: _planPrice(pkg),
                        bestValueLabel: GlowL10n.t('paywall_best'),
                        selected: selected == pkg.id,
                        onTap: () => setState(() => selected = pkg.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 4),
                      Text(error!, style: const TextStyle(color: AppColors.caution, fontSize: 13, height: 1.4)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
                child: Column(
                  children: [
                    GlowPrimaryButton(
                      giant: true,
                      title: busy
                          ? GlowL10n.t('paywall_working')
                          : (_weeklySelected ? GlowL10n.t('paywall_cta') : GlowL10n.t('paywall_cta_year')),
                      onPressed: busy ? () {} : _buy,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      GlowL10n.t('paywall_trial'),
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
                      GlowBilling.live ? GlowL10n.t('paywall_live') : GlowL10n.t('paywall_sandbox'),
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

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.pkg,
    required this.label,
    required this.price,
    required this.bestValueLabel,
    required this.selected,
    required this.onTap,
  });

  final BillingPackage pkg;
  final String label;
  final String price;
  final String bestValueLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: selected ? AppColors.card : AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (pkg.bestValue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.card : AppColors.ink,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              bestValueLabel,
                              style: TextStyle(
                                color: selected ? AppColors.ink : AppColors.card,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        color: selected ? AppColors.card.withValues(alpha: 0.78) : AppColors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.card : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
