import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('Supabase migration defines required tables and RLS policies', () {
    final migration = File(
      'backend/supabase/migrations/202606280001_create_catdex_cloud_schema.sql',
    );

    expect(migration.existsSync(), isTrue);

    final sql = migration.readAsStringSync();
    const tables = [
      'profiles',
      'cat_species',
      'cat_variants',
      'discoveries',
      'discovery_traits',
      'achievements',
      'user_achievements',
      'badges',
      'user_badges',
      'scan_history',
    ];

    for (final table in tables) {
      expect(sql, contains('create table if not exists public.$table'));
      expect(
        sql,
        contains('alter table public.$table enable row level security'),
      );
    }

    expect(sql, contains('profiles_select_own'));
    expect(sql, contains('discoveries_select_own'));
    expect(sql, contains('discoveries_insert_own'));
    expect(sql, contains('cat_species_public_read'));
    expect(sql, contains('cat_variants_public_read'));
  });

  test('Supabase seed files exist for master data', () {
    const seedFiles = [
      'backend/supabase/seed/001_cat_variants.sql',
      'backend/supabase/seed/002_cat_species.sql',
      'backend/supabase/seed/003_achievements.sql',
      'backend/supabase/seed/004_badges.sql',
    ];

    for (final path in seedFiles) {
      final file = File(path);

      expect(file.existsSync(), isTrue);
      expect(file.readAsStringSync(), contains('insert into public.'));
    }
  });

  test('collectible card migration defines ownership and uniqueness', () {
    final migration = File(
      'supabase/migrations/202607160001_create_cat_cards.sql',
    );

    expect(migration.existsSync(), isTrue);
    final sql = migration.readAsStringSync();
    expect(sql, contains('create table if not exists public.cat_cards'));
    expect(sql, contains('cat_cards_normal_unique'));
    expect(sql, contains("where card_type = 'normal'"));
    expect(sql, contains('cat_cards_event_unique'));
    expect(sql, contains('event_artwork_variant_id'));
    expect(
      sql,
      contains('alter table public.cat_cards enable row level security'),
    );
    expect(sql, contains('cat_cards_select_own'));
    expect(sql, contains('cat_cards_insert_own'));
    expect(sql, contains('auth.uid() = user_id'));
  });
}
