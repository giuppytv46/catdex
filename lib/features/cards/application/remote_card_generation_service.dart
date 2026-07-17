import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/cards/application/card_generation_performance.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/domain/entities/event_card_generation.dart';
import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef CardPhotoSignedUrlProvider =
    Future<String?> Function(
      String storagePath,
    );

typedef CardPhotoLocalUploadProvider =
    Future<String?> Function({
      required CatDiscovery discovery,
      required String sourcePath,
    });

typedef CardPhotoStoragePathPersister =
    Future<bool> Function({
      required CatDiscovery discovery,
      required String storagePath,
    });

typedef CardPhotoLocalPathResolver =
    Future<String?> Function(String storedPath);

typedef RemoteCardPostJson =
    Future<RemoteCardGenerationHttpResponse> Function({
      required Uri uri,
      required Map<String, Object?> payload,
    });

typedef CardGenerationRecoveryDelay = Future<void> Function(Duration delay);

enum RemoteCardGenerationPendingReason {
  renderInProgress,
  generationTimeout,
}

final remoteCardGenerationServiceProvider =
    Provider<RemoteCardGenerationService>((ref) {
      final supabaseConfigured = ref.watch(supabaseConfiguredProvider);
      return RemoteCardGenerationService(
        supabaseClient: supabaseConfigured
            ? ref.watch(supabaseClientProvider)
            : null,
        persistPhotoStoragePath: ({required discovery, required storagePath}) {
          return _persistResolvedPhotoStoragePath(
            ref,
            discovery: discovery,
            storagePath: storagePath,
          );
        },
      );
    });

Future<bool> _persistResolvedPhotoStoragePath(
  Ref ref, {
  required CatDiscovery discovery,
  required String storagePath,
}) async {
  final updated = discovery.copyWithPhotoPaths(
    originalPhotoStoragePath: storagePath,
  );
  final repository = ref.read(discoveryRepositoryProvider);
  try {
    await repository.saveDiscovery(updated);
    final readBack = await repository.getDiscoveryById(discovery.id);
    if (readBack?.originalPhotoStoragePath != storagePath) {
      debugPrint('CATDEX_EVENT_PHOTO_STORAGE_PATH_PERSISTED false');
      return false;
    }
    ref
        .read(localDiscoverySessionProvider.notifier)
        .replaceDiscovery(readBack!);
    debugPrint('CATDEX_EVENT_PHOTO_STORAGE_PATH_PERSISTED true');
    return true;
  } on Object catch (error) {
    debugPrint(
      'CATDEX_EVENT_PHOTO_STORAGE_PATH_PERSISTED false '
      'error=${error.runtimeType}',
    );
    return false;
  }
}

class RemoteGeneratedCard {
  const RemoteGeneratedCard({
    required this.finalCardUrl,
    this.illustratedCatUrl,
    this.selectedTemplateKey,
    this.analysisJson,
    this.eventKey,
    this.eventEdition,
    this.eventArtworkVariantId,
    this.eventArtworkTier,
    this.eventTemplateKey,
    this.generationStatus,
    this.originalPhotoStoragePath,
    this.isEventCard = false,
  });

  final String finalCardUrl;
  final String? illustratedCatUrl;
  final String? selectedTemplateKey;
  final Map<String, Object?>? analysisJson;
  final String? eventKey;
  final String? eventEdition;
  final String? eventArtworkVariantId;
  final String? eventArtworkTier;
  final String? eventTemplateKey;
  final String? generationStatus;
  final String? originalPhotoStoragePath;
  final bool isEventCard;
}

enum RemoteCardGenerationFailureReason {
  missingEndpoint,
  invalidPhotoUrl,
  missingPhoto,
  photoUploadFailed,
  storagePermissionDenied,
  signedUrlFailed,
  network,
  remoteApiFailure,
}

enum RemoteCardPhotoSource { existingHttps, storagePath, localUpload }

enum RemoteCardPhotoFailureReason {
  missingPhoto,
  photoUploadFailed,
  storagePermissionDenied,
  signedUrlFailed,
  network,
}

class RemoteCardPhotoResolution {
  const RemoteCardPhotoResolution._({
    this.httpsUrl,
    this.source,
    this.storagePath,
    this.failureReason,
  });

  const RemoteCardPhotoResolution.success({
    required String httpsUrl,
    required RemoteCardPhotoSource source,
    String? storagePath,
  }) : this._(
         httpsUrl: httpsUrl,
         source: source,
         storagePath: storagePath,
       );

  const RemoteCardPhotoResolution.failure(
    RemoteCardPhotoFailureReason reason,
  ) : this._(failureReason: reason);

  final String? httpsUrl;
  final RemoteCardPhotoSource? source;
  final String? storagePath;
  final RemoteCardPhotoFailureReason? failureReason;

  bool get isSuccess => httpsUrl != null && failureReason == null;
}

