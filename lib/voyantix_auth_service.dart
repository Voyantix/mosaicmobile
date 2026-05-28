import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'voyantix_supabase_config.dart';

class VoyantixAuthService {
  const VoyantixAuthService._();

  static bool _isInitialized = false;

  static bool get isReady =>
      VoyantixSupabaseConfig.isConfigured && _isInitialized;

  static SupabaseClient? get client {
    if (!isReady) return null;
    return Supabase.instance.client;
  }

  static User? get currentUser => client?.auth.currentUser;

  static Stream<AuthState>? get authStateChanges =>
      client?.auth.onAuthStateChange;

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    await _loadRuntimeEnvFallback();

    if (_isInitialized || !VoyantixSupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: VoyantixSupabaseConfig.projectUrl,
      anonKey: VoyantixSupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    _isInitialized = true;
  }

  static Future<void> _loadRuntimeEnvFallback() async {
    if (VoyantixSupabaseConfig.isConfigured) return;

    final separator = Platform.pathSeparator;
    final executableDirectory = File(
      Platform.resolvedExecutable,
    ).parent.path;
    final candidates = <File>[
      File('.env'),
      File('${Directory.current.path}$separator.env'),
      File('$executableDirectory$separator.env'),
      File(
        '$executableDirectory${separator}data${separator}flutter_assets$separator.env',
      ),
    ];

    for (final file in candidates) {
      if (!await file.exists()) continue;

      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        final separatorIndex = trimmed.indexOf('=');
        if (separatorIndex <= 0) continue;

        final key = trimmed.substring(0, separatorIndex).trim();
        final value = trimmed.substring(separatorIndex + 1).trim();
        if (key == 'VOYANTIX_SUPABASE_ANON_KEY') {
          VoyantixSupabaseConfig.setRuntimeAnonKey(value);
          return;
        }
      }
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final auth = client?.auth;
    if (auth == null) {
      throw const AuthException('Voyantix cloud saves are not configured.');
    }

    return auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final auth = client?.auth;
    if (auth == null) {
      throw const AuthException('Voyantix cloud saves are not configured.');
    }

    return auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await client?.auth.signOut();
  }
}
