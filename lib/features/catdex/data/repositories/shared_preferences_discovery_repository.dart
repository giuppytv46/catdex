import 'dart:convert';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:flutter/foundation.dart';
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
    final nextDiscoveries = _dedupeByDiscoveryId([
      discovery,
      ...discoveries.where((item) => item.id != discovery.id),
    ]);

    try {
      await _writeDiscoveries(nextDiscoveries);
      final readBack = await _readDiscoveries();
      final persisted = _findById(readBack, discovery.id);
      if (persisted == null ||
          jsonEncode(_toJson(persisted)) != jsonEncode(_toJson(discovery))) {
        throw StateError(
          'Discovery read-after-write failed: ${discovery.id}',
        );
      }
    } on Object {
      await _writeDiscoveries(discoveries);
      rethrow;
    }
  }

  Future<List<CatDiscovery>> _readDiscoveries() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedDiscoveries = preferences.getStringList(_storageKey) ?? [];
    var migrated = false;
    var skippedCorruptRecord = false;
    final decodedDiscoveries = <Map<String, Object?>>[];
    for (var index = 0; index < encodedDiscoveries.length; index += 1) {
      try {
        final encoded = encodedDiscoveries[index];
        final json = Map<String, Object?>.from(
          jsonDecode(encoded) as Map<String, dynamic>,
        );
        if (_migrateLocalPhotoPaths(json)) {
          migrated = true;
        }
        // Validate each record independently so one damaged entry cannot
        // prevent the remaining CatDex from restoring.
        _fromJson(json);
        decodedDiscoveries.add(json);
      } on Object catch (error) {
        skippedCorruptRecord = true;
        debugPrint(
          'CATDEX_RESTORE_CORRUPT_RECORD_SKIPPED '
          'index=$index error=${error.runtimeType}',
        );
      }
    }

    if (migrated || skippedCorruptRecord) {
      final written = await preferences.setStringList(
        _storageKey,
        decodedDiscoveries.map(jsonEncode).toList(growable: false),
      );
      if (!written) {
        throw StateError('Discovery migration write failed');
      }
    }

    return _dedupeByDiscoveryId(
      decodedDiscoveries.map(_fromJson).toList(growable: false),
    );
  }

  Future<void> _writeDiscoveries(List<CatDiscovery> discoveries) async {
    final preferences = await SharedPreferences.getInstance();
    final written = await preferences.setStringList(
      _storageKey,
      discoveries
          .map((discovery) => jsonEncode(_toJson(discovery)))
          .toList(growable: false),
    );
    if (!written) {
      throw StateError('Discovery write failed');
    }
  }

  Map<String, Object?> _toJson(CatDiscovery discovery) {
    return {
      'id': discovery.id,
      'playerId': discovery.playerId,
      'customName': discovery.customName,
      'suggestedName': discovery.suggestedName,
      'species': discovery.speciesId,
      'speciesId': discovery.speciesId,
      'photo': CatDexPersistedPhotoPath.normalizeForPersistence(
        discovery.photoPath,
      ),
      'photoPath': CatDexPersistedPhotoPath.normalizeForPersistence(
        discovery.photoPath,
      ),
      'originalPhotoPath': CatDexPersistedPhotoPath.normalizeForPersistence(
        discovery.originalPhotoPath,
      ),
      'displayPhotoPath': CatDexPersistedPhotoPath.normalizeForPersistence(
        discovery.displayPhotoPath,
      ),
      'originalPhotoStoragePath': discovery.originalPhotoStoragePath,
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
      'captureLocation': discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.captureLocation!.toJson()
          : null,
      'locationConsentVersion':
          discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.locationConsentVersion
          : null,
      'locationCapturedAt':
          discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.locationCapturedAt?.toIso8601String()
          : null,
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
          .whereType<Map<Object?, Object?>>()
          .map((item) => _traitFromJson(Map<String, Object?>.from(item)))
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
      originalPhotoStoragePath: json['originalPhotoStoragePath'] as String?,
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
      captureLocation: CatDiscoveryLocation.tryFromJson(
        json['captureLocation'],
      ),
      locationConsentVersion: json['locationConsentVersion'] as String?,
      locationCapturedAt: DateTime.tryParse(
        json['locationCapturedAt'] as String? ?? '',
      ),
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
      'cardImageUrl': card.cardImageUrl,
      'cardImagePath': card.cardImagePath,
      'aiIllustrationUrl': card.aiIllustrationUrl,
      'aiIllustrationPath': card.aiIllustrationPath,
      'illustratedCatImageUrl': card.illustratedCatImageUrl,
      'illustratedCatImagePath': card.illustratedCatImagePath,
      'cutoutImagePath': card.cutoutImagePath,
      'illustratedCatPath': card.illustratedCatPath,
      'cardTemplateId': card.cardTemplateId,
      'cardGeneratedAt': card.cardGeneratedAt?.toIso8601String(),
      'cardVersion': card.cardVersion,
      'generationStatus': card.generationStatus,
      'eventKey': card.eventKey,
      'eventEdition': card.eventEdition,
      'eventArtworkVariantId': card.eventArtworkVariantId,
      'eventArtworkTier': card.eventArtworkTier,
      'eventTemplateKey': card.eventTemplateKey,
      'generatedDuringEventAt': card.generatedDuringEventAt?.toIso8601String(),
      'originalPhotoPath': CatDexPersistedPhotoPath.normalizeForPersistence(
        card.originalPhotoPath,
      ),
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
      cardImageUrl: json['cardImageUrl'] as String?,
      cardImagePath: json['cardImagePath'] as String?,
      aiIllustrationUrl: json['aiIllustrationUrl'] as String?,
      aiIllustrationPath: json['aiIllustrationPath'] as String?,
      illustratedCatImageUrl: json['illustratedCatImageUrl'] as String?,
      illustratedCatImagePath: json['illustratedCatImagePath'] as String?,
      cutoutImagePath: json['cutoutImagePath'] as String?,
      illustratedCatPath: json['illustratedCatPath'] as String?,
      cardTemplateId: json['cardTemplateId'] as String? ?? 'common_clean',
      cardVersion: json['cardVersion'] as int? ?? 1,
      generationStatus: json['generationStatus'] as String?,
      eventKey: json['eventKey'] as String?,
      eventEdition: json['eventEdition'] as String?,
      eventArtworkVariantId: json['eventArtworkVariantId'] as String?,
      eventArtworkTier: json['eventArtworkTier'] as String?,
      eventTemplateKey: json['eventTemplateKey'] as String?,
      generatedDuringEventAt: DateTime.tryParse(
        json['generatedDuringEventAt'] as String? ?? '',
      ),
      originalPhotoPath: json['originalPhotoPath'] as String?,
      generatedAt: DateTime.parse(
        (json['cardGeneratedAt'] ?? json['generatedAt'])! as String,
      ),
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

  bool _migrateLocalPhotoPaths(Map<String, Object?> json) {
    var migrated = false;

    void migrateValue(Map<String, Object?> target, String key) {
      final current = target[key] as String?;
      final normalized = CatDexPersistedPhotoPath.normalizeForPersistence(
        current,
      );
      if (normalized != current) {
        target[key] = normalized;
        migrated = true;
      }
    }

    migrateValue(json, 'photo');
    migrateValue(json, 'photoPath');
    migrateValue(json, 'originalPhotoPath');
    migrateValue(json, 'displayPhotoPath');

    final rawCard = json['card'];
    if (rawCard is Map<Object?, Object?>) {
      final card = Map<String, Object?>.from(rawCard);
      migrateValue(card, 'originalPhotoPath');
      json['card'] = card;
    }

    return migrated;
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

  List<CatDiscovery> _dedupeByDiscoveryId(List<CatDiscovery> discoveries) {
    final seen = <String>{};
    final deduped = <CatDiscovery>[];
    for (final discovery in discoveries) {
      if (seen.add(discovery.id)) {
        deduped.add(discovery);
      }
    }

    return deduped;
  }

  CatDiscovery? _findById(
    List<CatDiscovery> discoveries,
    String discoveryId,
  ) {
    for (final discovery in discoveries) {
      if (discovery.id == discoveryId) {
        return discovery;
      }
    }
    return null;
  }
}
