import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('player progress survives repository recreation', () async {
    const progress = PlayerProgress(
      playerId: 'guest-player',
      totalXp: 840,
      level: 7,
      coins: 125,
      discoveryCount: 12,
      duplicateDiscoveryCount: 2,
      achievementIds: ['first-discovery', 'collector'],
      badgeIds: ['alpha-tester'],
    );
    const repository = SharedPreferencesPlayerProgressRepository();

    await repository.saveProgress(progress);

    const restartedRepository = SharedPreferencesPlayerProgressRepository();
    final restored = await restartedRepository.getProgress('guest-player');

    expect(restored.totalXp, 840);
    expect(restored.level, 7);
    expect(restored.coins, 125);
    expect(restored.discoveryCount, 12);
    expect(restored.duplicateDiscoveryCount, 2);
    expect(restored.achievementIds, ['first-discovery', 'collector']);
    expect(restored.badgeIds, ['alpha-tester']);
  });

  test('corrupt progress falls back without crashing restoration', () async {
    SharedPreferences.setMockInitialValues({
      'catdex_player_progress_guest-player': '{broken-json',
    });
    const fallback = PlayerProgress(
      playerId: 'guest-player',
      totalXp: 20,
      level: 2,
      coins: 5,
      discoveryCount: 1,
      duplicateDiscoveryCount: 0,
      achievementIds: [],
      badgeIds: [],
    );
    const repository = SharedPreferencesPlayerProgressRepository(
      fallbackProgress: fallback,
    );

    final restored = await repository.getProgress('guest-player');

    expect(restored.totalXp, 20);
    expect(restored.level, 2);
  });
}
