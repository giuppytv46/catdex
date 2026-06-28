import 'package:catdex/features/premium/domain/entities/monetization_placement.dart';

abstract interface class AdRepository {
  Future<List<MonetizationPlacement>> getPlacements();

  Future<bool> isPlacementEnabled(MonetizationPlacementType type);
}
