import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDexControllerProvider =
    NotifierProvider<CatDexController, CatDexCollectionState>(
      CatDexController.new,
    );

class CatDexController extends Notifier<CatDexCollectionState> {
  @override
  CatDexCollectionState build() {
    final sessionDiscoveries = ref.watch(localDiscoverySessionProvider);
    final entries = _buildEntries(sessionDiscoveries);
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
              entry.species.baseRarity == nextSelectedRarity;
          final matchesVariant =
              nextSelectedVariantId == null ||
              entry.variantId == nextSelectedVariantId;
          final matchesDiscovery = switch (nextDiscoveryFilter) {
            CatDexDiscoveryFilter.all => true,
            CatDexDiscoveryFilter.discovered => entry.discovered,
            CatDexDiscoveryFilter.undiscovered => !entry.discovered,
            CatDexDiscoveryFilter.favorites => entry.favorite,
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

  List<CatDexCollectionEntry> _buildEntries(
    List<CatDiscovery> sessionDiscoveries,
  ) {
    final entries = [
      for (final item in CatDexSeedData.species.indexed)
        _entryForSpecies(
          index: item.$1,
          speciesId: item.$2.id,
          sessionDiscoveries: sessionDiscoveries,
        ),
    ];

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

  CatDexCollectionEntry _entryForSpecies({
    required int index,
    required String speciesId,
    required List<CatDiscovery> sessionDiscoveries,
  }) {
    final species = CatDexSeedData.species[index];
    final localDiscovery = _localDiscoveryForSpecies(
      speciesId: speciesId,
      sessionDiscoveries: sessionDiscoveries,
    );

    return CatDexCollectionEntry(
      species: species,
      variantName: localDiscovery == null
          ? _variantNameForIndex(index)
          : _variantNameById(localDiscovery.variantId),
      variantId: localDiscovery?.variantId ?? _variantIdForIndex(index),
      discovered: localDiscovery != null,
      collectionNumber: index + 1,
      discovery: localDiscovery,
      displayName: localDiscovery?.customName,
      discoveredPhotoPath: localDiscovery?.photoPath,
    );
  }

  CatDiscovery? _localDiscoveryForSpecies({
    required String speciesId,
    required List<CatDiscovery> sessionDiscoveries,
  }) {
    for (final discovery in sessionDiscoveries) {
      if (discovery.speciesId == speciesId) {
        return discovery;
      }
    }

    return null;
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
}
