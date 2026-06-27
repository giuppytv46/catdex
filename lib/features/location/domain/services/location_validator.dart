import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_validation_result.dart';

class LocationValidator {
  const LocationValidator();

  LocationValidationResult validate(CatDexLocation? location) {
    if (location == null) {
      return const InvalidLocationValidationResult('Location unavailable');
    }

    final latitudeValid = location.latitude >= -90 && location.latitude <= 90;
    final longitudeValid =
        location.longitude >= -180 && location.longitude <= 180;

    if (!latitudeValid || !longitudeValid) {
      return const InvalidLocationValidationResult('Location unavailable');
    }

    return const ValidLocationValidationResult();
  }
}
