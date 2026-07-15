import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/cards/application/card_generation_performance.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
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
      );
    });

class RemoteGeneratedCard {
  const RemoteGeneratedCard({
    required this.finalCardUrl,
    this.illustratedCatUrl,
    this.selectedTemplateKey,
    this.analysisJson,
  });

  final String finalCardUrl;
  final String? illustratedCatUrl;
  final String? selectedTemplateKey;
  final Map<String, Object?>? analysisJson;
}

enum RemoteCardGenerationFailureReason {
  missingEndpoint,
  invalidPhotoUrl,
  remoteApiFailure,
}

class RemoteCardGenerationService {
  RemoteCardGenerationService({
    SupabaseClient? supabaseClient,
    String endpoint = const String.fromEnvironment('CARD_GENERATION_API_URL'),
    CardPhotoSignedUrlProvider? signedPhotoUrlProvider,
    CardPhotoLocalUploadProvider? localPhotoUploadProvider,
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
       _postJsonOverride = postJson,
       _recoveryDelays = List<Duration>.unmodifiable(recoveryDelays),
       _recoveryDelay = recoveryDelay ?? Future<void>.delayed;

  static const String _bucketName =
      SupabaseCatPhotoStorageRepository.catPhotosBucketName;

  final String _endpoint;
  final SupabaseClient? _supabaseClient;
  final CardPhotoSignedUrlProvider? _signedPhotoUrlProvider;
  final CardPhotoLocalUploadProvider? _localPhotoUploadProvider;
  final RemoteCardPostJson? _postJsonOverride;
  final List<Duration> _recoveryDelays;
  final CardGenerationRecoveryDelay _recoveryDelay;
  RemoteCardGenerationFailureReason? _lastFailureReason;

  RemoteCardGenerationFailureReason? get lastFailureReason =>
      _lastFailureReason;

  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
    String? debugRarityOverride,
    ValueChanged<RemoteCardGenerationPendingReason>? onPending,
  }) async {
    _lastFailureReason = null;
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
      final photoUrl = await resolveRendererAccessiblePhotoUrl(discovery);
      final photoUrlValid = _isValidRendererPhotoUrl(photoUrl);
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL ${_logValue(photoUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL_VALID $photoUrlValid',
      );

      if (!photoUrlValid) {
        _lastFailureReason = RemoteCardGenerationFailureReason.invalidPhotoUrl;
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR missingPhoto');
        debugPrint(
          'CATDEX_CARD_RENDERER_REQUEST_BLOCKED_NO_REMOTE_PHOTO '
          'reason=no_valid_https_photo',
        );
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
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
        '${_logValue(discovery.originalPhotoPath ?? discovery.photoPath)}',
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
        'CATDEX_REMOTE_GENERATE_CARD_PAYLOAD ${jsonEncode(payload)}',
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
      );
    } on Object catch (error) {
      _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR $error');
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
      return null;
    }
  }

