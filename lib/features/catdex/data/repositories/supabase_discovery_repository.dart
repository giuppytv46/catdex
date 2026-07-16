import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDiscoveryRepository implements DiscoveryRepository {
  const SupabaseDiscoveryRepository({
    required SupabaseClient client,
    required String userId,
  }) : _client = client,
       _userId = userId;

  final SupabaseClient _client;
  final String _userId;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    final rows = await _client
        .from('discoveries')
        .select('*, discovery_traits(*)')
        .eq('user_id', _userId)
        .order('discovered_at', ascending: false);

    return rows.map(mapDiscovery).toList(growable: false);
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    final row = await _client
        .from('discoveries')
        .select('*, discovery_traits(*)')
        .eq('user_id', _userId)
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : mapDiscovery(row);
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    final row = await _client
        .from('discoveries')
        .select('id')
        .eq('user_id', _userId)
        .eq('species_id', speciesId)
        .limit(1)
        .maybeSingle();

    return row != null;
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    await _client
        .from('discoveries')
        .upsert(toDiscoveryRow(discovery, _userId));

    await _client
        .from('discovery_traits')
        .delete()
        .eq('user_id', _userId)
        .eq('discovery_id', discovery.id);

    if (discovery.traits.isNotEmpty) {
      await _client
          .from('discovery_traits')
          .insert(
            discovery.traits
                .map((trait) {
                  return toTraitRow(
                    discoveryId: discovery.id,
                    userId: _userId,
                    trait: trait,
                  );
                })
                .toList(growable: false),
          );
    }
  }

  static CatDiscovery mapDiscovery(Map<String, dynamic> row) {
    final traitRows = row['discovery_traits'] as List<dynamic>? ?? const [];
    final photoUrl = row['photo_url'] as String?;

    return CatDiscovery(
      id: row['id'] as String,
      playerId: row['user_id'] as String,
      speciesId: row['species_id'] as String,
      variantId: row['variant_id'] as String,
      rarity: _rarity(row['rarity'] as String),
      personality: _personality(row['personality'] as String),
      traits: traitRows
          .cast<Map<String, dynamic>>()
          .map(mapTrait)
          .toList(growable: false),
      discoveredAt: DateTime.parse(row['discovered_at'] as String),
      friendshipPoints: row['friendship_points'] as int? ?? 0,
      nickname: row['nickname'] as String?,
      city: row['city'] as String?,
      country: row['country'] as String?,
      photoPath: photoUrl,
      originalPhotoStoragePath: _looksLikeStoragePath(photoUrl)
          ? photoUrl
          : null,
      favorite: row['favorite'] as bool? ?? false,
      captureLocation: CatDiscoveryLocation.tryFromJson(
        row['capture_location'],
      ),
      locationConsentVersion: row['location_consent_version'] as String?,
      locationCapturedAt: DateTime.tryParse(
        row['location_captured_at'] as String? ?? '',
      ),
    );
  }

  static CatTrait mapTrait(Map<String, dynamic> row) {
    return CatTrait(
      name: row['trait_name'] as String,
      value: row['trait_value'] as String,
      rarityWeight: (row['rarity_weight'] as num?)?.toDouble() ?? 1,
    );
  }

  static Map<String, Object?> toDiscoveryRow(
    CatDiscovery discovery,
    String userId, {
    bool includeLocationMetadata = false,
  }) {
    final row = <String, Object?>{
      'id': discovery.id,
      'user_id': userId,
      'species_id': discovery.speciesId,
      'variant_id': discovery.variantId,
      'rarity': discovery.rarity.name,
      'personality': discovery.personality.name,
      'friendship_points': discovery.friendshipPoints,
      'nickname': discovery.nickname,
      'city': discovery.city,
      'country': discovery.country,
      'photo_url':
          discovery.originalPhotoStoragePath ??
          CatDexPersistedPhotoPath.normalizeForPersistence(
            discovery.originalPhotoPath,
          ) ??
          CatDexPersistedPhotoPath.normalizeForPersistence(
            discovery.photoPath,
          ),
      'favorite': discovery.favorite,
      'discovered_at': discovery.discoveredAt.toIso8601String(),
    };
    if (includeLocationMetadata) {
      row.addAll(toLocationMetadataRow(discovery));
    }
    return row;
  }

  /// Opt-in mapping for deployments whose discoveries table has the location
  /// columns. Keeping it separate avoids assuming a database migration in this
  /// foundation-only change.
  static Map<String, Object?> toLocationMetadataRow(
    CatDiscovery discovery,
  ) {
    return {
      'capture_location': discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.captureLocation!.toJson()
          : null,
      'location_consent_version':
          discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.locationConsentVersion
          : null,
      'location_captured_at':
          discovery.captureLocation?.hasValidCoordinates == true
          ? discovery.locationCapturedAt?.toIso8601String()
          : null,
    };
  }

  static bool _looksLikeStoragePath(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }
    if (CatDexPersistedPhotoPath.isPersistedLocalPhotoPath(normalized)) {
      return false;
    }

    return normalized.startsWith('catdex/originals/') ||
        normalized.startsWith('catdex/photos/') ||
        normalized.startsWith('uploads/');
  }

  static Map<String, Object?> toTraitRow({
    required String discoveryId,
    required String userId,
    required CatTrait trait,
  }) {
    return {
      'discovery_id': discoveryId,
      'user_id': userId,
      'trait_name': trait.name,
      'trait_value': trait.value,
      'rarity_weight': trait.rarityWeight,
    };
  }

  static CatRarity _rarity(String name) {
    for (final rarity in CatRarity.values) {
      if (rarity.name == name) {
        return rarity;
      }
    }

    throw FormatException('Unknown rarity: $name');
  }

  static CatPersonality _personality(String name) {
    for (final personality in CatPersonality.values) {
      if (personality.name == name) {
        return personality;
      }
    }

    throw FormatException('Unknown personality: $name');
  }
}
