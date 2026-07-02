import 'dart:async';
import 'dart:convert';

import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

class CatDisplayFormatter {
  const CatDisplayFormatter();

  static const _legacyFormatter = CatAnalysisDisplayFormatter();
  static const _bicolorStory =
      'Un gatto domestico bicolore dal mantello nero e bianco entra nel tuo '
      'CatDex con uno sguardo curioso e attento.';
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
    final override = _bicolorOverrideReason(
      speciesId: speciesId,
      coatColor: coatColor,
      coatPattern: coatPattern,
    );
    final overrideApplied = override != null;

    final displayData = CatDisplayData(
      displayName: displayName,
      displaySpecies: overrideApplied
          ? 'Gatto domestico bicolore'
          : _legacyFormatter.speciesLabel(
              speciesId: speciesId,
              coatColor: coatColor,
              coatPattern: coatPattern,
            ),
      displayCoatColor: overrideApplied
          ? 'Nero/bianco'
          : _legacyFormatter.coatColorLabel(
              speciesId: speciesId,
              coatColor: coatColor,
              coatPattern: coatPattern,
              fallback: '-',
            ),
      displayCoatPattern: overrideApplied
          ? 'Bicolore'
          : _legacyFormatter.coatPatternLabel(
              speciesId: speciesId,
              coatColor: coatColor,
              coatPattern: coatPattern,
              fallback: '-',
            ),
      displayEyeColor: _legacyFormatter.nullableValue(eyeColor, fallback: '-'),
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
          ? _bicolorStory
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
      overrideReason: override ?? '-',
    );

    return displayData;
  }

  String? _bicolorOverrideReason({
    required String speciesId,
    required String? coatColor,
    required String? coatPattern,
  }) {
    final species = _normalizeKey(speciesId);
    final color = _normalizeKey(coatColor);
    final pattern = _normalizeKey(coatPattern);

    final speciesIsExplicitBicolor =
        species == 'domestic_black_white_cat' ||
        species == 'domestic_tuxedo_cat';
    if (speciesIsExplicitBicolor) {
      return 'explicit bicolor/tuxedo species';
    }

    final hasBicolorPatternSignal =
        pattern.contains('bicolore') ||
        pattern.contains('bicolor') ||
        pattern.contains('tuxedo') ||
        pattern.contains('bianco') ||
        pattern.contains('white') ||
        pattern.contains('nero') ||
        pattern.contains('black');
    final hasBicolorColorSignal =
        color.contains('nero/bianco') ||
        color.contains('bianco/nero') ||
        color.contains('black/white') ||
        color.contains('white/black');

    if (hasBicolorPatternSignal) {
      return 'coatPattern marked as bicolor/tuxedo';
    }

    if (hasBicolorColorSignal) {
      return 'coatColor marked as black/white';
    }

    return null;
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
  }) {
    _log('CATDEX_RAW_ANALYSIS ${_safeJson(raw)}');
    _log(
      'CATDEX_NORMALIZED_DISPLAY_DATA ${_safeJson(displayData.toDebugJson())}',
    );
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
