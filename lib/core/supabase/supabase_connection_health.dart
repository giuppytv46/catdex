enum SupabaseConnectionHealthStatus {
  localMode,
  healthy,
  unhealthy,
}

class SupabaseConnectionHealth {
  const SupabaseConnectionHealth({
    required this.status,
    required this.configured,
    required this.authReachable,
    required this.masterDataReachable,
    this.message,
  });

  const SupabaseConnectionHealth.localMode()
    : this(
        status: SupabaseConnectionHealthStatus.localMode,
        configured: false,
        authReachable: false,
        masterDataReachable: false,
      );

  final SupabaseConnectionHealthStatus status;
  final bool configured;
  final bool authReachable;
  final bool masterDataReachable;
  final String? message;

  bool get isHealthy => status == SupabaseConnectionHealthStatus.healthy;
}
