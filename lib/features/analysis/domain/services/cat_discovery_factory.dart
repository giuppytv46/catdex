import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

class CatDiscoveryFactory {
  const CatDiscoveryFactory();

  CatDiscovery create({
    required CatAnalysisResult result,
    required String discoveryId,
    required String playerId,
    required DateTime discoveredAt,
    required int friendshipPoints,
    String nickname = 'Mochi',
  }) {
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
      nickname: nickname,
    );
  }
}
