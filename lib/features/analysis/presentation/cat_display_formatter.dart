import 'dart:async';
import 'dart:convert';

import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

class CatDisplayFormatter {
  const CatDisplayFormatter();

  static const _legacyFormatter = CatAnalysisDisplayFormatter();
  static const _bicolorFunFact =
      'I gatti bicolore hanno spesso macchie uniche: ogni mantello è diverso '
      'dagli altri.';

  CatDisplayData fromAnalysis(CatAnalysisResult result) {
    final raw = {
      'source': 'analysis',
      'breed': result.displayBreed,
      'coatColor': result.visualTraits.coatColor,
      'coatPattern': result.visualTraits.coatPattern,
      'eyeColor': result.visualTraits.eyeColor,
      'hairLength': result.visualTraits.hairLength,
      'estimatedAge': result.estimatedAge,
      'personality': result.displayPersonality,
      'rarity': result.displayRarity,
      'variant': result.displayVariant,
      'story': result.story,
      'funFact': result.funFact,
    };

    return _normalize(
      raw: raw,
      displayName: _legacyFormatter.value(result.displayBreed),
      speciesId: result.displayBreed,
      coatColor: result.visualTraits.coatColor,
      coatPattern: result.visualTraits.coatPattern,
      eyeColor: result.visualTraits.eyeColor,
      hairLength: result.visualTraits.hairLength,
      age: result.estimatedAge,
      personality: result.displayPersonality,
      rarity: result.displayRarity,
      variant: result.displayVariant,
      story: result.story,
      funFact: result.funFact,
    );
  }

  CatDisplayData fromDiscovery(CatDiscovery discovery, {String? fallbackName}) {
    final raw = {
      'source': 'discovery',
      'id': discovery.id,
      'customName': discovery.customName,
      'suggestedName': discovery.suggestedName,
      'speciesId': discovery.speciesId,
      'coatColor': discovery.coatColor,
      'coatPattern': discovery.coatPattern,
      'eyeColor': discovery.eyeColor,
      'hairLength': discovery.hairLength,
      'estimatedAge': discovery.estimatedAge,
      'personality': discovery.personality.name,
      'rarity': discovery.rarity.name,
      'variant': discovery.variantId,
      'story': discovery.story,
      'funFact': discovery.funFact,
    };

    return _normalize(
      raw: raw,
      displayName:
          _cleanText(discovery.customName) ??
          _cleanText(discovery.suggestedName) ??
          fallbackName ??
          _legacyFormatter.value(discovery.speciesId),
      speciesId: discovery.speciesId,
      coatColor: discovery.coatColor,
      coatPattern: discovery.coatPattern,
      eyeColor: discovery.eyeColor,
      hairLength: discovery.hairLength,
      age: discovery.estimatedAge,
      personality: discovery.personality.name,
      rarity: discovery.rarity.name,
      variant: discovery.variantId,
      story: discovery.story,
      funFact: discovery.funFact,
    );
  }

