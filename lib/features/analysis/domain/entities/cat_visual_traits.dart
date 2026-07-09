import 'package:catdex/features/catdex/domain/entities/cat_trait.dart';

class CatVisualTraits {
  const CatVisualTraits({
    required this.coatColor,
    required this.coatPattern,
    required this.eyeColor,
    required this.hairLength,
    required this.notableTraits,
  });

  final String coatColor;
  final String coatPattern;
  final String eyeColor;
  final String hairLength;
  final List<CatTrait> notableTraits;

  CatVisualTraits copyWith({
    String? coatColor,
    String? coatPattern,
    String? eyeColor,
    String? hairLength,
    List<CatTrait>? notableTraits,
  }) {
    return CatVisualTraits(
      coatColor: coatColor ?? this.coatColor,
      coatPattern: coatPattern ?? this.coatPattern,
      eyeColor: eyeColor ?? this.eyeColor,
      hairLength: hairLength ?? this.hairLength,
      notableTraits: notableTraits ?? this.notableTraits,
    );
  }
}
