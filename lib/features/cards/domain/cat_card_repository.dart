import 'package:catdex/features/cards/domain/cat_card_record.dart';

abstract interface class CatCardRepository {
  Future<List<CatCardRecord>> getAllCards();

  Future<List<CatCardRecord>> getCardsForDiscovery(String discoveryId);

  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId);

  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  );

  Future<CatCardRecord?> getCardById(String cardId);

  Future<void> saveCard(CatCardRecord card);

  Future<void> deleteCard(String cardId);

  Future<bool> cardExists(String logicalIdentity);
}
