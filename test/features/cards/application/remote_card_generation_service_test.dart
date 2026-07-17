import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Storage object path becomes HTTPS signed URL', () async {
    final signedPaths = <String>[];
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      signedPhotoUrlProvider: (storagePath) async {
        signedPaths.add(storagePath);
        return _signedPhotoUrl;
      },
    );

    final resolved = await service.resolveRendererAccessiblePhotoUrl(
      _discovery(
        originalPhotoStoragePath:
            'catdex/originals/local-explorer/discovery-1.jpg',
      ),
    );

    expect(resolved, _signedPhotoUrl);
    expect(
      signedPaths,
      ['catdex/originals/local-explorer/discovery-1.jpg'],
    );
  });

  test('localhost fallback is rejected', () async {
    final service = RemoteCardGenerationService(endpoint: _endpoint);

    final resolved = await service.resolveRendererAccessiblePhotoUrl(
      _discovery(
        displayPhotoPath:
            'http://localhost:3000/cards/test_illustrated_cat.png',
      ),
    );

    expect(resolved, isNull);
  });

  test('local iPhone path is not sent directly', () async {
    var rendererCalls = 0;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      postJson: ({required uri, required payload}) async {
        rendererCalls += 1;
        return _successfulResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(
        displayPhotoPath:
            '/var/mobile/Containers/Data/Application/UUID/Documents/cat.jpg',
      ),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNull);
    expect(rendererCalls, 0);
    expect(
      service.lastFailureReason,
      RemoteCardGenerationFailureReason.missingPhoto,
    );
  });

  test('renderer is not called without a valid HTTPS photo', () async {
    var rendererCalls = 0;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      postJson: ({required uri, required payload}) async {
        rendererCalls += 1;
        return _successfulResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(),
      displayData: _displayData,
      collectionNumber: 1,
    );

    expect(generated, isNull);
    expect(rendererCalls, 0);
  });

  test('valid signed URL is sent in photoUrl', () async {
    Map<String, Object?>? postedPayload;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      signedPhotoUrlProvider: (_) async => _signedPhotoUrl,
      postJson: ({required uri, required payload}) async {
        postedPayload = Map<String, Object?>.from(payload);
        return _successfulResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(
        originalPhotoStoragePath:
            'catdex/originals/local-explorer/discovery-1.jpg',
      ),
      displayData: _displayData,
      collectionNumber: 1,
    );

    expect(generated, isNotNull);
    expect(postedPayload?['photoUrl'], _signedPhotoUrl);
    expect(
      postedPayload?['photoUrl'],
      isNot(contains('test_illustrated_cat.png')),
    );
  });

  test(
    'normal card payload remains unchanged by optional event fields',
    () async {
      late Map<String, Object?> requestPayload;
      final service = RemoteCardGenerationService(
        endpoint: _endpoint,
        postJson: ({required uri, required payload}) async {
          requestPayload = Map<String, Object?>.from(payload);
          return _successfulResponse();
        },
      );

      await service.generateCard(
        discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
        displayData: _displayData,
        collectionNumber: 1,
      );

      expect(requestPayload['eventKey'], isNull);
      expect(requestPayload.containsKey('eventEdition'), isFalse);
      expect(requestPayload.containsKey('eventArtworkVariantId'), isFalse);
      expect(requestPayload.containsKey('eventInstructionKey'), isFalse);
      expect(requestPayload.containsKey('idempotencyKey'), isFalse);
    },
  );

  test('event payload contains only known event identifiers', () async {
    late Map<String, Object?> requestPayload;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      postJson: ({required uri, required payload}) async {
        requestPayload = Map<String, Object?>.from(payload);
        return _successfulEventResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated?.isEventCard, isTrue);
    expect(requestPayload['eventKey'], 'halloween_2026');
    expect(requestPayload['eventArtworkVariantId'], 'halloween_pumpkins');
    expect(requestPayload['eventInstructionKey'], 'halloween_pumpkins');
    expect(requestPayload['idempotencyKey'], contains('halloween_2026'));
    expect(requestPayload.containsKey('prompt'), isFalse);
    expect(requestPayload.containsKey('artworkInstructions'), isFalse);
  });

  test('event generation signs originalPhotoStoragePath', () async {
    String? signedPath;
    Map<String, Object?>? postedPayload;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      signedPhotoUrlProvider: (storagePath) async {
        signedPath = storagePath;
        return _signedPhotoUrl;
      },
      postJson: ({required uri, required payload}) async {
        postedPayload = Map<String, Object?>.from(payload);
        return _successfulEventResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(
        originalPhotoStoragePath:
            'catdex/originals/local-explorer/discovery-1.jpg',
      ),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNotNull);
    expect(
      signedPath,
      'catdex/originals/local-explorer/discovery-1.jpg',
    );
    expect(postedPayload?['photoUrl'], _signedPhotoUrl);
  });

  test('event local photo upload persists stable storage path', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catdex_event_photo_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/luna.jpg');
    await photo.writeAsBytes(const [1, 2, 3]);
    String? persistedStoragePath;
    String? postedPhotoUrl;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      localPhotoUploadProvider:
          ({required discovery, required sourcePath}) async {
            expect(sourcePath, photo.path);
            return _signedPhotoUrl;
          },
      persistPhotoStoragePath:
          ({required discovery, required storagePath}) async {
            persistedStoragePath = storagePath;
            return true;
          },
      postJson: ({required uri, required payload}) async {
        postedPhotoUrl = payload['photoUrl'] as String?;
        return _successfulEventResponse();
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: photo.path),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNotNull);
    expect(postedPhotoUrl, _signedPhotoUrl);
    expect(
      persistedStoragePath,
      'catdex/originals/local-explorer/discovery-1.jpg',
    );
    expect(generated?.originalPhotoStoragePath, persistedStoragePath);
  });

  test('relative local photo is rebuilt before event upload', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catdex_relative_photo_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/original_discovery-1.jpg');
    await photo.writeAsBytes(const [1, 2, 3]);
    String? uploadedSource;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      localPhotoPathResolver: (storedPath) async {
        expect(storedPath, 'catdex/originals/original_discovery-1.jpg');
        return photo.path;
      },
      localPhotoUploadProvider:
          ({required discovery, required sourcePath}) async {
            uploadedSource = sourcePath;
            return _signedPhotoUrl;
          },
      persistPhotoStoragePath:
          ({required discovery, required storagePath}) async => true,
      postJson: ({required uri, required payload}) async =>
          _successfulEventResponse(),
    );

    final generated = await service.generateCard(
      discovery: _discovery(
        displayPhotoPath: 'catdex/originals/original_discovery-1.jpg',
      ),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNotNull);
    expect(uploadedSource, photo.path);
  });

  test('repeated generation reuses persisted photo object', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catdex_reused_photo_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final photo = File('${directory.path}/luna.jpg');
    await photo.writeAsBytes(const [1, 2, 3]);
    var uploadCalls = 0;
    var rendererCalls = 0;
    String? persistedStoragePath;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      signedPhotoUrlProvider: (_) async => _signedPhotoUrl,
      localPhotoUploadProvider:
          ({required discovery, required sourcePath}) async {
            uploadCalls += 1;
            return _signedPhotoUrl;
          },
      persistPhotoStoragePath:
          ({required discovery, required storagePath}) async {
            persistedStoragePath = storagePath;
            return true;
          },
      postJson: ({required uri, required payload}) async {
        rendererCalls += 1;
        return _successfulEventResponse();
      },
    );

    await service.generateCard(
      discovery: _discovery(displayPhotoPath: photo.path),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );
    await service.generateCard(
      discovery: _discovery(
        originalPhotoStoragePath: persistedStoragePath,
      ),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(uploadCalls, 1);
    expect(rendererCalls, 2);
  });

  test(
    'guest upload permission failure blocks renderer with typed error',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'catdex_denied_photo_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final photo = File('${directory.path}/luna.jpg');
      await photo.writeAsBytes(const [1, 2, 3]);
      var rendererCalls = 0;
      final service = RemoteCardGenerationService(
        endpoint: _endpoint,
        localPhotoUploadProvider:
            ({required discovery, required sourcePath}) async {
              throw const StorageException('Forbidden', statusCode: '403');
            },
        postJson: ({required uri, required payload}) async {
          rendererCalls += 1;
          return _successfulEventResponse();
        },
      );

      final generated = await service.generateCard(
        discovery: _discovery(displayPhotoPath: photo.path),
        displayData: _displayData,
        collectionNumber: 1,
        eventRequest: _eventRequest,
      );

      expect(generated, isNull);
      expect(rendererCalls, 0);
      expect(
        service.lastFailureReason,
        RemoteCardGenerationFailureReason.storagePermissionDenied,
      );
    },
  );

  test('event response metadata mismatch is rejected', () async {
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      postJson: ({required uri, required payload}) async {
        return _successfulEventResponse(variantId: 'halloween_moonlight');
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNull);
    expect(
      service.lastEventFailure,
      EventCardGenerationFailure.eventPersistenceFailed,
    );
  });

  test('event 504 recovery reuses the same idempotency payload', () async {
    final idempotencyKeys = <Object?>[];
    final responses = <RemoteCardGenerationHttpResponse>[
      _errorResponse(504, 'CARD_GENERATION_TIMEOUT'),
      _successfulEventResponse(),
    ];
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      recoveryDelays: const [Duration.zero],
      recoveryDelay: (_) async {},
      postJson: ({required uri, required payload}) async {
        idempotencyKeys.add(payload['idempotencyKey']);
        return responses.removeAt(0);
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
      eventRequest: _eventRequest,
    );

    expect(generated, isNotNull);
    expect(idempotencyKeys, hasLength(2));
    expect(idempotencyKeys.toSet(), hasLength(1));
  });

  test('409 followed by 200 recovers without consuming credit early', () async {
    final monetization = await _exhaustedMonetizationWithOneCredit();
    expect(
      await monetization.reserveCardGenerationCredit('discovery-1'),
      CardGenerationCreditReservationResult.reserved,
    );
    final responses = <RemoteCardGenerationHttpResponse>[
      _errorResponse(409, 'CARD_RENDER_IN_PROGRESS'),
      _successfulResponse(),
    ];
    var calls = 0;
    final pendingReasons = <RemoteCardGenerationPendingReason>[];
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      recoveryDelays: const [Duration.zero],
      recoveryDelay: (_) async {},
      postJson: ({required uri, required payload}) async {
        calls += 1;
        if (calls == 2) {
          final status = await monetization.getStatus();
          expect(status.extraCardGenerationCredits, 1);
        }
        return responses.removeAt(0);
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
      onPending: pendingReasons.add,
    );

    expect(generated, isNotNull);
    expect(calls, 2);
    expect(
      pendingReasons,
      [RemoteCardGenerationPendingReason.renderInProgress],
    );
    expect(
      await monetization.commitCardGenerationCredit('discovery-1'),
      isTrue,
    );
    expect(
      (await monetization.getStatus()).extraCardGenerationCredits,
      0,
    );
  });

  test('504 followed by 200 recovers without consuming credit early', () async {
    final monetization = await _exhaustedMonetizationWithOneCredit();
    await monetization.reserveCardGenerationCredit('discovery-1');
    final responses = <RemoteCardGenerationHttpResponse>[
      _errorResponse(504, 'CARD_GENERATION_TIMEOUT'),
      _successfulResponse(),
    ];
    var calls = 0;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      recoveryDelays: const [Duration.zero],
      recoveryDelay: (_) async {},
      postJson: ({required uri, required payload}) async {
        calls += 1;
        if (calls == 2) {
          expect(
            (await monetization.getStatus()).extraCardGenerationCredits,
            1,
          );
        }
        return responses.removeAt(0);
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
    );

    expect(generated, isNotNull);
    expect(calls, 2);
    await monetization.commitCardGenerationCredit('discovery-1');
    expect(
      (await monetization.getStatus()).extraCardGenerationCredits,
      0,
    );
  });

  test('permanent 400 does not retry or consume reserved credit', () async {
    final monetization = MonetizationService(() {});
    final before = await monetization.getStatus();
    await monetization.reserveCardGenerationCredit('discovery-1');
    var calls = 0;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      recoveryDelays: const [Duration.zero],
      recoveryDelay: (_) async {},
      postJson: ({required uri, required payload}) async {
        calls += 1;
        return _errorResponse(400, 'INVALID_INPUT');
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
    );
    monetization.releaseCardGenerationCredit('discovery-1');
    final after = await monetization.getStatus();

    expect(generated, isNull);
    expect(calls, 1);
    expect(after.dailyCardGenerationCount, before.dailyCardGenerationCount);
    expect(after.extraCardGenerationCredits, before.extraCardGenerationCredits);
  });

  test('recovery exhaustion releases credit without consumption', () async {
    final monetization = await _exhaustedMonetizationWithOneCredit();
    expect(
      await monetization.reserveCardGenerationCredit('discovery-1'),
      CardGenerationCreditReservationResult.reserved,
    );
    expect(
      await monetization.reserveCardGenerationCredit('discovery-1'),
      CardGenerationCreditReservationResult.duplicate,
    );
    var calls = 0;
    final service = RemoteCardGenerationService(
      endpoint: _endpoint,
      recoveryDelays: const [Duration.zero],
      recoveryDelay: (_) async {},
      postJson: ({required uri, required payload}) async {
        calls += 1;
        return _errorResponse(409, 'CARD_RENDER_IN_PROGRESS');
      },
    );

    final generated = await service.generateCard(
      discovery: _discovery(displayPhotoPath: _signedPhotoUrl),
      displayData: _displayData,
      collectionNumber: 1,
    );
    monetization.releaseCardGenerationCredit('discovery-1');

    expect(generated, isNull);
    expect(calls, 2);
    expect(
      (await monetization.getStatus()).extraCardGenerationCredits,
      1,
    );
  });
}

