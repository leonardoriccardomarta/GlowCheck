import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

enum RoundButtonType { primaryBG, secondaryBG }

class RoundButton extends StatelessWidget {
  final String title;
  final RoundButtonType type;
  final Function() onPressed;

  const RoundButton({
    Key? key,
    required this.title,
    required this.onPressed,
    this.type = RoundButtonType.secondaryBG,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final filled = type == RoundButtonType.secondaryBG || type == RoundButtonType.primaryBG;
    return Material(
      color: filled ? AppColors.ink : AppColors.card,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: filled ? AppColors.card : AppColors.ink,
              fontFamily: "Poppins",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
