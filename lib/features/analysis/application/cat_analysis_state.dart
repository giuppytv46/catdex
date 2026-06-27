import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

class CatAnalysisState {
  const CatAnalysisState({
    required this.status,
    this.photo,
    this.result,
    this.failure,
  });

  const CatAnalysisState.idle()
    : status = AnalysisStatus.idle,
      photo = null,
      result = null,
      failure = null;

  final AnalysisStatus status;
  final CapturedPhoto? photo;
  final CatAnalysisResult? result;
  final CatAnalysisFailure? failure;

  CatAnalysisState copyWith({
    AnalysisStatus? status,
    CapturedPhoto? photo,
    CatAnalysisResult? result,
    CatAnalysisFailure? failure,
    bool clearResult = false,
    bool clearFailure = false,
  }) {
    return CatAnalysisState(
      status: status ?? this.status,
      photo: photo ?? this.photo,
      result: clearResult ? null : result ?? this.result,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}
