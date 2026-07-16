class EventUsageSnapshot {
  const EventUsageSnapshot({
    this.committedUsage = 0,
    this.ownedVariantIds = const <String>{},
    this.committedRequestIds = const <String>{},
  });

  final int committedUsage;
  final Set<String> ownedVariantIds;
  final Set<String> committedRequestIds;

  EventUsageSnapshot copyWith({
    int? committedUsage,
    Set<String>? ownedVariantIds,
    Set<String>? committedRequestIds,
  }) {
    return EventUsageSnapshot(
      committedUsage: committedUsage ?? this.committedUsage,
      ownedVariantIds: ownedVariantIds ?? this.ownedVariantIds,
      committedRequestIds: committedRequestIds ?? this.committedRequestIds,
    );
  }
}

abstract interface class EventUsageRepository {
  Future<int> getCommittedUsage({
    required String playerId,
    required String eventId,
  });

  Future<void> setCommittedUsage({
    required String playerId,
    required String eventId,
    required int value,
  });

  Future<EventUsageSnapshot> getSnapshot({
    required String playerId,
    required String eventId,
  });

  Future<void> saveSnapshot({
    required String playerId,
    required String eventId,
    required EventUsageSnapshot snapshot,
  });
}
