import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/on_boarding/widgets/pager_widget.dart';
import 'package:fitnessapp/view/profile/complete_profile_screen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatefulWidget {
  static String routeName = "/OnBoardingScreen";
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final pageController = PageController();
  int selectedIndex = 0;

  List<OnboardPage> get pages => [
    OnboardPage(
      kicker: GlowL10n.t('onb1_kicker'),
      title: GlowL10n.t('onb1_title'),
      subtitle: GlowL10n.t('onb1_sub'),
      icon: Icons.document_scanner_outlined,
      chips: [GlowL10n.t('onb1_c1'), GlowL10n.t('onb1_c2'), GlowL10n.t('onb1_c3')],
    ),
    OnboardPage(
      kicker: GlowL10n.t('onb2_kicker'),
      title: GlowL10n.t('onb2_title'),
      subtitle: GlowL10n.t('onb2_sub'),
      icon: Icons.radio_button_checked,
      chips: [GlowL10n.t('onb2_c1'), GlowL10n.t('onb2_c2'), GlowL10n.t('onb2_c3')],
    ),
    OnboardPage(
      kicker: GlowL10n.t('onb3_kicker'),
      title: GlowL10n.t('onb3_title'),
      subtitle: GlowL10n.t('onb3_sub'),
      icon: Icons.science_outlined,
      chips: [GlowL10n.t('onb3_c1'), GlowL10n.t('onb3_c2'), GlowL10n.t('onb3_c3')],
    ),
    OnboardPage(
      kicker: GlowL10n.t('onb4_kicker'),
      title: GlowL10n.t('onb4_title'),
      subtitle: GlowL10n.t('onb4_sub'),
      icon: Icons.grid_view_rounded,
      chips: [GlowL10n.t('onb4_c1'), GlowL10n.t('onb4_c2'), GlowL10n.t('onb4_c3')],
    ),
  ];

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (selectedIndex < pages.length - 1) {
      pageController.animateToPage(
        selectedIndex + 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    Navigator.pushNamed(context, CompleteProfileScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final last = selectedIndex == pages.length - 1;

    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 10, 0),
              child: Row(
                children: [
                  Text(
                    "${selectedIndex + 1} / ${pages.length}",
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, CompleteProfileScreen.routeName);
                    },
                    child: Text(
                      GlowL10n.t('onb_skip'),
                      style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => selectedIndex = i),
                itemBuilder: (context, index) => PagerWidget(page: pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          height: 6,
                          width: i == selectedIndex ? 22 : 6,
                          decoration: BoxDecoration(
                            color: i == selectedIndex ? AppColors.ink : const Color(0xFFD8D4CE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlowPrimaryButton(
                    title: last ? GlowL10n.t('onb_set_skin') : GlowL10n.t('onb_continue'),
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
