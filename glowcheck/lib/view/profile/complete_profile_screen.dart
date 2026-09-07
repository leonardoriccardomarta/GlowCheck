import 'package:fitnessapp/common_widgets/glow_ui.dart';
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your skin",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.1),
              ),
              const SizedBox(height: 8),
              const Text(
                "Self-reported. The next screen only shows goals that fit this skin type.",
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              const Text("Skin type", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const {
                    'oily': 'Oily',
                    'dry': 'Dry',
                    'combination': 'Combination',
                    'sensitive': 'Sensitive',
                  }.entries)
                    GlowChip(
                      label: entry.value,
                      selected: skinType == entry.key,
                      onTap: () => setState(() => skinType = entry.key),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text("Typical monthly spend", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in const {
                    'low': 'Under \$20',
                    'mid': '\$20 to \$50',
                    'high': '\$50+',
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
                title: "Next",
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
  }
}
