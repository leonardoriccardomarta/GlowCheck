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
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _id = 'glow-field-${identityHashCode(this)}';
    _input = web.HTMLInputElement()
      ..id = _id
      ..className = 'glow-html-input is-hidden';
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
      ..boxSizing = 'border-box';
    _input.style.setProperty('-webkit-appearance', 'none');
    _input.style.setProperty('appearance', 'none');
    _input.style.setProperty('touch-action', 'manipulation');
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
    // Keep type=text so iOS Chrome actually opens the keyboard.
    // Mask password in CSS; hint the email keyboard via inputMode.
    _input
      ..type = 'text'
      ..placeholder = widget.hint
      ..autocomplete = 'off'
      ..spellcheck = false
      ..inputMode = widget.email ? 'email' : 'text';
    _input.className = _shown
        ? (widget.obscure ? 'glow-html-input is-secret' : 'glow-html-input')
        : (widget.obscure ? 'glow-html-input is-secret is-hidden' : 'glow-html-input is-hidden');
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

  bool _onStage(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;
    var hidden = false;
    context.visitAncestorElements((el) {
      final widget = el.widget;
      if (widget is Offstage && widget.offstage) {
        hidden = true;
        return false;
      }
      if (widget is Visibility && !widget.visible) {
        hidden = true;
        return false;
      }
      return true;
    });
    return !hidden;
  }

  void _hide({required bool blur}) {
    if (_shown || blur) {
      _shown = false;
      _input.classList.add('is-hidden');
      if (blur) {
        _input.blur();
      }
    }
  }

  void _syncPosition() {
    final ctx = _boxKey.currentContext;
    if (ctx == null || !ctx.mounted || !_onStage(ctx)) {
      _hide(blur: true);
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      _hide(blur: true);
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width < 8 || size.height < 8) {
      _hide(blur: true);
      return;
    }
    final view = View.of(ctx);
    final logical = view.physicalSize / view.devicePixelRatio;
    if (offset.dx + size.width < 0 ||
        offset.dy + size.height < 0 ||
        offset.dx > logical.width ||
        offset.dy > logical.height) {
      _hide(blur: true);
      return;
    }
    _shown = true;
    _input.classList.remove('is-hidden');
    _input.style
      ..left = '${offset.dx}px'
      ..top = '${offset.dy}px'
      ..width = '${size.width}px'
      ..height = '${size.height}px';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_syncFromController);
    _input.blur();
    _input.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hole = SizedBox.expand(key: _boxKey);
    if (widget.icon == null) return hole;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Icon(widget.icon, color: AppColors.muted)),
        const SizedBox(width: 10),
        Expanded(child: hole),
      ],
    );
  }
}
