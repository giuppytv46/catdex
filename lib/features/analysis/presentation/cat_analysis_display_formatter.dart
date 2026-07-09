import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatAnalysisDisplayFormatter {
  const CatAnalysisDisplayFormatter();

  static const _labels = {
    'domestic_tabby_cat': 'Gatto domestico tigrato',
    'domestic_gray_cat': 'Gatto domestico bicolore',
    'domestic_black_cat': 'Gatto nero domestico',
    'domestic_black_white_cat': 'Gatto domestico bicolore',
    'domestic_orange_cat': 'Gatto rosso domestico',
    'domestic_white_cat': 'Gatto bianco domestico',
    'domestic_tuxedo_cat': 'Gatto tuxedo domestico',
    'domestic_calico_cat': 'Gatto calico domestico',
    'domestic_tortoiseshell_cat': 'Gatto squama di tartaruga domestico',
    'domestic_colorpoint_cat': 'Gatto colorpoint domestico',
    'domestic_shorthair_cat': 'Gatto domestico a pelo corto',
    'domestic_mediumhair_cat': 'Gatto domestico a pelo medio',
    'domestic_longhair_cat': 'Gatto domestico a pelo lungo',
    'maine_coon': 'Maine Coon',
    'norwegian_forest_cat': 'Gatto Norvegese delle Foreste',
    'siberian_cat': 'Gatto Siberiano',
    'persian_cat': 'Persiano',
    'ragdoll_cat': 'Ragdoll',
    'birman_cat': 'Sacro di Birmania',
    'siamese_cat': 'Siamese',
    'british_shorthair_cat': 'British Shorthair',
    'russian_blue_cat': 'Blu di Russia',
    'bengal_cat': 'Bengala',
    'sphynx_cat': 'Sphynx',
    'scottish_fold_cat': 'Scottish Fold',
    'abyssinian_cat': 'Abissino',
    'common': 'Comune',
    'uncommon': 'Non comune',
    'rare': 'Rara',
    'epic': 'Epica',
    'legendary': 'Leggendaria',
    'mythic': 'Leggendaria',
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
    'grigio/bianco': 'Grigio/bianco',
    'gray/white': 'Grigio/bianco',
    'grey/white': 'Grigio/bianco',
    'arancione/bianco': 'Arancione/bianco',
    'orange/white': 'Arancione/bianco',
    'marrone/bianco': 'Marrone/bianco',
    'brown/white': 'Marrone/bianco',
    'black': 'Nero',
    'white': 'Bianco',
    'gray': 'Grigio',
    'grey': 'Grigio',
    'brown': 'Marrone',
    'orange': 'Arancione',
    'black_white': 'Nero/bianco',
    'gray_white': 'Grigio/bianco',
    'brown_white': 'Marrone/bianco',
    'orange_white': 'Arancione/bianco',
    'orange_tabby': 'Arancione tigrato',
    'brown_tabby': 'Marrone tigrato',
    'gray_tabby': 'Grigio tigrato',
    'bicolore': 'Bicolore',
    'bicolor': 'Bicolore',
    'tuxedo': 'Tuxedo',
    'solid': 'Solido',
    'tabby': 'Tigrato',
    'tricolor': 'Tricolore',
    'tortoiseshell': 'Tartarugato',
    'patched': 'Pezzato',
    'colorpoint': 'Colorpoint',
    'marrone/grigio': 'Marrone/grigio',
    'marrone/grigio tigrato': 'Marrone/grigio tigrato',
    'tigrato mackerel': 'Tigrato mackerel',
    'yellow': 'occhi gialli',
    'green': 'occhi verdi',
    'blue': 'occhi azzurri',
    'amber': 'occhi ambrati',
    'short': 'Pelo corto',
    'medium': 'Pelo medio',
    'long': 'Pelo lungo',
    'unknown': 'Sconosciuto',
    'sleepy': 'Sonnolento',
    'relaxed': 'Rilassato',
    'calm': 'Tranquillo',
    'curious': 'Curioso',
    'sweet': 'Dolce',
    'shy': 'Timido',
    'playful': 'Giocherellone',
    'boss': 'Capetto',
    'friendly': 'Amichevole',
    'elegant': 'Elegante',
    'royal': 'Regale',
    'mischievous': 'Birichino',
    'silly': 'Buffo',
    'mysterious': 'Misterioso',
    'energetic': 'Energico',
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
    if (_usesOrangeTabbyLabel(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return 'Gatto domestico arancione tigrato';
    }

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
    if (_usesOrangeTabbyLabel(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return 'Arancione tigrato';
    }

    if (_usesBlackWhiteBicolorSafeguard(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    )) {
      return _bicolorCoatColorLabel(coatColor);
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

    final bicolorSpecies =
        species == 'domestic_gray_cat' ||
        species == 'domestic_tabby_cat' ||
        species == 'domestic_shorthair_cat' ||
        species == 'domestic_black_white_cat' ||
        species == 'domestic_tuxedo_cat';
    final bicolorPattern =
        pattern.contains('bicolore') ||
        pattern.contains('bicolor') ||
        pattern.contains('tuxedo') ||
        pattern.contains('bianco') ||
        pattern.contains('white') ||
        pattern.contains('nero') ||
        pattern.contains('black');
    final bicolorColor =
        color.contains('nero/bianco') ||
        color.contains('bianco/nero') ||
        color.contains('black/white') ||
        color.contains('white/black');

    return bicolorSpecies && (bicolorPattern || bicolorColor);
  }

  bool _usesOrangeTabbyLabel({
    String? speciesId,
    String? coatColor,
    String? coatPattern,
  }) {
    final species = _normalize(speciesId);
    final color = _normalize(coatColor);
    final pattern = _normalize(coatPattern);

    final domesticTabby =
        species == 'domestic_tabby_cat' ||
        species == 'domestic_orange_cat' ||
        species == 'domestic_shorthair_cat';
    final orangeColor = _containsAny(color, const [
      'arancione',
      'orange',
      'rosso',
      'red',
      'ginger',
      'marmalade',
      'dorato',
      'golden',
      'fulvo',
      'crema/arancione',
      'cream/orange',
    ]);
    final tabbyPattern =
        _containsAny(pattern, const [
          'tigrato',
          'tabby',
          'mackerel',
          'striped',
        ]) ||
        color.contains('tigrat') ||
        color.contains('tabby');

    return domesticTabby && orangeColor && tabbyPattern;
  }

  String _bicolorCoatColorLabel(String? coatColor) {
    final color = _normalize(coatColor);

    if (_containsAny(color, const [
      'nero/bianco',
      'bianco/nero',
      'black/white',
      'white/black',
      'tuxedo',
    ])) {
      return _labels['nero/bianco']!;
    }

    if (_containsAny(color, const [
      'grigio',
      'gray',
      'grey',
      'blu',
      'blue_gray',
      'silver',
      'smoke',
    ])) {
      return _labels['grigio/bianco']!;
    }

    if (_containsAny(color, const [
      'arancione',
      'rosso',
      'ginger',
      'orange',
    ])) {
      return _labels['arancione/bianco']!;
    }

    if (_containsAny(color, const ['marrone', 'brown'])) {
      return _labels['marrone/bianco']!;
    }

    return _labels['bicolore']!;
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  String _normalize(String? value) => value?.trim().toLowerCase() ?? '';
}
