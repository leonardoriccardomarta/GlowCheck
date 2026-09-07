import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../l10n/glow_l10n.dart';
import '../models/scan_result.dart';
import '../state/glow_store.dart';

class GlowApi {
  GlowApi._();

  static String get baseUrl => AppEnv.analyzeBase;

  static Future<ScanResult> analyzeJpeg(List<int> bytes) async {
    final store = GlowStore.instance;
    final skin = store.skinType;
    final goal = store.mainGoal;
    if (skin == null || goal == null) {
      throw Exception(GlowL10n.t('err_quiz'));
    }

    final uri = Uri.parse('$baseUrl/analyze');
    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'imageBase64': base64Encode(bytes),
              'mimeType': 'image/jpeg',
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
      throw Exception(_errorMessage(json['errorCode'] as String?));
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

  static String _errorMessage(String? code) {
    switch (code) {
      case 'NOT_COSMETIC':
        return GlowL10n.t('err_not_cosmetic');
      case 'UNREADABLE':
        return GlowL10n.t('err_unreadable');
      case 'INTERNAL':
        return GlowL10n.t('err_internal');
      default:
        return GlowL10n.t('err_read');
    }
  }
}
