import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> shareTextImpl({
  required String text,
  required String title,
}) async {
  try {
    final data = web.ShareData(title: title, text: text);
    if (!web.window.navigator.canShare(data)) {
      return 'fallback';
    }
    await web.window.navigator.share(data).toDart;
    return 'shared';
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('abort') || msg.contains('cancel')) return 'cancelled';
    return 'fallback';
  }
}
