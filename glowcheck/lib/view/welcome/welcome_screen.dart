import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  static String routeName = "/WelcomeScreen";

  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final store = GlowStore.instance;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text(
                "You're set.",
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.05),
              ),
              const SizedBox(height: 12),
              Text(
                "${GlowStore.skinLabel(store.skinType)} skin  ·  ${GlowStore.goalLabel(store.mainGoal)}\n${GlowStore.spendLabel(store.spendBand)}",
                style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 20),
              const Text(
                "Photograph an INCI list. First readable scan is free. The score is only vs this profile, not medical advice.",
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.45),
              ),
              const Spacer(),
              GlowPrimaryButton(
                title: "Go to home",
                onPressed: () {
                  Navigator.pushNamed(context, DashboardScreen.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
