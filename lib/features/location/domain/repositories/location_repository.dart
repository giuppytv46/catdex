import 'package:catdex/features/location/domain/entities/location_permission_status.dart';
import 'package:catdex/features/location/domain/entities/location_service_result.dart';

abstract interface class LocationRepository {
  Future<bool> checkServiceEnabled();

  Future<LocationPermissionStatus> checkPermission();

  Future<LocationPermissionStatus> requestPermission();

  Future<LocationServiceResult> getCurrentLocation();

  Future<LocationServiceResult> getLastKnownLocation();
}
