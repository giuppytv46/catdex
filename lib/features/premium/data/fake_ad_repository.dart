import 'package:catdex/features/premium/domain/entities/monetization_placement.dart';
import 'package:catdex/features/premium/domain/repositories/ad_repository.dart';

class FakeAdRepository implements AdRepository {
  const FakeAdRepository();

  @override
  Future<List<MonetizationPlacement>> getPlacements() async {
    return const [
      MonetizationPlacement(
        id: 'extra_scan_rewarded_ad',
        type: MonetizationPlacementType.rewardedAd,
        enabled: false,
        description: 'Optional rewarded ad for an extra scan.',
      ),
      MonetizationPlacement(
        id: 'post_reveal_interstitial',
        type: MonetizationPlacementType.interstitial,
        enabled: false,
        description: 'Interstitial placement disabled by default.',
      ),
      MonetizationPlacement(
        id: 'home_banner',
        type: MonetizationPlacementType.banner,
        enabled: false,
        description: 'Banner placement disabled by default.',
      ),
    ];
  }

  @override
  Future<bool> isPlacementEnabled(MonetizationPlacementType type) async {
    final placements = await getPlacements();

    return placements.any((item) => item.type == type && item.enabled);
  }
}
