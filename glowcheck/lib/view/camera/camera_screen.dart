import 'package:fitnessapp/common_widgets/glow_live_preview.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/services/glow_api.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _live = GlowLiveController();
  bool busy = false;
  bool torch = false;
  String? error;

  Future<void> _ensureQuota() async {
    if (GlowStore.instance.canScan) return;
    await Navigator.pushNamed(context, PaywallScreen.routeName);
  }

  Future<void> _analyze(List<int> bytes) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final ScanResult result = await GlowApi.analyzeJpeg(bytes);
      await GlowStore.instance.addScan(result);
      if (!mounted) return;
      Navigator.pushNamed(context, FinishWorkoutScreen.routeName, arguments: result);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _shutter() async {
    if (busy) return;
    await _ensureQuota();
    if (!GlowStore.instance.canScan) return;
    final bytes = await _live.capture?.call();
    if (bytes == null || bytes.isEmpty) return;
    await _analyze(bytes);
  }

  Future<void> _gallery() async {
    if (busy) return;
    await _ensureQuota();
    if (!GlowStore.instance.canScan) return;
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1600,
    );
    if (file == null) return;
    await _analyze(await file.readAsBytes());
  }

  Future<void> _toggleTorch() async {
    final next = !torch;
    final ok = await _live.torch?.call(next) ?? false;
    if (mounted) setState(() => torch = ok ? next : false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GlowLivePreview(controller: _live, obscured: busy),
                if (GlowStore.instance.highlightFirstScan && error == null && !busy)
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 16,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.neon,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          GlowL10n.t('cam_free_ready'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (error != null)
                  Positioned(
                    left: 24,
                    right: 24,
                    top: 24,
                    child: Material(
                      color: AppColors.caution.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                        ),
                      ),
                    ),
                  ),
                if (busy)
                  ColoredBox(
                    color: AppColors.ink.withValues(alpha: 0.92),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(color: AppColors.card, strokeWidth: 3),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              GlowL10n.t('reading_label'),
                              style: const TextStyle(color: AppColors.card, fontSize: 24, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              GlowL10n.t('matching_skin', {
                                'skin': GlowStore.skinLabel(GlowStore.instance.skinType).toLowerCase(),
                              }),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.card.withValues(alpha: 0.7), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CamIcon(icon: Icons.photo_library_rounded, onTap: _gallery),
                  GestureDetector(
                    onTap: _shutter,
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  _CamIcon(
                    icon: torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    onTap: _toggleTorch,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

class _CamIcon extends StatelessWidget {
  const _CamIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
