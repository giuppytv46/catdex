import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/analysis/presentation/manual_edit_value_mapper.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:test/test.dart';

void main() {
  test('manual personality elegant round-trips without becoming regal', () {
    final internal = ManualEditValueMapper.normalize('Elegante');
    final personality = ManualEditValueMapper.personalityFromValue(internal);
    final discovery = _discovery(personality: personality);
    final display = const CatDisplayFormatter().fromDiscovery(discovery);

    expect(internal, 'elegant');
    expect(personality, CatPersonality.elegant);
    expect(discovery.personality.name, 'elegant');
    expect(display.displayPersonality, 'Elegante');
    expect(display.displayPersonality, isNot('Regale'));
    expect(discovery.personality.name, isNot('royal'));
  });

  test('manual personality lazy round-trips as lazy and Pigro', () {
    final internal = ManualEditValueMapper.normalize('Pigro');
    final personality = ManualEditValueMapper.personalityFromValue(internal);
    final display = const CatDisplayFormatter().fromDiscovery(
      _discovery(personality: personality),
    );

    expect(internal, 'lazy');
    expect(personality, CatPersonality.lazy);
    expect(display.displayPersonality, 'Pigro');
  });

  test('manual rarity epic round-trips as epic and Epica', () {
    final internal = ManualEditValueMapper.normalize('Epica');
    final rarity = ManualEditValueMapper.rarityFromValue(internal);
    final display = const CatDisplayFormatter().fromDiscovery(
      _discovery(rarity: rarity),
    );

    expect(internal, 'epic');
    expect(rarity, CatRarity.epic);
    expect(display.displayRarity, 'Epica');
  });

  test('manual hair length medium round-trips as medium and Pelo medio', () {
    final internal = ManualEditValueMapper.normalize('Pelo medio');
    final display = const CatDisplayFormatter().fromDiscovery(
      _discovery(hairLength: internal),
    );

    expect(internal, 'medium');
    expect(display.displayHairLength, 'Pelo medio');
  });

  test('manual internal personality key stays stable after display reload', () {
    const internal = 'elegant';

    expect(ManualEditValueMapper.personalityFromValue(internal).name, internal);
    expect(ManualEditValueMapper.normalize('Elegante'), internal);
  });
}

CatDiscovery _discovery({
  CatPersonality personality = CatPersonality.curious,
  CatRarity rarity = CatRarity.common,
  String hairLength = 'short',
}) {
  return CatDiscovery(
    id: 'manual-edit-test',
    playerId: 'local-player',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: rarity,
    personality: personality,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 9),
    friendshipPoints: 0,
    customName: 'Luna',
    suggestedName: 'Luna',
    coatColor: 'black_white',
    coatPattern: 'bicolor',
    eyeColor: 'amber',
    hairLength: hairLength,
    estimatedAge: 'adult',
    story: 'Un gatto entra nel CatDex.',
    funFact: 'Ogni gatto ha caratteristiche uniche.',
  );
}
