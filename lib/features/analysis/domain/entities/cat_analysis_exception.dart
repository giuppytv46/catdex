import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';

class CatAnalysisException implements Exception {
  const CatAnalysisException(this.failure);

  final CatAnalysisFailure failure;
}