Future<MonetizationService> _exhaustedMonetizationWithOneCredit() async {
  final monetization = MonetizationService(() {});
  for (var i = 0; i < MonetizationService.freeDailyCardGenerationLimit; i++) {
    expect(await monetization.consumeCardGeneration(), isTrue);
  }
  await monetization.addCardGenerationCredits(1);
  return monetization;
}

RemoteCardGenerationHttpResponse _successfulResponse() {
  return RemoteCardGenerationHttpResponse(
    statusCode: 200,
    bytes: utf8.encode(
      jsonEncode({
        'finalCardUrl':
            'https://renderer.example/generated/discovery-1/final-card.png',
      }),
    ),
  );
}

RemoteCardGenerationHttpResponse _successfulEventResponse({
  String variantId = 'halloween_pumpkins',
}) {
  return RemoteCardGenerationHttpResponse(
    statusCode: 200,
    bytes: utf8.encode(
      jsonEncode({
        'finalCardUrl':
            'https://renderer.example/generated/discovery-1/final-card.png',
        'illustratedCatUrl':
            'https://renderer.example/generated/discovery-1/illustrated-cat.png',
        'selectedTemplateKey': 'events/halloween_2026/halloween_pumpkins',
        'templateKey': 'halloween_pumpkins',
        'eventKey': 'halloween_2026',
        'eventEdition': '2026',
        'eventArtworkVariantId': variantId,
        'eventArtworkTier': 'free',
        'eventTemplateKey': 'halloween_pumpkins',
        'isEventCard': true,
        'generationStatus': 'completed',
      }),
    ),
  );
}

