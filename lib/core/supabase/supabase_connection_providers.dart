import 'package:catdex/core/supabase/cloud_repository_verifier.dart';
import 'package:catdex/core/supabase/supabase_connection_health.dart';
import 'package:catdex/core/supabase/supabase_connection_health_service.dart';
import 'package:catdex/core/supabase/supabase_connection_probe.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConnectionProbeProvider = Provider<SupabaseConnectionProbe>((
  ref,
) {
  if (!ref.watch(supabaseConfiguredProvider)) {
    return const LocalModeSupabaseConnectionProbe();
  }

  return SupabaseConnectionProbeImpl(ref.watch(supabaseClientProvider));
});

final supabaseConnectionHealthServiceProvider =
    Provider<SupabaseConnectionHealthService>((ref) {
      return SupabaseConnectionHealthService(
        probe: ref.watch(supabaseConnectionProbeProvider),
        configured: ref.watch(supabaseConfiguredProvider),
      );
    });

final supabaseConnectionHealthProvider =
    FutureProvider<SupabaseConnectionHealth>((ref) {
      return ref.watch(supabaseConnectionHealthServiceProvider).check();
    });

final cloudRepositoryVerifierProvider = Provider<CloudRepositoryVerifier>((
  ref,
) {
  return CloudRepositoryVerifier(
    catDexRepository: ref.watch(catDexRepositoryProvider),
    playerProgressRepository: ref.watch(playerProgressRepositoryProvider),
  );
});

final cloudRepositoryVerificationProvider =
    FutureProvider<CloudRepositoryVerification>((ref) {
      final userId = ref.watch(cloudUserIdProvider);

      return ref.watch(cloudRepositoryVerifierProvider).verify(userId: userId);
    });
