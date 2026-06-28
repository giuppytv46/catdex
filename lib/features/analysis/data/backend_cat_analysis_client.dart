import 'package:supabase_flutter/supabase_flutter.dart';

// The backend client is intentionally injectable so tests never call Supabase.
// ignore: one_member_abstracts
abstract interface class CatAnalysisBackendClient {
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body);
}

class SupabaseCatAnalysisBackendClient implements CatAnalysisBackendClient {
  const SupabaseCatAnalysisBackendClient(this._client);

  final SupabaseClient _client;

  @override
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body) async {
    final response = await _client.functions.invoke(
      'analyze_cat_photo',
      body: body,
    );

    return response.data;
  }
}
