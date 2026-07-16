import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';

abstract interface class LocationPrivacyPreferencesRepository {
  Future<LocationPrivacyPreferences> getPreferences();

  Future<void> savePreferences(LocationPrivacyPreferences preferences);
}
