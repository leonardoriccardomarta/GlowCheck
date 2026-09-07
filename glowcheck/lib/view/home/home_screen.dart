import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
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
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    GlowStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    GlowStore.instance.removeListener(_refresh);
    _search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<ScanResult> get _visible {
    final q = _search.text.trim().toLowerCase();
    final store = GlowStore.instance;
    return store.history.where((scan) {
      final badge = scan.badge.toUpperCase();
      if (_filter == 'match' && scan.score < 70) return false;
      if (_filter == 'caution' && scan.score >= 70) return false;
      if (_filter == 'saved' && !store.isPinned(scan.at)) return false;
      if (q.isEmpty) return true;
      final inci = scan.lines.any((item) => item.name.toLowerCase().contains(q));
      return scan.productName.toLowerCase().contains(q) ||
          scan.headline.toLowerCase().contains(q) ||
          badge.contains(q) ||
          inci;
    }).toList();
  }

  void _cycleFilter() {
    const order = ['all', 'match', 'caution', 'saved'];
    final i = order.indexOf(_filter);
    setState(() => _filter = order[(i + 1) % order.length]);
  }

  @override
  Widget build(BuildContext context) {
    final store = GlowStore.instance;
    final latest = store.latest;
    final visible = _visible;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        GlowL10n.t('hello'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      Text(
                        GlowL10n.t('skin_line', {'skin': GlowStore.skinLabel(store.skinType)}),
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      Text(
                        GlowStore.goalLabel(store.mainGoal),
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                GlowInitials(label: GlowStore.skinLabel(store.skinType), size: 52),
              ],
            ),
            const SizedBox(height: 22),
            GlowSearchBar(
              controller: _search,
              hint: GlowL10n.t('search_hint'),
              onChanged: (_) => setState(() {}),
              onFilter: _cycleFilter,
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GlowChip(label: GlowL10n.t('filter_all'), selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                  GlowChip(label: GlowL10n.t('filter_match'), selected: _filter == 'match', onTap: () => setState(() => _filter = 'match')),
                  GlowChip(label: GlowL10n.t('filter_caution'), selected: _filter == 'caution', onTap: () => setState(() => _filter = 'caution')),
                  GlowChip(label: GlowL10n.t('filter_saved'), selected: _filter == 'saved', onTap: () => setState(() => _filter = 'saved')),
                  GlowChip(
                    label: GlowL10n.t('filter_scan'),
                    selected: false,
                    onTap: () => DashboardScope.of(context)?.goTab(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
            if (visible.isEmpty)
              _EmptyShelf(onScan: () => DashboardScope.of(context)?.goTab(2))
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: visible.length.clamp(0, 8),
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final scan = visible[i];
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
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(GlowStyle.radiusCard),
                boxShadow: GlowStyle.soft,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.isPro ? GlowL10n.t('pro_unlocked') : GlowL10n.t('free_scans_left'),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          store.isPro ? GlowL10n.t('unlimited') : "${store.freeScansRemaining}",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          GlowL10n.t('bottles_saved', {'n': '${store.history.length}'}),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GlowPrimaryButton(
                    title: store.canScan ? GlowL10n.t('scan') : GlowL10n.t('unlock'),
                    compact: true,
                    onPressed: () {
                      if (store.canScan) {
                        DashboardScope.of(context)?.goTab(2);
                      } else {
                        Navigator.pushNamed(context, PaywallScreen.routeName);
                      }
                    },
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

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.latest, required this.onOpen});

  final ScanResult? latest;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final score = latest?.score;
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(32),
        boxShadow: GlowStyle.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF2A2623),
                    AppColors.ink,
                    score == null ? AppColors.ink : AppColors.scoreColor(score).withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -20,
            child: Icon(
              Icons.spa_outlined,
              size: 180,
              color: AppColors.card.withOpacity(0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  latest == null ? GlowL10n.t('first_bottle') : GlowL10n.t('last_match'),
                  style: TextStyle(color: AppColors.card.withOpacity(0.7), fontSize: 13),
                ),
                const Spacer(),
                Text(
                  latest?.productName ?? GlowL10n.t('photo_inci'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.card,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AppColors.star, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      latest == null ? "/ 100" : "${latest!.score} / 100",
                      style: const TextStyle(color: AppColors.card, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      latest == null
                          ? GlowL10n.t('vs_your_skin')
                          : latest!.lines.isEmpty
                              ? GlowStore.badgeLabel(latest!.badge)
                              : GlowL10n.t('inci_summary', {
                                  'n': '${latest!.lines.length}',
                                  'watch': '${latest!.watchCount}',
                                  'fit': '${latest!.fitCount}',
                                }),
                      style: TextStyle(color: AppColors.card.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Material(
                    color: AppColors.card.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(28),
                    child: InkWell(
                      onTap: onOpen,
                      borderRadius: BorderRadius.circular(28),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              latest == null ? GlowL10n.t('scan_now') : GlowL10n.t('see_more'),
                              style: const TextStyle(color: AppColors.card, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
                              child: const Icon(Icons.arrow_forward, size: 16, color: AppColors.ink),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            Row(
              children: [
                const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                const SizedBox(width: 4),
                Text("${scan.score}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward, size: 14, color: AppColors.card),
                ),
              ],
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
      height: 170,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            GlowL10n.t('nothing_saved'),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            GlowL10n.t('empty_shelf_body'),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const Spacer(),
          GlowPrimaryButton(title: GlowL10n.t('scan_a_label'), compact: true, onPressed: onScan),
        ],
      ),
    );
  }
}
