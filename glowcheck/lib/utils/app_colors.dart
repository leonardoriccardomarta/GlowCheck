import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF111111);
  static const inkSoft = Color(0xFF1C1C1C);
  static const canvas = Color(0xFFF3F1ED);
  static const card = Color(0xFFFFFFFF);
  static const muted = Color(0xFF6F6A67);
  static const line = Color(0xFFE6E2DC);
  static const neon = Color(0xFF00E676);
  static const amberHot = Color(0xFFFF9100);
  static const vividRed = Color(0xFFFF1744);
  static const star = amberHot;
  static const good = Color(0xFF00C853);
  static const caution = vividRed;

  static const primaryColor1 = ink;
  static const primaryColor2 = Color(0xFF2A2A2A);
  static const secondaryColor1 = ink;
  static const secondaryColor2 = Color(0xFF3A3A3A);

  static const whiteColor = card;
  static const blackColor = ink;
  static const grayColor = muted;
  static const lightGrayColor = canvas;
  static const midGrayColor = Color(0xFF9A9590);

  static List<Color> get primaryG => const [ink, Color(0xFF2C2C2C)];
  static List<Color> get secondaryG => const [inkSoft, Color(0xFF333333)];

  static Color scoreColor(int score) {
    if (score >= 80) return neon;
    if (score >= 60) return amberHot;
    return vividRed;
  }

  static Color tagColor(String tag) {
    switch (tag) {
      case 'watch':
        return vividRed;
      case 'fit':
        return neon;
      default:
        return muted;
    }
  }
}

class GlowStyle {
  static const radiusCard = 28.0;
  static const radiusPill = 40.0;

  static List<BoxShadow> get soft => const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ];

  static List<BoxShadow> get dock => const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 28,
          offset: Offset(0, 12),
        ),
      ];
}
