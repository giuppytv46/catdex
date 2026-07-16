import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/features/auth/application/auth_controller.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_pending_sync_queue_repository.dart';
import 'package:catdex/features/catdex/data/repositories/merged_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_catdex_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/supabase_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/pending_sync_queue_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward_calculator.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final supabaseConfiguredProvider = Provider<bool>((_) {
  return AppConfig.hasSupabaseConfig;
});

final supabaseClientProvider = Provider<supabase.SupabaseClient>((_) {
  return supabase.Supabase.instance.client;
});

final cloudUserIdProvider = Provider<String?>(_cloudUserId);

final activeCatDexSessionProvider = Provider<ActiveCatDexSession>((ref) {
  final userId = ref.watch(cloudUserIdProvider);
  if (userId != null) {
    return ActiveCatDexSession.cloud(playerId: userId);
  }

  return const ActiveCatDexSession.guest(
    playerId: LocalPlayerSession.playerId,
  );
});

final catDexRepositoryProvider = Provider<CatDexRepository>((ref) {
  if (ref.watch(cloudUserIdProvider) != null) {
    return SupabaseCatDexRepository(ref.watch(supabaseClientProvider));
  }

  return InMemoryCatDexRepository();
});

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final userId = ref.watch(cloudUserIdProvider);
  if (userId != null) {
    return MergedDiscoveryRepository(
      localRepository: const SharedPreferencesDiscoveryRepository(),
      remoteRepository: SupabaseDiscoveryRepository(
        client: ref.watch(supabaseClientProvider),
        userId: userId,
      ),
    );
  }

  return const SharedPreferencesDiscoveryRepository();
});

final playerProgressRepositoryProvider = Provider<PlayerProgressRepository>((
  ref,
) {
  if (ref.watch(cloudUserIdProvider) != null) {
    return SupabasePlayerProgressRepository(ref.watch(supabaseClientProvider));
  }

  return const SharedPreferencesPlayerProgressRepository(
    fallbackProgress: LocalPlayerSession.initialProgress,
  );
});

final pendingSyncQueueRepositoryProvider = Provider<PendingSyncQueueRepository>(
  (
    _,
  ) {
    return InMemoryPendingSyncQueueRepository();
  },
);

final discoveryRewardCalculatorProvider = Provider<DiscoveryRewardCalculator>((
  _,
) {
  return const DiscoveryRewardCalculator();
});

final levelCalculatorProvider = Provider<LevelCalculator>((_) {
  return const LevelCalculator();
});

String? _cloudUserId(Ref ref) {
  if (!ref.watch(supabaseConfiguredProvider)) {
    return null;
  }

  final authState = ref.watch(authControllerProvider);
  final session = switch (authState) {
    AsyncData(:final value) => value,
    _ => const AuthSession.guest(),
  };

  return session.user?.id;
}
