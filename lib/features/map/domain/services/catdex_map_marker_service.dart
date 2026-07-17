import 'dart:math' as math;

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/map/domain/entities/catdex_map_marker_data.dart';

class CatDexMapMarkerService {
  const CatDexMapMarkerService();

  static const neutralViewport = CatDexMapViewport(
    latitude: 41.9028,
    longitude: 12.4964,
    zoom: 5.5,
  );

  CatDexMapMarkerPreparation prepare(
    List<CatDiscovery> discoveries, {
    Set<CatRarity> rarityFilter = const {},
    bool eventOnly = false,
    Set<String> eventDiscoveryIds = const {},
  }) {
    final markers = <CatDexMapMarkerData>[];
    final seenDiscoveryIds = <String>{};
    final matchedDiscoveryIds = <String>{};
    for (final discovery in discoveries) {
      if (!seenDiscoveryIds.add(discovery.id)) continue;
      final hasEventArtwork = eventDiscoveryIds.contains(discovery.id);
      if (!_matchesRarity(discovery.rarity, rarityFilter) ||
          (eventOnly && !hasEventArtwork)) {
        continue;
      }
      matchedDiscoveryIds.add(discovery.id);
      final location = discovery.captureLocation;
      if (location?.hasValidCoordinates != true) continue;
      markers.add(
        CatDexMapMarkerData(
          discovery: discovery,
          location: location!,
          hasEventArtwork: hasEventArtwork,
        ),
      );
    }
    markers.sort(
      (a, b) => b.discovery.discoveredAt.compareTo(
        a.discovery.discoveredAt,
      ),
    );

    return CatDexMapMarkerPreparation(
      markers: List.unmodifiable(markers),
      totalDiscoveryCount: matchedDiscoveryIds.length,
      missingLocationCount: matchedDiscoveryIds.length - markers.length,
      initialViewport: _initialViewport(markers),
      nearbyClusterCount: _estimatedNearbyClusterCount(markers),
    );
  }

  bool _matchesRarity(CatRarity rarity, Set<CatRarity> filters) {
    if (filters.isEmpty) return true;
    final normalized = rarity == CatRarity.mythic
        ? CatRarity.legendary
        : rarity;
    return filters.contains(normalized);
  }

  CatDexMapViewport _initialViewport(List<CatDexMapMarkerData> markers) {
    if (markers.isEmpty) return neutralViewport;
    if (markers.length == 1) {
      return CatDexMapViewport(
        latitude: markers.single.latitude,
        longitude: markers.single.longitude,
        zoom: 14.5,
      );
    }

    var minLatitude = markers.first.latitude;
    var maxLatitude = markers.first.latitude;
    var minLongitude = markers.first.longitude;
    var maxLongitude = markers.first.longitude;
    for (final marker in markers.skip(1)) {
      minLatitude = math.min(minLatitude, marker.latitude);
      maxLatitude = math.max(maxLatitude, marker.latitude);
      minLongitude = math.min(minLongitude, marker.longitude);
      maxLongitude = math.max(maxLongitude, marker.longitude);
    }
    final span = math.max(
      maxLatitude - minLatitude,
      maxLongitude - minLongitude,
    );

    return CatDexMapViewport(
      latitude: (minLatitude + maxLatitude) / 2,
      longitude: (minLongitude + maxLongitude) / 2,
      zoom: _zoomForSpan(span),
    );
  }

  double _zoomForSpan(double span) {
    if (span <= 0.01) return 14;
    if (span <= 0.05) return 12.5;
    if (span <= 0.2) return 10.5;
    if (span <= 1) return 8.5;
    if (span <= 5) return 6.5;
    return 4.5;
  }

  int _estimatedNearbyClusterCount(List<CatDexMapMarkerData> markers) {
    final cells = <String, int>{};
    for (final marker in markers) {
      final latitudeCell = (marker.latitude / 0.02).floor();
      final longitudeCell = (marker.longitude / 0.02).floor();
      final key = '$latitudeCell:$longitudeCell';
      cells[key] = (cells[key] ?? 0) + 1;
    }
    return cells.values.where((count) => count > 1).length;
  }
}
