import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/view/on_boarding/on_boarding_screen.dart';
import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class StartScreen extends StatelessWidget {
  static String routeName = "/StartScreen";

  const StartScreen({Key? key}) : super(key: key);

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
                  Row(
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
                      const Spacer(),
                      const GlowLanguageButton(),
                    ],
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
                            GlowL10n.t('start_title'),
                            style: const TextStyle(
                              color: AppColors.card,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            GlowL10n.t('start_body'),
                            style: TextStyle(
                              color: AppColors.card.withValues(alpha: 0.68),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const Spacer(),
                          _Line(title: GlowL10n.t('start_line1_title'), body: GlowL10n.t('start_line1_body')),
                          const SizedBox(height: 14),
                          _Line(title: GlowL10n.t('start_line2_title'), body: GlowL10n.t('start_line2_body')),
                          const SizedBox(height: 14),
                          _Line(title: GlowL10n.t('start_line3_title'), body: GlowL10n.t('start_line3_body')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlowPrimaryButton(
                    title: GlowL10n.t('start_cta'),
                    onPressed: () {
                      Navigator.pushNamed(context, OnBoardingScreen.routeName);
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
