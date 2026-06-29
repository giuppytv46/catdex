import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatAnalysisDisplayFormatter {
  const CatAnalysisDisplayFormatter();

  static const _labels = {
    'domestic_tabby_cat': 'Gatto domestico tigrato',
    'domestic_shorthair_cat': 'Gatto domestico a pelo corto',
    'domestic_longhair_cat': 'Gatto domestico a pelo lungo',
    'common': 'Comune',
    'uncommon': 'Non comune',
    'rare': 'Raro',
    'epic': 'Epico',
    'legendary': 'Leggendario',
    'normal': 'Normale',
    'marrone/grigio tigrato': 'Marrone/grigio tigrato',
    'tigrato mackerel': 'Tigrato mackerel',
    'curious': 'Curioso',
  };

  String value(String value) {
    return _labels[value.trim()] ?? value;
  }

  String nullableValue(String? value, {String fallback = 'Unknown'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    return this.value(value);
  }

  String traits(List<CatTrait> traits, {String fallback = 'Unknown'}) {
    if (traits.isEmpty) {
      return fallback;
    }

    return traits
        .map((trait) => '${value(trait.name)}: ${value(trait.value)}')
        .join(', ');
  }
}
