import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatAnalysisDisplayFormatter {
  const CatAnalysisDisplayFormatter();

  static const _labels = {
    'domestic_tabby_cat': 'Gatto domestico tigrato',
    'domestic_gray_cat': 'Gatto domestico bicolore',
    'domestic_black_cat': 'Gatto nero domestico',
    'domestic_orange_cat': 'Gatto rosso domestico',
    'domestic_white_cat': 'Gatto bianco domestico',
    'domestic_tuxedo_cat': 'Gatto tuxedo domestico',
    'domestic_calico_cat': 'Gatto calico domestico',
    'domestic_tortoiseshell_cat': 'Gatto squama di tartaruga domestico',
    'domestic_colorpoint_cat': 'Gatto colorpoint domestico',
    'domestic_shorthair_cat': 'Gatto domestico a pelo corto',
    'domestic_longhair_cat': 'Gatto domestico a pelo lungo',
    'common': 'Comune',
    'uncommon': 'Non comune',
    'rare': 'Raro',
    'epic': 'Epico',
    'legendary': 'Leggendario',
    'mythic': 'Leggendario',
    'normal': 'Normale',
    'shiny': 'Brillante',
    'golden': 'Dorato',
    'albino': 'Albino',
    'melanistic': 'Melanico',
    'heterochromia': 'Eterocromia',
    'midnight': 'Mezzanotte',
    'lucky': 'Fortunato',
    'event_edition': 'Edizione evento',
    'marrone/grigio tigrato': 'Marrone/grigio tigrato',
    'tigrato mackerel': 'Tigrato mackerel',
    'sleepy': 'Sonnolento',
    'relaxed': 'Rilassato',
    'curious': 'Curioso',
    'playful': 'Giocherellone',
    'boss': 'Capetto',
    'friendly': 'Amichevole',
    'royal': 'Regale',
    'mischievous': 'Birichino',
    'silly': 'Buffo',
    'mysterious': 'Misterioso',
    'brave': 'Coraggioso',
    'lazy': 'Pigro',
  };

  String value(String value) {
    final trimmed = value.trim();
    return _labels[trimmed] ?? _humanizeTechnicalValue(trimmed);
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

  String _humanizeTechnicalValue(String value) {
    if (!value.contains('_')) {
      return value;
    }

    return value
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}
