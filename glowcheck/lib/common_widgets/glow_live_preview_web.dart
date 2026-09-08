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
  external void stop();
  external JSPromise<JSBoolean> torch(JSBoolean on);
}

@JS('GlowCam')
external JSGlowCam get _glowCam;

class GlowLivePreviewImpl extends State<GlowLivePreview> with WidgetsBindingObserver {
  final GlobalKey _boxKey = GlobalKey();
  late final web.HTMLVideoElement _video;
  late final web.HTMLDivElement _frame;
  bool _ready = false;
  bool _shown = false;
  String? _error;

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

    final layer = web.document.querySelector('#glow-html-layer');
    (layer ?? web.document.body)?.appendChild(_video);
    (layer ?? web.document.body)?.appendChild(_frame);

    widget.controller.capture = _capture;
    widget.controller.torch = _torch;
    widget.controller.retry = _start;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
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
