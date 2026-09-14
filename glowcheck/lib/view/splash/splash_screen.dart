import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/on_boarding/on_boarding_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/SplashScreen";
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    Future<void>.delayed(const Duration(milliseconds: 1400), _go);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  void _go() {
    if (!mounted) return;
    final store = GlowStore.instance;
    final Widget next;
    if (!store.hasProfile) {
      next = const OnBoardingScreen();
    } else {
      next = const DashboardScreen();
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => next,
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GlowCheck',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.neon,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_camera_rounded, color: AppColors.ink, size: 26),
              ),
              const SizedBox(height: 22),
              Text(
                GlowL10n.t('start_title'),
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.08,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                GlowL10n.t('splash_tag'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 16,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _motion,
                builder: (context, _) {
                  return Row(
                    children: List.generate(3, (i) {
                      final t = (_motion.value + i / 3) % 1;
                      final active = t < 0.45;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: active ? 18 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.ink : AppColors.line,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
