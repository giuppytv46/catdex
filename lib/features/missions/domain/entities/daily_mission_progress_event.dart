import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter/foundation.dart';

enum DailyMissionProgressEventType {
  discoverySaved,
  normalCardGenerated,
  mapOpened,
  discoverySavedWithLocation,
  rarityDiscovered,
  eventCardGenerated,
}

@immutable
class DailyMissionProgressEvent {
  const DailyMissionProgressEvent({
    required this.type,
    required this.operationId,
    this.rarity,
  });

  final DailyMissionProgressEventType type;
  final String operationId;
  final CatRarity? rarity;

  String get idempotencyKey => '${type.name}:${operationId.trim()}';
}
