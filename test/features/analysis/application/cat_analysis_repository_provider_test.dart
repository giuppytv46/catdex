import 'package:catdex/features/analysis/application/cat_analysis_controller.dart';
import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses fake analysis repository when Supabase env is missing', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(catAnalysisRepositoryProvider),
      isA<FakeCatAnalysisRepository>(),
    );
  });
}
