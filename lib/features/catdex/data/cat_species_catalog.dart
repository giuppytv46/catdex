import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_species.dart';

class CatSpeciesCatalog {
  const CatSpeciesCatalog._();

  static const _genericDomesticIdentifiers = {'domestic_cat'};

  static CatSpecies? find(String? rawIdentifier) {
    final identifier = _normalize(rawIdentifier);
    if (identifier.isEmpty) {
      return null;
    }

    final directMatch = _findByCanonicalKey(identifier);
    if (directMatch != null) {
      return directMatch;
    }

    if (identifier.endsWith('_cat')) {
      return _findByCanonicalKey(
        identifier.substring(0, identifier.length - '_cat'.length),
      );
    }

    return null;
  }

  static String canonicalIdentifier(
    String? rawIdentifier, {
    String? fallbackIdentifier,
  }) {
    final match = find(rawIdentifier);
    if (match != null) {
      return match.id;
    }

    final normalized = _normalize(rawIdentifier);
    if (_genericDomesticIdentifiers.contains(normalized)) {
      return normalized;
    }

    final fallback = find(fallbackIdentifier);
    if (fallback != null) {
      return fallback.id;
    }

    final normalizedFallback = _normalize(fallbackIdentifier);
    if (_genericDomesticIdentifiers.contains(normalizedFallback)) {
      return normalizedFallback;
    }

    return normalized.isNotEmpty ? normalized : 'domestic_cat';
  }

  static bool isKnownIdentifier(String? rawIdentifier) {
    final normalized = _normalize(rawIdentifier);
    return find(normalized) != null ||
        _genericDomesticIdentifiers.contains(normalized);
  }

  static bool isSpecificBreed(String? rawIdentifier) {
    final species = find(rawIdentifier);
    if (species == null) {
      return false;
    }

    return !species.id.startsWith('domestic_') &&
        !species.id.endsWith('_variant');
  }

  static CatSpecies? _findByCanonicalKey(String identifier) {
    for (final species in CatDexSeedData.species) {
      if (_normalize(species.id) == identifier ||
          _normalize(species.displayName) == identifier) {
        return species;
      }
    }

    return null;
  }

  static String _normalize(String? value) {
    return value
            ?.trim()
            .toLowerCase()
            .replaceAll(RegExp('[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '') ??
        '';
  }
}
