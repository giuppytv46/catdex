import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';

class CatDiscoveryFactory {
  const CatDiscoveryFactory();

  CatDiscovery create({
    required CatAnalysisResult result,
    required String discoveryId,
    required String playerId,
    required DateTime discoveredAt,
    required int friendshipPoints,
    required int xpEarned,
    required int coinsEarned,
    String customName = 'Mochi',
    String suggestedName = 'Mochi',
    String? originalPhotoPath,
    String? displayPhotoPath,
    CatDiscoveryLocation? captureLocation,
    String? locationConsentVersion,
  }) {
    final trimmedSuggestedName = _safeName(suggestedName);
    final trimmedCustomName = customName.trim().isEmpty
        ? trimmedSuggestedName
        : customName.trim();
    final resolvedOriginalPhotoPath = originalPhotoPath?.trim().isEmpty ?? true
        ? null
        : originalPhotoPath?.trim();
    final resolvedDisplayPhotoPath = displayPhotoPath?.trim().isEmpty ?? true
        ? resolvedOriginalPhotoPath
        : displayPhotoPath?.trim();
    final card = _cardForDiscovery(
      discoveryId: discoveryId,
      rarityName: result.rarity.name,
      story: result.story,
      originalPhotoPath: resolvedOriginalPhotoPath,
      generatedAt: discoveredAt,
    );

    return CatDiscovery(
      id: discoveryId,
      playerId: playerId,
      speciesId: result.primaryBreed.species.id,
      variantId: result.variant.id,
      rarity: result.rarity,
      personality: result.personality,
      traits: result.visualTraits.notableTraits,
      discoveredAt: discoveredAt,
      friendshipPoints: friendshipPoints,
      suggestedName: trimmedSuggestedName,
      customName: trimmedCustomName,
      originalPhotoPath: resolvedOriginalPhotoPath,
      displayPhotoPath: resolvedDisplayPhotoPath,
      story: result.story,
      funFact: result.funFact,
      coatColor: result.visualTraits.coatColor,
      coatPattern: result.visualTraits.coatPattern,
      eyeColor: result.visualTraits.eyeColor,
      hairLength: result.visualTraits.hairLength,
      estimatedAge: result.estimatedAge,
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      confidenceScore: result.confidence.score,
      card: card,
      captureLocation: captureLocation,
      locationConsentVersion: locationConsentVersion,
      locationCapturedAt: captureLocation?.capturedAt,
    );
  }

  CatDiscoveryCard _cardForDiscovery({
    required String discoveryId,
    required String rarityName,
    required String story,
    required String? originalPhotoPath,
    required DateTime generatedAt,
  }) {
    // TODO(CatDex): generate cat cutout image
    // TODO(CatDex): remove background from cat photo
    // TODO(CatDex): create event card variants
    // TODO(CatDex): generate seasonal card backgrounds
    return CatDiscoveryCard(
      cardId: 'card-$discoveryId',
      discoveryId: discoveryId,
      cardFrameStyle: _frameStyleForRarity(rarityName),
      cardBackgroundStyle: _backgroundStyleForStory(story),
      cardRarityStyle: rarityName,
      isEventCard: false,
      originalPhotoPath: originalPhotoPath,
      generatedAt: generatedAt,
    );
  }

  String _safeName(String value) {
    final trimmed = value.trim();

    return trimmed.isEmpty ? 'Mochi' : trimmed;
  }

  String _frameStyleForRarity(String rarityName) {
    return switch (rarityName) {
      'common' => 'green_simple_frame',
      'uncommon' => 'blue_frame',
      'rare' => 'purple_frame',
      'epic' => 'gold_purple_frame',
      'legendary' || 'mythic' => 'gold_animated_style_frame',
      _ => 'green_simple_frame',
    };
  }

  String _backgroundStyleForStory(String story) {
    final normalizedStory = story.toLowerCase();
    if (normalizedStory.contains('night') ||
        normalizedStory.contains('dark') ||
        normalizedStory.contains('notte') ||
        normalizedStory.contains('buio')) {
      return 'night';
    }

    return 'default';
  }
}
