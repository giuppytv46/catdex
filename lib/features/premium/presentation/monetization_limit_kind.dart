enum MonetizationLimitKind {
  analysis,
  cardGeneration,
}

extension MonetizationLimitKindLog on MonetizationLimitKind {
  String get logValue {
    return switch (this) {
      MonetizationLimitKind.analysis => 'analysis',
      MonetizationLimitKind.cardGeneration => 'card_generation',
    };
  }
}
