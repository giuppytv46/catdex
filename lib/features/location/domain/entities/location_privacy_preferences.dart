import 'package:catdex/features/location/domain/entities/location_permission_status.dart';

enum LocationPrecisionMode {
  precise,
  approximate,
}

class LocationPrivacyPreferences {
  const LocationPrivacyPreferences({
    required this.locationCollectionEnabled,
    required this.locationPrecisionMode,
    required this.rememberLocationChoice,
    required this.locationConsentVersion,
    required this.lastPermissionStatus,
  });

  const LocationPrivacyPreferences.defaults()
    : locationCollectionEnabled = false,
      locationPrecisionMode = LocationPrecisionMode.approximate,
      rememberLocationChoice = false,
      locationConsentVersion = null,
      lastPermissionStatus = LocationPermissionStatus.notDetermined;

  final bool locationCollectionEnabled;
  final LocationPrecisionMode locationPrecisionMode;
  final bool rememberLocationChoice;
  final String? locationConsentVersion;
  final LocationPermissionStatus lastPermissionStatus;

  LocationPrivacyPreferences copyWith({
    bool? locationCollectionEnabled,
    LocationPrecisionMode? locationPrecisionMode,
    bool? rememberLocationChoice,
    String? locationConsentVersion,
    LocationPermissionStatus? lastPermissionStatus,
  }) {
    return LocationPrivacyPreferences(
      locationCollectionEnabled:
          locationCollectionEnabled ?? this.locationCollectionEnabled,
      locationPrecisionMode:
          locationPrecisionMode ?? this.locationPrecisionMode,
      rememberLocationChoice:
          rememberLocationChoice ?? this.rememberLocationChoice,
      locationConsentVersion:
          locationConsentVersion ?? this.locationConsentVersion,
      lastPermissionStatus: lastPermissionStatus ?? this.lastPermissionStatus,
    );
  }
}
