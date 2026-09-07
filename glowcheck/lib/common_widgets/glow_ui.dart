import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class GlowSearchBar extends StatelessWidget {
  const GlowSearchBar({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onFilter,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(GlowStyle.radiusPill),
        boxShadow: GlowStyle.soft,
      ),
      padding: const EdgeInsets.only(left: 18, right: 6),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.muted, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.midGrayColor, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Material(
            color: AppColors.ink,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onFilter,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.tune, color: AppColors.card, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GlowChip extends StatelessWidget {
  const GlowChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.ink : AppColors.card,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.card : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlowCircleButton extends StatelessWidget {
  const GlowCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: dark ? AppColors.ink : AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: dark ? AppColors.card : AppColors.ink),
        ),
      ),
    );
  }
}

class GlowInitials extends StatelessWidget {
  const GlowInitials({
    super.key,
    required this.label,
    this.size = 56,
    this.dark = true,
  });

  final String label;
  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final initials = label
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? AppColors.ink : const Color(0xFFE8E4DC),
        borderRadius: BorderRadius.circular(size / 2.4),
      ),
      child: Text(
        initials.isEmpty ? 'GC' : initials,
        style: TextStyle(
          color: dark ? AppColors.card : AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.28,
        ),
      ),
    );
  }
}

class GlowPrimaryButton extends StatelessWidget {
  const GlowPrimaryButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.compact = false,
    this.light = false,
  });

  final String title;
  final VoidCallback onPressed;
  final bool compact;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : double.infinity,
      height: compact ? 40 : 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: light ? AppColors.card : AppColors.ink,
          foregroundColor: light ? AppColors.ink : AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlowStyle.radiusPill),
          ),
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13 : 16,
          ),
        ),
      ),
    );
  }
}