  Future<String?> resolveRendererAccessiblePhotoUrl(
    CatDiscovery discovery,
  ) async {
    final cardOriginal = discovery.card?.originalPhotoPath;
    final display = discovery.displayPhotoPath;
    final original = discovery.originalPhotoPath;
    final photoPath = discovery.photoPath;
    final originalStoragePath = discovery.originalPhotoStoragePath;

    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_CARD_ORIGINAL '
      '${_logValue(cardOriginal)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_DISPLAY ${_logValue(display)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_ORIGINAL ${_logValue(original)}',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_PHOTO_PATH ${_logValue(photoPath)}',
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
        return selected;
      }
    }

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
      final signedUrl = await _tryCreateSignedPhotoUrl(normalized);
      if (_isValidRendererPhotoUrl(signedUrl)) {
        _logSelectedPhoto(signedUrl!, source: 'signed_url');
        return signedUrl;
      }
    }

    for (final candidate in directCandidates) {
      final uploadedUrl = await _tryUploadLocalPhoto(
        discovery: discovery,
        sourcePath: candidate.value,
      );
      if (_isValidRendererPhotoUrl(uploadedUrl)) {
        _logSelectedPhoto(uploadedUrl!, source: 'uploaded_local_file');
        return uploadedUrl;
      }
    }

    debugPrint('CATDEX_CARD_PHOTO_SELECTED -');
    debugPrint('CATDEX_CARD_PHOTO_SELECTED_VALID false');
    return null;
  }

  Future<String?> _tryCreateSignedPhotoUrl(String? storagePath) async {
    if (storagePath == null || storagePath.trim().isEmpty) {
      return null;
    }
    final normalized = storagePath.trim();
    if (!_isSupabaseStorageObjectPath(normalized)) {
      return null;
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
        '${valid ? signedUrl : 'false'}',
      );
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS true');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL ${_logValue(signedUrl)}');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR -');
      return valid ? signedUrl : null;
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_PHOTO_SIGNED_URL_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL -');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR $error');
      return null;
    } finally {
      signedUrlTiming.finish();
    }
  }

  Future<String?> _tryUploadLocalPhoto({
    required CatDiscovery discovery,
    required String? sourcePath,
  }) async {
    final normalized = _localFilePath(sourcePath);
    if (normalized == null) {
      return null;
    }

    debugPrint('CATDEX_REMOTE_PHOTO_LOCAL_FILE_FOUND $normalized');
    final file = File(normalized);
    final exists = file.existsSync();
    debugPrint('CATDEX_REMOTE_PHOTO_LOCAL_FILE_EXISTS $exists');
    if (!exists) {
      if (normalized.contains('/tmp/image_picker_') ||
          normalized.contains('/image_picker_')) {
        debugPrint('CATDEX_REMOTE_PHOTO_TEMP_FILE_MISSING true');
        debugPrint('CATDEX_REMOTE_PHOTO_TEMP_FILE_MISSING_PATH $normalized');
      }
      return null;
    }

    final playerId = discovery.playerId.trim().isEmpty
        ? 'dev'
        : discovery.playerId.trim();
    final storagePath = 'catdex/originals/$playerId/${discovery.id}.jpg';
    debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_STARTED $normalized');
    final client = _supabaseClient;
    final uploadProvider = _localPhotoUploadProvider;
    if (uploadProvider != null) {
      try {
        return await uploadProvider(
          discovery: discovery,
          sourcePath: normalized,
        );
      } on Object catch (error) {
        debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS false');
        debugPrint(
          'CATDEX_REMOTE_GENERATE_CARD_ERROR local_photo_upload $error',
        );
        return null;
      }
    }
    if (client == null) {
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL -');
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_ERROR local_photo_upload_no_supabase',
      );
      return null;
    }

    try {
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
      final signedUrlTiming = CardGenerationPerformanceSpan.start(
        'CATDEX_PERF_FLUTTER_SIGNED_URL_CREATION',
        discoveryId: discovery.id,
        detail: 'storagePath=$storagePath',
      );
      late final String signedUrl;
      try {
        signedUrl = await client.storage
            .from(_bucketName)
            .createSignedUrl(storagePath, 60 * 60 * 24);
      } finally {
        signedUrlTiming.finish();
      }
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS true');
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL $signedUrl');
      return signedUrl;
    } on Object catch (error) {
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_UPLOAD_SIGNED_URL -');
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR local_photo_upload $error');
      return null;
    }
  }

  String? _localFilePath(String? value) {
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

    return normalized.startsWith('catdex/originals/') ||
        normalized.startsWith('catdex/photos/') ||
        normalized.startsWith('uploads/');
  }

  void _logSelectedPhoto(String value, {required String source}) {
    debugPrint('CATDEX_CARD_PHOTO_SELECTED $value');
    debugPrint('CATDEX_CARD_PHOTO_SELECTED_VALID true');
    debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED $value');
    debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND $source');
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
