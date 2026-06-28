import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatAnalysisDisplayText {
  const CatAnalysisDisplayText();

  String coatColor(String value) {
    return _normalized(value, const {
      'black': 'Nero',
      'nero': 'Nero',
      'brown': 'Marrone',
      'marrone': 'Marrone',
      'orange': 'Arancione',
      'arancione': 'Arancione',
      'white': 'Bianco',
      'bianco': 'Bianco',
      'gray': 'Grigio',
      'grey': 'Grigio',
      'grigio': 'Grigio',
      'cream': 'Crema',
      'crema': 'Crema',
    });
  }

  String coatPattern(String value) {
    return _normalized(value, const {
      'tabby': 'Tigrato',
      'tigrato': 'Tigrato',
      'tuxedo': 'Tuxedo',
      'calico': 'Calico',
      'solid': 'Solido',
      'solido': 'Solido',
      'bicolor': 'Bicolore',
      'bicolore': 'Bicolore',
      'tortoiseshell': 'Squama di tartaruga',
      'squama di tartaruga': 'Squama di tartaruga',
      'pointed': 'Colorpoint',
      'colorpoint': 'Colorpoint',
      'spotted': 'Maculato',
      'maculato': 'Maculato',
    });
  }

  String eyeColor(String value) {
    final normalized = _normalize(value);
    if (normalized.contains('amber')) {
      return 'Occhi ambrati';
    }
    if (normalized.contains('ambra')) {
      return 'Occhi ambrati';
    }
    if (normalized.contains('yellow') || normalized.contains('gial')) {
      return 'Occhi gialli';
    }
    if (normalized.contains('green') || normalized.contains('verd')) {
      return 'Occhi verdi';
    }
    if (normalized.contains('blue') || normalized.contains('blu')) {
      return 'Occhi blu';
    }
    if (normalized.contains('gold') || normalized.contains('dor')) {
      return 'Occhi dorati';
    }
    return value;
  }

  String hairLength(String value) {
    return _normalized(value, const {
      'short': 'Pelo corto',
      'short hair': 'Pelo corto',
      'corto': 'Pelo corto',
      'pelo corto': 'Pelo corto',
      'medium': 'Pelo medio',
      'medium hair': 'Pelo medio',
      'medio': 'Pelo medio',
      'pelo medio': 'Pelo medio',
      'long': 'Pelo lungo',
      'long hair': 'Pelo lungo',
      'lungo': 'Pelo lungo',
      'pelo lungo': 'Pelo lungo',
      'fluffy': 'Pelo soffice',
      'soft hair': 'Pelo soffice',
      'soffice': 'Pelo soffice',
      'pelo soffice': 'Pelo soffice',
    });
  }

  String personality(CatPersonality personality) {
    return switch (personality) {
      CatPersonality.sleepy => 'Sonnolento',
      CatPersonality.curious => 'Curioso',
      CatPersonality.boss => 'Dominante',
      CatPersonality.friendly => 'Amichevole',
      CatPersonality.royal => 'Regale',
      CatPersonality.mischievous => 'Birichino',
      CatPersonality.silly => 'Buffo',
      CatPersonality.mysterious => 'Misterioso',
      CatPersonality.brave => 'Coraggioso',
      CatPersonality.lazy => 'Pigro',
      CatPersonality.relaxed => 'Rilassato',
      CatPersonality.playful => 'Giocoso',
    };
  }

  String traitSummary(CatAnalysisResult result) {
    return [
      coatColor(result.visualTraits.coatColor),
      coatPattern(result.visualTraits.coatPattern),
      eyeColor(result.visualTraits.eyeColor),
      hairLength(result.visualTraits.hairLength),
      ...result.visualTraits.notableTraits
          .where(_isAllowedTrait)
          .map(_traitText),
    ].where((value) => value.isNotEmpty && value != 'Unknown').join(', ');
  }

  bool _isAllowedTrait(CatTrait trait) {
    final name = _normalize(trait.name);
    return name == 'posa' ||
        name == 'posture' ||
        name == 'ambiente' ||
        name == 'environment' ||
        name == 'espressione' ||
        name == 'expression' ||
        name == 'umore' ||
        name == 'mood';
  }

  String _traitText(CatTrait trait) {
    final name = _traitName(trait.name);
    final value = _traitValue(trait.value);
    return '$name: $value';
  }

  String _traitName(String value) {
    return _normalized(value, const {
      'posture': 'Posa',
      'posa': 'Posa',
      'environment': 'Ambiente',
      'ambiente': 'Ambiente',
      'expression': 'Espressione',
      'espressione': 'Espressione',
      'mood': 'Umore',
      'umore': 'Umore',
    });
  }

  String _traitValue(String value) {
    return _normalized(value, const {
      'relaxed': 'rilassata',
      'rilassato': 'rilassata',
      'rilassata': 'rilassata',
      'curious': 'curioso',
      'curioso': 'curioso',
      'lying down': 'distesa',
      'disteso': 'distesa',
      'distesa': 'distesa',
      'sitting': 'seduta',
      'seduto': 'seduta',
      'seduta': 'seduta',
      'watching': 'in osservazione',
      'in osservazione': 'in osservazione',
    });
  }

  String _normalized(String value, Map<String, String> replacements) {
    final replacement = replacements[_normalize(value)];
    if (replacement != null) {
      return replacement;
    }
    return value;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
