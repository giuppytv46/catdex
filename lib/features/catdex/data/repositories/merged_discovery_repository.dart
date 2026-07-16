import 'package:catdex/features/cards/domain/generated_card_state.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:flutter/foundation.dart';

class MergedDiscoveryRepository implements DiscoveryRepository {
  const MergedDiscoveryRepository({
    required DiscoveryRepository localRepository,
    required DiscoveryRepository remoteRepository,
  }) : _localRepository = localRepository,
       _remoteRepository = remoteRepository;

  final DiscoveryRepository _localRepository;
  final DiscoveryRepository _remoteRepository;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    final local = await _loadSafely(
      () => _localRepository.getDiscoveriesForPlayer(playerId),
    );
    final remote = await _loadSafely(
      () => _remoteRepository.getDiscoveriesForPlayer(playerId),
    );
    debugPrint('CATDEX_RESTORE_LOCAL_COUNT ${local.length}');
    debugPrint('CATDEX_RESTORE_REMOTE_COUNT ${remote.length}');
    debugPrint('CATDEX_DISCOVERY_LOAD_LOCAL_COUNT ${local.length}');
    debugPrint('CATDEX_DISCOVERY_LOAD_REMOTE_COUNT ${remote.length}');
    debugPrint(
      'CATDEX_DISCOVERY_MERGE_BEFORE_COUNT ${local.length + remote.length}',
    );

    final merged = mergeDiscoveriesById(local: local, remote: remote);
    debugPrint('CATDEX_RESTORE_MERGED_COUNT ${merged.length}');
    debugPrint('CATDEX_DISCOVERY_MERGE_AFTER_COUNT ${merged.length}');
    debugPrint(
      'CATDEX_DISCOVERY_MERGE_IDS ${merged.map((item) => item.id).join(',')}',
    );
    return merged;
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    CatDiscovery? local;
    CatDiscovery? remote;
    try {
      local = await _localRepository.getDiscoveryById(id);
    } on Object catch (error) {
      debugPrint('CATDEX_DISCOVERY_LOCAL_READ_FAILED id=$id error=$error');
    }
    try {
      remote = await _remoteRepository.getDiscoveryById(id);
    } on Object catch (error) {
      debugPrint('CATDEX_DISCOVERY_REMOTE_READ_FAILED id=$id error=$error');
    }

    if (local == null) {
      return remote;
    }
    if (remote == null) {
      return local;
    }
    return mergeDiscoveryRecords(preferred: local, fallback: remote);
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    final discoveries = await getDiscoveriesForPlayer(playerId);
    return discoveries.any((item) => item.speciesId == speciesId);
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    await _localRepository.saveDiscovery(discovery);
    await _remoteRepository.saveDiscovery(discovery);
  }

  Future<List<CatDiscovery>> _loadSafely(
    Future<List<CatDiscovery>> Function() load,
  ) async {
    try {
      return await load();
    } on Object catch (error) {
      debugPrint('CATDEX_DISCOVERY_SOURCE_LOAD_FAILED $error');
      return const [];
    }
  }
}

@visibleForTesting
List<CatDiscovery> mergeDiscoveriesById({
  required List<CatDiscovery> local,
  required List<CatDiscovery> remote,
}) {
  final byId = <String, CatDiscovery>{};
  for (final discovery in remote) {
    byId.putIfAbsent(discovery.id, () => discovery);
  }
  for (final discovery in local) {
    final remoteDiscovery = byId[discovery.id];
    byId[discovery.id] = remoteDiscovery == null
        ? discovery
        : mergeDiscoveryRecords(
            preferred: discovery,
            fallback: remoteDiscovery,
          );
  }

  final merged = byId.values.toList(growable: false);
  return merged..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
}

