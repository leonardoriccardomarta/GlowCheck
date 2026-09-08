import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/utils/glow_verdict.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  static String routeName = "/HomeScreen";

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    GlowStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    GlowStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = GlowStore.instance;
    final latest = store.latest;
    final shelf = store.history.take(8).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
          children: [
            Text(
              GlowL10n.t('home_kicker'),
              style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              GlowL10n.t('home_profile', {'skin': GlowStore.skinLabel(store.skinType)}),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, height: 1.15),
            ),
            const SizedBox(height: 14),
            Text(
              store.isPro
                  ? GlowL10n.t('pro_unlocked')
                  : GlowL10n.t('scans_left_n', {'n': '${store.freeScansRemaining}'}),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                if (store.canScan) {
                  DashboardScope.of(context)?.goTab(2);
                } else {
                  Navigator.pushNamed(context, PaywallScreen.routeName);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  GlowL10n.t('home_banner'),
                  style: const TextStyle(
                    color: AppColors.card,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _FeaturedCard(
              latest: latest,
              onOpen: () {
                if (latest == null) {
                  DashboardScope.of(context)?.goTab(2);
                  return;
                }
                Navigator.pushNamed(context, FinishWorkoutScreen.routeName, arguments: latest);
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: Text(
                    GlowL10n.t('your_shelf'),
                    style: const TextStyle(color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                GestureDetector(
                  onTap: () => DashboardScope.of(context)?.goTab(1),
                  child: Text(
                    GlowL10n.t('see_all'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (shelf.isEmpty)
              _EmptyShelf(onScan: () => DashboardScope.of(context)?.goTab(2))
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: shelf.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final scan = shelf[i];
                    return _BottleCard(
                      scan: scan,
                      onTap: () => Navigator.pushNamed(
                        context,
                        FinishWorkoutScreen.routeName,
                        arguments: scan,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.latest, required this.onOpen});

  final ScanResult? latest;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final score = latest?.score;
    final color = score == null ? AppColors.card : AppColors.scoreColor(score);
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(32),
          boxShadow: GlowStyle.soft,
        ),
        child: latest == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GlowL10n.t('first_bottle'),
                    style: TextStyle(color: AppColors.card.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    GlowL10n.t('photo_inci'),
                    style: const TextStyle(color: AppColors.card, fontSize: 24, fontWeight: FontWeight.w700, height: 1.15),
                  ),
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: latest!.score / 100,
                          strokeWidth: 7,
                          backgroundColor: AppColors.card.withValues(alpha: 0.16),
                          color: color,
                        ),
                        Text(
                          '${latest!.score}',
                          style: const TextStyle(color: AppColors.card, fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          latest!.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: AppColors.card.withValues(alpha: 0.7), fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          GlowVerdict.title(latest!).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.card,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          GlowVerdict.subtitle(latest!),
                          style: TextStyle(color: AppColors.card.withValues(alpha: 0.75), fontSize: 13, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BottleCard extends StatelessWidget {
  const _BottleCard({required this.scan, required this.onTap});

  final ScanResult scan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          boxShadow: GlowStyle.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlowInitials(label: scan.productName, size: 72, dark: true),
            const Spacer(),
            Text(
              scan.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              GlowVerdict.title(scan),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.scoreColor(scan.score)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyShelf extends StatelessWidget {
  const _EmptyShelf({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(GlowL10n.t('nothing_saved'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const Spacer(),
          GlowPrimaryButton(title: GlowL10n.t('scan_a_label'), compact: true, onPressed: onScan),
        ],
      ),
    );
  }
}
