import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:test/test.dart';

void main() {
  group('CatAnalysisConfidence', () {
    test('converts score to percentage and label', () {
      const confidence = CatAnalysisConfidence(0.86);

      expect(confidence.percentage, 86);
      expect(confidence.label, 'High');
      expect(confidence.isHigh, isTrue);
    });

    test('maps low scores to low confidence', () {
      const confidence = CatAnalysisConfidence(0.32);

      expect(confidence.percentage, 32);
      expect(confidence.label, 'Low');
      expect(confidence.isHigh, isFalse);
    });
  });

  test('CatVisualTraits stores notable traits', () {
    const traits = CatVisualTraits(
      coatColor: 'Black',
      coatPattern: 'Solid',
      eyeColor: 'Green',
      hairLength: 'Short',
      notableTraits: [CatTrait(name: 'Mood', value: 'Curious')],
    );

    expect(traits.coatColor, 'Black');
    expect(traits.notableTraits.single.value, 'Curious');
  });
}
