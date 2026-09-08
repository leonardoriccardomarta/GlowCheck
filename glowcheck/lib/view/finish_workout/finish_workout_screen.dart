import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/data/dupe_catalog.dart';
import 'package:fitnessapp/l10n/dupe_blurbs.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/services/glow_link.dart';
import 'package:fitnessapp/services/glow_share.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/utils/glow_inci.dart';
import 'package:fitnessapp/utils/glow_verdict.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

class FinishWorkoutScreen extends StatefulWidget {
  static String routeName = "/FinishWorkoutScreen";
  const FinishWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<FinishWorkoutScreen> createState() => _FinishWorkoutScreenState();
}

class _FinishWorkoutScreenState extends State<FinishWorkoutScreen> {
  String _inciFilter = 'all';

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
    final result = ModalRoute.of(context)?.settings.arguments;
    final scan = result is ScanResult ? result : null;
    if (scan == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: GlowPrimaryButton(
            title: GlowL10n.t('back'),
            compact: true,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    }

    final lines = scan.lines.where((item) {
      if (_inciFilter == 'all') return true;
      return item.tag == _inciFilter;
    }).toList();
    final catalog = getDupeById(scan.dupeId) ??
        getDupeByName(scan.dupe?.brand, scan.dupe?.name);
    final rawDupe = scan.dupe ??
        (catalog == null
            ? null
            : DupeSuggestion(
                brand: catalog.brand,
                name: catalog.name,
                estimatedPrice: catalog.estimatedPrice,
                blurb: catalog.blurb,
                id: catalog.id,
              ));
    final dupeId = rawDupe?.id ?? catalog?.id;
    final dupe = rawDupe == null
        ? null
        : DupeSuggestion(
            brand: rawDupe.brand,
            name: rawDupe.name,
            estimatedPrice: localizedDupePrice(rawDupe.estimatedPrice),
            blurb: localizedDupeBlurb(dupeId, rawDupe.blurb),
            id: dupeId,
            whyThis: rawDupe.whyThis,
          );
    final pinned = GlowStore.instance.isPinned(scan.at);
    final scoreColor = AppColors.scoreColor(scan.score);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.ink, scoreColor],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GlowCircleButton(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.pop(context),
                              ),
                              const Spacer(),
                              GlowCircleButton(
                                icon: Icons.ios_share_rounded,
                                onTap: () => _share(scan),
                              ),
                              const SizedBox(width: 8),
                              GlowCircleButton(
                                icon: pinned ? Icons.favorite : Icons.favorite_border,
                                onTap: () => GlowStore.instance.togglePin(scan.at),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            scan.productName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.card.withValues(alpha: 0.62),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: scan.score / 100),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return SizedBox(
                                width: 156,
                                height: 156,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox.expand(
                                      child: CircularProgressIndicator(
                                        value: value,
                                        strokeWidth: 11,
                                        backgroundColor: AppColors.card.withValues(alpha: 0.18),
                                        color: AppColors.card,
                                      ),
                                    ),
                                    Text(
                                      "${(value * 100).round()}",
                                      style: const TextStyle(
                                        color: AppColors.card,
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                        height: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            GlowVerdict.punchTitle(scan),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.card,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            GlowVerdict.punchSub(scan),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.card,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Column(
                    children: [
                      if (dupe != null) ...[
                        _DupeCard(scan: scan, dupe: dupe),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          _CountCard(
                            label: GlowL10n.t('watch'),
                            value: scan.watchCount,
                            color: AppColors.vividRed,
                          ),
                          const SizedBox(width: 8),
                          _CountCard(
                            label: GlowL10n.t('fit'),
                            value: scan.fitCount,
                            color: AppColors.neon,
                          ),
                          const SizedBox(width: 8),
                          _CountCard(
                            label: GlowL10n.t('listed'),
                            value: scan.listedCount,
                            color: AppColors.muted,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: GlowL10n.t('why_number'),
                        body: scan.why.isNotEmpty
                            ? scan.why
                            : GlowL10n.t('why_fallback'),
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        title: GlowL10n.t('occlusion'),
                        body: GlowStore.occlusionLabel(scan.occlusionAlert),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            GlowL10n.t('full_inci'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            GlowL10n.t('n_ingredients', {'n': '${scan.lines.length}'}),
                            style: const TextStyle(color: AppColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GlowChip(label: GlowL10n.t('filter_all'), selected: _inciFilter == 'all', onTap: () => setState(() => _inciFilter = 'all')),
                            GlowChip(label: GlowL10n.t('watch'), selected: _inciFilter == 'watch', onTap: () => setState(() => _inciFilter = 'watch')),
                            GlowChip(label: GlowL10n.t('fit'), selected: _inciFilter == 'fit', onTap: () => setState(() => _inciFilter = 'fit')),
                            GlowChip(label: GlowL10n.t('listed'), selected: _inciFilter == 'listed', onTap: () => setState(() => _inciFilter = 'listed')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (scan.lines.isEmpty)
                        _InfoCard(
                          title: GlowL10n.t('no_inci_title'),
                          body: GlowL10n.t('no_inci_body'),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: GlowStyle.soft,
                          ),
                          child: Column(
                            children: [
                              ..._inciRows(lines),
                              if (lines.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    GlowL10n.t('nothing_filter'),
                                    style: const TextStyle(color: AppColors.muted),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (!GlowStore.instance.isPro && GlowStore.instance.freeScansRemaining == 0) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                GlowL10n.t('free_scan_used'),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                GlowL10n.t('free_scan_used_body'),
                                style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              GlowPrimaryButton(
                                title: GlowL10n.t('unlock_unlimited'),
                                compact: true,
                                onPressed: () => Navigator.pushNamed(context, PaywallScreen.routeName),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        GlowL10n.t('legal_footer'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.45),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
              child: GlowPrimaryButton(
                title: GlowStore.instance.canScan
                    ? GlowL10n.t('scan_another')
                    : GlowL10n.t('unlock_unlimited'),
                onPressed: () {
                  if (GlowStore.instance.canScan) {
                    Navigator.pop(context);
                    return;
                  }
                  Navigator.pushNamed(context, PaywallScreen.routeName);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _inciRows(List<IngredientLine> lines) {
    final scents = lines.where((item) => GlowInci.isFragrance(item.name, item.note)).toList();
    if (scents.length < 2) {
      return [for (final item in lines) _IngredientRow(item: item)];
    }
    final rows = <Widget>[];
    var grouped = false;
    for (final item in lines) {
      if (GlowInci.isFragrance(item.name, item.note)) {
        if (!grouped) {
          rows.add(_FragranceGroup(items: scents));
          grouped = true;
        }
        continue;
      }
      rows.add(_IngredientRow(item: item));
    }
    return rows;
  }

  Future<void> _share(ScanResult scan) async {
    final text = GlowL10n.t('share_text', {
      'score': '${scan.score}',
      'name': scan.productName,
      'headline': scan.headline,
    });
    final outcome = await GlowShare.text(text: text, title: 'GlowCheck');
    if (!mounted || outcome != GlowShareOutcome.copied) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(GlowL10n.t('score_copied'))),
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              "$value",
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({required this.item});

  final IngredientLine item;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.tagColor(item.tag);
    final label = item.tag == 'watch'
        ? GlowL10n.t('tag_watch')
        : item.tag == 'fit'
            ? GlowL10n.t('tag_fit')
            : GlowL10n.t('tag_listed');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.3),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(item.note!, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DupeCard extends StatelessWidget {
  const _DupeCard({required this.scan, required this.dupe});

  final ScanResult scan;
  final DupeSuggestion dupe;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neon, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.neon,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              GlowL10n.t('dupe_tag'),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${dupe.brand} ${dupe.name}',
            style: const TextStyle(
              color: AppColors.card,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dupe.estimatedPrice,
            style: const TextStyle(
              color: AppColors.neon,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            GlowL10n.t('dupe_vs', {'name': scan.productName}),
            style: TextStyle(
              color: AppColors.card.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (dupe.blurb.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              dupe.blurb,
              style: TextStyle(
                color: AppColors.card.withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          GlowPrimaryButton(
            title: GlowL10n.t('dupe_find'),
            compact: true,
            light: true,
            onPressed: () => GlowLink.search('${dupe.brand} ${dupe.name}'),
          ),
        ],
      ),
    );
  }
}

class _FragranceGroup extends StatefulWidget {
  const _FragranceGroup({required this.items});

  final List<IngredientLine> items;

  @override
  State<_FragranceGroup> createState() => _FragranceGroupState();
}

class _FragranceGroupState extends State<_FragranceGroup> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final note = widget.items
        .map((item) => item.note)
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => GlowL10n.t('scent_note'));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => open = !open),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.muted.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    GlowL10n.t('tag_listed'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    GlowL10n.t('scent_group', {'n': '${widget.items.length}'}),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
                Icon(
                  open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
          if (open) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 62),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note!, style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.35)),
                  const SizedBox(height: 8),
                  Text(
                    widget.items.map((item) => item.name).join(' · '),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
