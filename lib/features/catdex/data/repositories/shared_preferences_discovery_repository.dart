import 'dart:convert';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDiscoveryRepository implements DiscoveryRepository {
  const SharedPreferencesDiscoveryRepository();

  static const _storageKey = 'catdex_local_discoveries';

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    final discoveries = await _readDiscoveries();

    return discoveries
        .where((discovery) => discovery.playerId == playerId)
        .toList(growable: false);
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    final discoveries = await _readDiscoveries();
    for (final discovery in discoveries) {
      if (discovery.id == id) {
        return discovery;
      }
    }

    return null;
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    final discoveries = await getDiscoveriesForPlayer(playerId);

    return discoveries.any((discovery) => discovery.speciesId == speciesId);
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    final discoveries = await _readDiscoveries();
    final nextDiscoveries = [
      discovery,
      ...discoveries.where((item) => item.id != discovery.id),
    ];

    await _writeDiscoveries(nextDiscoveries);
  }

  Future<List<CatDiscovery>> _readDiscoveries() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedDiscoveries = preferences.getStringList(_storageKey) ?? [];

    return encodedDiscoveries
        .map(
          (encoded) => _fromJson(jsonDecode(encoded) as Map<String, Object?>),
        )
        .toList(growable: false);
  }

  Future<void> _writeDiscoveries(List<CatDiscovery> discoveries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _storageKey,
      discoveries
          .map((discovery) => jsonEncode(_toJson(discovery)))
          .toList(growable: false),
    );
  }

  Map<String, Object?> _toJson(CatDiscovery discovery) {
    return {
      'id': discovery.id,
      'playerId': discovery.playerId,
      'customName': discovery.customName,
      'suggestedName': discovery.suggestedName,
      'species': discovery.speciesId,
      'speciesId': discovery.speciesId,
      'photo': discovery.photoPath,
      'photoPath': discovery.photoPath,
      'originalPhotoPath': discovery.originalPhotoPath,
      'displayPhotoPath': discovery.displayPhotoPath,
      'story': discovery.story,
      'funFact': discovery.funFact,
      'rarity': discovery.rarity.name,
      'variant': discovery.variantId,
      'variantId': discovery.variantId,
      'personality': discovery.personality.name,
      'coatColor': discovery.coatColor,
      'coatPattern': discovery.coatPattern,
      'eyeColor': discovery.eyeColor,
      'hairLength': discovery.hairLength,
      'estimatedAge': discovery.estimatedAge,
      'traits': discovery.traits.map(_traitToJson).toList(growable: false),
      'xp': discovery.xpEarned,
      'coins': discovery.coinsEarned,
      'confidence': discovery.confidenceScore,
      'discoveredAt': discovery.discoveredAt.toIso8601String(),
      'friendshipPoints': discovery.friendshipPoints,
      'city': discovery.city,
      'country': discovery.country,
      'favorite': discovery.favorite,
      'card': discovery.card == null ? null : _cardToJson(discovery.card!),
    };
  }

  CatDiscovery _fromJson(Map<String, Object?> json) {
    final traits = json['traits'] as List<dynamic>? ?? const [];

    return CatDiscovery(
      id: json['id']! as String,
      playerId: json['playerId']! as String,
      speciesId: (json['speciesId'] ?? json['species'])! as String,
      variantId: (json['variantId'] ?? json['variant'])! as String,
      rarity: _rarity(json['rarity']! as String),
      personality: _personality(json['personality'] as String? ?? 'curious'),
      traits: traits
          .cast<Map<String, Object?>>()
          .map(_traitFromJson)
          .toList(growable: false),
      discoveredAt: DateTime.parse(json['discoveredAt']! as String),
      friendshipPoints: json['friendshipPoints'] as int? ?? 0,
      customName: json['customName'] as String?,
      suggestedName: json['suggestedName'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      photoPath: (json['photoPath'] ?? json['photo']) as String?,
      originalPhotoPath:
          (json['originalPhotoPath'] ?? json['photoPath'] ?? json['photo'])
              as String?,
      displayPhotoPath:
          (json['displayPhotoPath'] ?? json['photoPath'] ?? json['photo'])
              as String?,
      story: json['story'] as String?,
      funFact: json['funFact'] as String?,
      coatColor: json['coatColor'] as String?,
      coatPattern: json['coatPattern'] as String?,
      eyeColor: json['eyeColor'] as String?,
      hairLength: json['hairLength'] as String?,
      estimatedAge: json['estimatedAge'] as String?,
      xpEarned: json['xp'] as int?,
      coinsEarned: json['coins'] as int?,
      confidenceScore: (json['confidence'] as num?)?.toDouble(),
      card: _cardFromJson(json['card'] as Map<String, Object?>?),
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  Map<String, Object?> _cardToJson(CatDiscoveryCard card) {
    return {
      'cardId': card.cardId,
      'discoveryId': card.discoveryId,
      'cardFrameStyle': card.cardFrameStyle,
      'cardBackgroundStyle': card.cardBackgroundStyle,
      'cardRarityStyle': card.cardRarityStyle,
      'eventThemeId': card.eventThemeId,
      'isEventCard': card.isEventCard,
      'cutoutImagePath': card.cutoutImagePath,
      'originalPhotoPath': card.originalPhotoPath,
      'generatedAt': card.generatedAt.toIso8601String(),
    };
  }

  CatDiscoveryCard? _cardFromJson(Map<String, Object?>? json) {
    if (json == null) {
      return null;
    }

    return CatDiscoveryCard(
      cardId: json['cardId']! as String,
      discoveryId: json['discoveryId']! as String,
      cardFrameStyle: json['cardFrameStyle']! as String,
      cardBackgroundStyle: json['cardBackgroundStyle']! as String,
      cardRarityStyle: json['cardRarityStyle']! as String,
      eventThemeId: json['eventThemeId'] as String?,
      isEventCard: json['isEventCard'] as bool? ?? false,
      cutoutImagePath: json['cutoutImagePath'] as String?,
      originalPhotoPath: json['originalPhotoPath'] as String?,
      generatedAt: DateTime.parse(json['generatedAt']! as String),
    );
  }

  Map<String, Object?> _traitToJson(CatTrait trait) {
    return {
      'name': trait.name,
      'value': trait.value,
      'rarityWeight': trait.rarityWeight,
    };
  }

  CatTrait _traitFromJson(Map<String, Object?> json) {
    return CatTrait(
      name: json['name']! as String,
      value: json['value']! as String,
      rarityWeight: (json['rarityWeight'] as num?)?.toDouble() ?? 1,
    );
  }

  CatRarity _rarity(String name) {
    for (final rarity in CatRarity.values) {
      if (rarity.name == name) {
        return rarity;
      }
    }

    return CatRarity.common;
  }

  CatPersonality _personality(String name) {
    for (final personality in CatPersonality.values) {
      if (personality.name == name) {
        return personality;
      }
    }

    return CatPersonality.curious;
  }
}