CatDiscovery mergeDiscoveryRecords({
  required CatDiscovery preferred,
  required CatDiscovery fallback,
}) {
  assert(preferred.id == fallback.id, 'Cannot merge different discoveries');
  final captureLocation = _mergeLocations(
    preferred.captureLocation,
    fallback.captureLocation,
  );
  final locationCapturedAt =
      identical(
        captureLocation,
        fallback.captureLocation,
      )
      ? fallback.locationCapturedAt
      : preferred.locationCapturedAt;
  return CatDiscovery(
    id: preferred.id,
    playerId: _pickText(preferred.playerId, fallback.playerId)!,
    speciesId: _pickText(preferred.speciesId, fallback.speciesId)!,
    variantId: _pickText(preferred.variantId, fallback.variantId)!,
    rarity: preferred.rarity,
    personality: preferred.personality,
    traits: preferred.traits.isNotEmpty ? preferred.traits : fallback.traits,
    discoveredAt: preferred.discoveredAt,
    friendshipPoints: preferred.friendshipPoints > 0
        ? preferred.friendshipPoints
        : fallback.friendshipPoints,
    customName: _pickText(preferred.customName, fallback.customName),
    suggestedName: _pickText(
      preferred.suggestedName,
      fallback.suggestedName,
    ),
    city: _pickText(preferred.city, fallback.city),
    country: _pickText(preferred.country, fallback.country),
    originalPhotoPath: _pickText(
      preferred.originalPhotoPath,
      fallback.originalPhotoPath,
    ),
    displayPhotoPath: _pickText(
      preferred.displayPhotoPath,
      fallback.displayPhotoPath,
    ),
    originalPhotoStoragePath: _pickText(
      preferred.originalPhotoStoragePath,
      fallback.originalPhotoStoragePath,
    ),
    story: _pickText(preferred.story, fallback.story),
    funFact: _pickText(preferred.funFact, fallback.funFact),
    coatColor: _pickText(preferred.coatColor, fallback.coatColor),
    coatPattern: _pickText(preferred.coatPattern, fallback.coatPattern),
    eyeColor: _pickText(preferred.eyeColor, fallback.eyeColor),
    hairLength: _pickText(preferred.hairLength, fallback.hairLength),
    estimatedAge: _pickText(preferred.estimatedAge, fallback.estimatedAge),
    xpEarned: preferred.xpEarned ?? fallback.xpEarned,
    coinsEarned: preferred.coinsEarned ?? fallback.coinsEarned,
    confidenceScore: preferred.confidenceScore ?? fallback.confidenceScore,
    card: _mergeCards(preferred.card, fallback.card),
    favorite: preferred.favorite || fallback.favorite,
    captureLocation: captureLocation,
    locationConsentVersion: _pickText(
      preferred.locationConsentVersion,
      fallback.locationConsentVersion,
    ),
    locationCapturedAt: captureLocation?.capturedAt ?? locationCapturedAt,
  );
}

CatDiscoveryLocation? _mergeLocations(
  CatDiscoveryLocation? preferred,
  CatDiscoveryLocation? fallback,
) {
  final preferredValid = preferred?.hasValidCoordinates ?? false;
  final fallbackValid = fallback?.hasValidCoordinates ?? false;
  if (!preferredValid) return fallbackValid ? fallback : null;
  if (!fallbackValid) return preferred;

  if (preferred!.completenessScore != fallback!.completenessScore) {
    return preferred.completenessScore > fallback.completenessScore
        ? preferred
        : fallback;
  }
  final preferredAt = preferred.capturedAt;
  final fallbackAt = fallback.capturedAt;
  if (preferredAt == null) return fallbackAt == null ? preferred : fallback;
  if (fallbackAt == null) return preferred;
  return fallbackAt.isAfter(preferredAt) ? fallback : preferred;
}

