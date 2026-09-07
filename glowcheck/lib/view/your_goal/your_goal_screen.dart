import 'package:fitnessapp/common_widgets/glow_ui.dart';
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
      return const [
        (
          id: 'pores',
          title: 'Less clogging feel',
          subtitle: 'Best match for oily. We flag heavy, occlusive textures first.',
          icon: Icons.blur_on_rounded,
        ),
        (
          id: 'budget',
          title: 'Drugstore swaps',
          subtitle: 'Same oily flags, plus a cheaper option when we have one.',
          icon: Icons.sell_outlined,
        ),
        (
          id: 'hydration',
          title: 'Hydration',
          subtitle: 'Only if the skin feels tight. We still skip heavy creams.',
          icon: Icons.water_drop_outlined,
        ),
      ];
    }
    if (skin == 'dry') {
      return const [
        (
          id: 'hydration',
          title: 'Hydration',
          subtitle: 'Best match for dry. Humectants and moisture first.',
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'budget',
          title: 'Drugstore swaps',
          subtitle: 'Hydration first, plus a cheaper option when we have one.',
          icon: Icons.sell_outlined,
        ),
        (
          id: 'pores',
          title: 'Less clogging feel',
          subtitle: 'Unusual for dry skin. Use only if a product feels too heavy.',
          icon: Icons.blur_on_rounded,
        ),
      ];
    }
    if (skin == 'sensitive') {
      return const [
        (
          id: 'hydration',
          title: 'Hydration',
          subtitle: 'Best starting point. We watch fragrance and harsh alcohol.',
          icon: Icons.water_drop_outlined,
        ),
        (
          id: 'pores',
          title: 'Less clogging feel',
          subtitle: 'Texture plus fragrance. Still not a medical allergy test.',
          icon: Icons.blur_on_rounded,
        ),
        (
          id: 'budget',
          title: 'Drugstore swaps',
          subtitle: 'Sensitive flags, plus a cheaper option when we have one.',
          icon: Icons.sell_outlined,
        ),
      ];
    }
    return const [
      (
        id: 'pores',
        title: 'Less clogging feel',
        subtitle: 'Good default for combination. Heavy textures first.',
        icon: Icons.blur_on_rounded,
      ),
      (
        id: 'hydration',
        title: 'Hydration',
        subtitle: 'If the dry zones bother you more than shine.',
        icon: Icons.water_drop_outlined,
      ),
      (
        id: 'budget',
        title: 'Drugstore swaps',
        subtitle: 'When we have one, show a cheaper verified option.',
        icon: Icons.sell_outlined,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
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
                "For ${GlowStore.skinLabel(skin).toLowerCase()} skin",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
              ),
              const SizedBox(height: 8),
              const Text(
                "We already picked the goal that usually fits. Change it only if you know why.",
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
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
                                              "Fits",
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
                title: "Confirm",
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
  }
}
