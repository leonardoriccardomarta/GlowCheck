import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:flutter/material.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _tab = 'all';
  int? _open;

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

  List<ScanResult> get _items {
    final history = GlowStore.instance.history;
    if (_tab == 'match') return history.where((s) => s.score >= 70).toList();
    if (_tab == 'caution') return history.where((s) => s.score < 70).toList();
    if (_tab == 'saved') return history.where((s) => GlowStore.instance.isPinned(s.at)).toList();
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
              child: Text(
                GlowL10n.t('your_shelf'),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GlowChip(label: GlowL10n.t('all_bottles'), selected: _tab == 'all', onTap: () => setState(() => _tab = 'all')),
                    GlowChip(label: GlowL10n.t('filter_match'), selected: _tab == 'match', onTap: () => setState(() => _tab = 'match')),
                    GlowChip(label: GlowL10n.t('filter_caution'), selected: _tab == 'caution', onTap: () => setState(() => _tab = 'caution')),
                    GlowChip(label: GlowL10n.t('filter_saved'), selected: _tab == 'saved', onTap: () => setState(() => _tab = 'saved')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              GlowL10n.t('shelf_empty'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              GlowL10n.t('shelf_empty_body'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 18),
                            GlowPrimaryButton(
                              title: GlowL10n.t('scan_a_label'),
                              compact: true,
                              onPressed: () => DashboardScope.of(context)?.goTab(2),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 120),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final scan = items[i];
                        final open = _open == i;
                        return _ShelfTile(
                          scan: scan,
                          index: i + 1,
                          expanded: open,
                          onToggle: () => setState(() => _open = open ? null : i),
                          onOpen: () => Navigator.pushNamed(
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

class _ShelfTile extends StatelessWidget {
  const _ShelfTile({
    required this.scan,
    required this.index,
    required this.expanded,
    required this.onToggle,
    required this.onOpen,
  });

  final ScanResult scan;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                          GlowL10n.t('bottle_n', {'n': '$index'}),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        Text(
                          scan.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        Text(
                          scan.lines.isEmpty
                              ? GlowStore.badgeLabel(scan.badge)
                              : GlowL10n.t('watch_fit_listed', {
                                  'watch': '${scan.watchCount}',
                                  'fit': '${scan.fitCount}',
                                  'listed': '${scan.listedCount}',
                                }),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "${scan.score}",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.scoreColor(scan.score),
                    ),
                  ),
                ],
              ),
              if (expanded) ...[
                const SizedBox(height: 14),
                Text(
                  scan.headline.isEmpty ? GlowL10n.t('no_headline') : scan.headline,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (scan.why.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(scan.why, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4)),
                ],
                const SizedBox(height: 8),
                Text(
                  GlowStore.occlusionLabel(scan.occlusionAlert),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 14),
                GlowPrimaryButton(title: GlowL10n.t('open_analysis'), compact: true, onPressed: onOpen),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
