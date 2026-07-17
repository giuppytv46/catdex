import 'package:catdex/features/missions/data/shared_preferences_daily_mission_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mission_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mission state survives repository recreation', () async {
    const first = SharedPreferencesDailyMissionRepository();
    final ledger = testLedger();
    await first.save(ledger);

    const recreated = SharedPreferencesDailyMissionRepository();
    final restored = await recreated.load('player-one');

    expect(restored?.assignedDate, ledger.assignedDate);
    expect(
      restored?.missions.map((mission) => mission.missionId),
      ledger.missions.map((mission) => mission.missionId),
    );
  });

  test('processed operation ids survive repository recreation', () async {
    const repository = SharedPreferencesDailyMissionRepository();
    await repository.save(testLedger(processed: {'discoverySaved:one'}));

    final restored = await const SharedPreferencesDailyMissionRepository().load(
      'player-one',
    );

    expect(restored?.processedOperationIds, contains('discoverySaved:one'));
  });

  test('claim transactions survive repository recreation', () async {
    final ledger = testLedger();
    const repository = SharedPreferencesDailyMissionRepository();
    await repository.save(ledger);

    final restored = await repository.load('player-one');
    expect(restored?.claimTransactions, isEmpty);
  });

  test('different player cannot read another mission ledger', () async {
    const repository = SharedPreferencesDailyMissionRepository();
    await repository.save(testLedger());

    expect(await repository.load('player-two'), isNull);
  });
}
