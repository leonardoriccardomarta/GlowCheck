import 'package:flutter/material.dart';

import 'glow_live_preview_io.dart' if (dart.library.js_interop) 'glow_live_preview_web.dart';

class GlowLiveController {
  Future<List<int>?> Function()? capture;
  String? lastBarcode;
  Future<bool> Function(bool on)? torch;
  Future<void> Function()? retry;
}

class GlowLivePreview extends StatefulWidget {
  const GlowLivePreview({
    super.key,
    required this.controller,
    this.onReady,
    this.obscured = false,
    this.torchOn = false,
    this.barcodeLocked = false,
    this.inciMode = false,
    this.badge,
    this.hint,
    this.onBarcode,
    this.onClose,
    this.onGallery,
    this.onShutter,
    this.onTorch,
  });

  final GlowLiveController controller;
  final VoidCallback? onReady;
  final bool obscured;
  final bool torchOn;
  final bool barcodeLocked;
  final bool inciMode;
  final String? badge;
  final String? hint;
  final ValueChanged<String?>? onBarcode;
  final VoidCallback? onClose;
  final VoidCallback? onGallery;
  final VoidCallback? onShutter;
  final VoidCallback? onTorch;

  @override
  State<GlowLivePreview> createState() => GlowLivePreviewImpl();
}
