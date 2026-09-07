import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:fitnessapp/view/on_boarding/start_screen.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({Key? key}) : super(key: key);

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  @override
  void initState() {
    super.initState();
    GlowStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    GlowStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = GlowStore.instance;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
          children: [
            const Text(
              "Profile",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                children: [
                  GlowInitials(
                    label: store.accountName ?? GlowStore.skinLabel(store.skinType),
                    size: 54,
                    dark: false,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.accountName ?? "Your account",
                          style: const TextStyle(color: AppColors.card, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          store.accountEmail ?? "Not signed in",
                          style: TextStyle(color: AppColors.card.withValues(alpha: 0.65), fontSize: 12),
                        ),
                        Text(
                          "Signed in with ${GlowStore.providerLabel(store.accountProvider)}",
                          style: TextStyle(color: AppColors.card.withValues(alpha: 0.55), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(28),
                boxShadow: GlowStyle.soft,
              ),
              child: Row(
                children: [
                  GlowInitials(label: GlowStore.skinLabel(store.skinType), size: 58),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          GlowStore.skinLabel(store.skinType),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          GlowStore.goalLabel(store.mainGoal),
                          style: const TextStyle(color: AppColors.muted, fontSize: 13),
                        ),
                        Text(
                          GlowStore.spendLabel(store.spendBand),
                          style: const TextStyle(color: AppColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GlowPrimaryButton(
                    title: "Edit",
                    compact: true,
                    onPressed: () async {
                      await GlowStore.instance.resetQuiz();
                      if (!mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const StartScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(title: store.planLabel, label: "Plan"),
                const SizedBox(width: 10),
                _Stat(title: "${store.history.length}", label: "Scans"),
                const SizedBox(width: 10),
                _Stat(
                  title: store.isPro ? "Unlimited" : "${store.freeScansRemaining}",
                  label: store.isPro ? "Scans" : "Free left",
                ),
              ],
            ),
            const SizedBox(height: 22),
            _MenuCard(
              children: [
                if (!store.isPro)
                  _MenuRow(
                    icon: Icons.workspace_premium_outlined,
                    title: "Unlock GlowCheck Pro",
                    onTap: () => Navigator.pushNamed(context, PaywallScreen.routeName),
                  ),
                _MenuRow(
                  icon: Icons.replay_rounded,
                  title: "Retake skin quiz",
                  onTap: () async {
                    await GlowStore.instance.resetQuiz();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const StartScreen()),
                      (route) => false,
                    );
                  },
                ),
                _MenuRow(
                  icon: Icons.grid_view_rounded,
                  title: "Saved bottles",
                  onTap: () => DashboardScope.of(context)?.goTab(1),
                ),
                _MenuRow(
                  icon: Icons.photo_camera_outlined,
                  title: "New scan",
                  onTap: () => DashboardScope.of(context)?.goTab(2),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MenuCard(
              children: [
                _MenuRow(
                  icon: Icons.logout_rounded,
                  title: "Sign out",
                  onTap: () async {
                    await GlowStore.instance.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
                _MenuRow(
                  icon: Icons.info_outline,
                  title: "Not medical advice",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('GlowCheck matches INCI to the profile you set. It is not a diagnosis.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.title, required this.label});

  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.ink),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
    );
  }
}
