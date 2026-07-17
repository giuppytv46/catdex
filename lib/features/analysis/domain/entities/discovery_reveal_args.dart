import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

class DiscoveryRevealArgs {
  const DiscoveryRevealArgs({
    required this.photo,
    required this.result,
    this.suggestedName = '',
    this.usesEditedDetails = false,
  });

  final CapturedPhoto photo;
  final CatAnalysisResult result;
  final String suggestedName;
  final bool usesEditedDetails;
}
