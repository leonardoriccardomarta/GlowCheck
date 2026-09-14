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
  String _left = '';
  String _top = '';
  String _width = '';
  String _height = '';

  bool get _focused {
    final active = web.document.activeElement;
    return active != null && active.id == _id;
  }

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
      ..fontSize = '16px'
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
    _input.onFocus.listen((_) {
      Future<void>.delayed(const Duration(milliseconds: 320), _ensureVisible);
    });
    widget.controller.addListener(_syncFromController);
    final layer = web.document.querySelector('#glow-html-layer');
    (layer ?? web.document.body)?.appendChild(_input);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  void _ensureVisible() {
    if (!mounted || !_focused) return;
    final ctx = _boxKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    try {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } catch (_) {}
  }

  void _applyAttrs() {
    final mode = widget.email ? 'email' : 'text';
    if (_input.type != 'text') _input.type = 'text';
    if (_input.placeholder != widget.hint) _input.placeholder = widget.hint;
    if (_input.inputMode != mode) _input.inputMode = mode;
    _input.autocomplete = widget.email ? 'email' : (widget.obscure ? 'current-password' : 'off');
    _input.spellcheck = false;
    _input.setAttribute('autocapitalize', widget.email || widget.obscure ? 'none' : 'sentences');
    _input.setAttribute('autocorrect', 'off');
    _input.setAttribute('enterkeyhint', 'done');
    final hidden = !_shown ? ' is-hidden' : '';
    final secret = widget.obscure ? ' is-secret' : '';
    final next = 'glow-html-input$secret$hidden';
    if (_input.className != next) _input.className = next;
  }

  void _syncFromController() {
    if (_focused) return;
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
      if (widget is IgnorePointer && widget.ignoring) {
        hidden = true;
        return false;
      }
      if (widget is TickerMode && !widget.enabled) {
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
    if (_focused && !blur) return;
    if (_shown || blur) {
      _shown = false;
      _input.classList.add('is-hidden');
      if (blur && _focused) {
        _input.blur();
      }
    }
  }

  void _syncPosition() {
    final ctx = _boxKey.currentContext;
    final focused = _focused;
    if (ctx == null || !ctx.mounted || !_onStage(ctx)) {
      if (!focused) _hide(blur: true);
      return;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) {
      if (!focused) _hide(blur: true);
      return;
    }
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    if (size.width < 8 || size.height < 8) {
      if (!focused) _hide(blur: true);
      return;
    }
    _shown = true;
    _input.classList.remove('is-hidden');
    final left = '${offset.dx.round()}px';
    final top = '${offset.dy.round()}px';
    final width = '${size.width.round()}px';
    final height = '${size.height.round()}px';
    if (left != _left) {
      _left = left;
      _input.style.left = left;
    }
    if (top != _top) {
      _top = top;
      _input.style.top = top;
    }
    if (width != _width) {
      _width = width;
      _input.style.width = width;
    }
    if (height != _height) {
      _height = height;
      _input.style.height = height;
    }
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
