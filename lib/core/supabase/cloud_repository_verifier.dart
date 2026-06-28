import 'package:catdex/features/catdex/domain/repositories/catdex_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';

enum CloudRepositoryVerificationStatus {
  skippedGuestMode,
  healthy,
  failed,
}

class CloudRepositoryVerification {
  const CloudRepositoryVerification({
    required this.status,
    this.message,
  });

  final CloudRepositoryVerificationStatus status;
  final String? message;
}

class CloudRepositoryVerifier {
  const CloudRepositoryVerifier({
    required CatDexRepository catDexRepository,
    required PlayerProgressRepository playerProgressRepository,
  }) : _catDexRepository = catDexRepository,
       _playerProgressRepository = playerProgressRepository;

  final CatDexRepository _catDexRepository;
  final PlayerProgressRepository _playerProgressRepository;

  Future<CloudRepositoryVerification> verify({
    required String? userId,
  }) async {
    if (userId == null) {
      return const CloudRepositoryVerification(
        status: CloudRepositoryVerificationStatus.skippedGuestMode,
      );
    }

    try {
      await _catDexRepository.getSpecies();
      await _catDexRepository.getVariants();
      final progress = await _playerProgressRepository.getProgress(userId);
      await _playerProgressRepository.saveProgress(progress);
    } on Object {
      return const CloudRepositoryVerification(
        status: CloudRepositoryVerificationStatus.failed,
        message: 'CatDex could not verify Supabase repository access.',
      );
    }

    return const CloudRepositoryVerification(
      status: CloudRepositoryVerificationStatus.healthy,
    );
  }
}
