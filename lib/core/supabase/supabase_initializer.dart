import 'package:catdex/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabaseConfig) {
      debugPrint('CATDEX_STARTUP_SUPABASE_OK skipped_no_config');
      return;
    }

    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
      debugPrint('CATDEX_STARTUP_SUPABASE_OK');
    } on Object catch (error) {
      AppConfig.markSupabaseUnavailable();
      debugPrint('CATDEX_STARTUP_SUPABASE_FAILED $error');
    }
  }
}
