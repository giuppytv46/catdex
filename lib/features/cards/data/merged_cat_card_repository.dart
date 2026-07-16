import 'package:catdex/features/cards/data/shared_preferences_cat_card_repository.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:flutter/foundation.dart';

class MergedCatCardRepository implements CatCardRepository {
  const MergedCatCardRepository({
    required CatCardRepository localRepository,
    required CatCardRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository;

  final CatCardRepository _localRepository;
  final CatCardRepository _remoteRepository;

  @override
  Future<List<CatCardRecord>> getAllCards() async {
    final local = await _loadSafely(_localRepository.getAllCards);
    final remote = await _loadSafely(_remoteRepository.getAllCards);
    debugPrint('CATDEX_CARD_COLLECTION_LOCAL_COUNT ${local.length}');
    debugPrint('CATDEX_CARD_COLLECTION_REMOTE_COUNT ${remote.length}');
    final merged = mergeCatCardRecords(local: local, remote: remote);
    debugPrint('CATDEX_CARD_COLLECTION_MERGED_COUNT ${merged.length}');
    return merged;
  }

  @override
  Future<CatCardRecord?> getCardById(String cardId) async {
    CatCardRecord? local;
    CatCardRecord? remote;
    try {
      local = await _localRepository.getCardById(cardId);
    } on Object {
      // A valid remote record may still be available.
    }
    try {
      remote = await _remoteRepository.getCardById(cardId);
    } on Object {
      // A valid local record remains authoritative offline.
    }
    if (local == null) return remote;
    if (remote == null) return local;
    return mergeCatCardRecord(local, remote);
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
    return await getCardById(logicalIdentity) != null;
  }

  @override
  Future<void> saveCard(CatCardRecord card) async {
    await _localRepository.saveCard(card);
    try {
      await _remoteRepository.saveCard(card);
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RECORD_REMOTE_SAVE_FAILED $error');
    }
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _localRepository.deleteCard(cardId);
    try {
      await _remoteRepository.deleteCard(cardId);
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RECORD_REMOTE_DELETE_FAILED $error');
    }
  }

  Future<List<CatCardRecord>> _loadSafely(
    Future<List<CatCardRecord>> Function() load,
  ) async {
    try {
      return await load();
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_COLLECTION_SOURCE_FAILED $error');
      return const <CatCardRecord>[];
    }
  }
}
