import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_player_progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  test('uses local repositories when Supabase is not configured', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(catDexRepositoryProvider),
      isA<InMemoryCatDexRepository>(),
    );
    expect(
      container.read(discoveryRepositoryProvider),
      isA<SharedPreferencesDiscoveryRepository>(),
    );
    expect(
      container.read(playerProgressRepositoryProvider),
      isA<InMemoryPlayerProgressRepository>(),
    );
  });

  test('uses Supabase repositories when a cloud user is active', () {
    final container = ProviderContainer(
      overrides: [
        cloudUserIdProvider.overrideWithValue('user-1'),
        supabaseClientProvider.overrideWithValue(
          supabase.SupabaseClient('https://example.supabase.co', 'anon-key'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(catDexRepositoryProvider),
      isA<SupabaseCatDexRepository>(),
    );
    expect(
      container.read(discoveryRepositoryProvider),
      isA<SupabaseDiscoveryRepository>(),
    );
    expect(
      container.read(playerProgressRepositoryProvider),
      isA<SupabasePlayerProgressRepository>(),
    );
  });
}
