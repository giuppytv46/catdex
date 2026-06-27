import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';

class InMemoryDiscoveryRepository implements DiscoveryRepository {
  InMemoryDiscoveryRepository({
    List<CatDiscovery> discoveries = const [],
  }) : _discoveriesById = {
         for (final discovery in discoveries) discovery.id: discovery,
       };

  final Map<String, CatDiscovery> _discoveriesById;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async {
    return List.unmodifiable(
      _discoveriesById.values.where(
        (discovery) => discovery.playerId == playerId,
      ),
    );
  }

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async {
    return _discoveriesById[id];
  }

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async {
    return _discoveriesById.values.any(
      (discovery) =>
          discovery.playerId == playerId && discovery.speciesId == speciesId,
    );
  }

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    _discoveriesById[discovery.id] = discovery;
  }
}
