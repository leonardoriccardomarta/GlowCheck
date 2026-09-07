import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_env.dart';
import '../l10n/glow_l10n.dart';
import '../state/glow_store.dart';

class GlowAuth {
  GlowAuth._();

  static bool get emailReady => AppEnv.authApiReady;
  static bool get googleReady => AppEnv.authApiReady && AppEnv.googleReady;
  static bool get appleReady => AppEnv.authApiReady && AppEnv.appleReady;

  static Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (AppEnv.authApiReady) {
      final user = await _post('/auth/register', {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      await GlowStore.instance.applySession(
        name: user['name'] as String? ?? name,
        email: user['email'] as String? ?? email,
        provider: 'email',
        token: user['token'] as String?,
      );
      return;
    }
    await GlowStore.instance.signUp(name: name, email: email, password: password);
  }

  static Future<void> loginEmail({
    required String email,
    required String password,
  }) async {
    if (AppEnv.authApiReady) {
      final user = await _post('/auth/login', {
        'email': email.trim().toLowerCase(),
        'password': password,
      });
      await GlowStore.instance.applySession(
        name: user['name'] as String? ?? 'GlowCheck',
        email: user['email'] as String? ?? email,
        provider: 'email',
        token: user['token'] as String?,
      );
      return;
    }
    await GlowStore.instance.signInEmail(email: email, password: password);
  }

  static Future<void> social(String provider) async {
    if (AppEnv.authApiReady &&
        ((provider == 'google' && AppEnv.googleReady) || (provider == 'apple' && AppEnv.appleReady))) {
      final user = await _post('/auth/social', {
        'provider': provider,
        'clientId': provider == 'google' ? AppEnv.googleClientId : AppEnv.appleServiceId,
      });
      await GlowStore.instance.applySession(
        name: user['name'] as String? ?? GlowL10n.t(provider == 'apple' ? 'apple_user' : 'google_user'),
        email: user['email'] as String? ?? '$provider@glowcheck.local',
        provider: provider,
        token: user['token'] as String?,
      );
      return;
    }
    await GlowStore.instance.signInSocial(provider);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${AppEnv.authBase}$path');
    late http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      throw Exception(GlowL10n.t('auth_unreachable', {'url': AppEnv.authBase}));
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || json['ok'] != true) {
      throw Exception(_authError(json));
    }
    final user = json['user'];
    if (user is Map<String, dynamic>) {
      return {
        ...user,
        'token': json['token'],
      };
    }
    throw Exception(GlowL10n.t('auth_missing'));
  }

  static String _authError(Map<String, dynamic> json) {
    final key = json['errorKey'] as String?;
    if (key != null && key.isNotEmpty) return GlowL10n.t(key);
    switch (json['error'] as String?) {
      case 'Email or password does not match.':
        return GlowL10n.t('err_email_pass');
      case 'An account with this email already exists.':
        return GlowL10n.t('auth_exists');
      case 'Name, email and a password of at least 6 characters.':
        return GlowL10n.t('login_fields');
      case 'Unsupported social login.':
        return GlowL10n.t('auth_social');
      default:
        return json['error'] as String? ?? GlowL10n.t('auth_failed');
    }
  }
}
