import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCatAnalysisRepository returns a realistic local result', () async {
    const repository = FakeCatAnalysisRepository();

    final result = await repository.analyzePhoto(_photo('local-cat.jpg'));

    expect(
      result.primaryBreed.species.id,
      isIn([
        'domestic_shorthair_cat',
        'domestic_tabby_cat',
        'european_shorthair',
      ]),
    );
    expect(result.breedCandidates, hasLength(2));
    expect(result.visualTraits.notableTraits, hasLength(3));
    expect(result.confidence.score, inInclusiveRange(0, 1));
    expect(result.variant.id, 'normal');
    expect(result.rarity, isIn([CatRarity.common, CatRarity.uncommon]));
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
