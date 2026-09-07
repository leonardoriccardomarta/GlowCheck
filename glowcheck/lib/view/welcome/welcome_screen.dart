import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
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
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    GlowL10n.t('welcome_title'),
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700, height: 1.05),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "${GlowStore.skinLabel(store.skinType)}  ·  ${GlowStore.goalLabel(store.mainGoal)}\n${GlowStore.spendLabel(store.spendBand)}",
                    style: const TextStyle(color: AppColors.muted, fontSize: 16, height: 1.45),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    GlowL10n.t('welcome_body'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.45),
                  ),
                  const Spacer(),
                  GlowPrimaryButton(
                    title: GlowL10n.t('welcome_go'),
                    onPressed: () {
                      Navigator.pushNamed(context, DashboardScreen.routeName);
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
