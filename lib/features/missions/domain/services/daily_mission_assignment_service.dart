import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';

class DailyMissionAvailability {
  const DailyMissionAvailability({
    required this.eventActive,
    required this.locationAvailable,
  });

  const DailyMissionAvailability.standard()
    : eventActive = false,
      locationAvailable = true;

  final bool eventActive;
  final bool locationAvailable;
}

class DailyMissionDatePolicy {
  const DailyMissionDatePolicy();

  String localDateKey(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

class DailyMissionAssignmentService {
  const DailyMissionAssignmentService();

  static const missionCount = 3;

  List<DailyMission> assign({
    required String playerId,
    required String dateKey,
    required DailyMissionAvailability availability,
    String generationSalt = '',
  }) {
    final candidates =
        _definitions
            .where(
              (definition) =>
                  (!definition.requiresEvent || availability.eventActive) &&
                  (!definition.requiresLocation ||
                      availability.locationAvailable),
            )
            .toList(growable: false)
          ..sort((left, right) {
            final leftScore = _stableHash(
              '$playerId|$dateKey|$generationSalt|${left.definitionId}',
            );
            final rightScore = _stableHash(
              '$playerId|$dateKey|$generationSalt|${right.definitionId}',
            );
            final scoreComparison = leftScore.compareTo(rightScore);
            return scoreComparison != 0
                ? scoreComparison
                : left.definitionId.compareTo(right.definitionId);
          });

    final selected = <_DailyMissionDefinition>[];
    final selectedTypes = <DailyMissionType>{};
    for (final candidate in candidates) {
      if (!selectedTypes.add(candidate.missionType)) continue;
      selected.add(candidate);
      if (selected.length == missionCount) break;
    }
    if (selected.length != missionCount) {
      throw StateError('Daily mission pool cannot provide three missions.');
    }

    return List.unmodifiable([
      for (var index = 0; index < selected.length; index += 1)
        selected[index].create(dateKey: dateKey, sortOrder: index),
    ]);
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static const _definitions = <_DailyMissionDefinition>[
    _DailyMissionDefinition(
      definitionId: 'discover_1',
      missionType: DailyMissionType.discoverCats,
      titleKey: DailyMissionTextKey.discoverOneCatTitle,
      descriptionKey: DailyMissionTextKey.discoverOneCatDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 50,
    ),
    _DailyMissionDefinition(
      definitionId: 'discover_2',
      missionType: DailyMissionType.discoverCats,
      titleKey: DailyMissionTextKey.discoverTwoCatsTitle,
      descriptionKey: DailyMissionTextKey.discoverTwoCatsDescription,
      targetValue: 2,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 100,
    ),
    _DailyMissionDefinition(
      definitionId: 'normal_card_1',
      missionType: DailyMissionType.generateNormalCard,
      titleKey: DailyMissionTextKey.generateNormalCardTitle,
      descriptionKey: DailyMissionTextKey.generateNormalCardDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.cardCredit,
      rewardAmount: 1,
    ),
    _DailyMissionDefinition(
      definitionId: 'open_map_1',
      missionType: DailyMissionType.openMap,
      titleKey: DailyMissionTextKey.openMapTitle,
      descriptionKey: DailyMissionTextKey.openMapDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 25,
    ),
    _DailyMissionDefinition(
      definitionId: 'location_1',
      missionType: DailyMissionType.discoverWithLocation,
      titleKey: DailyMissionTextKey.discoverWithLocationTitle,
      descriptionKey: DailyMissionTextKey.discoverWithLocationDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.analysisCredit,
      rewardAmount: 1,
      requiresLocation: true,
    ),
    _DailyMissionDefinition(
      definitionId: 'rarity_common_1',
      missionType: DailyMissionType.discoverRarity,
      titleKey: DailyMissionTextKey.discoverCommonTitle,
      descriptionKey: DailyMissionTextKey.discoverCommonDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 40,
      targetRarity: CatRarity.common,
    ),
    _DailyMissionDefinition(
      definitionId: 'rarity_uncommon_1',
      missionType: DailyMissionType.discoverRarity,
      titleKey: DailyMissionTextKey.discoverUncommonTitle,
      descriptionKey: DailyMissionTextKey.discoverUncommonDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 75,
      targetRarity: CatRarity.uncommon,
    ),
    _DailyMissionDefinition(
      definitionId: 'event_card_1',
      missionType: DailyMissionType.generateEventCard,
      titleKey: DailyMissionTextKey.generateEventCardTitle,
      descriptionKey: DailyMissionTextKey.generateEventCardDescription,
      targetValue: 1,
      rewardType: DailyMissionRewardType.xp,
      rewardAmount: 100,
      requiresEvent: true,
    ),
  ];
}

class _DailyMissionDefinition {
  const _DailyMissionDefinition({
    required this.definitionId,
    required this.missionType,
    required this.titleKey,
    required this.descriptionKey,
    required this.targetValue,
    required this.rewardType,
    required this.rewardAmount,
    this.targetRarity,
    this.requiresEvent = false,
    this.requiresLocation = false,
  });

  final String definitionId;
  final DailyMissionType missionType;
  final DailyMissionTextKey titleKey;
  final DailyMissionTextKey descriptionKey;
  final int targetValue;
  final DailyMissionRewardType rewardType;
  final int rewardAmount;
  final CatRarity? targetRarity;
  final bool requiresEvent;
  final bool requiresLocation;

  DailyMission create({required String dateKey, required int sortOrder}) {
    return DailyMission(
      missionId: 'daily:$dateKey:$definitionId',
      missionType: missionType,
      localizedTitleKey: titleKey,
      localizedDescriptionKey: descriptionKey,
      targetValue: targetValue,
      currentValue: 0,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
      status: DailyMissionStatus.active,
      assignedDate: dateKey,
      targetRarity: targetRarity,
      schemaVersion: DailyMission.currentSchemaVersion,
      sortOrder: sortOrder,
    );
  }
}
