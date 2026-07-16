import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_validation_result.dart';
import 'package:catdex/features/location/domain/services/location_validator.dart';
import 'package:test/test.dart';

void main() {
  group('CatDexLocation', () {
    test('builds a place display label when reverse geocoding succeeds', () {
      const location = CatDexLocation(
        latitude: 45.4642,
        longitude: 9.19,
        city: 'Milan',
        region: 'Lombardy',
        country: 'Italy',
      );

      expect(location.hasPlaceDetails, isTrue);
      expect(location.displayLabel, 'Milan, Lombardy, Italy');
    });

    test('does not invent a place label without place details', () {
      const location = CatDexLocation(latitude: 45.4642, longitude: 9.19);

      expect(location.hasPlaceDetails, isFalse);
      expect(location.displayLabel, isEmpty);
    });
  });

  group('LocationValidator', () {
    const validator = LocationValidator();

    test('accepts valid coordinates', () {
      final result = validator.validate(
        const CatDexLocation(latitude: 45.4642, longitude: 9.19),
      );

      expect(result, isA<ValidLocationValidationResult>());
    });

    test('rejects missing location', () {
      final result = validator.validate(null);

      expect(result, isA<InvalidLocationValidationResult>());
    });

    test('rejects coordinates outside valid ranges', () {
      final result = validator.validate(
        const CatDexLocation(latitude: 120, longitude: 9.19),
      );

      expect(result, isA<InvalidLocationValidationResult>());
    });
  });
}
