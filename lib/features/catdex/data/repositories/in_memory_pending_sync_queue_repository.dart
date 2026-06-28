import 'package:catdex/features/catdex/domain/entities/pending_discovery_sync.dart';
import 'package:catdex/features/catdex/domain/repositories/pending_sync_queue_repository.dart';

class InMemoryPendingSyncQueueRepository implements PendingSyncQueueRepository {
  InMemoryPendingSyncQueueRepository({
    List<PendingDiscoverySync> pendingDiscoveries = const [],
  }) : _pendingById = {
         for (final item in pendingDiscoveries) item.id: item,
       };

  final Map<String, PendingDiscoverySync> _pendingById;

  @override
  Future<void> enqueueDiscovery(PendingDiscoverySync pendingSync) async {
    _pendingById[pendingSync.id] = pendingSync;
  }

  @override
  Future<List<PendingDiscoverySync>> pendingDiscoveriesForPlayer(
    String playerId,
  ) async {
    return _pendingById.values
        .where((item) => item.discovery.playerId == playerId)
        .toList(growable: false);
  }

  @override
  Future<void> removePendingDiscovery(String id) async {
    _pendingById.remove(id);
  }
}
