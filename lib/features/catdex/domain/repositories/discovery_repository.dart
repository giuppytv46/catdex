import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

abstract interface class DiscoveryRepository {
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId);

  Future<CatDiscovery?> getDiscoveryById(String id);

  Future<void> saveDiscovery(CatDiscovery discovery);

  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  });
}
