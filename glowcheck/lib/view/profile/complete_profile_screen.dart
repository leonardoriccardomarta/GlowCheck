import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/your_goal/your_goal_screen.dart';
import 'package:flutter/material.dart';

class CompleteProfileScreen extends StatefulWidget {
  static String routeName = "/CompleteProfileScreen";
  const CompleteProfileScreen({Key? key}) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  String? skinType;
  String? spendBand;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    GlowL10n.t('skin_title'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    GlowL10n.t('skin_sub'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Text(GlowL10n.t('skin_type'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in {
                        'oily': GlowL10n.t('skin_oily'),
                        'dry': GlowL10n.t('skin_dry'),
                        'combination': GlowL10n.t('skin_combination'),
                        'sensitive': GlowL10n.t('skin_sensitive'),
                      }.entries)
                        GlowChip(
                          label: entry.value,
                          selected: skinType == entry.key,
                          onTap: () => setState(() => skinType = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(GlowL10n.t('spend_title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final entry in {
                        'low': GlowL10n.t('spend_low'),
                        'mid': GlowL10n.t('spend_mid'),
                        'high': GlowL10n.t('spend_high'),
                      }.entries)
                        GlowChip(
                          label: entry.value,
                          selected: spendBand == entry.key,
                          onTap: () => setState(() => spendBand = entry.key),
                        ),
                    ],
                  ),
                  const Spacer(),
                  GlowPrimaryButton(
                    title: GlowL10n.t('next'),
                    onPressed: () async {
                      if (skinType == null || spendBand == null) return;
                      await GlowStore.instance.setSkin(skinType!);
                      await GlowStore.instance.setSpend(spendBand!);
                      if (!mounted) return;
                      Navigator.pushNamed(context, YourGoalScreen.routeName);
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
