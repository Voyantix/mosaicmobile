import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoyantixSupabaseConfig {
  const VoyantixSupabaseConfig._();

  static const projectUrl = 'https://ppkjgmgmbpwmcavlmgaq.supabase.co';
  static const _dartDefineAnonKey = String.fromEnvironment(
    'VOYANTIX_SUPABASE_ANON_KEY',
  );
  static String? _runtimeAnonKey;

  static void setRuntimeAnonKey(String value) {
    if (value.isNotEmpty) {
      _runtimeAnonKey = value;
    }
  }

  static String get anonKey {
    if (_dartDefineAnonKey.isNotEmpty) return _dartDefineAnonKey;
    if (_runtimeAnonKey != null) return _runtimeAnonKey!;
    return dotenv.maybeGet('VOYANTIX_SUPABASE_ANON_KEY') ?? '';
  }

  static bool get isConfigured => anonKey.isNotEmpty;
}
