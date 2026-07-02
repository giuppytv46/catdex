import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  }) : _endpoint = endpoint,
       _supabaseClient = supabaseClient;

  static const debugFallbackPhotoUrl =
      'http://localhost:3000/cards/test_illustrated_cat.png';
  static const String _bucketName =
      SupabaseCatPhotoStorageRepository.catPhotosBucketName;

  final String _endpoint;
  final SupabaseClient? _supabaseClient;
  RemoteCardGenerationFailureReason? _lastFailureReason;

  RemoteCardGenerationFailureReason? get lastFailureReason =>
      _lastFailureReason;

  Future<RemoteGeneratedCard?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required int collectionNumber,
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
      final photoUrlValid = _isAccessibleUrl(photoUrl);
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL ${_logValue(photoUrl)}',
      );
      debugPrint(
        'CATDEX_REMOTE_GENERATE_CARD_PHOTO_URL_VALID $photoUrlValid',
      );

      if (!photoUrlValid) {
        _lastFailureReason = RemoteCardGenerationFailureReason.invalidPhotoUrl;
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_ERROR invalid_photo_url');
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      final payload = <String, Object?>{
        'discoveryId': discovery.id,
        'photoUrl': photoUrl,
        'rarity': _rarity(discovery),
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

      final response = await _postJson(uri: endpointUri, payload: payload);
      debugPrint('CATDEX_REMOTE_GENERATE_CARD_STATUS ${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _lastFailureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
        debugPrint(
          'CATDEX_REMOTE_GENERATE_CARD_ERROR HTTP ${response.statusCode}: '
          '${utf8.decode(response.bytes, allowMalformed: true)}',
        );
        debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS false');
        return null;
      }

      final decoded = Map<String, Object?>.from(
        jsonDecode(utf8.decode(response.bytes)) as Map,
      );
      final finalCardUrl = _absoluteUrl(
        decoded['finalCardUrl'] as String?,
        endpointUri,
      );
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
        'CATDEX_REMOTE_GENERATE_CARD_FINAL_URL ${_logValue(finalCardUrl)}',
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

      debugPrint('CATDEX_REMOTE_GENERATE_CARD_SUCCESS true');
      return RemoteGeneratedCard(
        finalCardUrl: finalCardUrl!,
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

    final directCandidates = [
      _PhotoSourceCandidate('card_original', cardOriginal),
      _PhotoSourceCandidate('display', display),
      _PhotoSourceCandidate('original', original),
      _PhotoSourceCandidate('photo_path', photoPath),
    ];

    for (final candidate in directCandidates) {
      final value = candidate.value;
      if (_isAccessibleUrl(value)) {
        final selected = value!.trim();
        debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED $selected');
        debugPrint(
          'CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND ${candidate.kind}',
        );
        return selected;
      }
    }

    for (final candidate in directCandidates) {
      final signedUrl = await _tryCreateSignedPhotoUrl(candidate.value);
      if (_isAccessibleUrl(signedUrl)) {
        debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED $signedUrl');
        debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND signed_url');
        return signedUrl;
      }
    }

    for (final candidate in directCandidates) {
      final uploadedUrl = await _tryUploadLocalPhoto(
        discovery: discovery,
        sourcePath: candidate.value,
      );
      if (_isAccessibleUrl(uploadedUrl)) {
        debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED $uploadedUrl');
        debugPrint(
          'CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND uploaded_local_file',
        );
        return uploadedUrl;
      }
    }

    debugPrint('CATDEX_REMOTE_PHOTO_USING_DEBUG_FALLBACK true');
    debugPrint(
      'CATDEX_REMOTE_PHOTO_DEBUG_FALLBACK_REASON no_valid_photo_url',
    );
    debugPrint(
      'CATDEX_REMOTE_PHOTO_SOURCE_SELECTED $debugFallbackPhotoUrl',
    );
    debugPrint('CATDEX_REMOTE_PHOTO_SOURCE_SELECTED_KIND debug_fallback');
    return debugFallbackPhotoUrl;
  }

  Future<String?> _tryCreateSignedPhotoUrl(String? storagePath) async {
    final client = _supabaseClient;
    if (client == null || storagePath == null || storagePath.trim().isEmpty) {
      return null;
    }
    final normalized = storagePath.trim();
    if (normalized == '-' ||
        normalized.startsWith('/') ||
        normalized.startsWith('file://') ||
        normalized.startsWith('assets/') ||
        normalized.startsWith('asset:')) {
      return null;
    }

    debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_STARTED $normalized');
    try {
      final signedUrl = await client.storage
          .from(_bucketName)
          .createSignedUrl(normalized, 60 * 60 * 24);
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS true');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL ${_logValue(signedUrl)}');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR -');
      return signedUrl;
    } on Object catch (error) {
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_SUCCESS false');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL -');
      debugPrint('CATDEX_REMOTE_PHOTO_SIGNED_URL_ERROR $error');
      return null;
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
      final signedUrl = await client.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, 60 * 60 * 24);
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

  Future<_RemoteGenerationResponse> _postJson({
    required Uri uri,
    required Map<String, Object?> payload,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      final bytes = await response.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      return _RemoteGenerationResponse(
        statusCode: response.statusCode,
        bytes: bytes,
      );
    } finally {
      client.close(force: true);
    }
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

  String _rarity(CatDiscovery discovery) {
    final rarity = discovery.rarity.name.trim().toLowerCase();
    return rarity.isEmpty ? 'common' : rarity;
  }

  String _logValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }
}

class _RemoteGenerationResponse {
  const _RemoteGenerationResponse({
    required this.statusCode,
    required this.bytes,
  });

  final int statusCode;
  final List<int> bytes;
}

class _PhotoSourceCandidate {
  const _PhotoSourceCandidate(this.kind, this.value);

  final String kind;
  final String? value;
}
