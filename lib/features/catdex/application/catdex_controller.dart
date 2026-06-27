import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDexControllerProvider =
    NotifierProvider<CatDexController, CatDexCollectionState>(
      CatDexController.new,
    );

class CatDexController extends Notifier<CatDexCollectionState> {
  static const _discoveredSpeciesIds = {
    'domestic_black_cat',
    'domestic_white_cat',
    'domestic_tuxedo_cat',
    'domestic_calico_cat',
    'domestic_tabby_cat',
    'domestic_orange_cat',
    'domestic_gray_cat',
    'domestic_tortoiseshell_cat',
    'domestic_colorpoint_cat',
    'domestic_longhair_cat',
    'domestic_shorthair_cat',
    'maine_coon',
    'siamese',
    'persian',
    'ragdoll',
    'bengal',
    'sphynx',
    'british_shorthair',
  };

  @override
  CatDexCollectionState build() {
    final entries = _buildEntries();
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
          final matchesSearch =
              normalizedQuery.isEmpty ||
              entry.species.displayName.toLowerCase().contains(normalizedQuery);
          final matchesRarity =
              nextSelectedRarity == null ||
              entry.species.baseRarity == nextSelectedRarity;
          final matchesVariant =
              nextSelectedVariantId == null ||
              entry.variantId == nextSelectedVariantId;
          final matchesDiscovery = switch (nextDiscoveryFilter) {
            CatDexDiscoveryFilter.all => true,
            CatDexDiscoveryFilter.discovered => entry.discovered,
            CatDexDiscoveryFilter.undiscovered => !entry.discovered,
          };

          return matchesSearch &&
              matchesRarity &&
              matchesVariant &&
              matchesDiscovery;
        })
        .toList(growable: false);

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

  List<CatDexCollectionEntry> _buildEntries() {
    return [
      for (final item in CatDexSeedData.species.indexed)
        CatDexCollectionEntry(
          species: item.$2,
          variantName: _variantNameForIndex(item.$1),
          variantId: _variantIdForIndex(item.$1),
          discovered: _discoveredSpeciesIds.contains(item.$2.id),
          collectionNumber: item.$1 + 1,
        ),
    ];
  }

  String _variantNameForIndex(int index) {
    return CatDexSeedData.variants[index % CatDexSeedData.variants.length].name;
  }

  String _variantIdForIndex(int index) {
    return CatDexSeedData.variants[index % CatDexSeedData.variants.length].id;
  }
}
