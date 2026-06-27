import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatDiscovery {
  const CatDiscovery({
    required this.id,
    required this.playerId,
    required this.speciesId,
    required this.variantId,
    required this.rarity,
    required this.personality,
    required this.traits,
    required this.discoveredAt,
    required this.friendshipPoints,
    this.nickname,
    this.city,
    this.country,
    this.favorite = false,
  }) : assert(friendshipPoints >= 0, 'friendshipPoints cannot be negative');

  final String id;
  final String playerId;
  final String speciesId;
  final String variantId;
  final CatRarity rarity;
  final CatPersonality personality;
  final List<CatTrait> traits;
  final DateTime discoveredAt;
  final int friendshipPoints;
  final String? nickname;
  final String? city;
  final String? country;
  final bool favorite;
}
