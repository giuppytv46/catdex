import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';

class CatDexMapMarkerData {
  const CatDexMapMarkerData({
    required this.discovery,
    required this.location,
  });

  final CatDiscovery discovery;
  final CatDiscoveryLocation location;

  String get discoveryId => discovery.id;
  double get latitude => location.latitude!;
  double get longitude => location.longitude!;
  bool get isApproximate => location.isApproximate;
}

class CatDexMapViewport {
  const CatDexMapViewport({
    required this.latitude,
    required this.longitude,
    required this.zoom,
  });

  final double latitude;
  final double longitude;
  final double zoom;
}

class CatDexMapMarkerPreparation {
  const CatDexMapMarkerPreparation({
    required this.markers,
    required this.totalDiscoveryCount,
    required this.missingLocationCount,
    required this.initialViewport,
    required this.nearbyClusterCount,
  });

  final List<CatDexMapMarkerData> markers;
  final int totalDiscoveryCount;
  final int missingLocationCount;
  final CatDexMapViewport initialViewport;

  /// A cheap initial estimate used only for diagnostics. Runtime clustering is
  /// handled spatially by flutter_map_marker_cluster as the camera moves.
  final int nearbyClusterCount;
}
