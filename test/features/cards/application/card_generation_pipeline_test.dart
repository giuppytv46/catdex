import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/domain/cat_card_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'normal generation persists and reads back canonical card record',
    () async {
      final discovery = _discovery();
      final discoveries = _MemoryDiscoveryRepository(discovery);
      final cards = _MemoryCatCardRepository();
      final container = _container(
        discoveries: discoveries,
        cards: cards,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .regenerateCardWithAiIllustration(
            discovery: discovery,
            displayData: _displayData,
            collectionNumber: 8,
          );

      expect(result.success, isTrue);
      expect(cards.saveCount, 1);
      expect(cards.readCount, greaterThanOrEqualTo(1));
      final record = await cards.getNormalCardForDiscovery(discovery.id);
      expect(record?.cardId, normalCardId(discovery.id));
      expect(record?.cardType, CatCardType.normal);
      expect(record?.finalCardUrl, _normalFinalUrl);
      expect(record?.displayName, 'Luna');
      expect(record?.displaySpecies, 'Gatto domestico bicolore');
      expect(discoveries.discovery?.card?.cardImageUrl, _normalFinalUrl);
    },
  );

  test(
    'normal regeneration replaces one stable record without duplicates',
    () async {
      final discovery = _discovery();
      final cards = _MemoryCatCardRepository();
      final container = _container(
        discoveries: _MemoryDiscoveryRepository(discovery),
        cards: cards,
      );
      addTearDown(container.dispose);

      final pipeline = container.read(cardGenerationPipelineProvider);
      await pipeline.regenerateCardWithAiIllustration(
        discovery: discovery,
        displayData: _displayData,
        collectionNumber: 8,
      );
      await pipeline.regenerateCardWithAiIllustration(
        discovery: discovery,
        displayData: _displayData,
        collectionNumber: 8,
      );

      expect(await cards.getCardsForDiscovery(discovery.id), hasLength(1));
      expect(cards.saveCount, 2);
    },
  );

  test(
    'failed card-record readback preserves last good discovery card',
    () async {
      final discovery = _discovery(card: _legacyNormalCard());
      final discoveries = _MemoryDiscoveryRepository(discovery);
      final cards = _MemoryCatCardRepository(failReadbackAfterSave: true);
      final container = _container(
        discoveries: discoveries,
        cards: cards,
      );
      addTearDown(container.dispose);

      final result = await container
          .read(cardGenerationPipelineProvider)
          .regenerateCardWithAiIllustration(
            discovery: discovery,
            displayData: _displayData,
            collectionNumber: 8,
          );

      expect(result.success, isFalse);
      expect(discoveries.saveCount, 0);
      expect(discoveries.discovery?.card?.cardImageUrl, _legacyFinalUrl);
    },
  );
}

ProviderContainer _container({
  required DiscoveryRepository discoveries,
  required CatCardRepository cards,
}) {
  return ProviderContainer(
    overrides: [
      discoveryRepositoryProvider.overrideWithValue(discoveries),
      catCardRepositoryProvider.overrideWithValue(cards),
      remoteCardGenerationServiceProvider.overrideWithValue(
        _NormalRemoteCardGenerationService(),
      ),
      eventRuntimeConfigurationProvider.overrideWithValue(
        const _InactiveEventRuntime(),
      ),
    ],
  );
}

class _InactiveEventRuntime extends EventRuntimeConfiguration {
  const _InactiveEventRuntime();

  @override
  CatDexEvent? activeEvent(DateTime now) => null;
}

class _NormalRemoteCardGenerationService extends RemoteCardGenerationService {
  _NormalRemoteCardGenerationService()
    : super(endpoint: 'https://renderer.example/api/generate-card');

  @override
  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    EventCardGenerationRequest? eventRequest,
    void Function(RemoteCardGenerationPendingReason)? onPending,
  }) async {
    return const RemoteGeneratedCard(
      finalCardUrl: _normalFinalUrl,
      illustratedCatUrl: 'https://renderer.example/generated/luna/cat.png',
      selectedTemplateKey: 'default/common',
      generationStatus: 'completed',
    );
  }
}

