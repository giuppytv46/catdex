import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventUiRefreshProvider = NotifierProvider<EventUiRefreshController, int>(
  EventUiRefreshController.new,
);

class EventUiRefreshController extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state += 1;
}

// The concrete family type is intentionally inferred by Riverpod's builder.
// ignore: specify_nonobvious_property_types
final eventUiStateProvider = FutureProvider.family<EventUiState, String>((
  ref,
  eventKey,
) async {
  ref.watch(eventUiRefreshProvider);
  final event = catDexEventByKey(eventKey);
  if (event == null) {
    throw StateError('unknown_event');
  }

  final runtime = ref.watch(eventRuntimeConfigurationProvider);
  final discoveries = ref.watch(localDiscoverySessionProvider);
  final allCards = ref.watch(catCardCollectionProvider);
  final session = ref.watch(activeCatDexSessionProvider);
  final premiumFuture = ref.watch(monetizationStatusSummaryProvider.future);
  final usageRepository = ref.watch(eventUsageRepositoryProvider);
  final usageFuture = usageRepository.getSnapshot(
    playerId: session.playerId,
    eventId: event.id,
  );
  final premiumSummary = await premiumFuture;
  final usage = await usageFuture;
  final isPremium =
      runtime.premiumTestEntitlementEnabled || premiumSummary.isPremium;
  final eventCards =
      allCards
          .where(
            (card) =>
                card.cardType == CatCardType.event &&
                card.eventKey == event.id &&
                card.eventEdition == event.edition &&
                card.isCompleted,
          )
          .toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  final safeDiscoveries =
      discoveries.where(_isSafeEventDiscovery).toList(growable: false)
        ..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
  final active = runtime.activeEvent(DateTime.now().toUtc())?.id == event.id;

  final state = EventUiState(
    event: event,
    active: active,
    debugMode: kDebugMode && runtime.debugModeEnabled,
    isPremium: isPremium,
    usage: usage,
    discoveries: safeDiscoveries,
    ownedCards: eventCards,
    rendererConfigured: ref
        .watch(remoteCardGenerationServiceProvider)
        .isConfigured,
  );
  debugPrint('CATDEX_EVENT_UI_USER_TIER ${isPremium ? 'premium' : 'free'}');
  debugPrint(
    'CATDEX_EVENT_UI_USAGE success=${state.committedUsage} '
    'remaining=${state.remainingGenerations}',
  );
  debugPrint('CATDEX_EVENT_UI_ALBUM_CARD_COUNT ${eventCards.length}');
  if (state.debugMode) {
    debugPrint('CATDEX_EVENT_UI_DEBUG_MODE_ACTIVE');
  }
  return state;
});

final activeEventUiStateProvider = FutureProvider<EventUiState?>((ref) async {
  final runtime = ref.watch(eventRuntimeConfigurationProvider);
  final event = runtime.activeEvent(DateTime.now().toUtc());
  if (event == null) return null;
  return ref.watch(eventUiStateProvider(event.id).future);
});

@immutable
class EventUiState {
  const EventUiState({
    required this.event,
    required this.active,
    required this.debugMode,
    required this.isPremium,
    required this.usage,
    required this.discoveries,
    required this.ownedCards,
    required this.rendererConfigured,
  });

  final CatDexEvent event;
  final bool active;
  final bool debugMode;
  final bool isPremium;
  final EventUsageSnapshot usage;
  final List<CatDiscovery> discoveries;
  final List<CatCardRecord> ownedCards;
  final bool rendererConfigured;

  int get generationLimit =>
      isPremium ? event.premiumGenerationLimit : event.freeGenerationLimit;

  int get committedUsage => usage.committedUsage;

  int get remainingGenerations =>
      (generationLimit - committedUsage).clamp(0, generationLimit);

  bool get limitReached => remainingGenerations <= 0;

  List<CatCardRecord> cardsForVariant(String variantId) {
    return ownedCards
        .where((card) => card.eventArtworkVariantId == variantId)
        .toList(growable: false);
  }

  int get collectedFreeArtworkCount => event.enabledStandardVariantIds
      .where((variant) => cardsForVariant(variant).isNotEmpty)
      .length;

  bool get premiumArtworkCollected =>
      cardsForVariant(event.premiumVariantId).isNotEmpty;

  int eventCardCountForDiscovery(String discoveryId) =>
      ownedCards.where((card) => card.discoveryId == discoveryId).length;
}

bool _isSafeEventDiscovery(CatDiscovery discovery) {
  return discovery.id.trim().isNotEmpty &&
      discovery.playerId.trim().isNotEmpty &&
      discovery.speciesId.trim().isNotEmpty;
}
