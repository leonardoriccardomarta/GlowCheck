import 'package:flutter/material.dart';

import 'glow_plain_field_io.dart' if (dart.library.js_interop) 'glow_plain_field_web.dart';

class GlowPlainField extends StatelessWidget {
  const GlowPlainField({
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
    return GlowPlainFieldImpl(
      controller: controller,
      hint: hint,
      onChanged: onChanged,
      obscure: obscure,
      email: email,
      icon: icon,
    );
  }
}