class RemoteCardGenerationService {
  RemoteCardGenerationService({
    SupabaseClient? supabaseClient,
    String endpoint = const String.fromEnvironment('CARD_GENERATION_API_URL'),
    CardPhotoSignedUrlProvider? signedPhotoUrlProvider,
    CardPhotoLocalUploadProvider? localPhotoUploadProvider,
    CardPhotoStoragePathPersister? persistPhotoStoragePath,
    CardPhotoLocalPathResolver? localPhotoPathResolver,
    RemoteCardPostJson? postJson,
    List<Duration> recoveryDelays = const [
      Duration(seconds: 10),
      Duration(seconds: 15),
      Duration(seconds: 20),
    ],
    CardGenerationRecoveryDelay? recoveryDelay,
  }) : _endpoint = endpoint,
       _supabaseClient = supabaseClient,
       _signedPhotoUrlProvider = signedPhotoUrlProvider,
       _localPhotoUploadProvider = localPhotoUploadProvider,
       _persistPhotoStoragePath = persistPhotoStoragePath,
       _localPhotoPathResolver =
           localPhotoPathResolver ??
           CatDexPersistedPhotoPath.rebuildAbsolutePath,
       _postJsonOverride = postJson,
       _recoveryDelays = List<Duration>.unmodifiable(recoveryDelays),
       _recoveryDelay = recoveryDelay ?? Future<void>.delayed;

  static const String _bucketName =
      SupabaseCatPhotoStorageRepository.catPhotosBucketName;

  final String _endpoint;
  final SupabaseClient? _supabaseClient;
  final CardPhotoSignedUrlProvider? _signedPhotoUrlProvider;
  final CardPhotoLocalUploadProvider? _localPhotoUploadProvider;
  final CardPhotoStoragePathPersister? _persistPhotoStoragePath;
  final CardPhotoLocalPathResolver _localPhotoPathResolver;
  final RemoteCardPostJson? _postJsonOverride;
  final List<Duration> _recoveryDelays;
  final CardGenerationRecoveryDelay _recoveryDelay;
  RemoteCardGenerationFailureReason? _lastFailureReason;
  EventCardGenerationFailure? _lastEventFailure;

  RemoteCardGenerationFailureReason? get lastFailureReason =>
      _lastFailureReason;

