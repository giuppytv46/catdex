import 'dart:async';

import 'package:catdex/features/cards/data/merged_cat_card_repository.dart';
import 'package:catdex/features/cards/data/shared_preferences_cat_card_repository.dart';
import 'package:catdex/features/cards/data/supabase_cat_card_repository.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catCardRepositoryProvider = Provider<CatCardRepository>((ref) {
  final userId = ref.watch(cloudUserIdProvider);
  const local = SharedPreferencesCatCardRepository();
  if (userId == null) return local;
  return MergedCatCardRepository(
    localRepository: local,
    remoteRepository: SupabaseCatCardRepository(
      client: ref.watch(supabaseClientProvider),
      userId: userId,
    ),
  );
});

final catCardCollectionProvider =
    NotifierProvider<CatCardCollectionController, List<CatCardRecord>>(
      CatCardCollectionController.new,
    );

class CatCardCollectionController extends Notifier<List<CatCardRecord>> {
  @override
  List<CatCardRecord> build() {
    unawaited(refresh());
    return const <CatCardRecord>[];
  }

  Future<void> refresh() async {
    final cards = await ref.read(catCardRepositoryProvider).getAllCards();
    if (!ref.mounted) return;
    state = cards;
    debugPrint('CATDEX_CARD_COLLECTION_MERGED_COUNT ${cards.length}');
  }

  void upsert(CatCardRecord card) {
    final byId = <String, CatCardRecord>{
      for (final item in state) item.cardId: item,
      card.cardId: card,
    };
    state = byId.values.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  CatCardRecord? byId(String cardId) {
    for (final card in state) {
      if (card.cardId == cardId) return card;
    }
    return null;
  }

  CatCardRecord? normalForDiscovery(String discoveryId) {
    return byId(normalCardId(discoveryId));
  }
}
