import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class GlowPlainFieldImpl extends StatelessWidget {
  const GlowPlainFieldImpl({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.obscure = false,
    this.email = false,
    this.icon,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool obscure;
  final bool email;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
      cursorColor: AppColors.ink,
      style: const TextStyle(color: AppColors.ink, fontSize: 14),
      decoration: InputDecoration(
        icon: icon == null ? null : Icon(icon, color: AppColors.muted),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.midGrayColor, fontSize: 14),
        isDense: true,
        isCollapsed: true,
        filled: true,
        fillColor: AppColors.card,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}
