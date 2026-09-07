import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';

class OnboardPage {
  const OnboardPage({
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.chips,
  });

  final String kicker;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> chips;
}

class PagerWidget extends StatelessWidget {
  const PagerWidget({Key? key, required this.page}) : super(key: key);

  final OnboardPage page;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      children: [
        Container(
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(32),
            boxShadow: GlowStyle.soft,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -18,
                child: Icon(
                  page.icon,
                  size: 180,
                  color: AppColors.card.withValues(alpha: 0.06),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      page.kicker,
                      style: TextStyle(
                        color: AppColors.card.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Icon(page.icon, size: 36, color: AppColors.card),
                    const SizedBox(height: 14),
                    Text(
                      page.title,
                      style: const TextStyle(
                        color: AppColors.card,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          page.subtitle,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in page.chips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chip,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
