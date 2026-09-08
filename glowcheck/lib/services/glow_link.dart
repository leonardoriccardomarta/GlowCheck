import 'glow_link_io.dart' if (dart.library.js_interop) 'glow_link_web.dart';

class GlowLink {
  GlowLink._();

  static void open(String url) => openUrlImpl(url);

  static void search(String query) {
    open('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
  }
}