  CatDisplayData _normalize({
    required Map<String, Object?> raw,
    required String displayName,
    required String speciesId,
    required String? coatColor,
    required String? coatPattern,
    required String? eyeColor,
    required String? hairLength,
    required String? age,
    required String? personality,
    required String? rarity,
    required String? variant,
    required String? story,
    required String? funFact,
  }) {
    final override = _bicolorOverride(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    );
    final overrideApplied = override != null;
    final normalizedEyeColor = _normalizedEyeColor(eyeColor);
    final orangeTabby = _isOrangeTabby(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
      story: story,
      funFact: funFact,
      raw: raw,
    );
    final displaySpecies = overrideApplied
        ? 'Gatto domestico bicolore'
        : orangeTabby
        ? 'Gatto domestico arancione tigrato'
        : _legacyFormatter.speciesLabel(
            speciesId: speciesId,
            coatColor: coatColor,
            coatPattern: coatPattern,
          );
    final displayCoatColor = overrideApplied
        ? override.coatColor
        : orangeTabby
        ? 'Arancione tigrato'
        : _legacyFormatter.coatColorLabel(
            speciesId: speciesId,
            coatColor: coatColor,
            coatPattern: coatPattern,
            fallback: '-',
          );

    final displayData = CatDisplayData(
      displayName: displayName,
      displaySpecies: displaySpecies,
      displayCoatColor: displayCoatColor,
      displayCoatPattern: overrideApplied
          ? 'Bicolore'
          : _legacyFormatter.coatPatternLabel(
              speciesId: speciesId,
              coatColor: coatColor,
              coatPattern: coatPattern,
              fallback: '-',
            ),
      displayEyeColor: normalizedEyeColor.value,
      displayHairLength: _legacyFormatter.nullableValue(
        hairLength,
        fallback: '-',
      ),
      displayAge: _legacyFormatter.nullableValue(age, fallback: '-'),
      displayPersonality: _legacyFormatter.nullableValue(
        personality,
        fallback: '-',
      ),
      displayRarity: _legacyFormatter.nullableValue(rarity, fallback: 'Comune'),
      displayVariant: _legacyFormatter.nullableValue(
        variant,
        fallback: 'Normale',
      ),
      displayStory: overrideApplied
          ? _bicolorStory(override.coatColor)
          : _cleanText(story) ?? 'Una nuova storia CatDex sta prendendo forma.',
      displayFunFact: overrideApplied
          ? _bicolorFunFact
          : _cleanText(funFact) ??
                'Continua a esplorare per scoprire altri dettagli.',
    );

    _debugPrintNormalization(
      raw: raw,
      displayData: displayData,
      overrideApplied: overrideApplied,
      overrideReason: override?.reason ?? '-',
      coatColorRaw: coatColor,
      coatPatternRaw: coatPattern,
      coatColorDecision:
          override?.decision ?? (orangeTabby ? 'orange_tabby' : 'preserve_raw'),
      eyeColorRaw: eyeColor,
      eyeColorDecision: normalizedEyeColor.decision,
      orangeTabbyDetected: orangeTabby,
    );

    return displayData;
  }

  bool _isOrangeTabby({
    required String speciesId,
    required String? coatColor,
    required String? coatPattern,
    required String? story,
    required String? funFact,
    required Map<String, Object?> raw,
  }) {
    final species = _normalizeKey(speciesId);
    final color = _normalizeKey(coatColor);
    final pattern = _normalizeKey(coatPattern);
    final text = _normalizeKey(
      '$speciesId ${coatColor ?? ''} ${coatPattern ?? ''} '
      '${story ?? ''} ${funFact ?? ''} ${_safeJson(raw)}',
    );
    final domesticTabby =
        species == 'domestic_tabby_cat' ||
        species == 'domestic_orange_cat' ||
        species == 'domestic_shorthair_cat';
    final orangeSignal = _containsAny(text, const [
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
        ]) ||
        color.contains('tigrat') ||
        color.contains('tabby') ||
        text.contains('striped');

    return domesticTabby && orangeSignal && tabbyPattern;
  }

