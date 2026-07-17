import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_session.dart';
import 'package:catdex/features/catdex/data/repositories/shared_preferences_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:catdex/features/events/domain/entities/event_card_xp_reward.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final eventCardXpRewardServiceProvider = Provider<EventCardXpRewardService>((
  ref,
) {
  final activeSession = ref.watch(activeCatDexSessionProvider);
  return EventCardXpRewardService(
    localRepository: SharedPreferencesPlayerProgressRepository(
      fallbackProgress: activeSession.playerId == LocalPlayerSession.playerId
          ? LocalPlayerSession.initialProgress
          : null,
    ),
    canonicalRepository: ref.watch(playerProgressRepositoryProvider),
    levelCalculator: ref.watch(levelCalculatorProvider),
    currentSessionProgress: () => ref.read(localPlayerProgressSessionProvider),
    updateSessionProgress: (progress) {
      ref.read(localPlayerProgressSessionProvider.notifier).progress = progress;
    },
  );
});

class EventCardXpRewardService {
  EventCardXpRewardService({
    required PlayerProgressRepository localRepository,
    required PlayerProgressRepository canonicalRepository,
    required LevelCalculator levelCalculator,
    required PlayerProgress Function() currentSessionProgress,
    required ValueChanged<PlayerProgress> updateSessionProgress,
  }) : _localRepository = localRepository,
       _canonicalRepository = canonicalRepository,
       _levelCalculator = levelCalculator,
       _currentSessionProgress = currentSessionProgress,
       _updateSessionProgress = updateSessionProgress;

  static const _ledgerStorageKey = 'catdex_event_card_xp_ledger_v1';

  final PlayerProgressRepository _localRepository;
  final PlayerProgressRepository _canonicalRepository;
  final LevelCalculator _levelCalculator;
  final PlayerProgress Function() _currentSessionProgress;
  final ValueChanged<PlayerProgress> _updateSessionProgress;
  final Map<String, Future<EventCardXpAwardResult>> _inFlight = {};

  Future<EventCardXpAwardResult> awardForPersistedEventCard(
    CatCardRecord card,
  ) {
    if (card.cardType != CatCardType.event || !card.isCompleted) {
      throw ArgumentError.value(
        card.cardId,
        'card',
        'Event XP requires a completed event card',
      );
    }
    final transactionId = eventCardXpTransactionId(card.cardId);
    final existing = _inFlight[transactionId];
    if (existing != null) return existing;

    final operation = _award(card, transactionId);
    _inFlight[transactionId] = operation;
    unawaited(
      operation.then<void>(
        (_) => _removeInFlight(transactionId, operation),
        onError: (Object _, StackTrace _) {
          _removeInFlight(transactionId, operation);
        },
      ),
    );
    return operation;
  }

  Future<EventCardXpAwardResult> _award(
    CatCardRecord card,
    String transactionId,
  ) async {
    debugPrint('CATDEX_EVENT_CARD_XP_STARTED cardId=${card.cardId}');
    final preferences = await SharedPreferences.getInstance();
    final ledger = _readLedger(preferences);
    final existing = ledger[transactionId];
    if (existing?.completed == true) {
      debugPrint('CATDEX_EVENT_CARD_XP_DUPLICATE_SKIPPED');
      return existing!.toResult(newlyGranted: false);
    }

    final current = await _bestProgress(card.ownerId);
    final transaction =
        existing ??
        _EventCardXpTransaction(
          transactionId: transactionId,
          playerId: card.ownerId,
          previousXp: current.totalXp,
          updatedXp: current.totalXp + eventCardGenerationXp,
          previousLevel: current.level,
          updatedLevel: _levelCalculator.levelForXp(
            current.totalXp + eventCardGenerationXp,
          ),
          completed: false,
        );
    ledger[transactionId] = transaction;
    await _writeLedger(preferences, ledger);

    final latest = await _bestProgress(card.ownerId);
    final xpNeeded = latest.totalXp < transaction.updatedXp;
    final targetXp = math.max(latest.totalXp, transaction.updatedXp);
    final updated = latest.copyWith(
      totalXp: targetXp,
      level: _levelCalculator.levelForXp(targetXp),
    );
    await _localRepository.saveProgress(updated);
    final localReadBack = await _localRepository.getProgress(card.ownerId);
    if (localReadBack.totalXp < transaction.updatedXp) {
      throw StateError('event_card_xp_local_readback_failed');
    }

    try {
      await _canonicalRepository.saveProgress(localReadBack);
    } on Object catch (error) {
      debugPrint(
        'CATDEX_EVENT_CARD_XP_REMOTE_SYNC_DEFERRED '
        'reason=${error.runtimeType}',
      );
    }
    _updateSessionProgress(localReadBack);

    final completed = transaction.copyWith(
      updatedXp: localReadBack.totalXp,
      updatedLevel: localReadBack.level,
      completed: true,
    );
    ledger[transactionId] = completed;
    await _writeLedger(preferences, ledger);
    debugPrint(
      'CATDEX_EVENT_CARD_XP_GRANTED amount=$eventCardGenerationXp',
    );
    return completed.toResult(
      newlyGranted: existing == null || xpNeeded,
    );
  }

