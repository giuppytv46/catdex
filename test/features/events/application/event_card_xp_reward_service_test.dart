import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:catdex/features/events/application/event_card_xp_reward_service.dart';
import 'package:catdex/features/events/domain/entities/event_card_xp_reward.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persisted event card awards exactly 100 XP', () async {
    final harness = _RewardHarness(initialXp: 0);

    final result = await harness.service.awardForPersistedEventCard(
      _eventCard('card-1'),
    );

    expect(result.newlyGranted, isTrue);
    expect(result.awardedAmount, eventCardGenerationXp);
    expect(result.previousXp, 0);
    expect(result.updatedXp, 100);
    expect(harness.progress.totalXp, 100);
    expect(result.transactionId, 'event_card_generation_xp:card-1');
  });

  test('retry with the same card id does not duplicate XP', () async {
    final harness = _RewardHarness(initialXp: 0);
    final card = _eventCard('card-duplicate');

    final first = await harness.service.awardForPersistedEventCard(card);
    final second = await harness.service.awardForPersistedEventCard(card);

    expect(first.newlyGranted, isTrue);
    expect(second.newlyGranted, isFalse);
    expect(harness.progress.totalXp, 100);
  });

  test('reward survives service recreation without replay', () async {
    final harness = _RewardHarness(initialXp: 0);
    final card = _eventCard('card-restart');
    await harness.service.awardForPersistedEventCard(card);

    final restoredService = harness.createService();
    final restored = await restoredService.awardForPersistedEventCard(card);

    expect(restored.newlyGranted, isFalse);
    expect(harness.progress.totalXp, 100);
  });

  test('Free and Premium event artwork award the same XP', () async {
    final freeHarness = _RewardHarness(initialXp: 0);
    final premiumHarness = _RewardHarness(
      initialXp: 0,
      playerId: 'premium-player',
    );

    final free = await freeHarness.service.awardForPersistedEventCard(
      _eventCard('free-card'),
    );
    final premium = await premiumHarness.service.awardForPersistedEventCard(
      _eventCard(
        'premium-card',
        ownerId: 'premium-player',
        premium: true,
      ),
    );

    expect(free.awardedAmount, eventCardGenerationXp);
    expect(premium.awardedAmount, eventCardGenerationXp);
  });

  test('event card XP reports a level-up', () async {
    final harness = _RewardHarness(initialXp: 50);

    final result = await harness.service.awardForPersistedEventCard(
      _eventCard('level-card'),
    );

    expect(result.previousLevel, 1);
    expect(result.updatedLevel, 2);
    expect(result.causedLevelUp, isTrue);
  });

  test('creating the service during startup does not grant XP', () async {
    final harness = _RewardHarness(initialXp: 220);

    expect(harness.createService(), isA<EventCardXpRewardService>());
    await Future<void>.delayed(Duration.zero);

    expect(harness.progress.totalXp, 220);
  });
}

class _RewardHarness {
  _RewardHarness({required int initialXp, this.playerId = 'local-explorer'})
    : progress = _progress(playerId, initialXp),
      repository = _MemoryProgressRepository(
        _progress(playerId, initialXp),
      ) {
    service = createService();
  }

  final String playerId;
  late PlayerProgress progress;
  final _MemoryProgressRepository repository;
  late EventCardXpRewardService service;

  EventCardXpRewardService createService() {
    return EventCardXpRewardService(
      localRepository: repository,
      canonicalRepository: repository,
      levelCalculator: const LevelCalculator(),
      currentSessionProgress: () => progress,
      updateSessionProgress: (value) => progress = value,
    );
  }
}

class _MemoryProgressRepository implements PlayerProgressRepository {
  _MemoryProgressRepository(this.progress);

  PlayerProgress progress;

  @override
  Future<PlayerProgress> getProgress(String playerId) async => progress;

  @override
  Future<void> saveProgress(PlayerProgress progress) async {
    this.progress = progress;
  }
}

PlayerProgress _progress(String playerId, int xp) {
  return PlayerProgress(
    playerId: playerId,
    totalXp: xp,
    level: const LevelCalculator().levelForXp(xp),
    coins: 0,
    discoveryCount: 0,
    duplicateDiscoveryCount: 0,
    achievementIds: const [],
    badgeIds: const [],
  );
}

CatCardRecord _eventCard(
  String cardId, {
  String ownerId = 'local-explorer',
  bool premium = false,
}) {
  final now = DateTime.utc(2026, 10, 31);
  return CatCardRecord(
    cardId: cardId,
    discoveryId: 'discovery-$cardId',
    ownerId: ownerId,
    cardType: CatCardType.event,
    rarity: CatRarity.rare,
    finalCardUrl: 'https://renderer.example/generated/$cardId/final-card.png',
    templateKey: 'events/halloween_2026/template',
    generationStatus: CatCardGenerationStatus.completed,
    generationRequestId: 'request-$cardId',
    idempotencyKey: 'event:$cardId',
    createdAt: now,
    updatedAt: now,
    eventKey: 'halloween_2026',
    eventEdition: '2026',
    eventArtworkVariantId: premium ? 'premium-variant' : 'free-variant',
    eventArtworkTier: premium ? 'premium' : 'free',
    eventTemplateKey: 'template',
    isPremiumArtwork: premium,
  );
}