CatDiscoveryCard? _mergeCards(
  CatDiscoveryCard? preferred,
  CatDiscoveryCard? fallback,
) {
  if (preferred == null) {
    return fallback;
  }
  if (fallback == null) {
    return preferred;
  }

  final preferredGenerated = isFinalGeneratedCardImageSource(
    preferred.cardImageUrl,
  );
  final fallbackGenerated = isFinalGeneratedCardImageSource(
    fallback.cardImageUrl,
  );
  final CatDiscoveryCard base;
  final CatDiscoveryCard other;
  if (fallbackGenerated &&
      (!preferredGenerated ||
          fallback.generatedAt.isAfter(preferred.generatedAt))) {
    base = fallback;
    other = preferred;
  } else {
    base = preferred;
    other = fallback;
  }

  final baseTemplate = _pickText(base.cardTemplateId, null);
  final otherTemplate = _pickText(other.cardTemplateId, null);
  final selectedTemplate =
      (baseTemplate == null || baseTemplate == 'common_clean') &&
          otherTemplate != null &&
          otherTemplate != 'common_clean'
      ? otherTemplate
      : baseTemplate ?? otherTemplate ?? 'common_clean';

  return CatDiscoveryCard(
    cardId: _pickText(base.cardId, other.cardId)!,
    discoveryId: _pickText(base.discoveryId, other.discoveryId)!,
    cardFrameStyle: _pickText(
      base.cardFrameStyle,
      other.cardFrameStyle,
    )!,
    cardBackgroundStyle: _pickText(
      base.cardBackgroundStyle,
      other.cardBackgroundStyle,
    )!,
    cardRarityStyle: _pickText(
      base.cardRarityStyle,
      other.cardRarityStyle,
    )!,
    eventThemeId: _pickText(base.eventThemeId, other.eventThemeId),
    isEventCard: base.isEventCard || other.isEventCard,
    cardImageUrl: isFinalGeneratedCardImageSource(base.cardImageUrl)
        ? base.cardImageUrl
        : (isFinalGeneratedCardImageSource(other.cardImageUrl)
              ? other.cardImageUrl
              : null),
    cardImagePath: _pickText(base.cardImagePath, other.cardImagePath),
    aiIllustrationUrl: _pickText(
      base.aiIllustrationUrl,
      other.aiIllustrationUrl,
    ),
    aiIllustrationPath: _pickText(
      base.aiIllustrationPath,
      other.aiIllustrationPath,
    ),
    illustratedCatImageUrl: _pickText(
      base.illustratedCatImageUrl,
      other.illustratedCatImageUrl,
    ),
    illustratedCatImagePath: _pickText(
      base.illustratedCatImagePath,
      other.illustratedCatImagePath,
    ),
    cutoutImagePath: _pickText(
      base.cutoutImagePath,
      other.cutoutImagePath,
    ),
    illustratedCatPath: _pickText(
      base.illustratedCatPath,
      other.illustratedCatPath,
    ),
    cardTemplateId: selectedTemplate,
    cardVersion: base.cardVersion >= other.cardVersion
        ? base.cardVersion
        : other.cardVersion,
    generationStatus: _pickText(
      base.generationStatus,
      other.generationStatus,
    ),
    eventKey: _pickText(base.eventKey, other.eventKey),
    eventEdition: _pickText(base.eventEdition, other.eventEdition),
    eventArtworkVariantId: _pickText(
      base.eventArtworkVariantId,
      other.eventArtworkVariantId,
    ),
    eventArtworkTier: _pickText(
      base.eventArtworkTier,
      other.eventArtworkTier,
    ),
    eventTemplateKey: _pickText(
      base.eventTemplateKey,
      other.eventTemplateKey,
    ),
    generatedDuringEventAt:
        base.generatedDuringEventAt ?? other.generatedDuringEventAt,
    originalPhotoPath: _pickText(
      base.originalPhotoPath,
      other.originalPhotoPath,
    ),
    generatedAt: base.generatedAt.isAfter(other.generatedAt)
        ? base.generatedAt
        : other.generatedAt,
  );
}

String? _pickText(String? preferred, String? fallback) {
  if (_meaningful(preferred)) {
    return preferred!.trim();
  }
  if (_meaningful(fallback)) {
    return fallback!.trim();
  }
  return null;
}

bool _meaningful(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized != null &&
      normalized.isNotEmpty &&
      normalized != '-' &&
      normalized != 'null' &&
      normalized != 'unknown' &&
      normalized != 'non rilevato';
}
