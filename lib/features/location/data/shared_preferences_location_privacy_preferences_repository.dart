import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:catdex/features/location/domain/repositories/location_privacy_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesLocationPrivacyPreferencesRepository
    implements LocationPrivacyPreferencesRepository {
  const SharedPreferencesLocationPrivacyPreferencesRepository();

  static const _enabledKey = 'catdex_location_collection_enabled';
  static const _precisionKey = 'catdex_location_precision_mode';
  static const _rememberKey = 'catdex_location_remember_choice';
  static const _consentVersionKey = 'catdex_location_consent_version';
  static const _permissionKey = 'catdex_location_last_permission_status';

  @override
  Future<LocationPrivacyPreferences> getPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return LocationPrivacyPreferences(
      locationCollectionEnabled: preferences.getBool(_enabledKey) ?? false,
      locationPrecisionMode: _precisionMode(
        preferences.getString(_precisionKey),
      ),
      rememberLocationChoice: preferences.getBool(_rememberKey) ?? false,
      locationConsentVersion: preferences.getString(_consentVersionKey),
      lastPermissionStatus: _permissionStatus(
        preferences.getString(_permissionKey),
      ),
    );
  }

  @override
  Future<void> savePreferences(
    LocationPrivacyPreferences locationPreferences,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final writes = await Future.wait([
      preferences.setBool(
        _enabledKey,
        locationPreferences.locationCollectionEnabled,
      ),
      preferences.setString(
        _precisionKey,
        locationPreferences.locationPrecisionMode.name,
      ),
      preferences.setBool(
        _rememberKey,
        locationPreferences.rememberLocationChoice,
      ),
      preferences.setString(
        _permissionKey,
        locationPreferences.lastPermissionStatus.name,
      ),
      if (locationPreferences.locationConsentVersion == null)
        preferences.remove(_consentVersionKey)
      else
        preferences.setString(
          _consentVersionKey,
          locationPreferences.locationConsentVersion!,
        ),
    ]);
    if (writes.any((written) => !written)) {
      throw StateError('Location privacy preferences write failed');
    }

    final readBack = await getPreferences();
    if (readBack.locationCollectionEnabled !=
            locationPreferences.locationCollectionEnabled ||
        readBack.locationPrecisionMode !=
            locationPreferences.locationPrecisionMode ||
        readBack.rememberLocationChoice !=
            locationPreferences.rememberLocationChoice ||
        readBack.locationConsentVersion !=
            locationPreferences.locationConsentVersion ||
        readBack.lastPermissionStatus !=
            locationPreferences.lastPermissionStatus) {
      throw StateError('Location privacy preferences readback failed');
    }
  }

  LocationPrecisionMode _precisionMode(String? value) {
    return LocationPrecisionMode.values.firstWhere(
      (item) => item.name == value,
      orElse: () => LocationPrecisionMode.approximate,
    );
  }

  LocationPermissionStatus _permissionStatus(String? value) {
    return LocationPermissionStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => LocationPermissionStatus.notDetermined,
    );
  }
}
