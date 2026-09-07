import 'dart:ui_web' as ui_web;

import 'package:fitnessapp/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class GlowPlainFieldImpl extends StatefulWidget {
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
  State<GlowPlainFieldImpl> createState() => _GlowPlainFieldImplState();
}

class _GlowPlainFieldImplState extends State<GlowPlainFieldImpl> {
  late final String _viewType;
  late final web.HTMLInputElement _input;

  @override
  void initState() {
    super.initState();
    _viewType = 'glow-field-${identityHashCode(this)}';
    _input = web.HTMLInputElement()
      ..type = widget.obscure ? 'password' : (widget.email ? 'email' : 'search')
      ..placeholder = widget.hint
      ..value = widget.controller.text
      ..autocomplete = widget.obscure ? 'current-password' : (widget.email ? 'email' : 'off');
    _input.style
      ..border = 'none'
      ..outline = 'none'
      ..width = '100%'
      ..height = '100%'
      ..backgroundColor = '#ffffff'
      ..fontSize = '14px'
      ..fontFamily = 'Poppins, sans-serif'
      ..color = '#111111'
      ..padding = '0'
      ..margin = '0'
      ..boxSizing = 'border-box'
      ..setProperty('-webkit-appearance', 'none');
    _input.onInput.listen((_) {
      final value = _input.value;
      if (widget.controller.text != value) {
        widget.controller.value = widget.controller.value.copyWith(text: value);
      }
      widget.onChanged?.call(value);
    });
    widget.controller.addListener(_syncFromController);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) => _input);
  }

  void _syncFromController() {
    if (_input.value != widget.controller.text) {
      _input.value = widget.controller.text;
    }
  }

  @override
  void didUpdateWidget(covariant GlowPlainFieldImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _input.placeholder = widget.hint;
    _input.type = widget.obscure ? 'password' : (widget.email ? 'email' : 'search');
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = SizedBox(
      height: 24,
      child: HtmlElementView(viewType: _viewType),
    );
    if (widget.icon == null) return field;
    return Row(
      children: [
        Icon(widget.icon, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: field),
      ],
    );
  }
}
