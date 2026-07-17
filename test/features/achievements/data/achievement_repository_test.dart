import 'package:catdex/features/achievements/data/shared_preferences_achievement_repository.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('progress survives repository recreation', () async {
    const first = SharedPreferencesAchievementRepository();
    final definition = AchievementCatalogV1.definitions.first;
    final achievement = PlayerAchievement.initial(definition).copyWith(
      currentValue: 1,
      status: PlayerAchievementStatus.unlocked,
      unlockedAt: DateTime.utc(2026, 7, 17),
    );
    await first.save(
      AchievementLedger.empty('player').copyWith(
        achievements: {definition.achievementId: achievement},
      ),
    );

    const recreated = SharedPreferencesAchievementRepository();
    final restored = await recreated.load('player');

    expect(restored.achievements['first_discovery']?.isUnlocked, isTrue);
  });

  test('repository exposes centralized definitions', () async {
    const repository = SharedPreferencesAchievementRepository();
    expect(await repository.loadDefinitions(), hasLength(27));
  });

  test(
    'category completion is calculated from persisted unlock state',
    () async {
      const repository = SharedPreferencesAchievementRepository();
      final definition = AchievementCatalogV1.definitions.first;
      await repository.saveProgress(
        'player',
        PlayerAchievement.initial(definition).copyWith(
          currentValue: 1,
          status: PlayerAchievementStatus.unlocked,
        ),
      );

      final completion = await repository.calculateCategoryCompletion(
        'player',
        AchievementCategory.discoveries,
      );
      expect(completion.unlocked, 1);
      expect(completion.total, 6);
    },
  );
}
