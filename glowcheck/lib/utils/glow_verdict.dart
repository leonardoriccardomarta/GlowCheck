import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/models/scan_result.dart';
import 'package:fitnessapp/state/glow_store.dart';

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

  static String punchTitle(ScanResult scan) {
    final n = '${scan.score}';
    if (scan.score >= 80) return GlowL10n.t('match_great', {'n': n});
    if (scan.score >= 60) return GlowL10n.t('match_good', {'n': n});
    return GlowL10n.t('match_poor', {'n': n});
  }

  static String punchSub(ScanResult scan) {
    final skin = GlowStore.skinLabel(GlowStore.instance.skinType);
    if (scan.score >= 60) return GlowL10n.t('match_skin_ok', {'skin': skin});
    return GlowL10n.t('match_skin_no', {'skin': skin});
  }
}
