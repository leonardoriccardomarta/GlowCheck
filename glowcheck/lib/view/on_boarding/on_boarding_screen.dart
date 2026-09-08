import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatefulWidget {
  static String routeName = "/OnBoardingScreen";
  const OnBoardingScreen({Key? key}) : super(key: key);

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final _pages = PageController();
  int step = 0;
  String? skin;
  String? goal;

  static const _skins = [
    (id: 'oily', icon: Icons.opacity_rounded, title: 'skin_oily', sub: 'quiz_skin_oily_sub'),
    (id: 'dry', icon: Icons.air_rounded, title: 'skin_dry', sub: 'quiz_skin_dry_sub'),
    (id: 'combination', icon: Icons.tonality_rounded, title: 'skin_combination', sub: 'quiz_skin_mix_sub'),
    (id: 'sensitive', icon: Icons.favorite_border_rounded, title: 'skin_sensitive', sub: 'quiz_skin_sens_sub'),
  ];

  static const _goals = [
    (id: 'pores', icon: Icons.blur_on_rounded, title: 'quiz_goal_pores'),
    (id: 'hydration', icon: Icons.water_drop_outlined, title: 'quiz_goal_hydration'),
    (id: 'budget', icon: Icons.sell_outlined, title: 'quiz_goal_dupe'),
  ];

  Future<void> _go(int next) async {
    setState(() => step = next);
    await _pages.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickSkin(String id) async {
    setState(() => skin = id);
    await GlowStore.instance.setSkin(id);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    await _go(1);
  }

  Future<void> _pickGoal(String id) async {
    setState(() => goal = id);
    await GlowStore.instance.finishQuiz(skin: skin!, goal: id);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    setState(() => step = 2);
  }

  void _launch() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const DashboardScreen(initialTab: 2),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
        if (step == 2) {
          return Scaffold(
            backgroundColor: AppColors.ink,
            body: _CalibratePage(onDone: _launch),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                  child: Row(
                    children: [
                      Text(
                        '${step + 1} / 2',
                        style: TextStyle(
                          color: step == 2 ? Colors.transparent : AppColors.muted,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (step < 2) const GlowLanguageMini(),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pages,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _ChoicePage(
                        title: GlowL10n.t('quiz_skin_title'),
                        children: [
                          for (final item in _skins)
                            _QuizCard(
                              selected: skin == item.id,
                              icon: item.icon,
                              title: GlowL10n.t(item.title),
                              subtitle: GlowL10n.t(item.sub),
                              onTap: () => _pickSkin(item.id),
                            ),
                        ],
                      ),
                      _ChoicePage(
                        title: GlowL10n.t('quiz_goal_title'),
                        children: [
                          for (final item in _goals)
                            _QuizCard(
                              selected: goal == item.id,
                              icon: item.icon,
                              title: GlowL10n.t(item.title),
                              onTap: () => _pickGoal(item.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class GlowLanguageMini extends StatelessWidget {
  const GlowLanguageMini({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => GlowL10n.pick(context),
      child: Text(
        GlowL10n.currentLang().nativeName,
        style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ChoicePage extends StatelessWidget {
  const _ChoicePage({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1),
        ),
        const SizedBox(height: 22),
        ...[
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            children[i],
          ],
        ],
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? AppColors.neon : const Color(0xFFEFEBE4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 28, color: AppColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected ? AppColors.card : AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: selected ? AppColors.card.withValues(alpha: 0.72) : AppColors.muted,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
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

class _CalibratePage extends StatefulWidget {
  const _CalibratePage({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_CalibratePage> createState() => _CalibratePageState();
}

class _CalibratePageState extends State<_CalibratePage> with SingleTickerProviderStateMixin {
  late final AnimationController _bar;
  int line = 0;

  @override
  void initState() {
    super.initState();
    _bar = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..forward();
    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => line = 1);
    });
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => line = 2);
    });
    Future<void>.delayed(const Duration(milliseconds: 2500), widget.onDone);
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = [
      GlowL10n.t('quiz_load_1'),
      GlowL10n.t('quiz_load_2'),
      GlowL10n.t('quiz_load_3'),
    ];
    return SizedBox.expand(
      child: ColoredBox(
      color: AppColors.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Text(
              GlowL10n.t('quiz_load_title', {
                'skin': GlowStore.skinLabel(GlowStore.instance.skinType),
              }),
              style: const TextStyle(
                color: AppColors.card,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 28),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: AnimatedBuilder(
                animation: _bar,
                builder: (context, _) {
                  return LinearProgressIndicator(
                    value: _bar.value,
                    minHeight: 10,
                    backgroundColor: const Color(0xFF2A2A2A),
                    color: AppColors.neon,
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                messages[line],
                key: ValueKey(line),
                style: TextStyle(
                  color: AppColors.card.withValues(alpha: 0.78),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
      ),
    );
  }
}
