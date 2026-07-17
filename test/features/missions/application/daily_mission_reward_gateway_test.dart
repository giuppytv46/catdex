import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('XP reward updates persistent and session player progress', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final gateway = container.read(dailyMissionRewardGatewayProvider);
    final baseline = await gateway.currentValue(DailyMissionRewardType.xp);

    await gateway.ensureAtLeast(DailyMissionRewardType.xp, baseline + 50);

    expect(
      await gateway.currentValue(DailyMissionRewardType.xp),
      baseline + 50,
    );
    expect(
      container.read(localPlayerProgressSessionProvider).totalXp,
      baseline + 50,
    );
  });

  test('analysis credit reward updates monetization storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final gateway = container.read(dailyMissionRewardGatewayProvider);

    await gateway.ensureAtLeast(DailyMissionRewardType.analysisCredit, 1);

    expect(
      await gateway.currentValue(DailyMissionRewardType.analysisCredit),
      1,
    );
  });

  test('card credit reward updates monetization storage', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final gateway = container.read(dailyMissionRewardGatewayProvider);

    await gateway.ensureAtLeast(DailyMissionRewardType.cardCredit, 1);

    expect(await gateway.currentValue(DailyMissionRewardType.cardCredit), 1);
  });
}
