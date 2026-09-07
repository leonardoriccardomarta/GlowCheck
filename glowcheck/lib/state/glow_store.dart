import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/scan_result.dart';

class GlowStore extends ChangeNotifier {
  GlowStore._();
  static final GlowStore instance = GlowStore._();

  static const _key = 'glowcheck.v1';

  bool ready = false;
  String? skinType;
  String? mainGoal;
  String? spendBand;
  String? accountName;
  String? accountEmail;
  String? accountProvider;
  String? accountPassword;
  String? accountToken;
  bool isPro = false;
  String? proPlan;
  int freeScansRemaining = 1;
  final List<ScanResult> history = [];
  final Set<int> pinned = {};

  bool get hasProfile =>
      skinType != null && mainGoal != null && spendBand != null;

  bool get hasAccount =>
      accountEmail != null && accountEmail!.isNotEmpty;

  ScanResult? get latest => history.isEmpty ? null : history.first;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      skinType = map['skinType'] as String?;
      mainGoal = map['mainGoal'] as String?;
      spendBand = map['spendBand'] as String?;
      accountName = map['accountName'] as String?;
      accountEmail = map['accountEmail'] as String?;
      accountProvider = map['accountProvider'] as String?;
      accountPassword = map['accountPassword'] as String?;
      accountToken = map['accountToken'] as String?;
      isPro = map['isPro'] == true;
      proPlan = map['proPlan'] as String?;
      freeScansRemaining = (map['freeScansRemaining'] as num?)?.toInt() ?? 1;
      history
        ..clear()
        ..addAll(
          ((map['history'] as List?) ?? [])
              .whereType<Map>()
              .map((item) => ScanResult.fromJson(Map<String, dynamic>.from(item))),
        );
      pinned
        ..clear()
        ..addAll(
          ((map['pinned'] as List?) ?? []).whereType<num>().map((item) => item.toInt()),
        );
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'skinType': skinType,
        'mainGoal': mainGoal,
        'spendBand': spendBand,
        'accountName': accountName,
        'accountEmail': accountEmail,
        'accountProvider': accountProvider,
        'accountPassword': accountPassword,
        'accountToken': accountToken,
        'isPro': isPro,
        'proPlan': proPlan,
        'freeScansRemaining': freeScansRemaining,
        'pinned': pinned.toList(),
        'history': history.map((item) => item.toJson()).toList(),
      }),
    );
  }

  Future<void> setSkin(String value) async {
    skinType = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setGoal(String value) async {
    mainGoal = value;
    notifyListeners();
    await _persist();
  }

  Future<void> setSpend(String value) async {
    spendBand = value;
    notifyListeners();
    await _persist();
  }

  bool get canScan => isPro || freeScansRemaining > 0;

  String get planLabel => isPro ? 'GlowCheck Pro' : 'Free scan';

  bool isPinned(int at) => pinned.contains(at);

  Future<void> togglePin(int at) async {
    if (pinned.contains(at)) {
      pinned.remove(at);
    } else {
      pinned.add(at);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> addScan(ScanResult result) async {
    if (!isPro && freeScansRemaining > 0) {
      freeScansRemaining -= 1;
    }
    history.insert(0, result);
    if (history.length > 40) {
      history.removeRange(40, history.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    accountName = name.trim();
    accountEmail = email.trim().toLowerCase();
    accountPassword = password;
    accountProvider = 'email';
    accountToken = null;
    notifyListeners();
    await _persist();
  }

  Future<void> applySession({
    required String name,
    required String email,
    required String provider,
    String? token,
  }) async {
    accountName = name.trim();
    accountEmail = email.trim().toLowerCase();
    accountProvider = provider;
    accountToken = token;
    if (provider != 'email') accountPassword = null;
    notifyListeners();
    await _persist();
  }

  Future<void> unlockPro({required String plan}) async {
    isPro = true;
    proPlan = plan;
    notifyListeners();
    await _persist();
  }

  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    final stored = accountEmail;
    if (stored == null || stored != email.trim().toLowerCase() || accountPassword != password) {
      throw Exception('Email or password does not match this device.');
    }
    notifyListeners();
  }

  Future<void> signInSocial(String provider, {String? name, String? email}) async {
    accountProvider = provider;
    accountName = (name ?? (provider == 'apple' ? 'Apple user' : 'Google user')).trim();
    accountEmail = (email ?? '$provider@glowcheck.local').toLowerCase();
    accountPassword = null;
    notifyListeners();
    await _persist();
  }

  Future<void> signOut() async {
    accountName = null;
    accountEmail = null;
    accountProvider = null;
    accountPassword = null;
    accountToken = null;
    notifyListeners();
    await _persist();
  }

  static String providerLabel(String? id) {
    switch (id) {
      case 'google':
        return 'Google';
      case 'apple':
        return 'Apple';
      case 'email':
        return 'Email';
      default:
        return 'This device';
    }
  }

  static String recommendedGoal(String? skin) {
    switch (skin) {
      case 'oily':
        return 'pores';
      case 'dry':
        return 'hydration';
      case 'sensitive':
        return 'hydration';
      default:
        return 'pores';
    }
  }

  static String? comboNote(String? skin, String? goal) {
    if (skin == 'oily' && goal == 'hydration') {
      return 'Oily is not dry. Use hydration only if the skin feels tight. We still flag heavy creams first.';
    }
    if (skin == 'dry' && goal == 'pores') {
      return 'Dry skin rarely needs pore first. Hydration is the usual match.';
    }
    if (skin == 'sensitive' && goal == 'pores') {
      return 'For sensitive we still watch fragrance and alcohol, not only texture.';
    }
    return null;
  }

  static bool isRecommendedGoal(String? skin, String goal) {
    return recommendedGoal(skin) == goal;
  }

  Future<void> resetQuiz() async {
    skinType = null;
    mainGoal = null;
    spendBand = null;
    notifyListeners();
    await _persist();
  }

  static String skinLabel(String? id) {
    switch (id) {
      case 'oily':
        return 'Oily';
      case 'dry':
        return 'Dry';
      case 'combination':
        return 'Combination';
      case 'sensitive':
        return 'Sensitive';
      default:
        return 'Your skin';
    }
  }

  static String goalLabel(String? id) {
    switch (id) {
      case 'pores':
        return 'Less clogging feel';
      case 'hydration':
        return 'Hydration';
      case 'budget':
        return 'Drugstore swaps';
      default:
        return 'Your goal';
    }
  }

  static String spendLabel(String? id) {
    switch (id) {
      case 'low':
        return 'Under \$20 / month';
      case 'mid':
        return '\$20 to \$50 / month';
      case 'high':
        return '\$50+ / month';
      default:
        return 'Budget unset';
    }
  }

  static String occlusionLabel(String? level) {
    switch (level) {
      case 'high':
        return 'Heavy / occlusive feel vs your profile';
      case 'medium':
        return 'Some occlusive textures on the list';
      default:
        return 'Light occlusion signal';
    }
  }
}