  void _removeInFlight(
    String transactionId,
    Future<EventCardXpAwardResult> operation,
  ) {
    if (identical(_inFlight[transactionId], operation)) {
      unawaited(_inFlight.remove(transactionId));
    }
  }

  Future<PlayerProgress> _bestProgress(String playerId) async {
    final session = _currentSessionProgress();
    final local = await _localRepository.getProgress(playerId);
    PlayerProgress? canonical;
    try {
      canonical = await _canonicalRepository.getProgress(playerId);
    } on Object {
      canonical = null;
    }
    final totalXp = math.max(
      session.playerId == playerId ? session.totalXp : 0,
      math.max(local.totalXp, canonical?.totalXp ?? 0),
    );
    final base = canonical?.totalXp == totalXp
        ? canonical!
        : local.totalXp == totalXp
        ? local
        : session.playerId == playerId
        ? session
        : local;
    return base.copyWith(
      totalXp: totalXp,
      level: _levelCalculator.levelForXp(totalXp),
    );
  }

  Map<String, _EventCardXpTransaction> _readLedger(
    SharedPreferences preferences,
  ) {
    final encoded = preferences.getString(_ledgerStorageKey);
    if (encoded == null || encoded.trim().isEmpty) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(encoded) as Map);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          _EventCardXpTransaction.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      );
    } on Object {
      return {};
    }
  }

  Future<void> _writeLedger(
    SharedPreferences preferences,
    Map<String, _EventCardXpTransaction> ledger,
  ) async {
    final encoded = jsonEncode(
      ledger.map((key, value) => MapEntry(key, value.toJson())),
    );
    final written = await preferences.setString(_ledgerStorageKey, encoded);
    if (!written) throw StateError('event_card_xp_ledger_write_failed');
  }
}

String eventCardXpTransactionId(String cardId) {
  return 'event_card_generation_xp:${cardId.trim()}';
}

@immutable
class _EventCardXpTransaction {
  const _EventCardXpTransaction({
    required this.transactionId,
    required this.playerId,
    required this.previousXp,
    required this.updatedXp,
    required this.previousLevel,
    required this.updatedLevel,
    required this.completed,
  });

  factory _EventCardXpTransaction.fromJson(Map<String, dynamic> json) {
    return _EventCardXpTransaction(
      transactionId: json['transactionId'] as String,
      playerId: json['playerId'] as String,
      previousXp: (json['previousXp'] as num).toInt(),
      updatedXp: (json['updatedXp'] as num).toInt(),
      previousLevel: (json['previousLevel'] as num).toInt(),
      updatedLevel: (json['updatedLevel'] as num).toInt(),
      completed: json['completed'] as bool? ?? false,
    );
  }

  final String transactionId;
  final String playerId;
  final int previousXp;
  final int updatedXp;
  final int previousLevel;
  final int updatedLevel;
  final bool completed;

  _EventCardXpTransaction copyWith({
    int? updatedXp,
    int? updatedLevel,
    bool? completed,
  }) {
    return _EventCardXpTransaction(
      transactionId: transactionId,
      playerId: playerId,
      previousXp: previousXp,
      updatedXp: updatedXp ?? this.updatedXp,
      previousLevel: previousLevel,
      updatedLevel: updatedLevel ?? this.updatedLevel,
      completed: completed ?? this.completed,
    );
  }

  EventCardXpAwardResult toResult({required bool newlyGranted}) {
    return EventCardXpAwardResult(
      previousXp: previousXp,
      updatedXp: updatedXp,
      previousLevel: previousLevel,
      updatedLevel: updatedLevel,
      awardedAmount: eventCardGenerationXp,
      rewardSource: EventCardXpAwardResult.rewardSourceId,
      transactionId: transactionId,
      newlyGranted: newlyGranted,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'transactionId': transactionId,
      'playerId': playerId,
      'previousXp': previousXp,
      'updatedXp': updatedXp,
      'previousLevel': previousLevel,
      'updatedLevel': updatedLevel,
      'completed': completed,
    };
  }
}
