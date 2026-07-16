import 'dart:convert';

import 'package:catdex/features/cards/data/cat_card_record_json.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesCatCardRepository implements CatCardRepository {
  const SharedPreferencesCatCardRepository();

  static const storageKey = 'catdex_collectible_card_records_v1';

  @override
  Future<List<CatCardRecord>> getAllCards() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getStringList(storageKey) ?? const <String>[];
    final cards = <CatCardRecord>[];
    for (final item in encoded) {
      try {
        cards.add(
          catCardRecordFromJson(
            Map<String, Object?>.from(jsonDecode(item) as Map),
          ),
        );
      } on Object catch (error) {
        debugPrint(
          'CATDEX_CARD_COLLECTION_RECORD_SKIPPED error=${error.runtimeType}',
        );
      }
    }
    final merged = mergeCatCardRecords(local: cards, remote: const []);
    debugPrint('CATDEX_CARD_COLLECTION_LOCAL_COUNT ${merged.length}');
    return merged;
  }

  @override
  Future<CatCardRecord?> getCardById(String cardId) async {
    for (final card in await getAllCards()) {
      if (card.cardId == cardId) return card;
    }
    return null;
  }

  @override
  Future<List<CatCardRecord>> getCardsForDiscovery(
    String discoveryId,
  ) async {
    return (await getAllCards())
        .where((card) => card.discoveryId == discoveryId)
        .toList(growable: false);
  }

  @override
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) {
    return getCardById(normalCardId(discoveryId));
  }

  @override
  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  ) async {
    return (await getAllCards())
        .where(
          (card) =>
              card.cardType == CatCardType.event &&
              card.eventKey == eventKey &&
              card.eventEdition == eventEdition,
        )
        .toList(growable: false);
  }

  @override
  Future<bool> cardExists(String logicalIdentity) async {
    return (await getAllCards()).any(
      (card) => card.logicalIdentity == logicalIdentity,
    );
  }

  @override
  Future<void> saveCard(CatCardRecord card) async {
    debugPrint('CATDEX_CARD_RECORD_SAVE_STARTED');
    debugPrint('CATDEX_CARD_RECORD_ID ${card.cardId}');
    debugPrint('CATDEX_CARD_RECORD_DISCOVERY_ID ${card.discoveryId}');
    debugPrint('CATDEX_CARD_RECORD_TYPE ${card.cardType.name}');
    debugPrint('CATDEX_CARD_RECORD_EVENT_KEY ${card.eventKey ?? '-'}');
    debugPrint(
      'CATDEX_CARD_RECORD_VARIANT ${card.eventArtworkVariantId ?? '-'}',
    );
    final current = await getAllCards();
    final next = mergeCatCardRecords(
      local: [card, ...current.where((item) => item.cardId != card.cardId)],
      remote: const [],
    );
    final preferences = await SharedPreferences.getInstance();
    final written = await preferences.setStringList(
      storageKey,
      next.map((item) => jsonEncode(catCardRecordToJson(item))).toList(),
    );
    if (!written) throw StateError('Cat card record write failed');
    final readBack = await getCardById(card.cardId);
    if (readBack == null || !sameCardRecord(readBack, card)) {
      debugPrint('CATDEX_CARD_RECORD_READBACK_FAILED');
      throw StateError('Cat card record readback failed');
    }
    debugPrint('CATDEX_CARD_RECORD_SAVE_COMPLETED');
    debugPrint('CATDEX_CARD_RECORD_READBACK_SUCCESS');
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final remaining = (await getAllCards())
        .where((card) => card.cardId != cardId)
        .toList(growable: false);
    final preferences = await SharedPreferences.getInstance();
    final written = await preferences.setStringList(
      storageKey,
      remaining.map((item) => jsonEncode(catCardRecordToJson(item))).toList(),
    );
    if (!written) throw StateError('Cat card record delete failed');
  }
}

List<CatCardRecord> mergeCatCardRecords({
  required List<CatCardRecord> local,
  required List<CatCardRecord> remote,
}) {
  final byIdentity = <String, CatCardRecord>{};
  for (final card in [...remote, ...local]) {
    final identity = card.logicalIdentity;
    final existing = byIdentity[identity];
    if (existing == null) {
      byIdentity[identity] = card;
      continue;
    }
    debugPrint('CATDEX_CARD_COLLECTION_DUPLICATE_SKIPPED $identity');
    byIdentity[identity] = mergeCatCardRecord(existing, card);
  }
  final merged = byIdentity.values.toList(growable: false)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
}

CatCardRecord mergeCatCardRecord(CatCardRecord first, CatCardRecord second) {
  final firstCompleted = first.isCompleted;
  final secondCompleted = second.isCompleted;
  if (firstCompleted != secondCompleted) return firstCompleted ? first : second;
  final newer = second.updatedAt.isAfter(first.updatedAt) ? second : first;
  final older = identical(newer, second) ? first : second;
  if (isValidFinalCardUrl(newer.finalCardUrl)) return newer;
  return older.isCompleted ? older : newer;
}

bool sameCardRecord(CatCardRecord first, CatCardRecord second) {
  return first.cardId == second.cardId &&
      first.discoveryId == second.discoveryId &&
      first.logicalIdentity == second.logicalIdentity &&
      first.finalCardUrl == second.finalCardUrl &&
      first.generationStatus == second.generationStatus &&
      first.eventKey == second.eventKey &&
      first.eventEdition == second.eventEdition &&
      first.eventArtworkVariantId == second.eventArtworkVariantId;
}
