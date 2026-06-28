import 'package:catdex/features/analysis/application/cat_analysis_state.dart';
import 'package:catdex/features/analysis/data/backend_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/data/supabase_cat_analysis_backend_client.dart';
import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catAnalysisRepositoryProvider = Provider<CatAnalysisRepository>((ref) {
  if (ref.watch(supabaseConfiguredProvider)) {
    return BackendCatAnalysisRepository(
      client: SupabaseCatAnalysisBackendClient(
        ref.watch(supabaseClientProvider),
      ),
    );
  }

  return const FakeCatAnalysisRepository();
});

final catAnalysisControllerProvider =
    NotifierProvider<CatAnalysisController, CatAnalysisState>(
      CatAnalysisController.new,
    );

class CatAnalysisController extends Notifier<CatAnalysisState> {
  @override
  CatAnalysisState build() {
    return const CatAnalysisState.idle();
  }

  Future<void> analyze(CapturedPhoto photo) async {
    state = CatAnalysisState(
      status: AnalysisStatus.analyzing,
      photo: photo,
    );

    try {
      final result = await ref
          .read(catAnalysisRepositoryProvider)
          .analyzePhoto(photo);
      state = CatAnalysisState(
        status: AnalysisStatus.success,
        photo: photo,
        result: result,
      );
    } on CatAnalysisException catch (error) {
      state = CatAnalysisState(
        status: AnalysisStatus.failure,
        photo: photo,
        failure: error.failure,
      );
    } on Object {
      state = CatAnalysisState(
        status: AnalysisStatus.failure,
        photo: photo,
        failure: const CatAnalysisFailure(
          message: 'CatDex could not analyze this photo yet.',
        ),
      );
    }
  }

  void reset() {
    state = const CatAnalysisState.idle();
  }
}
