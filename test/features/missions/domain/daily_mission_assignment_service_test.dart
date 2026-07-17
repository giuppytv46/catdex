import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/services/daily_mission_assignment_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DailyMissionAssignmentService();

  List<DailyMission> assign({
    String player = 'player-one',
    String date = '2026-07-17',
    bool event = false,
    bool location = true,
  }) {
    return service.assign(
      playerId: player,
      dateKey: date,
      availability: DailyMissionAvailability(
        eventActive: event,
        locationAvailable: location,
      ),
    );
  }

  test('exactly three missions are assigned', () {
    expect(assign(), hasLength(3));
  });

  test('same player and date receive the same mission ids', () {
    expect(
      assign().map((mission) => mission.missionId),
      assign().map((mission) => mission.missionId),
    );
  });

  test('next day creates date-specific mission identities', () {
    final first = assign().map((mission) => mission.missionId).toSet();
    final next = assign(
      date: '2026-07-18',
    ).map((mission) => mission.missionId).toSet();
    expect(first.intersection(next), isEmpty);
  });

  test('inactive event prevents event mission assignment', () {
    expect(
      assign().where(
        (mission) => mission.missionType == DailyMissionType.generateEventCard,
      ),
      isEmpty,
    );
  });

  test('active event allows event mission assignment', () {
    var found = false;
    for (var day = 1; day <= 31 && !found; day += 1) {
      found =
          assign(
            date: '2026-10-${day.toString().padLeft(2, '0')}',
            event: true,
          ).any(
            (mission) =>
                mission.missionType == DailyMissionType.generateEventCard,
          );
    }
    expect(found, isTrue);
  });

  test('unavailable location excludes location mission', () {
    expect(
      assign(location: false).where(
        (mission) =>
            mission.missionType == DailyMissionType.discoverWithLocation,
      ),
      isEmpty,
    );
  });

  test('daily set never contains duplicate mission types', () {
    final missions = assign(event: true);
    expect(
      missions.map((mission) => mission.missionType).toSet(),
      hasLength(missions.length),
    );
  });

  test('rarity missions target only Common or Uncommon', () {
    for (var day = 1; day <= 20; day += 1) {
      final missions = assign(
        date: '2026-08-${day.toString().padLeft(2, '0')}',
      );
      for (final mission in missions.where(
        (item) => item.missionType == DailyMissionType.discoverRarity,
      )) {
        expect(
          mission.targetRarity,
          anyOf(CatRarity.common, CatRarity.uncommon),
        );
      }
    }
  });

  test('card mission reward is exactly one card credit', () {
    DailyMission? cardMission;
    for (var day = 1; day <= 31 && cardMission == null; day += 1) {
      final candidates =
          assign(
            date: '2026-09-${day.toString().padLeft(2, '0')}',
          ).where(
            (mission) =>
                mission.missionType == DailyMissionType.generateNormalCard,
          );
      if (candidates.isNotEmpty) cardMission = candidates.first;
    }
    expect(cardMission?.rewardType, DailyMissionRewardType.cardCredit);
    expect(cardMission?.rewardAmount, 1);
  });

  test('location mission reward is exactly one analysis credit', () {
    DailyMission? locationMission;
    for (var day = 1; day <= 31 && locationMission == null; day += 1) {
      final candidates =
          assign(
            date: '2026-11-${day.toString().padLeft(2, '0')}',
          ).where(
            (mission) =>
                mission.missionType == DailyMissionType.discoverWithLocation,
          );
      if (candidates.isNotEmpty) locationMission = candidates.first;
    }
    expect(locationMission?.rewardType, DailyMissionRewardType.analysisCredit);
    expect(locationMission?.rewardAmount, 1);
  });
}
