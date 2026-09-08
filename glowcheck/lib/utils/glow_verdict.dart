import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';

class GlowVerdict {
  GlowVerdict._();

  static bool approved(ScanResult scan) => scan.score >= 70;

  static String title(ScanResult scan) {
    if (scan.score >= 70) return GlowL10n.t('verdict_ok');
    if (scan.score >= 48) return GlowL10n.t('verdict_mix');
    return GlowL10n.t('verdict_no');
  }

  static String subtitle(ScanResult scan) {
    if (scan.score >= 70 && scan.watchCount == 0) return GlowL10n.t('verdict_ok_sub');
    if (scan.score >= 70) return GlowL10n.t('verdict_mix_sub');
    return GlowL10n.t('verdict_no_sub');
  }
}
