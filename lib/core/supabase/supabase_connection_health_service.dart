import 'package:catdex/core/supabase/supabase_connection_health.dart';

abstract interface class SupabaseConnectionProbe {
  Future<void> verifyAuthConnection();

  Future<void> verifyMasterDataConnection();
}

class LocalModeSupabaseConnectionProbe implements SupabaseConnectionProbe {
  const LocalModeSupabaseConnectionProbe();

  @override
  Future<void> verifyAuthConnection() async {}

  @override
  Future<void> verifyMasterDataConnection() async {}
}

class SupabaseConnectionHealthService {
  const SupabaseConnectionHealthService({
    required SupabaseConnectionProbe probe,
    required bool configured,
  }) : _probe = probe,
       _configured = configured;

  final SupabaseConnectionProbe _probe;
  final bool _configured;

  Future<SupabaseConnectionHealth> check() async {
    if (!_configured) {
      return const SupabaseConnectionHealth.localMode();
    }

    var authReachable = false;
    var masterDataReachable = false;

    try {
      await _probe.verifyAuthConnection();
      authReachable = true;
      await _probe.verifyMasterDataConnection();
      masterDataReachable = true;
    } on Object {
      return SupabaseConnectionHealth(
        status: SupabaseConnectionHealthStatus.unhealthy,
        configured: true,
        authReachable: authReachable,
        masterDataReachable: masterDataReachable,
        message: 'CatDex could not reach Supabase.',
      );
    }

    return const SupabaseConnectionHealth(
      status: SupabaseConnectionHealthStatus.healthy,
      configured: true,
      authReachable: true,
      masterDataReachable: true,
    );
  }
}