RemoteCardGenerationHttpResponse _errorResponse(
  int statusCode,
  String error,
) {
  return RemoteCardGenerationHttpResponse(
    statusCode: statusCode,
    bytes: utf8.encode(jsonEncode({'success': false, 'error': error})),
  );
}

CatDiscovery _discovery({
  String? displayPhotoPath,
  String? originalPhotoStoragePath,
}) {
  return CatDiscovery(
    id: 'discovery-1',
    playerId: 'local-explorer',
    speciesId: 'domestic_cat',
    variantId: 'normal',
    rarity: CatRarity.common,
    personality: CatPersonality.curious,
    traits: const [],
    discoveredAt: DateTime.utc(2026, 7, 13),
    friendshipPoints: 0,
    customName: 'Luna',
    suggestedName: 'Luna',
    displayPhotoPath: displayPhotoPath,
    originalPhotoStoragePath: originalPhotoStoragePath,
  );
}

const _endpoint = 'https://renderer.example/api/generate-card';
const _signedPhotoUrl =
    'https://catdex.supabase.co/storage/v1/object/sign/cat-photos/'
    'catdex/originals/local-explorer/discovery-1.jpg?token=signed';

const _eventRequest = EventCardGenerationRequest(
  eventKey: 'halloween_2026',
  eventEdition: '2026',
  variantId: 'halloween_pumpkins',
  tier: EventArtworkTier.free,
  templateKey: 'halloween_pumpkins',
  instructionKey: 'halloween_pumpkins',
  generationRequestId: 'request-1',
);

const _displayData = CatDisplayData(
  displayName: 'Luna',
  displaySpecies: 'Gatto domestico bicolore',
  displayCoatColor: 'Nero/bianco',
  displayCoatPattern: 'Bicolore',
  displayEyeColor: 'occhi ambrati',
  displayHairLength: 'Pelo corto',
  displayAge: 'Adulto',
  displayPersonality: 'Curioso',
  displayRarity: 'Comune',
  displayVariant: 'Normale',
  displayStory: 'Luna entra nel CatDex.',
  displayFunFact: 'Ogni mantello bicolore e unico.',
);
