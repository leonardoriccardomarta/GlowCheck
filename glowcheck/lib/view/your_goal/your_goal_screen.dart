import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';

class YourGoalScreen extends StatefulWidget {
  static String routeName = "/YourGoalScreen";

  const YourGoalScreen({Key? key}) : super(key: key);

  @override
  State<YourGoalScreen> createState() => _YourGoalScreenState();
}

class _YourGoalScreenState extends State<YourGoalScreen> {
  late String selectedId;

  @override
  void initState() {
    super.initState();
    selectedId = GlowStore.recommendedGoal(GlowStore.instance.skinType);
  }

  List<({String id, String title, String subtitle, IconData icon})> get goals {
    final skin = GlowStore.instance.skinType;
    if (skin == 'oily') {
      return [
        (
          id: 'pores',
          title: GlowL10n.t('goal_pores'),
          subtitle: GlowL10n.t('goal_pores_oily'),
          icon: Icons.blur_on_rounded,
        ),
        (
          id: 'budget',
          title: GlowL10n.t('goal_budget'),
          subtitle: GlowL10n.t('goal_budget_oily'),
          icon: Icons.sell_outlined,
        ),
        (
          id: 'hydration',
          title: GlowL10n.t('goal_hydration'),
          subtitle: GlowL10n.t('goal_hydration_oily'),
          icon: Icons.water_drop_outlined,
        ),
      ];
    }
    if (skin == 'dry') {
      return [
        (
          id: 'hydration',
          title: GlowL10n.t('goal_hydration'),
          subtitle: GlowL10n.t('goal_hydration_dry'),
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'budget',
          title: GlowL10n.t('goal_budget'),
          subtitle: GlowL10n.t('goal_budget_dry'),
          icon: Icons.sell_outlined,
        ),
        (
          id: 'pores',
          title: GlowL10n.t('goal_pores'),
          subtitle: GlowL10n.t('goal_pores_dry'),
          icon: Icons.blur_on_rounded,
        ),
      ];
    }
    if (skin == 'sensitive') {
      return [
        (
          id: 'hydration',
          title: GlowL10n.t('goal_hydration'),
          subtitle: GlowL10n.t('goal_hydration_sensitive'),
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'pores',
          title: GlowL10n.t('goal_pores'),
          subtitle: GlowL10n.t('goal_pores_sensitive'),
          icon: Icons.blur_on_rounded,
        ),
        (
          id: 'budget',
          title: GlowL10n.t('goal_budget'),
          subtitle: GlowL10n.t('goal_budget_sensitive'),
          icon: Icons.sell_outlined,
        ),
      ];
    }
    return [
      (
        id: 'pores',
        title: GlowL10n.t('goal_pores'),
        subtitle: GlowL10n.t('goal_pores_combo'),
        icon: Icons.blur_on_rounded,
      ),
      (
        id: 'hydration',
        title: GlowL10n.t('goal_hydration'),
        subtitle: GlowL10n.t('goal_hydration_combo'),
        icon: Icons.water_drop_outlined,
      ),
      (
        id: 'budget',
        title: GlowL10n.t('goal_budget'),
        subtitle: GlowL10n.t('goal_budget_combo'),
        icon: Icons.sell_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
        final skin = GlowStore.instance.skinType;
        final note = GlowStore.comboNote(skin, selectedId);
        final list = goals;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GlowL10n.t('goal_for_skin', {'skin': GlowStore.skinLabel(skin).toLowerCase()}),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GlowL10n.t('goal_sub'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final goal = list[i];
                        final selected = selectedId == goal.id;
                        final recommended = GlowStore.isRecommendedGoal(skin, goal.id);
                        return Material(
                          color: selected ? AppColors.ink : AppColors.card,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: () => setState(() => selectedId = goal.id),
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Icon(
                                    goal.icon,
                                    color: selected ? AppColors.card : AppColors.ink,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                goal.title,
                                                style: TextStyle(
                                                  color: selected ? AppColors.card : AppColors.ink,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            if (recommended)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: selected
                                                      ? AppColors.card.withValues(alpha: 0.16)
                                                      : AppColors.ink,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  GlowL10n.t('goal_fits'),
                                                  style: TextStyle(
                                                    color: selected ? AppColors.card : AppColors.card,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          goal.subtitle,
                                          style: TextStyle(
                                            color: selected
                                                ? AppColors.card.withValues(alpha: 0.7)
                                                : AppColors.muted,
                                            fontSize: 13,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (note != null) ...[
                    Text(note, style: const TextStyle(color: AppColors.caution, fontSize: 12, height: 1.4)),
                    const SizedBox(height: 10),
                  ],
                  GlowPrimaryButton(
                    title: GlowL10n.t('goal_confirm'),
                    onPressed: () async {
                      await GlowStore.instance.setGoal(selectedId);
                      if (!mounted) return;
                      Navigator.pushNamed(context, WelcomeScreen.routeName);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
