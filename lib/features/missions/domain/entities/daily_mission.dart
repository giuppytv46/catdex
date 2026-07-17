import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter/foundation.dart';

enum DailyMissionType {
  discoverCats,
  generateNormalCard,
  openMap,
  discoverWithLocation,
  discoverRarity,
  generateEventCard,
}

enum DailyMissionRewardType { xp, analysisCredit, cardCredit }

enum DailyMissionStatus { active, completed, claimed, expired }

enum DailyMissionTextKey {
  discoverOneCatTitle,
  discoverOneCatDescription,
  discoverTwoCatsTitle,
  discoverTwoCatsDescription,
  generateNormalCardTitle,
  generateNormalCardDescription,
  openMapTitle,
  openMapDescription,
  discoverWithLocationTitle,
  discoverWithLocationDescription,
  discoverCommonTitle,
  discoverCommonDescription,
  discoverUncommonTitle,
  discoverUncommonDescription,
  generateEventCardTitle,
  generateEventCardDescription,
}

@immutable
class DailyMission {
  const DailyMission({
    required this.missionId,
    required this.missionType,
    required this.localizedTitleKey,
    required this.localizedDescriptionKey,
    required this.targetValue,
    required this.currentValue,
    required this.rewardType,
    required this.rewardAmount,
    required this.status,
    required this.assignedDate,
    required this.schemaVersion,
    required this.sortOrder,
    this.targetRarity,
    this.completedAt,
    this.claimedAt,
  }) : assert(targetValue > 0, 'targetValue must be positive'),
       assert(currentValue >= 0, 'currentValue cannot be negative'),
       assert(rewardAmount > 0, 'rewardAmount must be positive');

  static const currentSchemaVersion = 1;

  final String missionId;
  final DailyMissionType missionType;
  final DailyMissionTextKey localizedTitleKey;
  final DailyMissionTextKey localizedDescriptionKey;
  final int targetValue;
  final int currentValue;
  final DailyMissionRewardType rewardType;
  final int rewardAmount;
  final DailyMissionStatus status;
  final String assignedDate;
  final CatRarity? targetRarity;
  final DateTime? completedAt;
  final DateTime? claimedAt;
  final int schemaVersion;
  final int sortOrder;

  double get progress => (currentValue / targetValue).clamp(0, 1);
  bool get isActive => status == DailyMissionStatus.active;
  bool get isCompleted => status == DailyMissionStatus.completed;
  bool get isClaimed => status == DailyMissionStatus.claimed;
  bool get isClaimable => isCompleted;

  DailyMission copyWith({
    int? currentValue,
    DailyMissionStatus? status,
    DateTime? completedAt,
    DateTime? claimedAt,
    bool clearCompletedAt = false,
    bool clearClaimedAt = false,
    int? sortOrder,
  }) {
    return DailyMission(
      missionId: missionId,
      missionType: missionType,
      localizedTitleKey: localizedTitleKey,
      localizedDescriptionKey: localizedDescriptionKey,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
      status: status ?? this.status,
      assignedDate: assignedDate,
      targetRarity: targetRarity,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
      claimedAt: clearClaimedAt ? null : claimedAt ?? this.claimedAt,
      schemaVersion: schemaVersion,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'missionId': missionId,
      'missionType': missionType.name,
      'localizedTitleKey': localizedTitleKey.name,
      'localizedDescriptionKey': localizedDescriptionKey.name,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'rewardType': rewardType.name,
      'rewardAmount': rewardAmount,
      'status': status.name,
      'assignedDate': assignedDate,
      'targetRarity': targetRarity?.name,
      'completedAt': completedAt?.toIso8601String(),
      'claimedAt': claimedAt?.toIso8601String(),
      'schemaVersion': schemaVersion,
      'sortOrder': sortOrder,
    };
  }

  // Kept beside toJson so the persistence contract is reviewed as one block.
  // ignore: sort_constructors_first
  factory DailyMission.fromJson(Map<String, Object?> json) {
    return DailyMission(
      missionId: json['missionId']! as String,
      missionType: _enumByName(
        DailyMissionType.values,
        json['missionType'] as String?,
        DailyMissionType.discoverCats,
      ),
      localizedTitleKey: _enumByName(
        DailyMissionTextKey.values,
        json['localizedTitleKey'] as String?,
        DailyMissionTextKey.discoverOneCatTitle,
      ),
      localizedDescriptionKey: _enumByName(
        DailyMissionTextKey.values,
        json['localizedDescriptionKey'] as String?,
        DailyMissionTextKey.discoverOneCatDescription,
      ),
      targetValue: json['targetValue'] as int? ?? 1,
      currentValue: json['currentValue'] as int? ?? 0,
      rewardType: _enumByName(
        DailyMissionRewardType.values,
        json['rewardType'] as String?,
        DailyMissionRewardType.xp,
      ),
      rewardAmount: json['rewardAmount'] as int? ?? 1,
      status: _enumByName(
        DailyMissionStatus.values,
        json['status'] as String?,
        DailyMissionStatus.active,
      ),
      assignedDate: json['assignedDate']! as String,
      targetRarity: _nullableEnumByName(
        CatRarity.values,
        json['targetRarity'] as String?,
      ),
      completedAt: _date(json['completedAt']),
      claimedAt: _date(json['claimedAt']),
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

T? _nullableEnumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}

DateTime? _date(Object? value) {
  final raw = value as String?;
  return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
}
