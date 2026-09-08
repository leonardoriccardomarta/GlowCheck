import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/data/dupe_catalog.dart';
import 'package:fitnessapp/l10n/dupe_blurbs.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/utils/glow_verdict.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
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
    final history = GlowStore.instance.history;
    final approved = history.where(GlowVerdict.approved).toList();
    final rejected = history.where((s) => !GlowVerdict.approved(s)).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: history.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(GlowL10n.t('shelf_empty'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      GlowPrimaryButton(
                        title: GlowL10n.t('scan_a_label'),
                        compact: true,
                        onPressed: () => DashboardScope.of(context)?.goTab(2),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                children: [
                  Text(GlowL10n.t('your_shelf'), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  if (approved.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(label: GlowL10n.t('shelf_approved'), color: AppColors.good),
                    const SizedBox(height: 12),
                    ...approved.map((scan) => _ShelfCard(scan: scan, rejected: false)),
                  ],
                  if (rejected.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(label: GlowL10n.t('shelf_replace'), color: AppColors.caution),
                    const SizedBox(height: 12),
                    ...rejected.map((scan) => _ShelfCard(scan: scan, rejected: true)),
                  ],
                ],
              ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
        ),
      ],
    );
  }
}

class _ShelfCard extends StatelessWidget {
  const _ShelfCard({required this.scan, required this.rejected});

  final ScanResult scan;
  final bool rejected;

  void _open(BuildContext context) {
    Navigator.pushNamed(context, FinishWorkoutScreen.routeName, arguments: scan);
  }

  @override
  Widget build(BuildContext context) {
    final catalog = getDupeById(scan.dupeId) ?? getDupeByName(scan.dupe?.brand, scan.dupe?.name);
    final price = scan.dupe != null
        ? localizedDupePrice(scan.dupe!.estimatedPrice)
        : catalog != null
            ? localizedDupePrice(catalog.estimatedPrice)
            : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    GlowInitials(label: scan.productName, size: 54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            scan.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            GlowVerdict.title(scan),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.scoreColor(scan.score),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${scan.score}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.scoreColor(scan.score)),
                    ),
                  ],
                ),
                if (rejected && price != null) ...[
                  const SizedBox(height: 12),
                  GlowPrimaryButton(
                    title: GlowL10n.t('see_dupe_price', {'price': price}),
                    compact: true,
                    onPressed: () => _open(context),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