  bool get isConfigured {
    final uri = Uri.tryParse(_endpoint.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  EventCardGenerationFailure? get lastEventFailure => _lastEventFailure;

  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    EventCardGenerationRequest? eventRequest,
    ValueChanged<RemoteCardGenerationPendingReason>? onPending,
  }) async {
    _lastFailureReason = null;
    _lastEventFailure = null;
    debugPrint('CATDEX_REMOTE_GENERATE_CARD_STARTED ${discovery.id}');
    debugPrint(
      'CATDEX_REMOTE_GENERATE_CARD_ENDPOINT ${_logValue(_endpoint)}',
    );

    if (_endpoint.trim().isEmpty) {
      _lastFailureReason = RemoteCardGenerationFailureReason.missingEndpoint;
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_MISSING_URL');
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
      return null;
    }

    try {
      final endpointUri = Uri.parse(_endpoint);
      if (eventRequest != null) {
        debugPrint(
          'CATDEX_EVENT_PHOTO_RESOLUTION_STARTED discoveryId=${discovery.id}',
        );
      }
      final photoResolution = await resolveRendererPhoto(
        discovery,
        eventGeneration: eventRequest != null,
      );
      final photoUrl = photoResolution.httpsUrl;
      final photoUrlValid = _isValidRendererPhotoUrl(photoUrl);
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL ${_logUrl(photoUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL_VALID $photoUrlValid',
      );

      if (!photoUrlValid) {
        final safeReason =
            photoResolution.failureReason ??
            RemoteCardPhotoFailureReason.missingPhoto;
        _lastFailureReason = _generationFailureForPhoto(safeReason);
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR ${safeReason.name}');
        debugPrint(
          'CATDEX_CARD_RENDERER_REQUEST_BLOCKED_NO_REMOTE_PHOTO '
          'reason=${safeReason.name}',
        );
        if (eventRequest != null) {
          debugPrint(
            'CATDEX_EVENT_PHOTO_RESOLUTION_FAILED reason=${safeReason.name}',
          );
          debugPrint(
            'CATDEX_EVENT_RENDERER_CALL_BLOCKED reason=${safeReason.name}',
          );
        }
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      if (eventRequest != null) {
        debugPrint(
          'CATDEX_EVENT_PHOTO_SOURCE '
          '${_photoSourceName(photoResolution.source!)}',
        );
        debugPrint(
          'CATDEX_EVENT_PHOTO_STORAGE_PATH '
          '${_logValue(photoResolution.storagePath)}',
        );
        if (photoResolution.source == RemoteCardPhotoSource.storagePath ||
            photoResolution.source == RemoteCardPhotoSource.localUpload) {
          debugPrint('CATDEX_EVENT_PHOTO_SIGNED_URL_SUCCESS true');
        }
      }

      final rarity = _rarity(discovery, debugRarityOverride);
      if (debugRarityOverride != null) {
        debugPrint('CATDEX_DEBUG_RARITY_OVERRIDE_ENABLED true');
        debugPrint(
          'CATDEX_DEBUG_RARITY_OVERRIDE_SELECTED_VALUE $rarity',
        );
      }
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_PAYLOAD_RARITY $rarity');
      debugPrint('CATDEX_REMOTE_CARD_GENERATION_REQUEST_STARTED');
      debugPrint(
        'CATDEX_REMOTE_CARD_GENERATION_DISCOVERY_ID ${discovery.id}',
      );
      debugPrint(
        'CATDEX_REMOTE_CARD_GENERATION_ORIGINAL_PHOTO '
        '${_logUrl(discovery.originalPhotoPath ?? discovery.photoPath)}',
      );
      debugPrint('CATDEX_REMOTE_CARD_GENERATION_RARITY $rarity');
      debugPrint(
        'CATDEX_REMOTE_CARD_GENERATION_NAME ${displayData.displayName}',
      );

      final payload = <String, Object?>{
        'discoveryId': discovery.id,
        'photoUrl': photoUrl,
        'rarity': rarity,
        'eventKey': null,
        'displayName': displayData.displayName,
        'displaySpecies': displayData.displaySpecies,
        'displayCoatColor': displayData.displayCoatColor,
        'displayCoatPattern': displayData.displayCoatPattern,
        'displayEyeColor': displayData.displayEyeColor,
        'displayHairLength': displayData.displayHairLength,
        'displayPersonality': displayData.displayPersonality,
        'displayRarity': displayData.displayRarity,
        'displayStory': displayData.displayStory,
        'displayFunFact': displayData.displayFunFact,
      };
      if (eventRequest != null) {
        payload
          ..addAll(eventRequest.toPayload())
          ..['idempotencyKey'] = eventRequest.idempotencyKey(discovery.id);
        debugPrint('CATDEX_EVENT_CARD_REQUEST_STARTED');
        debugPrint('CATDEX_EVENT_CARD_EVENT_KEY ${eventRequest.eventKey}');
        debugPrint('CATDEX_EVENT_CARD_VARIANT ${eventRequest.variantId}');
        debugPrint('CATDEX_EVENT_CARD_TIER ${eventRequest.tier.wireValue}');
        debugPrint('CATDEX_EVENT_CARD_RENDERER_STARTED');
      }
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_DISPLAY_NAME '
        '${displayData.displayName}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_DISPLAY_SPECIES '
        '${displayData.displaySpecies}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_DISPLAY_COAT '
        '${displayData.displayCoatColor}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_DISPLAY_PATTERN '
        '${displayData.displayCoatPattern}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PAYLOAD '
        '${jsonEncode(_payloadForLog(payload))}',
      );

      final recoveredResponse = await _postJsonWithRecovery(
        uri: endpointUri,
        payload: payload,
        onPending: onPending,
      );
      if (recoveredResponse == null) {
        return null;
      }
      final response = recoveredResponse.response;

      final decoded = Map<String, Object?>.from(
        jsonDecode(utf8.decode(response.bytes)) as Map,
      );
      debugPrint(
        'CATDEX_REMOTE_CARD_GENERATION_RESPONSE ${jsonEncode(decoded)}',
      );
      final rawFinalCardUrl = _rawFinalCardUrl(decoded);
      final finalCardUrl = _absoluteUrl(rawFinalCardUrl, endpointUri);
      final illustratedCatUrl = _absoluteUrl(
        decoded['illustratedCatUrl'] as String?,
        endpointUri,
      );
      final selectedTemplateKey = decoded['selectedTemplateKey'] as String?;
      final responseEventKey = decoded['eventKey'] as String?;
      final responseEventEdition = decoded['eventEdition'] as String?;
      final responseVariantId = decoded['eventArtworkVariantId'] as String?;
      final responseTier = decoded['eventArtworkTier'] as String?;
      final responseTemplateKey =
          (decoded['eventTemplateKey'] ?? decoded['templateKey']) as String?;
      final responseIsEventCard = decoded['isEventCard'] as bool? ?? false;
      final generationStatus = decoded['generationStatus'] as String?;
      final analysisRaw = decoded['analysisJson'];
      final analysisJson = analysisRaw is Map
          ? Map<String, Object?>.from(analysisRaw)
          : null;

      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_FINAL_URL_RAW '
        '${_logValue(rawFinalCardUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_FINAL_URL_NORMALIZED '
        '${_logValue(finalCardUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_FINAL_URL ${_logValue(finalCardUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_CARD_GENERATION_FINAL_URL ${_logValue(finalCardUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_ILLUSTRATED_URL '
        '${_logValue(illustratedCatUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_TEMPLATE '
        '${_logValue(selectedTemplateKey)}',
      );

      if (!_isAccessibleUrl(finalCardUrl)) {
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR missing_finalCardUrl');
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      if (eventRequest != null &&
          !_eventResponseMatches(
            request: eventRequest,
            eventKey: responseEventKey,
            eventEdition: responseEventEdition,
            variantId: responseVariantId,
            tier: responseTier,
            templateKey: responseTemplateKey,
            isEventCard: responseIsEventCard,
            generationStatus: generationStatus,
          )) {
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        _lastEventFailure = EventCardGenerationFailure.eventPersistenceFailed;
        debugPrint(
          'CATDEX_EVENT_CARD_BLOCKED reason=response_metadata_mismatch',
        );
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      if (_looksLikeOriginalPhotoResult(
        finalCardUrl: finalCardUrl!,
        photoUrl: photoUrl!,
        discovery: discovery,
      )) {
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        debugPrint('CATDEX_CARD_IMAGE_REJECTED_ORIGINAL_PHOTO_PATH');
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      if (recoveredResponse.recovered) {
        debugPrint('CATDEX_CARD_GENERATION_RECOVERY_SUCCESS');
      }
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS true');
      return RemoteGeneratedCard(
        finalCardUrl: finalCardUrl,
        illustratedCatUrl: illustratedCatUrl,
        selectedTemplateKey: selectedTemplateKey,
        analysisJson: analysisJson,
        eventKey: responseEventKey,
        eventEdition: responseEventEdition,
        eventArtworkVariantId: responseVariantId,
        eventArtworkTier: responseTier,
        eventTemplateKey: responseTemplateKey,
        generationStatus: generationStatus,
        originalPhotoStoragePath: photoResolution.storagePath,
        isEventCard: responseIsEventCard,
      );
    } on Object catch (error) {
      _lastFailureReason = error is SocketException || error is HttpException
          ? RemoteCardGenerationFailureReason.network
          : RemoteCardGenerationFailureReason.remoteApiFailure;
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR $error');
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
      return null;
    }
  }

  bool _eventResponseMatches({
    required EventCardGenerationRequest request,
    required String? eventKey,
    required String? eventEdition,
    required String? variantId,
    required String? tier,
    required String? templateKey,
    required bool isEventCard,
    required String? generationStatus,
  }) {
    return isEventCard &&
        eventKey == request.eventKey &&
        eventEdition == request.eventEdition &&
        variantId == request.variantId &&
        tier == request.tier.wireValue &&
        templateKey == request.templateKey &&
        generationStatus == 'completed';
  }

  Future<String?> resolveRendererAccessiblePhotoUrl(
    CatDiscovery discovery,
  ) async {
    return (await resolveRendererPhoto(discovery)).httpsUrl;
  }

  Future<RemoteCardPhotoResolution> resolveRendererPhoto(
    CatDiscovery discovery, {
    bool eventGeneration = false,
  }) async {
    final cardOriginal = discovery.card?.originalPhotoPath;
    final display = discovery.displayPhotoPath;
    final original = discovery.originalPhotoPath;
    final photoPath = discovery.photoPath;
    final originalStoragePath = discovery.originalPhotoStoragePath;

    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_CARD_ORIGINAL '
      '${_logUrl(cardOriginal)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_DISPLAY ${_logUrl(display)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_ORIGINAL ${_logUrl(original)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_PHOTO_PATH ${_logUrl(photoPath)}',
    );
    debugPrint(
      'CATDEX_CARD_PHOTO_STORAGE_PATH ${_logValue(originalStoragePath)}',
    );

    final directCandidates = [
      _PhotoSourceCandidate('card_original', cardOriginal),
      _PhotoSourceCandidate('display', display),
      _PhotoSourceCandidate('original', original),
      _PhotoSourceCandidate('photo_path', photoPath),
    ];

    for (final candidate in directCandidates) {
      final value = candidate.value;
      if (_isValidRendererPhotoUrl(value)) {
        final selected = value!.trim();
        _logSelectedPhoto(selected, source: candidate.kind);
        return RemoteCardPhotoResolution.success(
          httpsUrl: selected,
          source: RemoteCardPhotoSource.existingHttps,
        );
      }
    }

    RemoteCardPhotoFailureReason? strongestFailure;
    final storageCandidates = <String?>[
      originalStoragePath,
      ...directCandidates.map((candidate) => candidate.value),
    ];
    final attemptedStoragePaths = <String>{};
    for (final storagePath in storageCandidates) {
      final normalized = storagePath?.trim();
      if (normalized == null ||
          !attemptedStoragePaths.add(normalized) ||
          !_isSupabaseStorageObjectPath(normalized)) {
        continue;
      }
      debugPrint('CATDEX_CARD_PHOTO_STORAGE_PATH $normalized');
      final signed = await _tryCreateSignedPhotoUrl(normalized);
      if (signed.url != null) {
        if (eventGeneration) {
          debugPrint('CATDEX_EVENT_PHOTO_UPLOAD_REUSED_EXISTING true');
        }
        _logSelectedPhoto(signed.url!, source: 'signed_url');
        return RemoteCardPhotoResolution.success(
          httpsUrl: signed.url!,
          source: RemoteCardPhotoSource.storagePath,
          storagePath: normalized,
        );
      }
      strongestFailure = _strongerPhotoFailure(
        strongestFailure,
        signed.failureReason,
      );
    }

    for (final candidate in directCandidates) {
      final localPath = await _resolveLocalFilePath(candidate.value);
      if (localPath == null) continue;
      final file = File(localPath);
      final exists = file.existsSync();
      debugPrint(
        'CATDEX_REMOTE_PHOTO_LOCAL_FILE_EXISTS $exists path=$localPath',
      );
      if (!exists) continue;

      final uploaded = await _tryUploadLocalPhoto(
        discovery: discovery,
        sourcePath: localPath,
        eventGeneration: eventGeneration,
      );
      if (uploaded.isSuccess) {
        _logSelectedPhoto(
          uploaded.httpsUrl!,
          source: 'uploaded_local_file',
        );
        return uploaded;
      }
      strongestFailure = _strongerPhotoFailure(
        strongestFailure,
        uploaded.failureReason,
      );
    }

    debugPrint('CATDEX_CARD_PHOTO_SELECTED -');
    debugPrint('CATDEX_CARD_PHOTO_SELECTED_VALID false');
    return RemoteCardPhotoResolution.failure(
      strongestFailure ?? RemoteCardPhotoFailureReason.missingPhoto,
    );
  }

  Future<_PhotoUrlAttempt> _tryCreateSignedPhotoUrl(
    String? storagePath,
  ) async {
    if (storagePath == null || storagePath.trim().isEmpty) {
      return const _PhotoUrlAttempt.failure(
        RemoteCardPhotoFailureReason.signedUrlFailed,
      );
    }
    final normalized = storagePath.trim();
    if (!_isSupabaseStorageObjectPath(normalized)) {
      return const _PhotoUrlAttempt.failure(
        RemoteCardPhotoFailureReason.signedUrlFailed,
      );
    }

    debugPrint('CATDEX_CARD_PHOTO_SIGNED_URL_STARTED $normalized');
    debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_STARTED $normalized');
    final signedUrlTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_SIGNED_URL_CREATION',
      detail: 'storagePath=$normalized',
    );
    try {
      final provider = _signedPhotoUrlProvider;
      final client = _supabaseClient;
      final signedUrl = provider != null
          ? await provider(normalized)
          : client == null
          ? null
          : await client.storage
                .from(_bucketName)
                .createSignedUrl(normalized, 60 * 60 * 24);
      final valid = _isValidRendererPhotoUrl(signedUrl);
      debugPrint(
        'CATDEX_CARD_PHOTO_SIGNED_URL_SUCCESS '
        '${valid ? 'true' : 'false'}',
      );
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS $valid');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL ${_logUrl(signedUrl)}');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR -');
      return valid
          ? _PhotoUrlAttempt.success(signedUrl!)
          : const _PhotoUrlAttempt.failure(
              RemoteCardPhotoFailureReason.signedUrlFailed,
            );
    } on Object catch (error) {
      final reason = _photoFailureForError(
        error,
        fallback: RemoteCardPhotoFailureReason.signedUrlFailed,
      );
      debugPrint('CATDEX_CARD_PHOTO_SIGNED_URL_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL -');
      debugPrint(
        'CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR reason=${reason.name} '
        'type=${error.runtimeType}',
      );
      return _PhotoUrlAttempt.failure(reason);
    } finally {
      signedUrlTiming.finish();
    }
  }

