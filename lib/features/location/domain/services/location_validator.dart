import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_validation_result.dart';

class LocationValidator {
  const LocationValidator();

  LocationValidationResult validate(CatDexLocation? location) {
    if (location == null) {
      return const InvalidLocationValidationResult('Location unavailable');
    }

    if (!location.hasValidCoordinates ||
        (location.horizontalAccuracyMeters != null &&
            (!location.horizontalAccuracyMeters!.isFinite ||
                location.horizontalAccuracyMeters! < 0))) {
      return const InvalidLocationValidationResult('Location unavailable');
    }

    return const ValidLocationValidationResult();
  }
}
