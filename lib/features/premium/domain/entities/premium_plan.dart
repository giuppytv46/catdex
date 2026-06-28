enum PremiumBillingPeriod {
  monthly,
  yearly,
}

class PremiumPlan {
  const PremiumPlan({
    required this.id,
    required this.name,
    required this.billingPeriod,
    required this.priceLabel,
    required this.benefits,
    required this.featured,
  });

  final String id;
  final String name;
  final PremiumBillingPeriod billingPeriod;
  final String priceLabel;
  final List<String> benefits;
  final bool featured;
}
