import 'package:catdex/features/location/data/shared_preferences_location_privacy_preferences_repository.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_privacy_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('privacy defaults keep collection disabled and approximate', () async {
    const repository = SharedPreferencesLocationPrivacyPreferencesRepository();

    final preferences = await repository.getPreferences();

    expect(preferences.locationCollectionEnabled, isFalse);
    expect(
      preferences.locationPrecisionMode,
      LocationPrecisionMode.approximate,
    );
    expect(preferences.rememberLocationChoice, isFalse);
    expect(
      preferences.lastPermissionStatus,
      LocationPermissionStatus.notDetermined,
    );
  });

  test('privacy choice and permission survive repository recreation', () async {
    const first = SharedPreferencesLocationPrivacyPreferencesRepository();
    await first.savePreferences(
      const LocationPrivacyPreferences(
        locationCollectionEnabled: true,
        locationPrecisionMode: LocationPrecisionMode.precise,
        rememberLocationChoice: true,
        locationConsentVersion: 'location-v1',
        lastPermissionStatus: LocationPermissionStatus.granted,
      ),
    );

    const recreated = SharedPreferencesLocationPrivacyPreferencesRepository();
    final restored = await recreated.getPreferences();

    expect(restored.locationCollectionEnabled, isTrue);
    expect(restored.locationPrecisionMode, LocationPrecisionMode.precise);
    expect(restored.rememberLocationChoice, isTrue);
    expect(restored.locationConsentVersion, 'location-v1');
    expect(restored.lastPermissionStatus, LocationPermissionStatus.granted);
  });
}