  _BicolorOverride? _bicolorOverride({
    required String speciesId,
    required String? coatColor,
    required String? coatPattern,
  }) {
    final species = _normalizeKey(speciesId);
    final color = _normalizeKey(coatColor);
    final pattern = _normalizeKey(coatPattern);

    final speciesIsExplicitBicolor =
        species == 'domestic_gray_cat' ||
        species == 'domestic_black_white_cat' ||
        species == 'domestic_tuxedo_cat';

    final hasBicolorPatternSignal =
        pattern.contains('bicolore') ||
        pattern.contains('bicolor') ||
        pattern.contains('tuxedo');
    final hasBicolorColorSignal =
        color.contains('nero/bianco') ||
        color.contains('bianco/nero') ||
        color.contains('black_white') ||
        color.contains('black/white') ||
        color.contains('white/black') ||
        color.contains('grigio/bianco') ||
        color.contains('bianco/grigio') ||
        color.contains('gray_white') ||
        color.contains('grey_white') ||
        color.contains('gray/white') ||
        color.contains('grey/white') ||
        color.contains('white/gray') ||
        color.contains('white/grey') ||
        color.contains('arancione/bianco') ||
        color.contains('bianco/arancione') ||
        color.contains('orange_white') ||
        color.contains('orange/white') ||
        color.contains('white/orange') ||
        color.contains('marrone/bianco') ||
        color.contains('bianco/marrone') ||
        color.contains('brown_white') ||
        color.contains('brown/white') ||
        color.contains('white/brown');

    if (!speciesIsExplicitBicolor &&
        !hasBicolorPatternSignal &&
        !hasBicolorColorSignal) {
      return null;
    }

    final colorDecision = _bicolorColorDecision(
      species: species,
      color: color,
      pattern: pattern,
    );
    final reason = speciesIsExplicitBicolor
        ? 'explicit bicolor/tuxedo species'
        : hasBicolorPatternSignal
        ? 'coatPattern marked as bicolor/tuxedo'
        : 'coatColor marked as bicolor';

    return _BicolorOverride(
      coatColor: colorDecision.coatColor,
      decision: colorDecision.decision,
      reason: reason,
    );
  }

  _BicolorColorDecision _bicolorColorDecision({
    required String species,
    required String color,
    required String pattern,
  }) {
    final combined = '$species $color $pattern';

    if (_containsAny(combined, const [
      'nero/bianco',
      'bianco/nero',
      'black/white',
      'black_white',
      'white/black',
      'tuxedo',
      'domestic_black_white_cat',
      'domestic_tuxedo_cat',
    ])) {
      return const _BicolorColorDecision('Nero/bianco', 'nero_bianco');
    }

    if (_containsAny(combined, const [
      'grigio',
      'gray',
      'grey',
      'gray_white',
      'grey_white',
      'blu',
      'blue_gray',
      'silver',
      'smoke',
      'domestic_gray_cat',
    ])) {
      return const _BicolorColorDecision('Grigio/bianco', 'grigio_bianco');
    }

    if (_containsAny(combined, const [
      'arancione',
      'rosso',
      'ginger',
      'orange',
      'orange_white',
    ])) {
      return const _BicolorColorDecision(
        'Arancione/bianco',
        'arancione_bianco',
      );
    }

    if (_containsAny(combined, const ['marrone', 'brown', 'brown_white'])) {
      return const _BicolorColorDecision('Marrone/bianco', 'marrone_bianco');
    }

    return const _BicolorColorDecision('Bicolore', 'bicolore_unknown');
  }

  _EyeColorDecision _normalizedEyeColor(String? eyeColor) {
    final normalized = _normalizeKey(eyeColor);

    if (_containsAny(normalized, const [
      'amber',
      'ambra',
      'ambr',
      'orange',
      'aranc',
      'copper',
      'rame',
      'golden',
      'yellow-orange',
      'giallo-arancio',
    ])) {
      return _EyeColorDecision(
        'occhi ambrati',
        normalized.contains('occhi') ? 'main_analysis' : 'normalization',
      );
    }

    if (_containsAny(normalized, const ['yellow', 'gold', 'giall', 'dorat'])) {
      return _EyeColorDecision(
        'occhi gialli',
        normalized.contains('occhi') ? 'main_analysis' : 'normalization',
      );
    }

    if (_containsAny(normalized, const ['green', 'verd'])) {
      return _EyeColorDecision(
        'occhi verdi',
        normalized.contains('occhi') ? 'main_analysis' : 'normalization',
      );
    }

    if (_containsAny(normalized, const ['blue', 'azzurr'])) {
      return _EyeColorDecision(
        'occhi azzurri',
        normalized.contains('occhi') ? 'main_analysis' : 'normalization',
      );
    }

    if (_containsAny(normalized, const [
      'mixed',
      'heterochromia',
      'eterocrom',
    ])) {
      return _EyeColorDecision(
        'occhi eterocromi',
        normalized.contains('occhi') ? 'main_analysis' : 'normalization',
      );
    }

    if (normalized.isEmpty ||
        normalized == 'unknown' ||
        normalized == 'null' ||
        normalized == 'non rilevato') {
      return const _EyeColorDecision('-', 'not_visible');
    }

    return _EyeColorDecision(
      _legacyFormatter.nullableValue(eyeColor, fallback: '-'),
      'preserve_raw',
    );
  }

