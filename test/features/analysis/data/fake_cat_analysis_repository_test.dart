import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCatAnalysisRepository returns a realistic local result', () async {
    const repository = FakeCatAnalysisRepository();

    final result = await repository.analyzePhoto(_photo('local-cat.jpg'));

    expect(result.primaryBreed.species.displayName, isNotEmpty);
    expect(result.breedCandidates, hasLength(3));
    expect(result.visualTraits.notableTraits, hasLength(3));
    expect(result.confidence.score, inInclusiveRange(0, 1));
    expect(result.variant.name, isNotEmpty);
    expect(result.story, contains(result.primaryBreed.species.displayName));
  });
}

CapturedPhoto _photo(String path) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}
