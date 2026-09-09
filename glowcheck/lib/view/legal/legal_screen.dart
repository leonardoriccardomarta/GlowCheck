import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LegalScreen extends StatelessWidget {
  static const termsRoute = '/LegalTerms';
  static const privacyRoute = '/LegalPrivacy';

  const LegalScreen({Key? key, required this.privacy}) : super(key: key);

  final bool privacy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    GlowL10n.t(privacy ? 'privacy_title' : 'terms_title'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              GlowL10n.t(privacy ? 'privacy_body' : 'terms_body'),
              style: const TextStyle(color: AppColors.inkSoft, fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
