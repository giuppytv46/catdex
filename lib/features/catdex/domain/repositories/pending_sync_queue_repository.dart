import 'package:catdex/features/catdex/domain/entities/pending_discovery_sync.dart';

abstract interface class PendingSyncQueueRepository {
  Future<void> enqueueDiscovery(PendingDiscoverySync pendingSync);

  Future<List<PendingDiscoverySync>> pendingDiscoveriesForPlayer(
    String playerId,
  );

  Future<void> removePendingDiscovery(String id);
}
