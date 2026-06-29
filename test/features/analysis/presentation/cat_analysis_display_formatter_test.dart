import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';
import 'package:test/test.dart';

void main() {
  const formatter = CatAnalysisDisplayFormatter();

  test('formats backend technical labels as readable Italian labels', () {
    expect(formatter.value('domestic_tabby_cat'), 'Gatto domestico tigrato');
    expect(formatter.value('domestic_gray_cat'), 'Gatto domestico bicolore');
    expect(formatter.value('domestic_black_cat'), 'Gatto nero domestico');
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
    expect(formatter.value('rare'), 'Raro');
    expect(formatter.value('epic'), 'Epico');
    expect(formatter.value('legendary'), 'Leggendario');
    expect(formatter.value('normal'), 'Normale');
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
}
