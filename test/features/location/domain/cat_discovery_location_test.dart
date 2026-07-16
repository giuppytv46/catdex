import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CatDiscoveryLocation', () {
    test('valid coordinates serialize and deserialize', () {
      final capturedAt = DateTime.utc(2026, 7, 16, 10);
      final location = CatDiscoveryLocation.tryCreate(
        latitude: 45.4642,
        longitude: 9.19,
        horizontalAccuracyMeters: 12,
        capturedAt: capturedAt,
        source: CatDiscoveryLocationSource.gps,
        locality: 'Milano',
        administrativeArea: 'Lombardia',
        countryCode: 'IT',
      );

      expect(location, isNotNull);
      expect(CatDiscoveryLocation.tryFromJson(location!.toJson()), location);
    });

    test('invalid latitude is rejected safely', () {
      expect(
        CatDiscoveryLocation.tryCreate(latitude: 91, longitude: 9),
        isNull,
      );
      expect(
        CatDiscoveryLocation.tryCreate(
          latitude: double.nan,
          longitude: 9,
        ),
        isNull,
      );
    });

    test('invalid longitude is rejected safely', () {
      expect(
        CatDiscoveryLocation.tryCreate(latitude: 45, longitude: 181),
        isNull,
      );
      expect(
        CatDiscoveryLocation.tryCreate(
          latitude: 45,
          longitude: double.infinity,
        ),
        isNull,
      );
    });

    test('negative or non-finite accuracy is rejected safely', () {
      expect(
        CatDiscoveryLocation.tryCreate(
          latitude: 45,
          longitude: 9,
          horizontalAccuracyMeters: -1,
        ),
        isNull,
      );
    });

    test('approximate mode removes full coordinate precision', () {
      final precise = CatDiscoveryLocation.tryCreate(
        latitude: 45.464237,
        longitude: 9.189982,
        horizontalAccuracyMeters: 8,
      )!;

      final approximate = precise.toApproximate();

      expect(approximate.latitude, 45.46);
      expect(approximate.longitude, 9.19);
      expect(approximate.isApproximate, isTrue);
      expect(approximate.horizontalAccuracyMeters, greaterThanOrEqualTo(1500));
      expect(approximate.latitude, isNot(precise.latitude));
    });
  });
}