class _MemoryDiscoveryRepository implements DiscoveryRepository {
  _MemoryDiscoveryRepository(this.discovery);

  CatDiscovery? discovery;
  int saveCount = 0;

  @override
  Future<CatDiscovery?> getDiscoveryById(String id) async =>
      discovery?.id == id ? discovery : null;

  @override
  Future<List<CatDiscovery>> getDiscoveriesForPlayer(String playerId) async =>
      discovery?.playerId == playerId ? [discovery!] : const [];

  @override
  Future<bool> hasDiscoveredSpecies({
    required String playerId,
    required String speciesId,
  }) async => false;

  @override
  Future<void> saveDiscovery(CatDiscovery discovery) async {
    saveCount += 1;
    this.discovery = discovery;
  }
}

class _MemoryCatCardRepository implements CatCardRepository {
  _MemoryCatCardRepository({this.failReadbackAfterSave = false});

  final bool failReadbackAfterSave;
  final Map<String, CatCardRecord> _cards = {};
  int saveCount = 0;
  int readCount = 0;

  @override
  Future<bool> cardExists(String logicalIdentity) async {
    return _cards.values.any((card) => card.logicalIdentity == logicalIdentity);
  }

  @override
  Future<void> deleteCard(String cardId) async => _cards.remove(cardId);

  @override
  Future<List<CatCardRecord>> getAllCards() async =>
      _cards.values.toList(growable: false);

  @override
  Future<CatCardRecord?> getCardById(String cardId) async {
    readCount += 1;
    if (failReadbackAfterSave && saveCount > 0) return null;
    return _cards[cardId];
  }

  @override
  Future<List<CatCardRecord>> getCardsForDiscovery(String discoveryId) async {
    return _cards.values
        .where((card) => card.discoveryId == discoveryId)
        .toList(growable: false);
  }

  @override
  Future<List<CatCardRecord>> getEventCards(
    String eventKey,
    String eventEdition,
  ) async => const [];

  @override
  Future<CatCardRecord?> getNormalCardForDiscovery(String discoveryId) async =>
      _cards[normalCardId(discoveryId)];

  @override
  Future<void> saveCard(CatCardRecord card) async {
    saveCount += 1;
    _cards[card.cardId] = card;
  }
}

CatDiscovery _discovery({CatDiscoveryCard? card}) {
  return CatDiscovery(
    id: 'normal-discovery-1',
    playerId: 'local-explorer',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 16),
    friendshipPoints: 0,
    customName: 'Luna',
    displayPhotoPath: 'https://example.test/luna.jpg',
    card: card,
  );
}

CatDiscoveryCard _legacyNormalCard() {
  return CatDiscoveryCard(
    cardId: 'legacy-normal-card',
    discoveryId: 'normal-discovery-1',
    cardFrameStyle: 'default',
    cardBackgroundStyle: 'default',
    cardRarityStyle: 'common',
    isEventCard: false,
    originalPhotoPath: 'https://example.test/luna.jpg',
    generatedAt: DateTime.utc(2026, 7, 15),
    cardImageUrl: _legacyFinalUrl,
    cardTemplateId: 'default/common',
    generationStatus: 'completed',
  );
}

const _displayData = CatDisplayData(
  displayName: 'Luna',
  displaySpecies: 'Gatto domestico bicolore',
  displayCoatColor: 'Nero/bianco',
  displayCoatPattern: 'Bicolore',
  displayEyeColor: 'occhi ambrati',
  displayHairLength: 'Corto',
  displayAge: '-',
  displayPersonality: 'Curiosa',
  displayRarity: 'Comune',
  displayVariant: 'Normale',
  displayStory: '',
  displayFunFact: '',
);

const _normalFinalUrl =
    'https://renderer.example/generated/normal-discovery-1/final-card.png';
const _legacyFinalUrl =
    'https://renderer.example/generated/normal-discovery-1/legacy/final-card.png';
