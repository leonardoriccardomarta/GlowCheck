import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/services/glow_auth.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/on_boarding/start_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = "/LoginScreen";
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool register = false;
  String? error;
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!mounted) return;
    final next = GlowStore.instance.hasProfile
        ? const DashboardScreen()
        : const StartScreen();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => next),
      (route) => false,
    );
  }

  Future<void> _email() async {
    setState(() => error = null);
    try {
      if (register) {
        if (name.text.trim().isEmpty || email.text.trim().isEmpty || password.text.length < 6) {
          setState(() => error = GlowL10n.t('login_fields'));
          return;
        }
        await GlowAuth.register(
          name: name.text,
          email: email.text,
          password: password.text,
        );
      } else {
        await GlowAuth.loginEmail(email: email.text, password: password.text);
      }
      await _finish();
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _social(String provider) async {
    setState(() => error = null);
    await GlowAuth.social(provider);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) => Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Row(
              children: [
                const Text(
                  "GlowCheck",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.6),
                ),
                const Spacer(),
                const GlowLanguageButton(),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              register ? GlowL10n.t('login_create') : GlowL10n.t('login_welcome'),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1),
            ),
            const SizedBox(height: 8),
            Text(
              GlowL10n.t('login_note'),
              style: const TextStyle(color: AppColors.muted, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            _SocialButton(
              label: GlowL10n.t('login_google'),
              icon: Icons.g_mobiledata,
              onTap: () => _social('google'),
            ),
            const SizedBox(height: 10),
            _SocialButton(
              label: GlowL10n.t('login_apple'),
              icon: Icons.apple,
              onTap: () => _social('apple'),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.line)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(GlowL10n.t('login_or_email'), style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ),
                const Expanded(child: Divider(color: AppColors.line)),
              ],
            ),
            const SizedBox(height: 18),
            if (register) ...[
              _Field(controller: name, hint: GlowL10n.t('login_name'), icon: Icons.person_outline),
              const SizedBox(height: 10),
            ],
            _Field(controller: email, hint: GlowL10n.t('login_email'), icon: Icons.mail_outline, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 10),
            _Field(controller: password, hint: GlowL10n.t('login_password'), icon: Icons.lock_outline, obscure: true),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: const TextStyle(color: AppColors.caution, fontSize: 13)),
            ],
            const SizedBox(height: 18),
            GlowPrimaryButton(
              title: register ? GlowL10n.t('login_create_btn') : GlowL10n.t('login_btn'),
              onPressed: _email,
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => setState(() {
                register = !register;
                error = null;
              }),
              child: Text(
                register ? GlowL10n.t('login_have_account') : GlowL10n.t('login_new_here'),
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.obscure = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppColors.muted),
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.midGrayColor),
          filled: true,
          fillColor: AppColors.card,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}
