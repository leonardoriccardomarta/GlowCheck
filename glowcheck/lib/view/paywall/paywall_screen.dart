import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/services/glow_billing.dart';
import 'package:fitnessapp/utils/app_colors.dart';
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
    selected = packages.first.id;
    _load();
  }

  Future<void> _load() async {
    final next = await GlowBilling.packages();
    if (!mounted || next.isEmpty) return;
    setState(() {
      packages = next;
      selected = next.first.id;
    });
  }

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
          error =
              'Store checkout is wired. Add REVENUECAT_API_KEY on iOS/Android, or STRIPE_CHECKOUT_URL on web, then rebuild.';
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
          error = 'Restore pulls an existing Pro entitlement after App Store products are connected.';
        });
        return;
      }
      if (outcome == PurchaseOutcome.nothingToRestore) {
        setState(() => error = 'Nothing to restore on this device yet.');
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            Row(
              children: [
                GlowCircleButton(
                  icon: Icons.close,
                  onTap: () => Navigator.pop(context),
                ),
                const Spacer(),
                TextButton(
                  onPressed: busy ? null : _restore,
                  child: const Text(
                    "Restore",
                    style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              "GlowCheck Pro",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1),
            ),
            const SizedBox(height: 8),
            const Text(
              "First readable INCI is free. Pro keeps scoring every bottle vs your skin.",
              style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Feature(text: "Score vs your skin, not a public Yuka number"),
                  _Feature(text: "Full INCI tagged Watch / Fit / Listed"),
                  _Feature(text: "Drugstore swap from the readable formula"),
                  _Feature(text: "Unlimited shelf after the free scan"),
                ],
              ),
            ),
            const SizedBox(height: 18),
            for (final pkg in packages) ...[
              _PlanTile(
                pkg: pkg,
                selected: selected == pkg.id,
                onTap: () => setState(() => selected = pkg.id),
              ),
              const SizedBox(height: 10),
            ],
            if (error != null) ...[
              const SizedBox(height: 6),
              Text(error!, style: const TextStyle(color: AppColors.caution, fontSize: 13, height: 1.4)),
            ],
            const SizedBox(height: 16),
            GlowPrimaryButton(
              title: busy ? "Working..." : "Unlock Pro",
              onPressed: busy ? () {} : _buy,
            ),
            const SizedBox(height: 12),
            Text(
              GlowBilling.live
                  ? "Live store keys are set. Checkout completes on the native or Stripe path."
                  : "Sandbox on this device until you add REVENUECAT_API_KEY or STRIPE_CHECKOUT_URL.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
            ),
          ],
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: AppColors.card, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: AppColors.card.withValues(alpha: 0.88), fontSize: 14, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.pkg, required this.selected, required this.onTap});

  final BillingPackage pkg;
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
                          pkg.label,
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
                              "Best value",
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
                      pkg.priceString,
                      style: TextStyle(
                        color: selected ? AppColors.card.withValues(alpha: 0.7) : AppColors.muted,
                        fontSize: 13,
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
