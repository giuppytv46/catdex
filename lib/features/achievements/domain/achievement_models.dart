// JSON factories stay beside their serializers so persistence can be audited.
// ignore_for_file: sort_constructors_first

import 'package:flutter/foundation.dart';

enum AchievementCategory {
  discoveries,
  collection,
  cards,
  rarity,
  exploration,
  missions,
  events,
  progression,
}

enum AchievementTier { bronze, silver, gold, platinum }

enum PlayerAchievementStatus { locked, inProgress, unlocked }

enum AchievementMetric {
  persistedDiscoveries,
  persistedNormalCards,
  uncommonDiscoveries,
  rareDiscoveries,
  epicDiscoveries,
  legendaryDiscoveries,
  geolocatedDiscoveries,
  claimedDailyMissions,
  persistedEventCards,
  halloweenFreeVariants,
  halloweenPremiumVariants,
  playerLevel,
}

enum AchievementRewardTransactionStatus { started, completed }

@immutable
class AchievementDefinition {
  const AchievementDefinition({
    required this.achievementId,
    required this.category,
    required this.metric,
    required this.localizedTitleKey,
    required this.localizedDescriptionKey,
    required this.localizedLockedHintKey,
    required this.iconKey,
    required this.targetValue,
    required this.rewardXp,
    required this.sortOrder,
    required this.tier,
    this.isEventSpecific = false,
    this.eventKey,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  final String achievementId;
  final AchievementCategory category;
  final AchievementMetric metric;
  final String localizedTitleKey;
  final String localizedDescriptionKey;
  final String localizedLockedHintKey;
  final String iconKey;
  final int targetValue;
  final int rewardXp;
  final int sortOrder;
  final AchievementTier tier;
  final bool isEventSpecific;
  final String? eventKey;
  final int schemaVersion;
}

@immutable
class PlayerAchievement {
  const PlayerAchievement({
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.status,
    required this.lastEvaluatedAt,
    this.unlockedAt,
    this.rewardTransactionId,
    this.rewardGrantedAt,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;

  factory PlayerAchievement.initial(AchievementDefinition definition) {
    return PlayerAchievement(
      achievementId: definition.achievementId,
      currentValue: 0,
      targetValue: definition.targetValue,
      status: PlayerAchievementStatus.locked,
      lastEvaluatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String achievementId;
  final int currentValue;
  final int targetValue;
  final PlayerAchievementStatus status;
  final DateTime? unlockedAt;
  final String? rewardTransactionId;
  final DateTime? rewardGrantedAt;
  final DateTime lastEvaluatedAt;
  final int schemaVersion;

  bool get isUnlocked => status == PlayerAchievementStatus.unlocked;
  double get progress =>
      targetValue <= 0 ? 1 : (currentValue / targetValue).clamp(0.0, 1.0);

  PlayerAchievement copyWith({
    int? currentValue,
    int? targetValue,
    PlayerAchievementStatus? status,
    DateTime? unlockedAt,
    String? rewardTransactionId,
    DateTime? rewardGrantedAt,
    DateTime? lastEvaluatedAt,
  }) {
    return PlayerAchievement(
      achievementId: achievementId,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      status: status ?? this.status,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rewardTransactionId: rewardTransactionId ?? this.rewardTransactionId,
      rewardGrantedAt: rewardGrantedAt ?? this.rewardGrantedAt,
      lastEvaluatedAt: lastEvaluatedAt ?? this.lastEvaluatedAt,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, Object?> toJson() => {
    'achievementId': achievementId,
    'currentValue': currentValue,
    'targetValue': targetValue,
    'status': status.name,
    'unlockedAt': unlockedAt?.toIso8601String(),
    'rewardTransactionId': rewardTransactionId,
    'rewardGrantedAt': rewardGrantedAt?.toIso8601String(),
    'lastEvaluatedAt': lastEvaluatedAt.toIso8601String(),
    'schemaVersion': schemaVersion,
  };

  factory PlayerAchievement.fromJson(Map<String, Object?> json) {
    return PlayerAchievement(
      achievementId: json['achievementId']! as String,
      currentValue: json['currentValue'] as int? ?? 0,
      targetValue: json['targetValue'] as int? ?? 1,
      status: PlayerAchievementStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => PlayerAchievementStatus.locked,
      ),
      unlockedAt: DateTime.tryParse(json['unlockedAt'] as String? ?? ''),
      rewardTransactionId: json['rewardTransactionId'] as String?,
      rewardGrantedAt: DateTime.tryParse(
        json['rewardGrantedAt'] as String? ?? '',
      ),
      lastEvaluatedAt:
          DateTime.tryParse(
            json['lastEvaluatedAt'] as String? ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}

@immutable
class AchievementRewardTransaction {
  const AchievementRewardTransaction({
    required this.transactionId,
    required this.achievementId,
    required this.playerId,
    required this.rewardXp,
    required this.previousXp,
    required this.updatedXp,
    required this.previousLevel,
    required this.updatedLevel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String transactionId;
  final String achievementId;
  final String playerId;
  final int rewardXp;
  final int previousXp;
  final int updatedXp;
  final int previousLevel;
  final int updatedLevel;
  final AchievementRewardTransactionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AchievementRewardTransaction copyWith({
    int? updatedXp,
    int? updatedLevel,
    AchievementRewardTransactionStatus? status,
    DateTime? updatedAt,
  }) {
    return AchievementRewardTransaction(
      transactionId: transactionId,
      achievementId: achievementId,
      playerId: playerId,
      rewardXp: rewardXp,
      previousXp: previousXp,
      updatedXp: updatedXp ?? this.updatedXp,
      previousLevel: previousLevel,
      updatedLevel: updatedLevel ?? this.updatedLevel,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toJson() => {
    'transactionId': transactionId,
    'achievementId': achievementId,
    'playerId': playerId,
    'rewardXp': rewardXp,
    'previousXp': previousXp,
    'updatedXp': updatedXp,
    'previousLevel': previousLevel,
    'updatedLevel': updatedLevel,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AchievementRewardTransaction.fromJson(Map<String, Object?> json) {
    return AchievementRewardTransaction(
      transactionId: json['transactionId']! as String,
      achievementId: json['achievementId']! as String,
      playerId: json['playerId']! as String,
      rewardXp: json['rewardXp'] as int? ?? 0,
      previousXp: json['previousXp'] as int? ?? 0,
      updatedXp: json['updatedXp'] as int? ?? 0,
      previousLevel: json['previousLevel'] as int? ?? 1,
      updatedLevel: json['updatedLevel'] as int? ?? 1,
      status: AchievementRewardTransactionStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => AchievementRewardTransactionStatus.started,
      ),
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt']! as String).toUtc(),
    );
  }
}

@immutable
class AchievementLedger {
  const AchievementLedger({
    required this.playerId,
    required this.achievements,
    required this.rewardTransactions,
    required this.reconciliationVersion,
    this.schemaVersion = currentSchemaVersion,
  });

  static const currentSchemaVersion = 1;
  static const currentReconciliationVersion = 1;

  factory AchievementLedger.empty(String playerId) => AchievementLedger(
    playerId: playerId,
    achievements: const {},
    rewardTransactions: const {},
    reconciliationVersion: 0,
  );

  final String playerId;
  final Map<String, PlayerAchievement> achievements;
  final Map<String, AchievementRewardTransaction> rewardTransactions;
  final int reconciliationVersion;
  final int schemaVersion;

  AchievementLedger copyWith({
    Map<String, PlayerAchievement>? achievements,
    Map<String, AchievementRewardTransaction>? rewardTransactions,
    int? reconciliationVersion,
  }) {
    return AchievementLedger(
      playerId: playerId,
      achievements: Map.unmodifiable(achievements ?? this.achievements),
      rewardTransactions: Map.unmodifiable(
        rewardTransactions ?? this.rewardTransactions,
      ),
      reconciliationVersion:
          reconciliationVersion ?? this.reconciliationVersion,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, Object?> toJson() => {
    'playerId': playerId,
    'achievements': {
      for (final entry in achievements.entries) entry.key: entry.value.toJson(),
    },
    'rewardTransactions': {
      for (final entry in rewardTransactions.entries)
        entry.key: entry.value.toJson(),
    },
    'reconciliationVersion': reconciliationVersion,
    'schemaVersion': schemaVersion,
  };

  factory AchievementLedger.fromJson(Map<String, Object?> json) {
    final rawAchievements = Map<String, dynamic>.from(
      json['achievements'] as Map<dynamic, dynamic>? ?? const {},
    );
    final rawTransactions = Map<String, dynamic>.from(
      json['rewardTransactions'] as Map<dynamic, dynamic>? ?? const {},
    );
    return AchievementLedger(
      playerId: json['playerId']! as String,
      achievements: Map.unmodifiable({
        for (final entry in rawAchievements.entries)
          entry.key: PlayerAchievement.fromJson(
            Map<String, Object?>.from(entry.value as Map<dynamic, dynamic>),
          ),
      }),
      rewardTransactions: Map.unmodifiable({
        for (final entry in rawTransactions.entries)
          entry.key: AchievementRewardTransaction.fromJson(
            Map<String, Object?>.from(entry.value as Map<dynamic, dynamic>),
          ),
      }),
      reconciliationVersion: json['reconciliationVersion'] as int? ?? 0,
      schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
    );
  }
}

String achievementRewardTransactionId(String achievementId) {
  return 'achievement_reward:${achievementId.trim()}';
}

@immutable
class AchievementUnlockResult {
  const AchievementUnlockResult({
    required this.achievementId,
    required this.rewardXp,
    required this.previousXp,
    required this.updatedXp,
    required this.previousLevel,
    required this.updatedLevel,
    required this.rewardTransactionId,
    required this.wasAlreadyUnlocked,
  });

  final String achievementId;
  final int rewardXp;
  final int previousXp;
  final int updatedXp;
  final int previousLevel;
  final int updatedLevel;
  final String rewardTransactionId;
  final bool wasAlreadyUnlocked;

  bool get causedLevelUp => updatedLevel > previousLevel;
}
