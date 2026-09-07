import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/glow_l10n.dart';
import '../models/scan_result.dart';

class GlowStore extends ChangeNotifier {
  GlowStore._();
  static final GlowStore instance = GlowStore._();

  static const _key = 'glowcheck.v1';

  bool ready = false;
  String localeCode = 'it';
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
      localeCode = GlowL10n.normalize(map['localeCode'] as String?);
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
    GlowL10n.currentCode = localeCode;
    GlowL10n.persistLocale = setLocale;
    ready = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'localeCode': localeCode,
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

  Future<void> setLocale(String value) async {
    localeCode = GlowL10n.normalize(value);
    GlowL10n.currentCode = localeCode;
    notifyListeners();
    await _persist();
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

  String get planLabel => GlowL10n.t(isPro ? 'plan_pro' : 'plan_free');

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
      throw Exception(GlowL10n.t('err_email_pass'));
    }
    notifyListeners();
  }

  Future<void> signInSocial(String provider, {String? name, String? email}) async {
    accountProvider = provider;
    accountName = (name ?? GlowL10n.t(provider == 'apple' ? 'apple_user' : 'google_user')).trim();
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
        return GlowL10n.t('provider_google');
      case 'apple':
        return GlowL10n.t('provider_apple');
      case 'email':
        return GlowL10n.t('provider_email');
      default:
        return GlowL10n.t('provider_device');
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
      return GlowL10n.t('combo_oily_hydration');
    }
    if (skin == 'dry' && goal == 'pores') {
      return GlowL10n.t('combo_dry_pores');
    }
    if (skin == 'sensitive' && goal == 'pores') {
      return GlowL10n.t('combo_sensitive_pores');
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
        return GlowL10n.t('skin_oily');
      case 'dry':
        return GlowL10n.t('skin_dry');
      case 'combination':
        return GlowL10n.t('skin_combination');
      case 'sensitive':
        return GlowL10n.t('skin_sensitive');
      default:
        return GlowL10n.t('skin_default');
    }
  }

  static String goalLabel(String? id) {
    switch (id) {
      case 'pores':
        return GlowL10n.t('goal_pores');
      case 'hydration':
        return GlowL10n.t('goal_hydration');
      case 'budget':
        return GlowL10n.t('goal_budget');
      default:
        return GlowL10n.t('goal_default');
    }
  }

  static String spendLabel(String? id) {
    switch (id) {
      case 'low':
        return GlowL10n.t('spend_low_full');
      case 'mid':
        return GlowL10n.t('spend_mid_full');
      case 'high':
        return GlowL10n.t('spend_high_full');
      default:
        return GlowL10n.t('spend_unset');
    }
  }

  static String occlusionLabel(String? level) {
    switch (level) {
      case 'high':
        return GlowL10n.t('occ_high');
      case 'medium':
        return GlowL10n.t('occ_mid');
      default:
        return GlowL10n.t('occ_low');
    }
  }

  static String badgeLabel(String? badge) {
    final key = 'badge_${(badge ?? '').replaceAll(' ', '_')}';
    final translated = GlowL10n.t(key);
    return translated == key ? (badge ?? '').replaceAll('_', ' ') : translated;
  }
}
