import 'package:fitnessapp/common_widgets/glow_live_preview.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class GlowLivePreviewImpl extends State<GlowLivePreview> {
  @override
  void initState() {
    super.initState();
    widget.controller.capture = () async {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (file == null) return null;
      return file.readAsBytes();
    };
    widget.controller.torch = (_) async => false;
    widget.controller.retry = () async {};
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady?.call());
  }

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(color: Color(0xFF111111));
  }
}
