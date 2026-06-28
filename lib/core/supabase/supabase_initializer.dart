import 'package:catdex/core/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } on Object {
      AppConfig.markSupabaseUnavailable();
    }
  }
}
