import 'package:catdex/features/location/domain/entities/catdex_location.dart';
import 'package:catdex/features/location/domain/entities/location_permission_status.dart';

abstract interface class LocationRepository {
  Future<bool> isLocationServiceEnabled();

  Future<LocationPermissionStatus> requestPermission();

  Future<CatDexLocation> getCurrentLocation();
}
