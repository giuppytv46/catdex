import 'package:flutter/foundation.dart';

const int eventCardGenerationXp = 100;

@immutable
class EventCardXpAwardResult {
  const EventCardXpAwardResult({
    required this.previousXp,
    required this.updatedXp,
    required this.previousLevel,
    required this.updatedLevel,
    required this.awardedAmount,
    required this.rewardSource,
    required this.transactionId,
    required this.newlyGranted,
  });

  static const rewardSourceId = 'event_card_generation';

  final int previousXp;
  final int updatedXp;
  final int previousLevel;
  final int updatedLevel;
  final int awardedAmount;
  final String rewardSource;
  final String transactionId;
  final bool newlyGranted;

  bool get causedLevelUp => updatedLevel > previousLevel;
}
