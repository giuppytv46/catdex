import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'session restores persisted XP without blocking initial state',
    () async {
      const repository = SharedPreferencesPlayerProgressRepository();
      await repository.saveProgress(
        const PlayerProgress(
          playerId: 'guest-test',
          totalXp: 450,
          level: 5,
          coins: 90,
          discoveryCount: 8,
          duplicateDiscoveryCount: 1,
          achievementIds: ['collector'],
          badgeIds: ['alpha'],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          activeCatDexSessionProvider.overrideWithValue(
            const ActiveCatDexSession.guest(playerId: 'guest-test'),
          ),
          playerProgressRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final initial = container.read(localPlayerProgressSessionProvider);
      expect(initial.totalXp, 0);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final restored = container.read(localPlayerProgressSessionProvider);
      expect(restored.totalXp, 450);
      expect(restored.level, 5);
      expect(restored.achievementIds, ['collector']);
      expect(restored.badgeIds, ['alpha']);
    },
  );
}
