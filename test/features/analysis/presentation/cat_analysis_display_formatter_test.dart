import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:test/test.dart';

void main() {
  const formatter = CatAnalysisDisplayFormatter();

  test('formats backend technical labels as readable Italian labels', () {
    expect(formatter.value('domestic_tabby_cat'), 'Gatto domestico tigrato');
    expect(formatter.value('domestic_gray_cat'), 'Gatto domestico bicolore');
    expect(formatter.value('domestic_black_cat'), 'Gatto nero domestico');
    expect(
      formatter.value('domestic_black_white_cat'),
      'Gatto domestico bicolore',
    );
    expect(formatter.value('domestic_orange_cat'), 'Gatto rosso domestico');
    expect(
      formatter.value('domestic_shorthair_cat'),
      'Gatto domestico a pelo corto',
    );
    expect(
      formatter.value('domestic_longhair_cat'),
      'Gatto domestico a pelo lungo',
    );
    expect(formatter.value('common'), 'Comune');
    expect(formatter.value('uncommon'), 'Non comune');
    expect(formatter.value('rare'), 'Rara');
    expect(formatter.value('epic'), 'Epica');
    expect(formatter.value('legendary'), 'Leggendaria');
    expect(formatter.value('normal'), 'Normale');
    expect(formatter.value('nero/bianco'), 'Nero/bianco');
    expect(formatter.value('bicolore'), 'Bicolore');
    expect(formatter.value('relaxed'), 'Rilassato');
    expect(formatter.value('curious'), 'Curioso');
    expect(formatter.value('playful'), 'Giocherellone');
    expect(
      formatter.value('marrone/grigio tigrato'),
      'Marrone/grigio tigrato',
    );
    expect(formatter.value('tigrato mackerel'), 'Tigrato mackerel');
    expect(formatter.value('unknown_species_id'), 'Unknown Species Id');
  });

  test('formats trait values without changing the source traits', () {
    const traits = [
      CatTrait(name: 'Mantello', value: 'marrone/grigio tigrato'),
      CatTrait(name: 'Pattern', value: 'tigrato mackerel'),
    ];

    expect(
      formatter.traits(traits),
      'Mantello: Marrone/grigio tigrato, Pattern: Tigrato mackerel',
    );
  });

  test('defensively formats black and white bicolor display values', () {
    expect(
      formatter.speciesLabel(
        speciesId: 'domestic_gray_cat',
        coatColor: 'marrone/grigio',
        coatPattern: 'bicolore',
      ),
      'Gatto domestico bicolore',
    );
    expect(
      formatter.coatColorLabel(
        speciesId: 'domestic_gray_cat',
        coatColor: 'brown/gray',
        coatPattern: 'bicolor',
      ),
      'Nero/bianco',
    );
    expect(
      formatter.coatPatternLabel(
        speciesId: 'domestic_gray_cat',
        coatColor: 'grigio',
        coatPattern: 'bicolore',
      ),
      'Bicolore',
    );
    expect(
      formatter.speciesLabel(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'marrone/grigio',
        coatPattern: 'bicolore',
      ),
      'Gatto domestico bicolore',
    );
    expect(
      formatter.speciesLabel(
        speciesId: 'domestic_shorthair_cat',
        coatColor: 'black/white',
        coatPattern: 'unknown',
      ),
      'Gatto domestico bicolore',
    );
    expect(
      formatter.coatColorLabel(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'nero/bianco',
        coatPattern: 'tuxedo',
      ),
      'Nero/bianco',
    );
  });

  test('keeps real tabby display values as tabby', () {
    expect(
      formatter.speciesLabel(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'marrone/grigio tigrato',
        coatPattern: 'tigrato mackerel',
      ),
      'Gatto domestico tigrato',
    );
    expect(
      formatter.coatPatternLabel(
        speciesId: 'domestic_tabby_cat',
        coatColor: 'marrone/grigio tigrato',
        coatPattern: 'tigrato mackerel',
      ),
      'Tigrato mackerel',
    );
  });
}
