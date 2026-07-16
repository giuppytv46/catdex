import 'dart:convert';

import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesEventUsageRepository implements EventUsageRepository {
  const SharedPreferencesEventUsageRepository();

  static const _storageKey = 'catdex_event_generation_usage_v1';
  static const _snapshotStorageKey = 'catdex_event_generation_snapshot_v2';

  @override
  Future<int> getCommittedUsage({
    required String playerId,
    required String eventId,
  }) async {
    final usage = await _read();
    return usage[_key(playerId, eventId)] ?? 0;
  }

  @override
  Future<void> setCommittedUsage({
    required String playerId,
    required String eventId,
    required int value,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final usage = await _read();
    usage[_key(playerId, eventId)] = value < 0 ? 0 : value;
    final written = await preferences.setString(_storageKey, jsonEncode(usage));
    if (!written) {
      throw StateError('Event usage write failed');
    }
    final snapshot = await getSnapshot(playerId: playerId, eventId: eventId);
    await saveSnapshot(
      playerId: playerId,
      eventId: eventId,
      snapshot: snapshot.copyWith(committedUsage: value < 0 ? 0 : value),
    );
  }

  @override
  Future<EventUsageSnapshot> getSnapshot({
    required String playerId,
    required String eventId,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_snapshotStorageKey);
    if (encoded == null || encoded.isEmpty) {
      return EventUsageSnapshot(
        committedUsage: await getCommittedUsage(
          playerId: playerId,
          eventId: eventId,
        ),
      );
    }
    try {
      final all = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      final raw = all[_key(playerId, eventId)];
      if (raw is! Map) return const EventUsageSnapshot();
      final map = Map<String, dynamic>.from(raw);
      return EventUsageSnapshot(
        committedUsage: (map['committedUsage'] as num?)?.toInt() ?? 0,
        ownedVariantIds: (map['ownedVariantIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet(),
        committedRequestIds:
            (map['committedRequestIds'] as List<dynamic>? ?? const [])
                .whereType<String>()
                .toSet(),
      );
    } on Object {
      return const EventUsageSnapshot();
    }
  }

  @override
  Future<void> saveSnapshot({
    required String playerId,
    required String eventId,
    required EventUsageSnapshot snapshot,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_snapshotStorageKey);
    final all = <String, dynamic>{};
    if (encoded != null && encoded.isNotEmpty) {
      try {
        all.addAll(Map<String, dynamic>.from(jsonDecode(encoded) as Map));
      } on Object {
        // Replace malformed local event state with the verified snapshot.
      }
    }
    all[_key(playerId, eventId)] = <String, Object?>{
      'committedUsage': snapshot.committedUsage,
      'ownedVariantIds': snapshot.ownedVariantIds.toList()..sort(),
      'committedRequestIds': snapshot.committedRequestIds.toList()..sort(),
    };
    final written = await preferences.setString(
      _snapshotStorageKey,
      jsonEncode(all),
    );
    if (!written) throw StateError('Event snapshot write failed');

    final usage = await _read();
    usage[_key(playerId, eventId)] = snapshot.committedUsage;
    await preferences.setString(_storageKey, jsonEncode(usage));
  }

  Future<Map<String, int>> _read() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) return <String, int>{};
    try {
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      );
    } on Object {
      return <String, int>{};
    }
  }

  String _key(String playerId, String eventId) => '$playerId::$eventId';
}
