// The backend client is intentionally injectable so tests never call Supabase.
// ignore: one_member_abstracts
abstract interface class CatAnalysisBackendClient {
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body);
}
