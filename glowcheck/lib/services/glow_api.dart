import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
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
      throw Exception('Finish the skin quiz first.');
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
                if (store.spendBand != null) 'spendBand': store.spendBand,
              },
            }),
          )
          .timeout(const Duration(seconds: 60));
    } catch (_) {
      throw Exception(
        'Cannot reach the API at $baseUrl. Backend on, same Wi-Fi, or pass --dart-define=API_URL=http://PC_IP:4000',
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
        return 'That photo does not look like a skincare label. Shoot the INCI list on the back.';
      case 'UNREADABLE':
        return 'Could not read the INCI list. Fill the frame, avoid glare, try again. Unreadable stays free.';
      case 'INTERNAL':
        return 'Scan failed on our side. Try again in a moment.';
      default:
        return 'Could not read the INCI list. Fill the frame, avoid glare, try again.';
    }
  }
}