  Future<RemoteCardPhotoResolution> _tryUploadLocalPhoto({
    required CatDiscovery discovery,
    required String sourcePath,
    required bool eventGeneration,
  }) async {
    final file = File(sourcePath);

    final playerId = discovery.playerId.trim().isEmpty
        ? 'local-explorer'
        : discovery.playerId.trim();
    final storagePath = 'catdex/originals/$playerId/${discovery.id}.jpg';
    debugPrint('CATDEX_REMOTE_PHOTO_LOCAL_FILE_FOUND $sourcePath');
    debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_STARTED $sourcePath');
    if (eventGeneration) {
      debugPrint(
        'CATDEX_EVENT_PHOTO_UPLOAD_STARTED storagePath=$storagePath',
      );
    }
    final client = _supabaseClient;
    final uploadProvider = _localPhotoUploadProvider;
    try {
      String? providerResult;
      if (uploadProvider != null) {
        providerResult = await uploadProvider(
          discovery: discovery,
          sourcePath: sourcePath,
        );
      } else {
        if (client == null) {
          debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS false');
          debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL -');
          return const RemoteCardPhotoResolution.failure(
            RemoteCardPhotoFailureReason.photoUploadFailed,
          );
        }
        final bytes = Uint8List.fromList(await file.readAsBytes());
        await client.storage
            .from(_bucketName)
            .uploadBinary(
              storagePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
      }

      final uploadedStoragePath =
          providerResult != null &&
              _isSupabaseStorageObjectPath(providerResult.trim())
          ? providerResult.trim()
          : storagePath;
      var signedUrl = _isValidRendererPhotoUrl(providerResult)
          ? providerResult!.trim()
          : null;
      if (signedUrl == null) {
        final signed = await _tryCreateSignedPhotoUrl(uploadedStoragePath);
        if (signed.url == null) {
          return RemoteCardPhotoResolution.failure(
            signed.failureReason ??
                RemoteCardPhotoFailureReason.signedUrlFailed,
          );
        }
        signedUrl = signed.url;
      }

      final persister = _persistPhotoStoragePath;
      if (persister != null) {
        final persisted = await persister(
          discovery: discovery,
          storagePath: uploadedStoragePath,
        );
        if (!persisted) {
          return const RemoteCardPhotoResolution.failure(
            RemoteCardPhotoFailureReason.photoUploadFailed,
          );
        }
      }

      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS true');
      debugPrint(
        'CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL ${_logUrl(signedUrl)}',
      );
      if (eventGeneration) {
        debugPrint(
          'CATDEX_EVENT_PHOTO_UPLOAD_SUCCESS storagePath=$uploadedStoragePath',
        );
      }
      return RemoteCardPhotoResolution.success(
        httpsUrl: signedUrl!,
        source: RemoteCardPhotoSource.localUpload,
        storagePath: uploadedStoragePath,
      );
    } on Object catch (error) {
      final reason = _photoFailureForError(
        error,
        fallback: RemoteCardPhotoFailureReason.photoUploadFailed,
      );
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL -');
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_ERROR local_photo_upload '
        'reason=${reason.name} type=${error.runtimeType}',
      );
      return RemoteCardPhotoResolution.failure(reason);
    }
  }

