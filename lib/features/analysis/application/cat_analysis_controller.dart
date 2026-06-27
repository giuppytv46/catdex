import 'package:catdex/features/analysis/application/cat_analysis_state.dart';
import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catAnalysisRepositoryProvider = Provider<CatAnalysisRepository>((_) {
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
