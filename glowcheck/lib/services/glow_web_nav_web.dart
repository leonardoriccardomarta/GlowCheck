import 'package:web/web.dart' as web;

void goToCheckout(String url) {
  web.window.location.assign(url);
}

void stripCheckoutQuery() {
  final loc = web.window.location;
  web.window.history.replaceState(null, '', loc.pathname + loc.hash);
}
