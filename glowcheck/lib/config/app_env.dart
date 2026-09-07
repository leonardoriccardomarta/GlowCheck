import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AppEnv {
  AppEnv._();

  static String apiUrl = const String.fromEnvironment('API_URL');
  static String authApiUrl = const String.fromEnvironment('AUTH_API_URL');
  static String googleClientId = const String.fromEnvironment('GOOGLE_CLIENT_ID');
  static String appleServiceId = const String.fromEnvironment('APPLE_SERVICE_ID');
  static String revenueCatKey = const String.fromEnvironment('REVENUECAT_API_KEY');
  static String stripeCheckoutUrl = const String.fromEnvironment('STRIPE_CHECKOUT_URL');
  static const weeklyProductId = String.fromEnvironment(
    'IAP_WEEKLY_ID',
    defaultValue: 'glowcheck_weekly',
  );
  static const yearlyProductId = String.fromEnvironment(
    'IAP_YEARLY_ID',
    defaultValue: 'glowcheck_yearly',
  );
  static const entitlement = String.fromEnvironment(
    'IAP_ENTITLEMENT',
    defaultValue: 'pro',
  );

  static Future<void> loadRuntime() async {
    if (!kIsWeb) return;
    try {
      final response = await http.get(Uri.base.resolve('config.json')).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return;
      final map = jsonDecode(response.body);
      if (map is! Map) return;
      void take(String key, void Function(String value) set) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) set(value.trim());
      }

      take('apiUrl', (value) => apiUrl = value);
      take('authApiUrl', (value) => authApiUrl = value);
      take('googleClientId', (value) => googleClientId = value);
      take('appleServiceId', (value) => appleServiceId = value);
      take('revenueCatApiKey', (value) => revenueCatKey = value);
      take('stripeCheckoutUrl', (value) => stripeCheckoutUrl = value);
    } catch (_) {}
  }

  static String get analyzeBase {
    if (apiUrl.isNotEmpty) return apiUrl;
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host.isNotEmpty && host != 'localhost' && host != '127.0.0.1') {
        return Uri.base.origin;
      }
    }
    return 'http://127.0.0.1:4000';
  }

  static String get authBase {
    if (authApiUrl.isNotEmpty) return authApiUrl;
    return analyzeBase;
  }

  static bool get authApiReady => authApiUrl.isNotEmpty;
  static bool get googleReady => googleClientId.isNotEmpty;
  static bool get appleReady => appleServiceId.isNotEmpty;
  static bool get billingLive => revenueCatKey.isNotEmpty || stripeCheckoutUrl.isNotEmpty;
}
