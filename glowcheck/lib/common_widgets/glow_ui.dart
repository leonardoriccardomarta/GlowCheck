import 'package:fitnessapp/common_widgets/glow_plain_field.dart';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Icon(Icons.search, color: AppColors.muted, size: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: GlowPlainField(
              controller: controller,
              hint: hint,
              onChanged: onChanged,
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
    this.giant = false,
  });

  final String title;
  final VoidCallback onPressed;
  final bool compact;
  final bool light;
  final bool giant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? null : double.infinity,
      height: giant ? 72 : compact ? 40 : 56,
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
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: giant ? 18 : compact ? 13 : 16,
          ),
        ),
      ),
    );
  }
}

class GlowGoogleMark extends StatelessWidget {
  const GlowGoogleMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class GlowAppleMark extends StatelessWidget {
  const GlowAppleMark({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Transform.translate(
        offset: const Offset(0, -0.4),
        child: CustomPaint(painter: _AppleMarkPainter()),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final red = Paint()..color = const Color(0xFFEA4335);

    canvas.drawPath(
      Path()
        ..moveTo(22.56, 12.25)
        ..cubicTo(22.56, 11.47, 22.49, 10.72, 22.36, 10)
        ..lineTo(12, 10)
        ..lineTo(12, 14.26)
        ..lineTo(17.92, 14.26)
        ..cubicTo(17.66, 15.63, 16.88, 16.79, 15.71, 17.57)
        ..lineTo(15.71, 20.34)
        ..lineTo(19.28, 20.34)
        ..cubicTo(21.36, 18.42, 22.56, 15.6, 22.56, 12.25)
        ..close(),
      blue,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 23)
        ..cubicTo(14.97, 23, 17.46, 22.02, 19.28, 20.34)
        ..lineTo(15.71, 17.57)
        ..cubicTo(14.73, 18.23, 13.48, 18.63, 12, 18.63)
        ..cubicTo(9.14, 18.63, 6.71, 16.7, 5.84, 14.1)
        ..lineTo(2.18, 14.1)
        ..lineTo(2.18, 16.94)
        ..cubicTo(3.99, 20.53, 7.7, 23, 12, 23)
        ..close(),
      green,
    );
    canvas.drawPath(
      Path()
        ..moveTo(5.84, 14.09)
        ..cubicTo(5.62, 13.43, 5.49, 12.73, 5.49, 12)
        ..cubicTo(5.49, 11.27, 5.62, 10.57, 5.84, 9.91)
        ..lineTo(5.84, 7.07)
        ..lineTo(2.18, 7.07)
        ..cubicTo(1.43, 8.55, 1, 10.22, 1, 12)
        ..cubicTo(1, 13.78, 1.43, 15.45, 2.18, 16.93)
        ..lineTo(5.03, 14.71)
        ..lineTo(5.84, 14.09)
        ..close(),
      yellow,
    );
    canvas.drawPath(
      Path()
        ..moveTo(12, 5.38)
        ..cubicTo(13.62, 5.38, 15.06, 5.94, 16.21, 7.02)
        ..lineTo(19.36, 3.87)
        ..cubicTo(17.45, 2.09, 14.97, 1, 12, 1)
        ..cubicTo(7.7, 1, 3.99, 3.47, 2.18, 7.07)
        ..lineTo(5.84, 9.91)
        ..cubicTo(6.71, 7.31, 9.14, 5.38, 12, 5.38)
        ..close(),
      red,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;

    final body = Path()
      ..moveTo(16.365, 12.23)
      ..relativeCubicTo(-0.016, -2.764, 2.251, -4.091, 2.351, -4.156)
      ..relativeCubicTo(-1.281, -1.873, -3.275, -2.131, -3.985, -2.16)
      ..relativeCubicTo(-1.697, -0.172, -3.313, 1, -4.175, 1)
      ..relativeCubicTo(-0.862, 0, -2.197, -0.975, -3.614, -0.948)
      ..relativeCubicTo(-1.86, 0.029, -3.57, 1.08, -4.524, 2.743)
      ..relativeCubicTo(-1.93, 3.345, -0.494, 8.296, 1.386, 11.01)
      ..relativeCubicTo(0.917, 1.338, 2.01, 2.84, 3.443, 2.786)
      ..relativeCubicTo(1.381, -0.056, 1.904, -0.893, 3.576, -0.893)
      ..relativeCubicTo(1.672, 0, 2.145, 0.893, 3.614, 0.864)
      ..relativeCubicTo(1.495, -0.025, 2.443, -1.364, 3.358, -2.705)
      ..relativeCubicTo(1.059, -1.548, 1.495, -3.048, 1.52, -3.126)
      ..relativeCubicTo(-0.033, -0.015, -2.916, -1.119, -2.95, -4.445)
      ..close();

    final leaf = Path()
      ..moveTo(13.597, 4.068)
      ..relativeCubicTo(0.76, -0.921, 1.272, -2.201, 1.132, -3.475)
      ..relativeCubicTo(-1.093, 0.044, -2.415, 0.73, -3.2, 1.647)
      ..relativeCubicTo(-0.704, 0.818, -1.32, 2.124, -1.154, 3.378)
      ..relativeCubicTo(1.221, 0.095, 2.47, -0.622, 3.222, -1.55)
      ..close();

    canvas.drawPath(body, paint);
    canvas.drawPath(leaf, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
