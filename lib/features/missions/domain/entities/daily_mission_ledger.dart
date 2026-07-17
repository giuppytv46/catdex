import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:flutter/foundation.dart';

enum DailyMissionClaimTransactionStatus { started, completed }

@immutable
class DailyMissionClaimTransaction {
  const DailyMissionClaimTransaction({
    required this.transactionId,
    required this.missionId,
    required this.rewardType,
    required this.rewardAmount,
    required this.baselineValue,
    required this.expectedValue,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String transactionId;
  final String missionId;
  final DailyMissionRewardType rewardType;
  final int rewardAmount;
  final int baselineValue;
  final int expectedValue;
  final DailyMissionClaimTransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  DailyMissionClaimTransaction copyWith({
    DailyMissionClaimTransactionStatus? status,
    DateTime? updatedAt,
  }) {
    return DailyMissionClaimTransaction(
      transactionId: transactionId,
      missionId: missionId,
      rewardType: rewardType,
      rewardAmount: rewardAmount,
      baselineValue: baselineValue,
      expectedValue: expectedValue,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'transactionId': transactionId,
      'missionId': missionId,
      'rewardType': rewardType.name,
      'rewardAmount': rewardAmount,
      'baselineValue': baselineValue,
      'expectedValue': expectedValue,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Kept beside toJson so the persistence contract is reviewed as one block.
  // ignore: sort_constructors_first
  factory DailyMissionClaimTransaction.fromJson(Map<String, Object?> json) {
    final statusName = json['status'] as String?;
    return DailyMissionClaimTransaction(
      transactionId: json['transactionId']! as String,
      missionId: json['missionId']! as String,
      rewardType: DailyMissionRewardType.values.firstWhere(
        (value) => value.name == json['rewardType'],
        orElse: () => DailyMissionRewardType.xp,
      ),
      rewardAmount: json['rewardAmount'] as int? ?? 1,
      baselineValue: json['baselineValue'] as int? ?? 0,
      expectedValue: json['expectedValue'] as int? ?? 0,
      status: DailyMissionClaimTransactionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => DailyMissionClaimTransactionStatus.started,
      ),
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
    );
  }
}

@immutable
class DailyMissionLedger {
  const DailyMissionLedger({
    required this.playerId,
    required this.assignedDate,
    required this.lastResetDate,
    required this.missions,
    required this.expiredMissions,
    required this.processedOperationIds,
    required this.claimTransactions,
    required this.schemaVersion,
  });

  static const currentSchemaVersion = 1;

  final String playerId;
  final String assignedDate;
  final String lastResetDate;
  final List<DailyMission> missions;
  final List<DailyMission> expiredMissions;
  final Set<String> processedOperationIds;
  final Map<String, DailyMissionClaimTransaction> claimTransactions;
  final int schemaVersion;

  int get completedCount => missions
      .where(
        (mission) =>
            mission.status == DailyMissionStatus.completed ||
            mission.status == DailyMissionStatus.claimed,
      )
      .length;

  int get claimedCount => missions.where((mission) => mission.isClaimed).length;

  DailyMissionLedger copyWith({
    String? assignedDate,
    String? lastResetDate,
    List<DailyMission>? missions,
    List<DailyMission>? expiredMissions,
    Set<String>? processedOperationIds,
    Map<String, DailyMissionClaimTransaction>? claimTransactions,
  }) {
    return DailyMissionLedger(
      playerId: playerId,
      assignedDate: assignedDate ?? this.assignedDate,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      missions: List.unmodifiable(missions ?? this.missions),
      expiredMissions: List.unmodifiable(
        expiredMissions ?? this.expiredMissions,
      ),
      processedOperationIds: Set.unmodifiable(
        processedOperationIds ?? this.processedOperationIds,
      ),
      claimTransactions: Map.unmodifiable(
        claimTransactions ?? this.claimTransactions,
      ),
      schemaVersion: schemaVersion,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': playerId,
      'assignedDate': assignedDate,
      'lastResetDate': lastResetDate,
      'missions': missions.map((mission) => mission.toJson()).toList(),
      'expiredMissions': expiredMissions
          .map((mission) => mission.toJson())
          .toList(),
      'processedOperationIds': processedOperationIds.toList()..sort(),
      'claimTransactions': {
        for (final entry in claimTransactions.entries)
          entry.key: entry.value.toJson(),
      },
      'schemaVersion': schemaVersion,
    };
  }

  // Kept beside toJson so the persistence contract is reviewed as one block.
  // ignore: sort_constructors_first
  factory DailyMissionLedger.fromJson(Map<String, Object?> json) {
    final rawTransactions = Map<String, dynamic>.from(
      json['claimTransactions'] as Map<dynamic, dynamic>? ?? const {},
    );
    return DailyMissionLedger(
      playerId: json['playerId']! as String,
      assignedDate: json['assignedDate']! as String,
      lastResetDate: json['lastResetDate']! as String,
      missions: _missionList(json['missions']),
      expiredMissions: _missionList(json['expiredMissions']),
      processedOperationIds: Set.unmodifiable(
        (json['processedOperationIds'] as List<dynamic>? ?? const [])
            .whereType<String>(),
      ),
      claimTransactions: Map.unmodifiable({
        for (final entry in rawTransactions.entries)
          entry.key: DailyMissionClaimTransaction.fromJson(
            Map<String, Object?>.from(entry.value as Map<dynamic, dynamic>),
          ),
      }),
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}

List<DailyMission> _missionList(Object? raw) {
  return (raw as List<dynamic>? ?? const [])
      .whereType<Map<dynamic, dynamic>>()
      .map(
        (value) => DailyMission.fromJson(Map<String, Object?>.from(value)),
      )
      .toList(growable: false);
}
