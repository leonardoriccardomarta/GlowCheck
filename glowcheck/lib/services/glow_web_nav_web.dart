import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

void goToCheckout(String url) {
  web.window.location.assign(url);
}

void stripCheckoutQuery() {
  final loc = web.window.location;
  web.window.history.replaceState(null, '', loc.pathname + loc.hash);
}

bool isStandaloneDisplay() {
  if (web.window.matchMedia('(display-mode: standalone)').matches) return true;
  if (web.window.matchMedia('(display-mode: fullscreen)').matches) return true;
  final standalone = web.window.navigator.getProperty('standalone'.toJS);
  return standalone == true.toJS;
}

bool isIosWeb() {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('iphone') || ua.contains('ipad') || ua.contains('ipod');
}

bool isAndroidWeb() {
  return web.window.navigator.userAgent.toLowerCase().contains('android');
}