  Future<String?> _resolveLocalFilePath(String? value) async {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return null;
    }
    final normalized = value.trim();
    if (normalized.startsWith('assets/') || normalized.startsWith('asset:')) {
      return null;
    }
    final uri = Uri.tryParse(normalized);
    if (uri != null && uri.isScheme('file')) {
      return uri.toFilePath();
    }
    if (normalized.startsWith('/')) {
      return normalized;
    }

    if (CatDexPersistedPhotoPath.isRelativeApplicationPath(normalized) &&
        !_isSupabaseStorageObjectPath(normalized)) {
      return _localPhotoPathResolver(normalized);
    }

    return null;
  }

  Future<RemoteCardGenerationHttpResponse> _postJson({
    required Uri uri,
    required Map<String, Object?> payload,
  }) async {
    final requestTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_REQUEST',
      detail: 'uri=$uri',
    );
    final firstByteTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_FIRST_BYTE',
      detail: 'uri=$uri',
    );
    final responseTiming = CardGenerationPerformanceSpan.start(
      'CATDEX_PERF_FLUTTER_RESPONSE_RECEIVED',
      detail: 'uri=$uri',
    );
    final override = _postJsonOverride;
    try {
      if (override != null) {
        final response = await override(uri: uri, payload: payload);
        firstByteTiming.finish();
        responseTiming.finish();
        return response;
      }

      final client = HttpClient();
      try {
        final request = await client.postUrl(uri);
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));
        final response = await request.close();
        firstByteTiming.finish();
        final bytes = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        responseTiming.finish();
        return RemoteCardGenerationHttpResponse(
          statusCode: response.statusCode,
          bytes: bytes,
        );
      } finally {
        client.close(force: true);
      }
    } finally {
      firstByteTiming.finish();
      responseTiming.finish();
      requestTiming.finish();
    }
  }

  Future<_RecoveredRemoteResponse?> _postJsonWithRecovery({
    required Uri uri,
    required Map<String, Object?> payload,
    required ValueChanged<RemoteCardGenerationPendingReason>? onPending,
  }) async {
    var recoveryAttempt = 0;
    var recovered = false;

    while (true) {
      final response = await _postJson(uri: uri, payload: payload);
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_STATUS ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _RecoveredRemoteResponse(
          response: response,
          recovered: recovered,
        );
      }

      final responseBody = utf8.decode(
        response.bytes,
        allowMalformed: true,
      );
      final errorCode = _responseErrorCode(responseBody);
      final pendingReason = _pendingReason(
        statusCode: response.statusCode,
        errorCode: errorCode,
      );
      if (pendingReason == null) {
        _lastEventFailure = _eventFailureFromErrorCode(errorCode);
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        debugPrint(
          'CATDEX_REMOTE_GENERATE_CARD_ERROR HTTP ${response.statusCode}: '
          '$responseBody',
        );
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      recovered = true;
      onPending?.call(pendingReason);
      switch (pendingReason) {
        case RemoteCardGenerationPendingReason.renderInProgress:
          debugPrint('CATDEX_CARD_GENERATION_PENDING_409');
        case RemoteCardGenerationPendingReason.generationTimeout:
          debugPrint('CATDEX_CARD_GENERATION_PENDING_504');
      }
      debugPrint('CATDEX_CARD_CREDIT_NOT_CONSUMED_TRANSIENT_FAILURE');

      if (recoveryAttempt >= _recoveryDelays.length) {
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        debugPrint('CATDEX_CARD_GENERATION_RECOVERY_EXHAUSTED');
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      final delay = _recoveryDelays[recoveryAttempt];
      recoveryAttempt += 1;
      debugPrint(
        'CATDEX_CARD_GENERATION_RECOVERY_ATTEMPT '
        '$recoveryAttempt delayMs=${delay.inMilliseconds}',
      );
      await _recoveryDelay(delay);
    }
  }

  EventCardGenerationFailure? _eventFailureFromErrorCode(String? code) {
    return switch (code) {
      'eventInactive' => EventCardGenerationFailure.eventInactive,
      'eventVariantInvalid' => EventCardGenerationFailure.eventVariantInvalid,
      'eventVariantDisabled' => EventCardGenerationFailure.eventVariantDisabled,
      'selectedVariantInvalid' =>
        EventCardGenerationFailure.selectedVariantInvalid,
      'selectedVariantDisabled' =>
        EventCardGenerationFailure.selectedVariantDisabled,
      'freeEventLimitReached' =>
        EventCardGenerationFailure.freeEventLimitReached,
      'premiumRequired' => EventCardGenerationFailure.premiumRequired,
      'premiumVerificationUnavailable' =>
        EventCardGenerationFailure.premiumVerificationUnavailable,
      'eventReservationConflict' =>
        EventCardGenerationFailure.eventReservationConflict,
      'eventGenerationPending' =>
        EventCardGenerationFailure.eventGenerationPending,
      'eventArtworkValidationFailed' =>
        EventCardGenerationFailure.eventArtworkValidationFailed,
      'eventPersistenceFailed' =>
        EventCardGenerationFailure.eventPersistenceFailed,
      _ => null,
    };
  }

  String? _responseErrorCode(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map) {
        final value = decoded['error'];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  RemoteCardGenerationPendingReason? _pendingReason({
    required int statusCode,
    required String? errorCode,
  }) {
    if (statusCode == HttpStatus.conflict &&
        errorCode == 'CARD_RENDER_IN_PROGRESS') {
      return RemoteCardGenerationPendingReason.renderInProgress;
    }
    if (statusCode == HttpStatus.gatewayTimeout &&
        errorCode == 'CARD_GENERATION_TIMEOUT') {
      return RemoteCardGenerationPendingReason.generationTimeout;
    }

    return null;
  }

  String? _absoluteUrl(String? value, Uri endpointUri) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return null;
    }
    final parsed = Uri.tryParse(value.trim());
    if (parsed == null) {
      return null;
    }
    if (parsed.hasScheme &&
        (parsed.scheme == 'http' || parsed.scheme == 'https')) {
      return parsed.toString();
    }

    final origin = Uri.parse(
      '${endpointUri.scheme}://${endpointUri.authority}',
    );
    return origin.resolveUri(parsed).toString();
  }

  bool _isAccessibleUrl(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return false;
    }
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool _isValidRendererPhotoUrl(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return false;
    }
    final normalized = value.trim();
    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      if (_looksLikeLocalhostUrl(uri) ||
          normalized.contains('test_illustrated_cat.png')) {
        debugPrint('CATDEX_CARD_PHOTO_REJECTED_LOCALHOST $normalized');
      }
      return false;
    }
    if (_looksLikeLocalhostUrl(uri) ||
        normalized.contains('test_illustrated_cat.png')) {
      debugPrint('CATDEX_CARD_PHOTO_REJECTED_LOCALHOST $normalized');
      return false;
    }
    if (_isExpiredSignedUrl(uri)) {
      debugPrint('CATDEX_CARD_PHOTO_REJECTED_EXPIRED_SIGNED_URL');
      return false;
    }
    return true;
  }

  bool _looksLikeLocalhostUrl(Uri? uri) {
    final host = uri?.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  bool _isSupabaseStorageObjectPath(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == '-' ||
        normalized.startsWith('/') ||
        normalized.startsWith('file://') ||
        normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('assets/') ||
        normalized.startsWith('asset:')) {
      return false;
    }

    if (CatDexPersistedPhotoPath.isPersistedLocalPhotoPath(normalized)) {
      return false;
    }

    return normalized.startsWith('catdex/originals/') ||
        normalized.startsWith('catdex/photos/') ||
        normalized.startsWith('uploads/');
  }

  void _logSelectedPhoto(String value, {required String source}) {
    debugPrint('CATDEX_CARD_PHOTO_SELECTED ${_logUrl(value)}');
    debugPrint('CATDEX_CARD_PHOTO_SELECTED_VALID true');
    debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED ${_logUrl(value)}');
    debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND $source');
  }

  RemoteCardGenerationFailureReason _generationFailureForPhoto(
    RemoteCardPhotoFailureReason reason,
  ) => switch (reason) {
    RemoteCardPhotoFailureReason.missingPhoto =>
      RemoteCardGenerationFailureReason.missingPhoto,
    RemoteCardPhotoFailureReason.photoUploadFailed =>
      RemoteCardGenerationFailureReason.photoUploadFailed,
    RemoteCardPhotoFailureReason.storagePermissionDenied =>
      RemoteCardGenerationFailureReason.storagePermissionDenied,
    RemoteCardPhotoFailureReason.signedUrlFailed =>
      RemoteCardGenerationFailureReason.signedUrlFailed,
    RemoteCardPhotoFailureReason.network =>
      RemoteCardGenerationFailureReason.network,
  };

  RemoteCardPhotoFailureReason? _strongerPhotoFailure(
    RemoteCardPhotoFailureReason? current,
    RemoteCardPhotoFailureReason? candidate,
  ) {
    if (candidate == null) return current;
    if (current == null) return candidate;
    const priority = <RemoteCardPhotoFailureReason, int>{
      RemoteCardPhotoFailureReason.missingPhoto: 0,
      RemoteCardPhotoFailureReason.signedUrlFailed: 1,
      RemoteCardPhotoFailureReason.photoUploadFailed: 2,
      RemoteCardPhotoFailureReason.network: 3,
      RemoteCardPhotoFailureReason.storagePermissionDenied: 4,
    };
    return priority[candidate]! > priority[current]! ? candidate : current;
  }

  RemoteCardPhotoFailureReason _photoFailureForError(
    Object error, {
    required RemoteCardPhotoFailureReason fallback,
  }) {
    if (error is SocketException || error is HttpException) {
      return RemoteCardPhotoFailureReason.network;
    }
    if (error is StorageException) {
      final statusCode = error.statusCode;
      final message = '${error.message} ${error.error ?? ''}'.toLowerCase();
      if (statusCode == '401' ||
          statusCode == '403' ||
          message.contains('permission') ||
          message.contains('unauthorized') ||
          message.contains('forbidden')) {
        return RemoteCardPhotoFailureReason.storagePermissionDenied;
      }
    }
    return fallback;
  }

  String _photoSourceName(RemoteCardPhotoSource source) => switch (source) {
    RemoteCardPhotoSource.existingHttps => 'existing_https',
    RemoteCardPhotoSource.storagePath => 'storage_path',
    RemoteCardPhotoSource.localUpload => 'local_upload',
  };

  bool _isExpiredSignedUrl(Uri uri) {
    final token = uri.queryParameters['token'];
    if (token == null || token.split('.').length != 3) return false;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(token.split('.')[1])),
      );
      final decoded = jsonDecode(payload);
      final expiration = decoded is Map ? decoded['exp'] : null;
      if (expiration is! num) return false;
      return DateTime.fromMillisecondsSinceEpoch(
        expiration.toInt() * 1000,
        isUtc: true,
      ).isBefore(DateTime.now().toUtc());
    } on Object {
      return false;
    }
  }

  Map<String, Object?> _payloadForLog(Map<String, Object?> payload) {
    final safe = Map<String, Object?>.from(payload);
    final photoUrl = safe['photoUrl'];
    if (photoUrl is String) safe['photoUrl'] = _logUrl(photoUrl);
    return safe;
  }

  String _logUrl(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.query.isEmpty) return value.trim();
    return uri.replace(query: 'redacted').toString();
  }

  String? _rawFinalCardUrl(Map<String, Object?> decoded) {
    for (final key in ['finalCardUrl', 'finalUrl', 'cardUrl', 'imageUrl']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty && value.trim() != '-') {
        return value;
      }
    }

    return null;
  }

  bool _looksLikeOriginalPhotoResult({
    required String finalCardUrl,
    required String photoUrl,
    required CatDiscovery discovery,
  }) {
    if (looksLikeOriginalPhotoPath(finalCardUrl)) {
      return true;
    }

    final normalizedFinal = finalCardUrl.trim();
    final candidates = [
      photoUrl,
      discovery.card?.originalPhotoPath,
      discovery.displayPhotoPath,
      discovery.originalPhotoPath,
      discovery.photoPath,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null &&
          value.isNotEmpty &&
          value != '-' &&
          value == normalizedFinal) {
        return true;
      }
    }

    return false;
  }

  String _rarity(CatDiscovery discovery, String? debugRarityOverride) {
    return _rendererRarity(
      debugRarityOverride,
      fallback: discovery.rarity.name,
    );
  }

  String _rendererRarity(String? value, {required String fallback}) {
    final normalized = _normalizeRarity(value);
    if (normalized != null) {
      return normalized;
    }

    return _normalizeRarity(fallback) ?? 'common';
  }

  String? _normalizeRarity(String? value) {
    final normalized = value
        ?.trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (normalized == 'common' || normalized == 'comune') {
      return 'common';
    }

    if (normalized == 'uncommon' || normalized == 'non comune') {
      return 'uncommon';
    }

    if (normalized == 'rare' || normalized == 'rara' || normalized == 'raro') {
      return 'rare';
    }

    if (normalized == 'epic' ||
        normalized == 'epica' ||
        normalized == 'epico') {
      return 'epic';
    }

    if (normalized == 'legendary' ||
        normalized == 'leggendaria' ||
        normalized == 'leggendario' ||
        normalized == 'mythic') {
      return 'legendary';
    }

    return null;
  }

  String _logValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }
}

class RemoteCardGenerationHttpResponse {
  const RemoteCardGenerationHttpResponse({
    required this.statusCode,
    required this.bytes,
  });

  final int statusCode;
  final List<int> bytes;
}

class _RecoveredRemoteResponse {
  const _RecoveredRemoteResponse({
    required this.response,
    required this.recovered,
  });

  final RemoteCardGenerationHttpResponse response;
  final bool recovered;
}

class _PhotoSourceCandidate {
  const _PhotoSourceCandidate(this.kind, this.value);

  final String kind;
  final String? value;
}

class _PhotoUrlAttempt {
  const _PhotoUrlAttempt._({this.url, this.failureReason});

  const _PhotoUrlAttempt.success(String url) : this._(url: url);

  const _PhotoUrlAttempt.failure(RemoteCardPhotoFailureReason reason)
    : this._(failureReason: reason);

  final String? url;
  final RemoteCardPhotoFailureReason? failureReason;
}
