import 'dart:convert';
import 'dart:js_interop';

import 'package:fitnessapp/common_widgets/glow_live_preview.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('GlowCam')
@staticInterop
class JSGlowCam {}

extension JSGlowCamMethods on JSGlowCam {
  external JSPromise<JSAny?> start(web.HTMLVideoElement video);
  external String capture(web.HTMLVideoElement video);
  external JSPromise<JSAny?> readBarcode(web.HTMLVideoElement video);
  external void stop();
  external JSPromise<JSBoolean> torch(JSBoolean on);
}

@JS('GlowCam')
external JSGlowCam get _glowCam;

class GlowLivePreviewImpl extends State<GlowLivePreview> with WidgetsBindingObserver {
  final GlobalKey _boxKey = GlobalKey();
  late final web.HTMLVideoElement _video;
  late final web.HTMLDivElement _frame;
  late final web.HTMLDivElement _chrome;
  late final web.HTMLButtonElement _close;
  late final web.HTMLButtonElement _gallery;
  late final web.HTMLButtonElement _shutter;
  late final web.HTMLButtonElement _flash;
  late final web.HTMLDivElement _badge;
  bool _ready = false;
  bool _shown = false;
  String? _error;

  web.HTMLButtonElement _btn(String className, String aria) {
    final btn = web.HTMLButtonElement()
      ..type = 'button'
      ..className = className;
    btn.setAttribute('aria-label', aria);
    return btn;
  }

  @override
  void initState() {
    super.initState();
    _video = web.HTMLVideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false
      ..className = 'glow-cam-video is-hidden';
    _video.setAttribute('playsinline', 'true');
    _video.style
      ..position = 'fixed'
      ..objectFit = 'cover'
      ..backgroundColor = '#111111'
      ..pointerEvents = 'none'
      ..zIndex = '2147483645';

    _frame = web.HTMLDivElement()..className = 'glow-cam-frame is-hidden';
    _chrome = web.HTMLDivElement()..className = 'glow-cam-chrome is-hidden';
    _close = _btn('glow-cam-btn glow-cam-close', 'Close');
    _gallery = _btn('glow-cam-btn glow-cam-gallery', 'Gallery');
    _flash = _btn('glow-cam-btn glow-cam-flash', 'Flash');
    _shutter = web.HTMLButtonElement()
      ..type = 'button'
      ..className = 'glow-cam-shutter'
      ..setAttribute('aria-label', 'Shutter');
    _badge = web.HTMLDivElement()..className = 'glow-cam-badge is-hidden';
    _chrome.appendChild(_close);
    _chrome.appendChild(_badge);
    _chrome.appendChild(_gallery);
    _chrome.appendChild(_shutter);
    _chrome.appendChild(_flash);

    _close.onClick.listen((_) {
      if (widget.obscured) return;
      widget.onClose?.call();
    });
    _gallery.onClick.listen((_) {
      if (widget.obscured) return;
      widget.onGallery?.call();
    });
    _shutter.onClick.listen((_) {
      if (widget.obscured) return;
      widget.onShutter?.call();
    });
    _flash.onClick.listen((_) {
      if (widget.obscured) return;
      widget.onTorch?.call();
    });

    final layer = web.document.querySelector('#glow-html-layer');
    final host = layer ?? web.document.body;
    host?.appendChild(_video);
    host?.appendChild(_frame);
    host?.appendChild(_chrome);

    widget.controller.capture = _capture;
    widget.controller.torch = _torch;
    widget.controller.retry = _start;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didUpdateWidget(covariant GlowLivePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncChrome();
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

  void _hide() {
    _shown = false;
    _video.classList.add('is-hidden');
    _frame.classList.add('is-hidden');
    _chrome.classList.add('is-hidden');
  }

  void _syncChrome() {
    if (widget.torchOn) {
      _flash.classList.add('is-on');
    } else {
      _flash.classList.remove('is-on');
    }
    final badge = widget.badge;
    if (badge == null || badge.isEmpty) {
      _badge.classList.add('is-hidden');
    } else {
      _badge.classList.remove('is-hidden');
      _badge.textContent = badge;
    }
  }

  void _syncPosition() {
    final ctx = _boxKey.currentContext;
    if (ctx == null || !ctx.mounted || !_onStage(ctx) || _error != null || widget.obscured) {
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
    _shown = true;
    _syncChrome();
    _video.classList.remove('is-hidden');
    _video.style
      ..left = '${offset.dx}px'
      ..top = '${offset.dy}px'
      ..width = '${size.width}px'
      ..height = '${size.height}px';

    _frame.classList.remove('is-hidden');
    _frame.style
      ..left = '${offset.dx + size.width * 0.11}px'
      ..top = '${offset.dy + size.height * 0.33}px'
      ..width = '${size.width * 0.78}px'
      ..height = '${size.height * 0.34}px';

    _chrome.classList.remove('is-hidden');
    _chrome.style
      ..left = '${offset.dx}px'
      ..top = '${offset.dy}px'
      ..width = '${size.width}px'
      ..height = '${size.height}px';
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await _glowCam.start(_video).toDart;
      if (!mounted) return;
      setState(() => _ready = true);
      widget.onReady?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _error = 'cam';
      });
    }
  }

  Future<List<int>?> _capture() async {
    if (!_ready || !_shown) return null;
    widget.controller.lastBarcode = null;
    try {
      final raw = await _glowCam.readBarcode(_video).toDart;
      final digits = (raw?.toString() ?? '').replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 8 && digits.length <= 14) {
        widget.controller.lastBarcode = digits;
      }
    } catch (_) {}
    final dataUrl = _glowCam.capture(_video);
    final comma = dataUrl.indexOf(',');
    if (comma < 0) return null;
    return base64Decode(dataUrl.substring(comma + 1));
  }

  Future<bool> _torch(bool on) async {
    try {
      final ok = await _glowCam.torch(on.toJS).toDart;
      return ok.toDart;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _glowCam.stop();
    _video.remove();
    _frame.remove();
    _chrome.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111111),
      child: GestureDetector(
        onTap: _error == null ? null : () => _start(),
        child: SizedBox.expand(
          key: _boxKey,
          child: _error == null
              ? null
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      GlowL10n.t('cam_need_perm'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
