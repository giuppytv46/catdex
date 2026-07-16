import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryLocationServiceProvider = Provider<DiscoveryLocationService>((
  ref,
) {
  return DiscoveryLocationService(ref);
});

class DiscoveryLocationService {
  const DiscoveryLocationService(this._ref);

  final Ref _ref;

  Future<bool> removeLocationFromDiscovery(String discoveryId) async {
    final normalizedId = discoveryId.trim();
    if (normalizedId.isEmpty) return false;

    final repository = _ref.read(discoveryRepositoryProvider);
    final discovery = await repository.getDiscoveryById(normalizedId);
    if (discovery == null) return false;

    final updated = discovery.copyWithLocation(clearCaptureLocation: true);
    await repository.saveDiscovery(updated);
    final readBack = await repository.getDiscoveryById(normalizedId);
    final removed =
        readBack != null &&
        readBack.captureLocation == null &&
        readBack.locationConsentVersion == null &&
        readBack.locationCapturedAt == null;
    if (removed) {
      _ref
          .read(localDiscoverySessionProvider.notifier)
          .replaceDiscovery(readBack);
      debugPrint('CATDEX_LOCATION_REMOVED id=$normalizedId');
    }
    return removed;
  }
}
