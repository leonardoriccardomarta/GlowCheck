import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  static const routeName = '/LanguageScreen';

  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
        final current = GlowL10n.currentCode;
        return Scaffold(
          backgroundColor: AppColors.canvas,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
              children: [
                Row(
                  children: [
                    GlowCircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      GlowL10n.t('language_title'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    GlowL10n.t('language_hint'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      for (final lang in GlowL10n.supported)
                        ListTile(
                          title: Text(
                            lang.nativeName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: current == lang.code
                              ? const Icon(Icons.check_rounded)
                              : null,
                          onTap: () async {
                            await GlowStore.instance.setLocale(lang.code);
                            if (context.mounted) Navigator.pop(context);
                          },
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
