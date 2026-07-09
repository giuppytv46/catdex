import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';

class ManualEditOption {
  const ManualEditOption(this.value);

  final String value;
}

class ManualEditValueMapper {
  const ManualEditValueMapper._();

  static const speciesOptions = <ManualEditOption>[
    ManualEditOption('domestic_cat'),
    ManualEditOption('domestic_tabby_cat'),
    ManualEditOption('european_shorthair'),
    ManualEditOption('siamese'),
    ManualEditOption('persian'),
    ManualEditOption('maine_coon'),
    ManualEditOption('british_shorthair'),
    ManualEditOption('unknown'),
  ];

  static const coatColorOptions = <ManualEditOption>[
    ManualEditOption('black'),
    ManualEditOption('white'),
    ManualEditOption('gray'),
    ManualEditOption('brown'),
    ManualEditOption('orange'),
    ManualEditOption('black_white'),
    ManualEditOption('gray_white'),
    ManualEditOption('brown_white'),
    ManualEditOption('orange_white'),
    ManualEditOption('orange_tabby'),
    ManualEditOption('brown_tabby'),
    ManualEditOption('gray_tabby'),
    ManualEditOption('calico'),
    ManualEditOption('tricolor'),
    ManualEditOption('tortoiseshell'),
    ManualEditOption('bicolor'),
    ManualEditOption('unknown'),
  ];

  static const patternOptions = <ManualEditOption>[
    ManualEditOption('solid'),
    ManualEditOption('tabby'),
    ManualEditOption('bicolor'),
    ManualEditOption('calico'),
    ManualEditOption('tricolor'),
    ManualEditOption('tortoiseshell'),
    ManualEditOption('patched'),
    ManualEditOption('colorpoint'),
    ManualEditOption('unknown'),
  ];

  static const eyeOptions = <ManualEditOption>[
    ManualEditOption('yellow'),
    ManualEditOption('green'),
    ManualEditOption('blue'),
    ManualEditOption('amber'),
    ManualEditOption('heterochromia'),
    ManualEditOption('unknown'),
  ];

  static const hairLengthOptions = <ManualEditOption>[
    ManualEditOption('short'),
    ManualEditOption('medium'),
    ManualEditOption('long'),
    ManualEditOption('unknown'),
  ];

  static const personalityOptions = <ManualEditOption>[
    ManualEditOption('curious'),
    ManualEditOption('sweet'),
    ManualEditOption('shy'),
    ManualEditOption('playful'),
    ManualEditOption('elegant'),
    ManualEditOption('mysterious'),
    ManualEditOption('energetic'),
    ManualEditOption('calm'),
    ManualEditOption('lazy'),
    ManualEditOption('unknown'),
  ];

  static const rarityOptions = <ManualEditOption>[
    ManualEditOption('common'),
    ManualEditOption('uncommon'),
    ManualEditOption('rare'),
    ManualEditOption('epic'),
    ManualEditOption('legendary'),
  ];

  static String optionValue(
    String? rawValue,
    List<ManualEditOption> options, {
    required String fallback,
  }) {
    final normalized = normalize(rawValue);
    for (final option in options) {
      if (option.value == normalized) {
        return option.value;
      }
    }

    return fallback;
  }

  static String normalize(String? value) {
    final key = value?.trim().toLowerCase().replaceAll('_', ' ') ?? '';
    if (key.isEmpty || key == '-' || key == 'null') {
      return 'unknown';
    }

    return _aliases[key] ?? key.replaceAll(' ', '_');
  }

  static CatPersonality personalityFromValue(String value) {
    return switch (normalize(value)) {
      'curious' => CatPersonality.curious,
      'sweet' => CatPersonality.friendly,
      'shy' => CatPersonality.sleepy,
      'playful' => CatPersonality.playful,
      'elegant' => CatPersonality.elegant,
      'mysterious' => CatPersonality.mysterious,
      'energetic' => CatPersonality.brave,
      'calm' => CatPersonality.calm,
      'lazy' => CatPersonality.lazy,
      _ => CatPersonality.unknown,
    };
  }

  static CatRarity rarityFromValue(String value) {
    return switch (normalize(value)) {
      'uncommon' => CatRarity.uncommon,
      'rare' => CatRarity.rare,
      'epic' => CatRarity.epic,
      'legendary' => CatRarity.legendary,
      _ => CatRarity.common,
    };
  }

  static const _aliases = <String, String>{
    'gatto domestico': 'domestic_cat',
    'domestic cat': 'domestic_cat',
    'gatto domestico tigrato': 'domestic_tabby_cat',
    'domestic tabby cat': 'domestic_tabby_cat',
    'gatto europeo': 'european_shorthair',
    'european shorthair': 'european_shorthair',
    'maine coon': 'maine_coon',
    'british shorthair': 'british_shorthair',
    'sconosciuto': 'unknown',
    'non rilevato': 'unknown',
    'nero': 'black',
    'bianco': 'white',
    'grigio': 'gray',
    'marrone': 'brown',
    'arancione': 'orange',
    'nero/bianco': 'black_white',
    'black/white': 'black_white',
    'grigio/bianco': 'gray_white',
    'gray/white': 'gray_white',
    'grey/white': 'gray_white',
    'marrone/bianco': 'brown_white',
    'brown/white': 'brown_white',
    'arancione/bianco': 'orange_white',
    'orange/white': 'orange_white',
    'arancione tigrato': 'orange_tabby',
    'marrone tigrato': 'brown_tabby',
    'grigio tigrato': 'gray_tabby',
    'tartarugato': 'tortoiseshell',
    'bicolore': 'bicolor',
    'solido': 'solid',
    'tigrato': 'tabby',
    'pezzato': 'patched',
    'gialli': 'yellow',
    'occhi gialli': 'yellow',
    'verdi': 'green',
    'occhi verdi': 'green',
    'azzurri': 'blue',
    'occhi azzurri': 'blue',
    'ambrati': 'amber',
    'occhi ambrati': 'amber',
    'eterocromia': 'heterochromia',
    'occhi eterocromi': 'heterochromia',
    'corto': 'short',
    'pelo corto': 'short',
    'medio': 'medium',
    'pelo medio': 'medium',
    'lungo': 'long',
    'pelo lungo': 'long',
    'comune': 'common',
    'non comune': 'uncommon',
    'rara': 'rare',
    'epica': 'epic',
    'epico': 'epic',
    'leggendaria': 'legendary',
    'leggendario': 'legendary',
    'curioso': 'curious',
    'dolce': 'sweet',
    'timido': 'shy',
    'giocherellone': 'playful',
    'elegante': 'elegant',
    'misterioso': 'mysterious',
    'energico': 'energetic',
    'tranquillo': 'calm',
    'calmo': 'calm',
    'pigro': 'lazy',
    'relaxed': 'calm',
  };
}
