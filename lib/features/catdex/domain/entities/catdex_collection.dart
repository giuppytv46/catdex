import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';

class CatDexCollectionState {
  const CatDexCollectionState({
    required this.entries,
    required this.visibleEntries,
    required this.totalCount,
    required this.discoveredCount,
    required this.searchQuery,
    required this.selectedRarity,
    required this.selectedVariantId,
    required this.discoveryFilter,
    required this.availableVariants,
  });

  final List<CatDexCollectionEntry> entries;
  final List<CatDexCollectionEntry> visibleEntries;
  final int totalCount;
  final int discoveredCount;
  final String searchQuery;
  final CatRarity? selectedRarity;
  final String? selectedVariantId;
  final CatDexDiscoveryFilter discoveryFilter;
  final List<CatDexVariantFilter> availableVariants;

  double get completionPercentage {
    if (totalCount == 0) {
      return 0;
    }

    return discoveredCount / totalCount;
  }

  CatDexCollectionState copyWith({
    List<CatDexCollectionEntry>? entries,
    List<CatDexCollectionEntry>? visibleEntries,
    int? totalCount,
    int? discoveredCount,
    String? searchQuery,
    CatRarity? selectedRarity,
    bool clearSelectedRarity = false,
    String? selectedVariantId,
    bool clearSelectedVariant = false,
    CatDexDiscoveryFilter? discoveryFilter,
    List<CatDexVariantFilter>? availableVariants,
  }) {
    return CatDexCollectionState(
      entries: entries ?? this.entries,
      visibleEntries: visibleEntries ?? this.visibleEntries,
      totalCount: totalCount ?? this.totalCount,
      discoveredCount: discoveredCount ?? this.discoveredCount,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRarity: clearSelectedRarity
          ? null
          : selectedRarity ?? this.selectedRarity,
      selectedVariantId: clearSelectedVariant
          ? null
          : selectedVariantId ?? this.selectedVariantId,
      discoveryFilter: discoveryFilter ?? this.discoveryFilter,
      availableVariants: availableVariants ?? this.availableVariants,
    );
  }
}

class CatDexCollectionEntry {
  const CatDexCollectionEntry({
    required this.species,
    required this.variantName,
    required this.variantId,
    required this.discovered,
    required this.collectionNumber,
  });

  final CatSpecies species;
  final String variantName;
  final String variantId;
  final bool discovered;
  final int collectionNumber;
}

class CatDexVariantFilter {
  const CatDexVariantFilter({required this.id, required this.name});

  final String id;
  final String name;
}

enum CatDexDiscoveryFilter {
  all,
  discovered,
  undiscovered,
}
