import 'package:fitnessapp/common_widgets/glow_ui.dart';
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
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();
    GlowStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    GlowStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _scan(ImageSource source) async {
    if (busy) return;
    if (!GlowStore.instance.canScan) {
      await Navigator.pushNamed(context, PaywallScreen.routeName);
      if (!GlowStore.instance.canScan) {
        setState(() => error = 'Free scan used. Unlock Pro to keep scoring bottles.');
      }
      return;
    }
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 70, maxWidth: 1600);
    if (file == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final bytes = await file.readAsBytes();
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

  @override
  Widget build(BuildContext context) {
    final store = GlowStore.instance;
    final history = store.history;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
              children: [
                const Text(
                  "Scan INCI",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Fill the frame with Aqua / Glycerin. Glare or cropped lists stay free.",
                  style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Photograph the ingredient list",
                        style: const TextStyle(
                          color: AppColors.card,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${GlowStore.skinLabel(store.skinType)}  ·  ${GlowStore.goalLabel(store.mainGoal)}",
                        style: TextStyle(color: AppColors.card.withValues(alpha: 0.65), fontSize: 13),
                      ),
                      const Spacer(),
                      GlowPrimaryButton(
                        title: "Take photo",
                        light: true,
                        onPressed: () {
                          if (!busy) _scan(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Or pick a label from the library",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      GlowCircleButton(
                        icon: Icons.photo_library_outlined,
                        dark: true,
                        onTap: () {
                          if (!busy) _scan(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.caution.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(error!, style: const TextStyle(color: AppColors.caution, fontSize: 13, height: 1.4)),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        "Recent bottles",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      "${history.length} saved",
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  const Text(
                    "No scans yet. The first readable INCI is free.",
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                else
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: history.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final scan = history[i];
                        return InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            FinishWorkoutScreen.routeName,
                            arguments: scan,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          child: Ink(
                            width: 168,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                GlowInitials(label: scan.productName, size: 44),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        scan.productName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      Text(
                                        "${scan.score}  ·  ${scan.watchCount} watch",
                                        style: const TextStyle(color: AppColors.muted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (busy)
            Positioned.fill(
              child: ColoredBox(
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
                        const Text(
                          "Reading the label",
                          style: TextStyle(color: AppColors.card, fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Matching INCI vs ${GlowStore.skinLabel(store.skinType).toLowerCase()} skin",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.card.withValues(alpha: 0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
