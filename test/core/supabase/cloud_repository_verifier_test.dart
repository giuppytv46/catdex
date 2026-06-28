import 'package:catdex/core/supabase/cloud_repository_verifier.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/cat_variant.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:test/test.dart';

void main() {
  test('skips verification in guest mode', () async {
    final verifier = CloudRepositoryVerifier(
      catDexRepository: _HealthyCatDexRepository(),
      playerProgressRepository: _HealthyProgressRepository(),
    );

    final result = await verifier.verify(userId: null);

    expect(result.status, CloudRepositoryVerificationStatus.skippedGuestMode);
  });

  test('verifies cloud repository read and write path', () async {
    final progressRepository = _HealthyProgressRepository();
    final verifier = CloudRepositoryVerifier(
      catDexRepository: _HealthyCatDexRepository(),
      playerProgressRepository: progressRepository,
    );

    final result = await verifier.verify(userId: 'cloud-user');

    expect(result.status, CloudRepositoryVerificationStatus.healthy);
    expect(progressRepository.savedProgress?.playerId, 'cloud-user');
  });

  test('returns failed when repository access fails', () async {
    final verifier = CloudRepositoryVerifier(
      catDexRepository: _FailingCatDexRepository(),
      playerProgressRepository: _HealthyProgressRepository(),
    );

    final result = await verifier.verify(userId: 'cloud-user');

    expect(result.status, CloudRepositoryVerificationStatus.failed);
    expect(result.message, isNotEmpty);
  });
}

class _HealthyCatDexRepository implements CatDexRepository {
  @override
  Future<List<CatSpecies>> getSpecies() async {
    return CatDexSeedData.species.take(1).toList(growable: false);
  }

  @override
  Future<CatSpecies?> getSpeciesById(String id) async {
    return CatDexSeedData.species.first;
  }

  @override
  Future<List<CatVariant>> getVariants() async {
    return CatDexSeedData.variants.take(1).toList(growable: false);
  }

  @override
  Future<CatVariant?> getVariantById(String id) async {
    return CatDexSeedData.variants.first;
  }
}

class _FailingCatDexRepository extends _HealthyCatDexRepository {
  @override
  Future<List<CatSpecies>> getSpecies() async {
    throw StateError('unavailable');
  }
}

class _HealthyProgressRepository implements PlayerProgressRepository {
  PlayerProgress? savedProgress;

  @override
  Future<PlayerProgress> getProgress(String playerId) async {
    return PlayerProgress.empty(playerId);
  }

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    savedProgress = progress;
  }
}
