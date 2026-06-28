import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/core/config/env_file_parser.dart';
import 'package:test/test.dart';

void main() {
  tearDown(AppConfig.resetForTests);

  test('parses dotenv values', () {
    const parser = EnvFileParser();

    final values = parser.parse('''
# CatDex local config
SUPABASE_URL="https://catdex.supabase.co"
SUPABASE_ANON_KEY='public-anon-key'
IGNORED_LINE
''');

    expect(values['SUPABASE_URL'], 'https://catdex.supabase.co');
    expect(values['SUPABASE_ANON_KEY'], 'public-anon-key');
    expect(values.containsKey('IGNORED_LINE'), isFalse);
  });

  test('stays in guest mode when Supabase env is missing', () {
    AppConfig.configureFromEnvironment(const {});

    expect(AppConfig.hasSupabaseConfig, isFalse);
  });

  test('uses configured Supabase env values', () {
    AppConfig.configureFromEnvironment({
      'SUPABASE_URL': 'https://catdex.supabase.co',
      'SUPABASE_ANON_KEY': 'public-anon-key',
    });

    expect(AppConfig.hasSupabaseConfig, isTrue);
    expect(AppConfig.supabaseUrl, 'https://catdex.supabase.co');
    expect(AppConfig.supabaseAnonKey, 'public-anon-key');
  });

  test('falls back to guest mode when Supabase is marked unavailable', () {
    AppConfig.configureFromEnvironment({
      'SUPABASE_URL': 'https://catdex.supabase.co',
      'SUPABASE_ANON_KEY': 'public-anon-key',
    });

    AppConfig.markSupabaseUnavailable();

    expect(AppConfig.hasSupabaseConfig, isFalse);
  });
}
