import 'package:flutter/material.dart';

import 'glow_live_preview_io.dart' if (dart.library.js_interop) 'glow_live_preview_web.dart';

class GlowLiveController {
  Future<List<int>?> Function()? capture;
  Future<bool> Function(bool on)? torch;
  Future<void> Function()? retry;
}

class GlowLivePreview extends StatefulWidget {
  const GlowLivePreview({
    super.key,
    required this.controller,
    this.onReady,
    this.obscured = false,
  });

  final GlowLiveController controller;
  final VoidCallback? onReady;
  final bool obscured;

  @override
  State<GlowLivePreview> createState() => GlowLivePreviewImpl();
}
