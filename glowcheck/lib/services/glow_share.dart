import 'package:flutter/services.dart';

import 'glow_share_io.dart' if (dart.library.js_interop) 'glow_share_web.dart';

enum GlowShareOutcome { shared, cancelled, copied }

class GlowShare {
  GlowShare._();

  static Future<GlowShareOutcome> text({
    required String text,
    required String title,
  }) async {
    final opened = await shareTextImpl(text: text, title: title);
    if (opened == 'shared') return GlowShareOutcome.shared;
    if (opened == 'cancelled') return GlowShareOutcome.cancelled;
    await Clipboard.setData(ClipboardData(text: text));
    return GlowShareOutcome.copied;
  }
}
