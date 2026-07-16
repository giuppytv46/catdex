import 'package:catdex/features/cards/application/cat_card_legacy_migration.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDexControllerProvider =
    NotifierProvider<CatDexController, CatDexCollectionState>(
      CatDexController.new,
    );

class CatDexController extends Notifier<CatDexCollectionState> {
  @override
  CatDexCollectionState build() {
    final sessionDiscoveries = ref.watch(localDiscoverySessionProvider);
    ref.watch(catCardLegacyMigrationProvider);
    final cardRecords = ref.watch(catCardCollectionProvider);
    final entries = _buildEntries(sessionDiscoveries, cardRecords);
    final variants = CatDexSeedData.variants
        .map(
          (variant) => CatDexVariantFilter(id: variant.id, name: variant.name),
        )
        .toList(growable: false);

    return CatDexCollectionState(
      entries: entries,
      visibleEntries: entries,
      totalCount: entries.length,
      discoveredCount: entries.where((entry) => entry.discovered).length,
      searchQuery: '',
      selectedRarity: null,
      selectedVariantId: null,
      discoveryFilter: CatDexDiscoveryFilter.all,
      availableVariants: variants,
    );
  }

  void updateSearchQuery(String query) {
    state = _filteredState(searchQuery: query);
  }

  void toggleRarity(CatRarity rarity) {
    if (state.selectedRarity == rarity) {
      state = _filteredState(clearSelectedRarity: true);
      return;
    }

    state = _filteredState(selectedRarity: rarity);
  }

  void clearRarityFilter() {
    state = _filteredState(clearSelectedRarity: true);
  }

  void toggleVariant(String variantId) {
    if (state.selectedVariantId == variantId) {
      state = _filteredState(clearSelectedVariant: true);
      return;
    }

    state = _filteredState(selectedVariantId: variantId);
  }

  void clearVariantFilter() {
    state = _filteredState(clearSelectedVariant: true);
  }

  void setDiscoveryFilter(CatDexDiscoveryFilter filter) {
    state = _filteredState(discoveryFilter: filter);
  }