  String _bicolorStory(String coatColor) {
    final coatPhrase = switch (coatColor) {
      'Nero/bianco' => 'nero e bianco',
      'Grigio/bianco' => 'grigio e bianco',
      'Arancione/bianco' => 'arancione e bianco',
      'Marrone/bianco' => 'marrone e bianco',
      _ => 'bicolore',
    };

    return 'Un gatto domestico bicolore dal mantello $coatPhrase entra nel '
        'tuo CatDex con uno sguardo curioso e attento.';
  }

  bool _containsAny(String value, List<String> needles) {
    return needles.any(value.contains);
  }

  String _normalizeKey(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  String? _cleanText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.toLowerCase();
    if (normalized == 'null' || normalized == 'unknown') {
      return null;
    }

    return trimmed;
  }

  void _debugPrintNormalization({
    required Map<String, Object?> raw,
    required CatDisplayData displayData,
    required bool overrideApplied,
    required String overrideReason,
    required String? coatColorRaw,
    required String? coatPatternRaw,
    required String coatColorDecision,
    required String? eyeColorRaw,
    required String eyeColorDecision,
    required bool orangeTabbyDetected,
  }) {
    final orangeTabbyDecision = orangeTabbyDetected
        ? 'orange_signal_with_tabby_pattern'
        : 'not_orange_tabby';
    _log('CATDEX_RAW_ANALYSIS ${_safeJson(raw)}');
    _log(
      'CATDEX_NORMALIZED_DISPLAY_DATA ${_safeJson(displayData.toDebugJson())}',
    );
    _log('CATDEX_COAT_COLOR_RAW ${coatColorRaw ?? '-'}');
    _log('CATDEX_COAT_PATTERN_RAW ${coatPatternRaw ?? '-'}');
    _log('CATDEX_ORANGE_TABBY_RAW_COLOR ${coatColorRaw ?? '-'}');
    _log('CATDEX_ORANGE_TABBY_RAW_PATTERN ${coatPatternRaw ?? '-'}');
    _log('CATDEX_COAT_COLOR_NORMALIZED ${displayData.displayCoatColor}');
    _log('CATDEX_DISPLAY_SPECIES_DECISION ${displayData.displaySpecies}');
    _log('CATDEX_ORANGE_TABBY_DETECTED $orangeTabbyDetected');
    _log('CATDEX_ORANGE_TABBY_DECISION $orangeTabbyDecision');
    _log('CATDEX_BICOLOR_COLOR_DECISION $coatColorDecision');
    _log('CATDEX_EYE_COLOR_RAW ${eyeColorRaw ?? '-'}');
    _log('CATDEX_EYE_COLOR_NORMALIZED ${displayData.displayEyeColor}');
    _log('CATDEX_EYE_COLOR_DECISION $eyeColorDecision');
    _log('CATDEX_BICOLOR_OVERRIDE_APPLIED $overrideApplied');
    _log('CATDEX_BICOLOR_OVERRIDE_REASON $overrideReason');
  }

  void _log(String message) {
    Zone.current.print(message);
  }

  String _safeJson(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }
}

class _BicolorOverride {
  const _BicolorOverride({
    required this.coatColor,
    required this.decision,
    required this.reason,
  });

  final String coatColor;
  final String decision;
  final String reason;
}

class _BicolorColorDecision {
  const _BicolorColorDecision(this.coatColor, this.decision);

  final String coatColor;
  final String decision;
}

class _EyeColorDecision {
  const _EyeColorDecision(this.value, this.decision);

  final String value;
  final String decision;
}
