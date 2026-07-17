import 'package:catdex/features/achievements/domain/achievement_facts.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/location/domain/entities/cat_discovery_location.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('failed discovery absent from persistence does not increment', () {
    final facts = _facts();
    expect(facts.discoveryCount, 0);
  });

  test('duplicate discovery ID does not increment twice', () {
    final discovery = _discovery('same');
    final facts = _facts(discoveries: [discovery, discovery]);
    expect(facts.discoveryCount, 1);
  });

  test('five persisted discoveries produce progress five', () {
    final facts = _facts(
      discoveries: List.generate(5, (index) => _discovery('$index')),
    );
    expect(facts.discoveryCount, 5);
  });

  test('normal cards count only completed persisted normal cards', () {
    final facts = _facts(
      cards: [
        _card('normal', CatCardType.normal),
        _card('event', CatCardType.event),
        _card('failed', CatCardType.normal, completed: false),
      ],
    );
    expect(facts.normalCardCount, 1);
    expect(facts.eventCardCount, 1);
  });

  test('duplicate event variant does not count collection twice', () {
    final facts = _facts(
      cards: [
        _card('one', CatCardType.event),
        _card('two', CatCardType.event),
      ],
    );
    expect(facts.halloweenFreeVariantCount, 1);
  });

  test('Halloween Free requires all three distinct variants', () {
    final facts = _facts(
      cards: [
        _card('one', CatCardType.event),
        _card('two', CatCardType.event, variant: 'halloween_moonlight'),
        _card(
          'three',
          CatCardType.event,
          variant: 'halloween_haunted_frame',
        ),
      ],
    );
    expect(facts.halloweenFreeVariantCount, 3);
  });

  test('Halloween Premium requires all three distinct variants', () {
    final facts = _facts(
      cards: [
        _card('one', CatCardType.event, variant: 'halloween_witch_cat'),
        _card('two', CatCardType.event, variant: 'halloween_pumpkin_king'),
        _card('three', CatCardType.event, variant: 'halloween_night_spirit'),
      ],
    );
    expect(facts.halloweenPremiumVariantCount, 3);
  });

  test('valid GPS increments but invalid coordinates do not', () {
    final facts = _facts(
      discoveries: [
        _discovery(
          'valid',
          location: CatDiscoveryLocation.tryCreate(
            latitude: 45.46,
            longitude: 9.18,
          ),
        ),
        _discovery(
          'invalid',
          location: const CatDiscoveryLocation(latitude: 130, longitude: 500),
        ),
      ],
    );
    expect(facts.geolocatedDiscoveryCount, 1);
  });

  test('only claimed mission transactions increment mission progress', () {
    final facts = _facts(
      missionLedger: _missionLedger(
        transactions: {
          'claimed': _transaction(
            'claimed',
            DailyMissionClaimTransactionStatus.completed,
          ),
          'only-completed': _transaction(
            'only-completed',
            DailyMissionClaimTransactionStatus.started,
          ),
        },
      ),
    );
    expect(facts.claimedDailyMissionCount, 1);
  });

  test('rarity and player level use persisted normalized values', () {
    final facts = _facts(
      discoveries: [
        _discovery('rare', rarity: CatRarity.rare),
        _discovery('legendary', rarity: CatRarity.legendary),
      ],
      playerLevel: 10,
    );
    expect(facts.discoveryCountsByRarity[CatRarity.rare], 1);
    expect(facts.discoveryCountsByRarity[CatRarity.legendary], 1);
    expect(facts.playerLevel, 10);
  });
}

AchievementFacts _facts({
  List<CatDiscovery> discoveries = const [],
  List<CatCardRecord> cards = const [],
  DailyMissionLedger? missionLedger,
  int playerLevel = 1,
}) {
  return AchievementFacts.fromPersistedData(
    discoveries: discoveries,
    cards: cards,
    missionLedger: missionLedger,
    playerLevel: playerLevel,
  );
}

CatDiscovery _discovery(
  String id, {
  CatRarity rarity = CatRarity.common,
  CatDiscoveryLocation? location,
}) {
  return CatDiscovery(
    id: id,
    playerId: 'player',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: rarity,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 17),
    friendshipPoints: 0,
    captureLocation: location,
  );
}

CatCardRecord _card(
  String id,
  CatCardType type, {
  bool completed = true,
  String variant = 'halloween_pumpkins',
}) {
  final now = DateTime.utc(2026, 10, 31);
  return CatCardRecord(
    cardId: id,
    discoveryId: 'discovery-$id',
    ownerId: 'player',
    cardType: type,
    rarity: CatRarity.common,
    finalCardUrl: completed ? 'https://example.test/$id/final-card.png' : '',
    templateKey: 'template',
    generationStatus: completed
        ? CatCardGenerationStatus.completed
        : CatCardGenerationStatus.failed,
    generationRequestId: 'request-$id',
    idempotencyKey: 'key-$id',
    createdAt: now,
    updatedAt: now,
    eventKey: type == CatCardType.event ? 'halloween_2026' : null,
    eventEdition: type == CatCardType.event ? '2026' : null,
    eventArtworkVariantId: type == CatCardType.event ? variant : null,
  );
}

DailyMissionLedger _missionLedger({
  required Map<String, DailyMissionClaimTransaction> transactions,
}) {
  return DailyMissionLedger(
    playerId: 'player',
    assignedDate: '2026-07-17',
    lastResetDate: '2026-07-17',
    missions: const [],
    expiredMissions: const [],
    processedOperationIds: const {},
    claimTransactions: transactions,
    schemaVersion: 1,
  );
}

DailyMissionClaimTransaction _transaction(
  String id,
  DailyMissionClaimTransactionStatus status,
) {
  final now = DateTime.utc(2026, 7, 17);
  return DailyMissionClaimTransaction(
    transactionId: id,
    missionId: id,
    rewardType: DailyMissionRewardType.xp,
    rewardAmount: 10,
    baselineValue: 0,
    expectedValue: 10,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}