  CatDexCollectionState _filteredState({
    String? searchQuery,
    CatRarity? selectedRarity,
    bool clearSelectedRarity = false,
    String? selectedVariantId,
    bool clearSelectedVariant = false,
    CatDexDiscoveryFilter? discoveryFilter,
  }) {
    final nextSearchQuery = searchQuery ?? state.searchQuery;
    final nextSelectedRarity = clearSelectedRarity
        ? null
        : selectedRarity ?? state.selectedRarity;
    final nextSelectedVariantId = clearSelectedVariant
        ? null
        : selectedVariantId ?? state.selectedVariantId;
    final nextDiscoveryFilter = discoveryFilter ?? state.discoveryFilter;
    final normalizedQuery = nextSearchQuery.trim().toLowerCase();
    final visibleEntries = state.entries
        .where((entry) {
          final formattedSpeciesName = _speciesSearchLabel(
            entry.discovery?.speciesId ?? entry.species.id,
          );
          final matchesSearch =
              normalizedQuery.isEmpty ||
              entry.species.displayName.toLowerCase().contains(
                normalizedQuery,
              ) ||
              formattedSpeciesName.contains(normalizedQuery) ||
              (entry.displayName?.toLowerCase().contains(normalizedQuery) ??
                  false);
          final matchesRarity =
              nextSelectedRarity == null ||
              (entry.discovery?.rarity ?? entry.species.baseRarity) ==
                  nextSelectedRarity;
          final matchesVariant =
              nextSelectedVariantId == null ||
              entry.variantId == nextSelectedVariantId;
          final matchesDiscovery = switch (nextDiscoveryFilter) {
            CatDexDiscoveryFilter.all => true,
            CatDexDiscoveryFilter.discovered => entry.discovered,
            CatDexDiscoveryFilter.undiscovered => !entry.discovered,
            CatDexDiscoveryFilter.favorites => entry.favorite,
          };

          final visible =
              matchesSearch &&
              matchesRarity &&
              matchesVariant &&
              matchesDiscovery;
          if (!visible && entry.discovery != null) {
            debugPrint(
              'CATDEX_DISCOVERY_FILTER_REJECTED '
              'id=${entry.discovery!.id} '
              'reason=${_filterRejectionReason(
                matchesSearch: matchesSearch,
                matchesRarity: matchesRarity,
                matchesVariant: matchesVariant,
                matchesDiscovery: matchesDiscovery,
              )}',
            );
          }
          return visible;
        })
        .toList(growable: false);
    debugPrint('CATDEX_DISCOVERY_FILTER_INPUT_COUNT ${state.entries.length}');
    debugPrint(
      'CATDEX_DISCOVERY_FILTER_OUTPUT_COUNT ${visibleEntries.length}',
    );

    return state.copyWith(
      visibleEntries: visibleEntries,
      searchQuery: nextSearchQuery,
      selectedRarity: nextSelectedRarity,
      clearSelectedRarity: clearSelectedRarity,
      selectedVariantId: nextSelectedVariantId,
      clearSelectedVariant: clearSelectedVariant,
      discoveryFilter: nextDiscoveryFilter,
    );
  }

  List<CatDexCollectionEntry> _buildEntries(
    List<CatDiscovery> sessionDiscoveries,
    List<CatCardRecord> cardRecords,
  ) {
    final normalCards = <String, CatCardRecord>{
      for (final card in cardRecords)
        if (card.cardType == CatCardType.normal && card.isCompleted)
          card.discoveryId: card,
    };
    final speciesIndexes = <String, int>{
      for (final item in CatDexSeedData.species.indexed) item.$2.id: item.$1,
    };
    final discoveredSpeciesIds = sessionDiscoveries
        .map((item) => item.speciesId)
        .toSet();
    final entries = <CatDexCollectionEntry>[
      for (final item in sessionDiscoveries.indexed)
        _entryForDiscovery(
          discovery: item.$2,
          fallbackIndex: CatDexSeedData.species.length + item.$1,
          speciesIndex: speciesIndexes[item.$2.speciesId],
          normalCard: normalCards[item.$2.id],
        ),
      for (final item in CatDexSeedData.species.indexed)
        if (!discoveredSpeciesIds.contains(item.$2.id))
          _undiscoveredEntry(index: item.$1, species: item.$2),
    ];

    debugPrint(
      'CATDEX_DISCOVERY_FILTER_INPUT_COUNT ${sessionDiscoveries.length}',
    );
    debugPrint(
      'CATDEX_DISCOVERY_FILTER_OUTPUT_COUNT '
      '${entries.where((entry) => entry.discovered).length}',
    );

    return entries..sort(_collectionSort);
  }

  int _collectionSort(CatDexCollectionEntry a, CatDexCollectionEntry b) {
    if (a.discovered != b.discovered) {
      return a.discovered ? -1 : 1;
    }

    if (a.discovered && b.discovered) {
      final aDate = a.discovery?.discoveredAt;
      final bDate = b.discovery?.discoveredAt;
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
    }

    return a.collectionNumber.compareTo(b.collectionNumber);
  }

  CatDexCollectionEntry _entryForDiscovery({
    required CatDiscovery discovery,
    required int fallbackIndex,
    required int? speciesIndex,
    CatCardRecord? normalCard,
  }) {
    final index = speciesIndex ?? fallbackIndex;
    final species = speciesIndex == null
        ? _fallbackSpecies(discovery)
        : CatDexSeedData.species[speciesIndex];

    final displayDiscovery = normalCard == null
        ? discovery
        : discoveryWithCardRecordForDisplay(discovery, normalCard);
    return CatDexCollectionEntry(
      species: species,
      variantName: _variantNameById(discovery.variantId),
      variantId: discovery.variantId,
      discovered: true,
      collectionNumber: index + 1,
      discovery: displayDiscovery,
      displayName: discovery.customName,
      discoveredPhotoPath: discovery.photoPath,
      cardRecord: normalCard,
    );
  }

  CatDexCollectionEntry _undiscoveredEntry({
    required int index,
    required CatSpecies species,
  }) {
    return CatDexCollectionEntry(
      species: species,
      variantName: _variantNameForIndex(index),
      variantId: _variantIdForIndex(index),
      discovered: false,
      collectionNumber: index + 1,
    );
  }

  CatSpecies _fallbackSpecies(CatDiscovery discovery) {
    return CatSpecies(
      id: discovery.speciesId,
      displayName: discovery.speciesId.replaceAll('_', ' '),
      scientificName: 'Felis catus',
      originCountry: 'Worldwide',
      baseRarity: discovery.rarity,
      active: true,
    );
  }

  String _variantNameById(String variantId) {
    return CatDexSeedData.variants
        .firstWhere((variant) => variant.id == variantId)
        .name;
  }

  String _variantNameForIndex(int index) {
    return CatDexSeedData.variants[index % CatDexSeedData.variants.length].name;
  }

  String _variantIdForIndex(int index) {
    return CatDexSeedData.variants[index % CatDexSeedData.variants.length].id;
  }

  String _speciesSearchLabel(String speciesId) {
    return speciesId.replaceAll('_', ' ').toLowerCase();
  }

  String _filterRejectionReason({
    required bool matchesSearch,
    required bool matchesRarity,
    required bool matchesVariant,
    required bool matchesDiscovery,
  }) {
    if (!matchesSearch) {
      return 'search';
    }
    if (!matchesRarity) {
      return 'rarity';
    }
    if (!matchesVariant) {
      return 'variant';
    }
    if (!matchesDiscovery) {
      return 'discovery_filter';
    }
    return 'unknown';
  }
}
