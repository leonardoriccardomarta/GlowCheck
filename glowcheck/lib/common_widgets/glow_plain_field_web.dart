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

class _GlowPlainFieldImplState extends State<GlowPlainFieldImpl>
    with WidgetsBindingObserver {
  final GlobalKey _boxKey = GlobalKey();
  late final String _id;
  late final web.HTMLInputElement _input;

  @override
  void initState() {
    super.initState();
    _id = 'glow-field-${identityHashCode(this)}';
    _input = web.HTMLInputElement()
      ..id = _id
      ..className = 'glow-html-input';
    _applyAttrs();
    _input.value = widget.controller.text;
    _input.style
      ..position = 'fixed'
      ..zIndex = '2147483646'
      ..border = 'none'
      ..outline = 'none'
      ..margin = '0'
      ..padding = '0'
      ..backgroundColor = '#ffffff'
      ..color = '#111111'
      ..fontSize = '14px'
      ..lineHeight = '20px'
      ..fontFamily = 'Poppins, sans-serif'
      ..fontWeight = '400'
      ..boxSizing = 'border-box'
      ..visibility = 'hidden';
    _input.style.setProperty('-webkit-appearance', 'none');
    _input.style.setProperty('appearance', 'none');
    _input.style.setProperty('pointer-events', 'auto');
    _input.style.setProperty('transform', 'translateZ(0)');
    _input.onInput.listen((_) {
      final value = _input.value;
      if (widget.controller.text != value) {
        widget.controller.value = TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        );
      }
      widget.onChanged?.call(value);
    });
    widget.controller.addListener(_syncFromController);
    final layer = web.document.querySelector('#glow-html-layer');
    (layer ?? web.document.body)?.appendChild(_input);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _applyAttrs() {
    _input
      ..type = widget.obscure ? 'password' : (widget.email ? 'email' : 'text')
      ..placeholder = widget.hint
      ..autocomplete = widget.obscure
          ? 'current-password'
          : (widget.email ? 'email' : 'off')
      ..spellcheck = false;
    _input.inputMode = widget.email ? 'email' : 'text';
  }

  void _syncFromController() {
    if (_input.value != widget.controller.text) {
      _input.value = widget.controller.text;
    }
  }

  void _onFrame(Duration _) {
    if (!mounted) return;
    _syncPosition();
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  void didChangeMetrics() {
    _syncPosition();
  }

  @override
  void didUpdateWidget(covariant GlowPlainFieldImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _applyAttrs();
  }

  void _hide() {
    _input.style.visibility = 'hidden';
    _input.style.left = '-4000px';
  }

  void _syncPosition() {
    final ctx = _boxKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      _hide();
      return;
    }
    final route = ModalRoute.of(ctx);
    if (route != null && !route.isCurrent) {
      _hide();
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      _hide();
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width < 8 || size.height < 8) {
      _hide();
      return;
    }
    final view = View.of(ctx);
    final logical = view.physicalSize / view.devicePixelRatio;
    if (offset.dx + size.width < 0 ||
        offset.dy + size.height < 0 ||
        offset.dx > logical.width ||
        offset.dy > logical.height) {
      _hide();
      return;
    }
    _input.style
      ..left = '${offset.dx}px'
      ..top = '${offset.dy}px'
      ..width = '${size.width}px'
      ..height = '${size.height}px'
      ..visibility = 'visible';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_syncFromController);
    _input.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hole = SizedBox(key: _boxKey, height: 24, width: double.infinity);
    if (widget.icon == null) return hole;
    return Row(
      children: [
        Icon(widget.icon, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(child: hole),
      ],
    );
  }
}
