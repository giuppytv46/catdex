import 'package:flutter/foundation.dart';

enum CatDiscoveryLocationSource {
  gps,
  manual,
  importedPhotoMetadata,
  unknown,
}

@immutable
class CatDiscoveryLocation {
  const CatDiscoveryLocation({
    this.latitude,
    this.longitude,
    this.horizontalAccuracyMeters,
    this.capturedAt,
    this.source = CatDiscoveryLocationSource.unknown,
    String? locality,
    String? administrativeArea,
    String? countryCode,
    String? city,
    String? region,
    String? country,
    this.isApproximate = false,
    this.schemaVersion = currentSchemaVersion,
  }) : locality = locality ?? city,
       administrativeArea = administrativeArea ?? region,
       countryCode = countryCode ?? country;

  static const currentSchemaVersion = 1;

  final double? latitude;
  final double? longitude;
  final double? horizontalAccuracyMeters;
  final DateTime? capturedAt;
  final CatDiscoveryLocationSource source;
  final String? locality;
  final String? administrativeArea;
  final String? countryCode;
  final bool isApproximate;
  final int schemaVersion;

  // Backward-compatible names used by the original location foundation.
  String? get city => locality;
  String? get region => administrativeArea;
  String? get country => countryCode;

  bool get hasValidCoordinates => coordinatesAreValid(latitude, longitude);

  bool get hasPlaceDetails => [
    locality,
    administrativeArea,
    countryCode,
  ].any(_hasText);

  String get displayLabel {
    final parts = [
      locality,
      administrativeArea,
      countryCode,
    ].where(_hasText).cast<String>().toList(growable: false);
    return parts.join(', ');
  }

  int get completenessScore {
    var score = hasValidCoordinates ? 4 : 0;
    if (horizontalAccuracyMeters != null) score += 1;
    if (capturedAt != null) score += 1;
    if (source != CatDiscoveryLocationSource.unknown) score += 1;
    if (_hasText(locality)) score += 1;
    if (_hasText(administrativeArea)) score += 1;
    if (_hasText(countryCode)) score += 1;
    return score;
  }

  static CatDiscoveryLocation? tryCreate({
    required double? latitude,
    required double? longitude,
    double? horizontalAccuracyMeters,
    DateTime? capturedAt,
    CatDiscoveryLocationSource source = CatDiscoveryLocationSource.unknown,
    String? locality,
    String? administrativeArea,
    String? countryCode,
    bool isApproximate = false,
    int schemaVersion = currentSchemaVersion,
  }) {
    if (!coordinatesAreValid(latitude, longitude) ||
        !_accuracyIsValid(horizontalAccuracyMeters)) {
      return null;
    }
    return CatDiscoveryLocation(
      latitude: latitude,
      longitude: longitude,
      horizontalAccuracyMeters: horizontalAccuracyMeters,
      capturedAt: capturedAt,
      source: source,
      locality: _clean(locality),
      administrativeArea: _clean(administrativeArea),
      countryCode: _clean(countryCode),
      isApproximate: isApproximate,
      schemaVersion: schemaVersion > 0 ? schemaVersion : currentSchemaVersion,
    );
  }

  static bool coordinatesAreValid(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Rounds coordinates to two decimal places (roughly kilometre-level) and
  /// reports at least 1.5 km accuracy so exact source precision is discarded.
  CatDiscoveryLocation toApproximate() {
    if (!hasValidCoordinates) return this;
    const precisionFactor = 100.0;
    final approximateLatitude =
        (latitude! * precisionFactor).round() / precisionFactor;
    final approximateLongitude =
        (longitude! * precisionFactor).round() / precisionFactor;
    final reportedAccuracy = horizontalAccuracyMeters == null
        ? 1500.0
        : horizontalAccuracyMeters! < 1500
        ? 1500.0
        : horizontalAccuracyMeters;
    return CatDiscoveryLocation(
      latitude: approximateLatitude,
      longitude: approximateLongitude,
      horizontalAccuracyMeters: reportedAccuracy,
      capturedAt: capturedAt,
      source: source,
      locality: locality,
      administrativeArea: administrativeArea,
      countryCode: countryCode,
      isApproximate: true,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'horizontalAccuracyMeters': horizontalAccuracyMeters,
      'capturedAt': capturedAt?.toIso8601String(),
      'source': source.name,
      'locality': _clean(locality),
      'administrativeArea': _clean(administrativeArea),
      'countryCode': _clean(countryCode),
      'isApproximate': isApproximate,
      'schemaVersion': schemaVersion,
    };
  }

  static CatDiscoveryLocation? tryFromJson(Object? value) {
    if (value is! Map<Object?, Object?>) return null;
    try {
      final json = Map<String, Object?>.from(value);
      return tryCreate(
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        horizontalAccuracyMeters: (json['horizontalAccuracyMeters'] as num?)
            ?.toDouble(),
        capturedAt: DateTime.tryParse(json['capturedAt'] as String? ?? ''),
        source: _sourceFrom(json['source'] as String?),
        locality: json['locality'] as String?,
        administrativeArea: json['administrativeArea'] as String?,
        countryCode: json['countryCode'] as String?,
        isApproximate: json['isApproximate'] as bool? ?? false,
        schemaVersion: json['schemaVersion'] as int? ?? currentSchemaVersion,
      );
    } on Object {
      return null;
    }
  }

  static CatDiscoveryLocationSource _sourceFrom(String? value) {
    return CatDiscoveryLocationSource.values.firstWhere(
      (item) => item.name == value,
      orElse: () => CatDiscoveryLocationSource.unknown,
    );
  }

  static bool _accuracyIsValid(double? value) {
    return value == null || (value.isFinite && value >= 0);
  }

  static bool _hasText(String? value) => _clean(value) != null;

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == '-' ||
        trimmed.toLowerCase() == 'unknown location' ||
        trimmed.toLowerCase() == 'location placeholder') {
      return null;
    }
    return trimmed;
  }

  @override
  bool operator ==(Object other) {
    return other is CatDiscoveryLocation &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.horizontalAccuracyMeters == horizontalAccuracyMeters &&
        other.capturedAt == capturedAt &&
        other.source == source &&
        other.locality == locality &&
        other.administrativeArea == administrativeArea &&
        other.countryCode == countryCode &&
        other.isApproximate == isApproximate &&
        other.schemaVersion == schemaVersion;
  }

  @override
  int get hashCode => Object.hash(
    latitude,
    longitude,
    horizontalAccuracyMeters,
    capturedAt,
    source,
    locality,
    administrativeArea,
    countryCode,
    isApproximate,
    schemaVersion,
  );
}
