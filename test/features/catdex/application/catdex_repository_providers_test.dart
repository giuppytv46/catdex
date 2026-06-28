import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses in-memory repositories when Supabase is not configured', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(catDexRepositoryProvider),
      isA<InMemoryCatDexRepository>(),
    );
    expect(
      container.read(discoveryRepositoryProvider),
      isA<InMemoryDiscoveryRepository>(),
    );
    expect(
      container.read(playerProgressRepositoryProvider),
      isA<InMemoryPlayerProgressRepository>(),
    );
  });
}
