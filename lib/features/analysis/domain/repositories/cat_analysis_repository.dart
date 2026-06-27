import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

// The sprint explicitly needs a repository seam for the future real AI service.
// ignore: one_member_abstracts
abstract interface class CatAnalysisRepository {
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo);
}
