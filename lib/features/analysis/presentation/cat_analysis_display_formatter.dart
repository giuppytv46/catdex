import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatAnalysisDisplayFormatter {
  const CatAnalysisDisplayFormatter();

  static const _labels = {
    'domestic_tabby_cat': 'Gatto domestico tigrato',
    'domestic_gray_cat': 'Gatto domestico',
    'domestic_black_cat': 'Gatto nero domestico',
    'domestic_black_white_cat': 'Gatto domestico bicolore',
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
    'nero/bianco': 'Nero/bianco',
    'bicolore': 'Bicolore',
    'tuxedo': 'Tuxedo',
    'marrone/grigio': 'Marrone/grigio',
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

  String speciesLabel({
    required String speciesId,
    String? coatColor,
    String? coatPattern,
  }) {
    if (_usesBlackWhiteBicolorSafeguard(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return _labels['domestic_black_white_cat']!;
    }

    return value(speciesId);
  }

  String coatColorLabel({
    required String? coatColor,
    String? speciesId,
    String? coatPattern,
    String fallback = 'Unknown',
  }) {
    if (_usesBlackWhiteBicolorSafeguard(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return _labels['nero/bianco']!;
    }

    return nullableValue(coatColor, fallback: fallback);
  }

  String coatPatternLabel({
    required String? coatPattern,
    String? speciesId,
    String? coatColor,
    String fallback = 'Unknown',
  }) {
    if (_usesBlackWhiteBicolorSafeguard(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return _labels['bicolore']!;
    }

    return nullableValue(coatPattern, fallback: fallback);
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

  bool _usesBlackWhiteBicolorSafeguard({
    String? speciesId,
    String? coatColor,
    String? coatPattern,
  }) {
    final species = _normalize(speciesId);
    final color = _normalize(coatColor);
    final pattern = _normalize(coatPattern);

    return (species == 'domestic_gray_cat' ||
            species == 'domestic_tabby_cat') &&
        (pattern.contains('bicolore') ||
            pattern.contains('bicolor') ||
            pattern.contains('tuxedo')) &&
        (color.contains('marrone/grigio') ||
            color.contains('brown/gray') ||
            color.contains('gray') ||
            color.contains('grey') ||
            color.contains('grigio'));
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}
