import 'package:catdex/features/cards/data/cat_card_record_json.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCatCardRepository implements CatCardRepository {
  const SupabaseCatCardRepository({
    required SupabaseClient client,
    required String userId,
  }) : _client = client,
       _userId = userId;

  final SupabaseClient _client;
  final String _userId;

  @override
  Future<List<CatCardRecord>> getAllCards() async {
    final rows = await _client
        .from('cat_cards')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<CatCardRecord?> getCardById(String cardId) async {
    final row = await _client
        .from('cat_cards')
        .select()
        .eq('user_id', _userId)
        .eq('id', cardId)
        .maybeSingle();
    return row == null ? null : _fromRow(row);
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
    final rows = await _client
        .from('cat_cards')
        .select()
        .eq('user_id', _userId)
        .eq('event_key', eventKey)
        .eq('event_edition', eventEdition);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<bool> cardExists(String logicalIdentity) async {
    return await getCardById(logicalIdentity) != null;
  }

  @override
  Future<void> saveCard(CatCardRecord card) async {
    await _client.from('cat_cards').upsert(_toRow(card));
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await _client
        .from('cat_cards')
        .delete()
        .eq('user_id', _userId)
        .eq('id', cardId);
  }

  Map<String, Object?> _toRow(CatCardRecord card) {
    final metadata = catCardRecordToJson(card);
    return <String, Object?>{
      'id': card.cardId,
      'user_id': _userId,
      'discovery_id': card.discoveryId,
      'card_type': card.cardType.name,
      'rarity': card.rarity.name,
      'final_card_url': card.finalCardUrl,
      'illustrated_cat_url': card.illustratedCatUrl,
      'template_key': card.templateKey,
      'generation_status': card.generationStatus.name,
      'generation_request_id': card.generationRequestId,
      'idempotency_key': card.idempotencyKey,
      'event_key': card.eventKey,
      'event_edition': card.eventEdition,
      'event_artwork_variant_id': card.eventArtworkVariantId,
      'event_artwork_tier': card.eventArtworkTier,
      'event_template_key': card.eventTemplateKey,
      'is_premium_artwork': card.isPremiumArtwork,
      'metadata': metadata,
      'created_at': card.createdAt.toUtc().toIso8601String(),
      'updated_at': card.updatedAt.toUtc().toIso8601String(),
    };
  }

  CatCardRecord _fromRow(Map<String, dynamic> row) {
    final metadata = Map<String, Object?>.from(
      row['metadata'] as Map? ?? const <String, Object?>{},
    );
    return catCardRecordFromJson({
      ...metadata,
      'cardId': row['id'],
      'discoveryId': row['discovery_id'],
      'ownerId': row['user_id'],
      'cardType': row['card_type'],
      'rarity': row['rarity'],
      'finalCardUrl': row['final_card_url'],
      'illustratedCatUrl': row['illustrated_cat_url'],
      'templateKey': row['template_key'],
      'generationStatus': row['generation_status'],
      'generationRequestId': row['generation_request_id'],
      'idempotencyKey': row['idempotency_key'],
      'eventKey': row['event_key'],
      'eventEdition': row['event_edition'],
      'eventArtworkVariantId': row['event_artwork_variant_id'],
      'eventArtworkTier': row['event_artwork_tier'],
      'eventTemplateKey': row['event_template_key'],
      'isPremiumArtwork': row['is_premium_artwork'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
    });
  }
}
