import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/view/on_boarding/on_boarding_screen.dart';
import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class StartScreen extends StatelessWidget {
  static String routeName = "/StartScreen";

  const StartScreen({Key? key}) : super(key: key);

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
                "GLOWCHECK",
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: GlowStyle.soft,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Your bottle.\nYour skin.",
                        style: const TextStyle(
                          color: AppColors.card,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Photograph an INCI list. Get a match score vs the profile you set.",
                        style: TextStyle(
                          color: AppColors.card.withValues(alpha: 0.68),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const Spacer(),
                      const _Line(title: "Read the full list", body: "Aqua, Glycerin and the rest. No barcode catalog."),
                      const SizedBox(height: 14),
                      const _Line(title: "Score vs you", body: "Oily and dry can split the same formula."),
                      const SizedBox(height: 14),
                      const _Line(title: "Watch, Fit, Listed", body: "Every readable ingredient tagged for your goal."),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GlowPrimaryButton(
                title: "Get started",
                onPressed: () {
                  Navigator.pushNamed(context, OnBoardingScreen.routeName);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.card, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 2),
        Text(body, style: TextStyle(color: AppColors.card.withValues(alpha: 0.62), fontSize: 13, height: 1.35)),
      ],
    );
  }
}
