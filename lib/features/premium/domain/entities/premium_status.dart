enum PremiumTier {
  free,
  premium,
}

class PremiumStatus {
  const PremiumStatus({
    required this.tier,
    this.expiresAt,
  });

  const PremiumStatus.free() : this(tier: PremiumTier.free);

  const PremiumStatus.premium({DateTime? expiresAt})
    : this(tier: PremiumTier.premium, expiresAt: expiresAt);

  final PremiumTier tier;
  final DateTime? expiresAt;

  bool get isPremium => tier == PremiumTier.premium;
}
