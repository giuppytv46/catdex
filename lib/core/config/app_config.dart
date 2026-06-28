import 'dart:io';

import 'package:catdex/core/config/env_file_parser.dart';

class AppConfig {
  const AppConfig._();

  static const appName = 'CatDex';
  static const _dartDefinedSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const _dartDefinedSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String? _envSupabaseUrl;
  static String? _envSupabaseAnonKey;
  static bool _supabaseInitializationAvailable = true;

  static String get supabaseUrl {
    return _envSupabaseUrl ?? _dartDefinedSupabaseUrl;
  }

  static String get supabaseAnonKey {
    return _envSupabaseAnonKey ?? _dartDefinedSupabaseAnonKey;
  }

  static bool get hasSupabaseConfig {
    return _supabaseInitializationAvailable &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }

  static Future<void> loadDotEnv({
    String path = '.env',
    EnvFileParser parser = const EnvFileParser(),
  }) async {
    final file = File(path);
    if (!file.existsSync()) {
      return;
    }

    configureFromEnvironment(parser.parse(await file.readAsString()));
  }

  static void configureFromEnvironment(Map<String, String> values) {
    final supabaseUrl = values['SUPABASE_URL']?.trim();
    final supabaseAnonKey = values['SUPABASE_ANON_KEY']?.trim();

    if (supabaseUrl != null && supabaseUrl.isNotEmpty) {
      _envSupabaseUrl = supabaseUrl;
    }

    if (supabaseAnonKey != null && supabaseAnonKey.isNotEmpty) {
      _envSupabaseAnonKey = supabaseAnonKey;
    }
  }

  static void markSupabaseUnavailable() {
    _supabaseInitializationAvailable = false;
  }

  static void resetForTests() {
    _envSupabaseUrl = null;
    _envSupabaseAnonKey = null;
    _supabaseInitializationAvailable = true;
  }
}
