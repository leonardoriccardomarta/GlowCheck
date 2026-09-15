import 'package:fitnessapp/common_widgets/glow_ui.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/services/glow_web_nav.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

Future<void> showGlowInstallHint(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (context) => const GlowInstallHintSheet(),
  );
}

class GlowInstallHintSheet extends StatelessWidget {
  const GlowInstallHintSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final ios = isIosWeb();
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + (bottom > 0 ? bottom : 8)),
      decoration: const BoxDecoration(
        color: Color(0xFFF3F1ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E2DC),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.neon,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ios ? Icons.ios_share_rounded : Icons.add_to_home_screen_rounded,
              color: AppColors.ink,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            GlowL10n.t('install_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            GlowL10n.t(ios ? 'install_ios' : 'install_android'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          GlowPrimaryButton(
            title: GlowL10n.t('install_ok'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
