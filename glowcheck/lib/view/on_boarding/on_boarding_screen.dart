import 'package:fitnessapp/common_widgets/glow_ui.dart';
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

  final pages = const [
    OnboardPage(
      kicker: "01  Scan",
      title: "Photograph the INCI list",
      subtitle:
          "Shoot the back of the bottle. We read Aqua, Glycerin and the full formula. No barcode catalog required.",
      icon: Icons.document_scanner_outlined,
      chips: ["Full INCI", "No barcode needed", "Unreadable stays free"],
    ),
    OnboardPage(
      kicker: "02  Score",
      title: "A match vs your skin",
      subtitle:
          "Same formula can score differently on oily and dry skin. The number is only vs the profile you set.",
      icon: Icons.radio_button_checked,
      chips: ["0 to 100", "Your skin type", "Your goal first"],
    ),
    OnboardPage(
      kicker: "03  Ingredients",
      title: "Watch, Fit, Listed",
      subtitle:
          "Every readable ingredient is tagged for your goal. First successful scan is free.",
      icon: Icons.science_outlined,
      chips: ["Watch", "Fit", "Listed"],
    ),
    OnboardPage(
      kicker: "04  Shelf",
      title: "Keep every bottle",
      subtitle:
          "Save scans, pin the ones you like, come back when you buy something new.",
      icon: Icons.grid_view_rounded,
      chips: ["History", "Pin favorites", "Drugstore swap if we have one"],
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

    return Scaffold(
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
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
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
                    title: last ? "Set your skin" : "Continue",
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
