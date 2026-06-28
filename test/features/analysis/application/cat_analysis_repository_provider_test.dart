import 'package:catdex/features/analysis/application/cat_analysis_controller.dart';
import 'package:catdex/features/analysis/data/backend_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

void main() {
  test('uses fake analysis repository when Supabase env is missing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(catAnalysisRepositoryProvider),
      isA<FakeCatAnalysisRepository>(),
    );
  });

  test('uses backend analysis repository when Supabase is configured', () {
    final container = ProviderContainer(
      overrides: [
        supabaseConfiguredProvider.overrideWithValue(true),
        supabaseClientProvider.overrideWithValue(
          supabase.SupabaseClient('https://example.supabase.co', 'anon-key'),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(catAnalysisRepositoryProvider),
      isA<BackendCatAnalysisRepository>(),
    );
  });
}
