const bool showMonetizationDebug = bool.fromEnvironment(
  'SHOW_MONETIZATION_DEBUG',
  // Keep the default explicit because this flag must stay opt-in even in debug.
  // ignore: avoid_redundant_argument_values
  defaultValue: false,
);
