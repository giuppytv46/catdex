import 'package:catdex/core/supabase/supabase_connection_health_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConnectionProbeImpl implements SupabaseConnectionProbe {
  const SupabaseConnectionProbeImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<void> verifyAuthConnection() async {
    _client.auth.currentSession;
  }

  @override
  Future<void> verifyMasterDataConnection() async {
    await _client.from('cat_species').select('id').limit(1);
  }
}
