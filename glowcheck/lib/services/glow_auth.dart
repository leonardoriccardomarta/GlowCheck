import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../config/app_env.dart';
import '../l10n/glow_l10n.dart';
import '../state/glow_store.dart';

class GlowAuth {
  GlowAuth._();

  static bool get emailReady => AppEnv.authApiReady;
  static bool get googleReady => AppEnv.authApiReady && AppEnv.googleReady;
  static bool get nativeApple =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get appleReady => AppEnv.appleReady || nativeApple;

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
        isPro: user['isPro'] == true,
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
        isPro: user['isPro'] == true,
      );
      return;
    }
    await GlowStore.instance.signInEmail(email: email, password: password);
  }

  static Future<void> social(String provider) async {
    if (provider == 'apple' && nativeApple) {
      await _appleNative();
      return;
    }
    if (provider == 'google' && AppEnv.authApiReady && AppEnv.googleReady) {
      await _google();
      return;
    }
    if (AppEnv.authApiReady && provider == 'apple' && AppEnv.appleReady) {
      final user = await _post('/auth/social', {
        'provider': provider,
        'clientId': AppEnv.appleServiceId,
      });
      await GlowStore.instance.applySession(
        name: user['name'] as String? ?? GlowL10n.t('apple_user'),
        email: user['email'] as String? ?? 'apple@glowcheck.local',
        provider: provider,
        token: user['token'] as String?,
        isPro: user['isPro'] == true,
      );
      return;
    }
    await GlowStore.instance.signInSocial(provider);
  }

  static Future<void> _google() async {
    final google = GoogleSignIn(
      clientId: AppEnv.googleClientId,
      scopes: const ['email', 'profile', 'openid'],
    );
    final account = await google.signIn();
    if (account == null) {
      throw Exception(GlowL10n.t('auth_failed'));
    }
    final tokens = await account.authentication;
    final idToken = tokens.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(GlowL10n.t('auth_failed'));
    }
    final user = await _post('/auth/social', {
      'provider': 'google',
      'clientId': AppEnv.googleClientId,
      'email': account.email,
      'name': account.displayName ?? '',
      'idToken': idToken,
    });
    await GlowStore.instance.applySession(
      name: user['name'] as String? ?? account.displayName ?? GlowL10n.t('google_user'),
      email: user['email'] as String? ?? account.email,
      provider: 'google',
      token: user['token'] as String?,
      isPro: user['isPro'] == true,
    );
  }

  static Future<void> _appleNative() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final name = [
      credential.givenName,
      credential.familyName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    final email = (credential.email ?? '').trim();
    final token = credential.identityToken;
    if (AppEnv.authApiReady) {
      final user = await _post('/auth/social', {
        'provider': 'apple',
        'clientId': AppEnv.appleServiceId.isNotEmpty ? AppEnv.appleServiceId : 'com.glowcheck.app',
        if (email.isNotEmpty) 'email': email,
        if (name.isNotEmpty) 'name': name,
        if (token != null && token.isNotEmpty) 'idToken': token,
      });
      await GlowStore.instance.applySession(
        name: user['name'] as String? ?? (name.isEmpty ? GlowL10n.t('apple_user') : name),
        email: user['email'] as String? ?? (email.isEmpty ? 'apple@glowcheck.local' : email),
        provider: 'apple',
        token: user['token'] as String?,
        isPro: user['isPro'] == true,
      );
      return;
    }
    await GlowStore.instance.signInSocial(
      'apple',
      name: name.isEmpty ? null : name,
      email: email.isEmpty ? null : email,
    );
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
      throw Exception(GlowL10n.t('auth_unreachable'));
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
        'isPro': json['isPro'] == true,
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
