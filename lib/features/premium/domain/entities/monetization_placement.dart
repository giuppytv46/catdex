enum MonetizationPlacementType {
  rewardedAd,
  interstitial,
  banner,
}

class MonetizationPlacement {
  const MonetizationPlacement({
    required this.id,
    required this.type,
    required this.enabled,
    required this.description,
  });

  final String id;
  final MonetizationPlacementType type;
  final bool enabled;
  final String description;
}
