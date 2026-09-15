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
  String localeCode = GlowL10n.defaultCode;
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
  String? stripeSessionId;
  int freeScansRemaining = 1;
  final List<ScanResult> history = [];
  final Set<int> pinned = {};

  bool highlightFirstScan = false;
  bool pendingHomeInstallHint = false;

  bool get hasProfile => skinType != null && mainGoal != null;

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
      spendBand = null;
      accountName = map['accountName'] as String?;
      accountEmail = map['accountEmail'] as String?;
      accountProvider = map['accountProvider'] as String?;
      accountPassword = map['accountPassword'] as String?;
      accountToken = map['accountToken'] as String?;
      isPro = map['isPro'] == true;
      proPlan = map['proPlan'] as String?;
      stripeSessionId = map['stripeSessionId'] as String?;
      pendingHomeInstallHint = map['pendingHomeInstallHint'] == true;
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
        'stripeSessionId': stripeSessionId,
        'pendingHomeInstallHint': pendingHomeInstallHint,
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

  Future<void> finishQuiz({required String skin, required String goal}) async {
    skinType = skin;
    mainGoal = goal;
    spendBand = null;
    highlightFirstScan = true;
    notifyListeners();
    await _persist();
  }

  void clearFirstScanBadge() {
    if (!highlightFirstScan) return;
    highlightFirstScan = false;
    notifyListeners();
  }

  Future<void> setSpend(String value) async {
    spendBand = value;
    notifyListeners();
    await _persist();
  }

  bool get canScan => isPro || freeScansRemaining > 0;

  String get planLabel => GlowL10n.t(isPro ? 'plan_pro' : 'plan_free');

  bool isPinned(int at) => pinned.contains(at);

  List<ScanResult> pinnedFirst(Iterable<ScanResult> source) {
    final items = source.toList();
    items.sort((a, b) {
      final pin = (isPinned(b.at) ? 1 : 0) - (isPinned(a.at) ? 1 : 0);
      if (pin != 0) return pin;
      return b.at.compareTo(a.at);
    });
    return items;
  }

  List<ScanResult> historyPinnedFirst({int? limit}) {
    final items = pinnedFirst(history);
    if (limit == null || items.length <= limit) return items;
    return items.take(limit).toList();
  }

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

  Future<void> mergeHistory(Iterable<ScanResult> remote) async {
    if (remote.isEmpty) return;
    final byAt = <int, ScanResult>{
      for (final item in history) item.at: item,
    };
    var changed = false;
    for (final item in remote) {
      if (byAt.containsKey(item.at)) continue;
      byAt[item.at] = item;
      changed = true;
    }
    if (!changed) return;
    final next = byAt.values.toList()..sort((a, b) => b.at.compareTo(a.at));
    if (next.length > 40) {
      next.removeRange(40, next.length);
    }
    history
      ..clear()
      ..addAll(next);
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
    bool? isPro,
  }) async {
    accountName = name.trim();
    accountEmail = email.trim().toLowerCase();
    accountProvider = provider;
    accountToken = token;
    if (provider != 'email') accountPassword = null;
    if (isPro == true) {
      this.isPro = true;
      proPlan = proPlan ?? 'lifetime';
    } else if (isPro == false) {
      this.isPro = false;
      proPlan = null;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> markFreeUsed() async {
    if (isPro || freeScansRemaining <= 0) return;
    freeScansRemaining = 0;
    notifyListeners();
    await _persist();
  }

  Future<void> markHomeInstallHint() async {
    pendingHomeInstallHint = true;
    notifyListeners();
    await _persist();
  }

  Future<void> consumeHomeInstallHint() async {
    if (!pendingHomeInstallHint) return;
    pendingHomeInstallHint = false;
    notifyListeners();
    await _persist();
  }

  Future<void> unlockPro({required String plan, String? stripeSession}) async {
    isPro = true;
    proPlan = plan;
    if (stripeSession != null && stripeSession.isNotEmpty) {
      stripeSessionId = stripeSession;
    }
    notifyListeners();
    await _persist();
  }

  Future<void> setStripeSessionId(String? value) async {
    stripeSessionId = value;
    notifyListeners();
    await _persist();
  }

  Future<void> applyStoreEntitlement({required bool active, String? plan}) async {
    if (active == isPro && (plan == null || plan == proPlan)) return;
    isPro = active;
    proPlan = active ? (plan ?? proPlan) : null;
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

  Future<void> applyStripeAccount(String email) async {
    final value = email.trim().toLowerCase();
    if (value.isEmpty || !value.contains('@')) return;
    if (hasAccount) return;
    accountEmail = value;
    accountName = accountName ?? value.split('@').first;
    accountProvider = 'email';
    notifyListeners();
    await _persist();
  }

  Future<void> signOut() async {
    accountName = null;
    accountEmail = null;
    accountProvider = null;
    accountPassword = null;
    accountToken = null;
    isPro = false;
    proPlan = null;
    stripeSessionId = null;
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
