import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../l10n/glow_l10n.dart';
import '../models/scan_result.dart';
import '../state/glow_store.dart';
import 'glow_http.dart';

class GlowScanException implements Exception {
  GlowScanException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
}

class GlowApi {
  GlowApi._();

  static String get baseUrl => AppEnv.analyzeBase;
  static final http.Client _client = createGlowHttpClient();

  static Map<String, String> _headers() {
    final token = GlowStore.instance.accountToken;
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ScanResult> analyzeJpeg(List<int> bytes, {String? barcode, bool readInci = false}) async {
    final store = GlowStore.instance;
    final skin = store.skinType;
    final goal = store.mainGoal;
    if (skin == null || goal == null) {
      throw Exception(GlowL10n.t('err_quiz'));
    }

    final uri = Uri.parse('$baseUrl/analyze');
    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: _headers(),
            body: jsonEncode({
              'imageBase64': base64Encode(bytes),
              'mimeType': 'image/jpeg',
              if (barcode != null && barcode.replaceAll(RegExp(r'\D'), '').length >= 8)
                'barcode': barcode.replaceAll(RegExp(r'\D'), ''),
              if (readInci) 'readInci': true,
              'profile': {
                'skinType': skin,
                'mainGoal': goal,
                'locale': GlowL10n.normalize(store.localeCode),
                if (store.spendBand != null) 'spendBand': store.spendBand,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw Exception(
        GlowL10n.t('err_api', {'url': baseUrl}),
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['readable'] != true) {
      throw GlowScanException(
        json['errorCode'] as String? ?? 'UNREADABLE',
        _errorMessage(json['errorCode'] as String?),
      );
    }

    return ScanResult(
      productName: json['productName'] as String? ?? 'INCI scan',
      score: (json['compatibilityScore'] as num?)?.toInt() ?? 0,
      badge: json['statusBadge'] as String? ?? 'CAUTION',
      headline: json['headline'] as String? ?? '',
      why: json['whyForYou'] as String? ?? '',
      at: DateTime.now().millisecondsSinceEpoch,
      occlusionAlert: json['occlusionAlert'] as String? ?? 'low',
      dupeId: json['dupeId'] as String?,
      dupe: json['dupe'] is Map
          ? DupeSuggestion.fromJson(Map<String, dynamic>.from(json['dupe'] as Map))
          : null,
      ingredients: ((json['ingredients'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => IngredientLine.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      flagged: ((json['flaggedIngredients'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => FlaggedIngredient.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  static Future<void> saveShelf(ScanResult scan) async {
    final token = GlowStore.instance.accountToken;
    if (token == null || token.isEmpty) return;
    try {
      await _client
          .post(
            Uri.parse('$baseUrl/shelf'),
            headers: _headers(),
            body: jsonEncode(scan.toJson()),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {}
  }

  static Future<List<ScanResult>> fetchShelf() async {
    final token = GlowStore.instance.accountToken;
    if (token == null || token.isEmpty) return const [];
    final response = await _client
        .get(Uri.parse('$baseUrl/shelf'), headers: _headers())
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) return const [];
    final json = jsonDecode(response.body);
    if (json is! Map || json['ok'] != true) return const [];
    return ((json['items'] as List?) ?? [])
        .whereType<Map>()
        .map((item) => ScanResult.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> syncShelf(List<ScanResult> items) async {
    final token = GlowStore.instance.accountToken;
    if (token == null || token.isEmpty) return;
    await _client
        .post(
          Uri.parse('$baseUrl/shelf/sync'),
          headers: _headers(),
          body: jsonEncode({'items': items.map((item) => item.toJson()).toList()}),
        )
        .timeout(const Duration(seconds: 20));
  }

  static Future<void> pullAndMergeShelf() async {
    final token = GlowStore.instance.accountToken;
    if (token == null || token.isEmpty) return;
    try {
      final remote = await fetchShelf();
      await GlowStore.instance.mergeHistory(remote);
      final local = GlowStore.instance.history;
      if (local.isNotEmpty) {
        await syncShelf(local);
      }
    } catch (_) {}
  }

  static Future<bool> billingReady() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/billing/ready'))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return false;
      final json = jsonDecode(response.body);
      return json is Map && json['stripe'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> createCheckout({
    required String successUrl,
    required String cancelUrl,
    String? locale,
  }) async {
    late http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/billing/checkout'),
            headers: _headers(),
            body: jsonEncode({
              'successUrl': successUrl,
              'cancelUrl': cancelUrl,
              if (locale != null && locale.isNotEmpty) 'locale': locale,
            }),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(GlowL10n.t('paywall_store_err'));
    }
    final json = jsonDecode(response.body);
    if (json is Map && json['ok'] == true && json['url'] is String) {
      return json['url'] as String;
    }
    final detail = json is Map ? json['detail'] : null;
    if (detail is String && detail.trim().isNotEmpty) {
      throw Exception(detail.trim());
    }
    throw Exception(GlowL10n.t('paywall_store_err'));
  }

  static Future<({bool unlocked, bool attached})> confirmCheckout(String sessionId) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/billing/confirm'),
            headers: _headers(),
            body: jsonEncode({'sessionId': sessionId}),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return (unlocked: false, attached: false);
      final json = jsonDecode(response.body);
      if (json is! Map || json['unlocked'] != true) {
        return (unlocked: false, attached: false);
      }
      return (unlocked: true, attached: json['isPro'] == true);
    } catch (_) {
      return (unlocked: false, attached: false);
    }
  }

  static String _errorMessage(String? code) {
    switch (code) {
      case 'NOT_COSMETIC':
        return GlowL10n.t('err_not_cosmetic');
      case 'UNREADABLE':
        return GlowL10n.t('err_unreadable');
      case 'NEED_INCI':
        return GlowL10n.t('err_need_inci');
      case 'PAYWALL':
        return GlowL10n.t('err_paywall');
      case 'INTERNAL':
        return GlowL10n.t('err_internal');
      default:
        return GlowL10n.t('err_read');
    }
  }
}
