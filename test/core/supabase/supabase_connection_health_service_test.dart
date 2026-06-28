import 'package:catdex/core/supabase/supabase_connection_health.dart';
import 'package:catdex/core/supabase/supabase_connection_health_service.dart';
import 'package:test/test.dart';

void main() {
  test('reports local mode when Supabase is not configured', () async {
    const service = SupabaseConnectionHealthService(
      probe: _HealthyProbe(),
      configured: false,
    );

    final health = await service.check();

    expect(health.status, SupabaseConnectionHealthStatus.localMode);
    expect(health.configured, isFalse);
  });

  test('reports healthy when auth and master data probes pass', () async {
    const service = SupabaseConnectionHealthService(
      probe: _HealthyProbe(),
      configured: true,
    );

    final health = await service.check();

    expect(health.status, SupabaseConnectionHealthStatus.healthy);
    expect(health.authReachable, isTrue);
    expect(health.masterDataReachable, isTrue);
  });

  test('reports unhealthy when a probe fails', () async {
    const service = SupabaseConnectionHealthService(
      probe: _FailingProbe(),
      configured: true,
    );

    final health = await service.check();

    expect(health.status, SupabaseConnectionHealthStatus.unhealthy);
    expect(health.message, isNotEmpty);
  });
}

class _HealthyProbe implements SupabaseConnectionProbe {
  const _HealthyProbe();

  @override
  Future<void> verifyAuthConnection() async {}

  @override
  Future<void> verifyMasterDataConnection() async {}
}

class _FailingProbe implements SupabaseConnectionProbe {
  const _FailingProbe();

  @override
  Future<void> verifyAuthConnection() async {}

  @override
  Future<void> verifyMasterDataConnection() async {
    throw StateError('offline');
  }
}
