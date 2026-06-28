import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/features/auth/application/auth_controller.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward_calculator.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final catDexRepositoryProvider = Provider<CatDexRepository>((ref) {
  if (_cloudUserId(ref) != null) {
    return SupabaseCatDexRepository(supabase.Supabase.instance.client);
  }

  return InMemoryCatDexRepository();
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final userId = _cloudUserId(ref);
  if (userId != null) {
    return SupabaseDiscoveryRepository(
      client: supabase.Supabase.instance.client,
      userId: userId,
    );
  }

  return InMemoryDiscoveryRepository();
});

final playerProgressRepositoryProvider = Provider<PlayerProgressRepository>((
  ref,
) {
  if (_cloudUserId(ref) != null) {
    return SupabasePlayerProgressRepository(supabase.Supabase.instance.client);
  }

  return InMemoryPlayerProgressRepository();
});

final discoveryRewardCalculatorProvider = Provider<DiscoveryRewardCalculator>((
  _,
) {
  return const DiscoveryRewardCalculator();
});

final levelCalculatorProvider = Provider<LevelCalculator>((_) {
  return const LevelCalculator();
});

String? _cloudUserId(Ref ref) {
  if (!AppConfig.hasSupabaseConfig) {
    return null;
  }

  final authState = ref.watch(authControllerProvider);
  final session = switch (authState) {
    AsyncData(:final value) => value,
    _ => const AuthSession.guest(),
  };

  return session.user?.id;
}
