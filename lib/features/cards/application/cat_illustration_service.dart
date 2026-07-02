import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final catIllustrationServiceProvider = Provider<CatIllustrationService>((ref) {
  final supabaseConfigured = ref.watch(supabaseConfiguredProvider);
  return CatIllustrationService(
    activeSession: ref.watch(activeCatDexSessionProvider),
    supabaseClient: supabaseConfigured
        ? ref.watch(supabaseClientProvider)
        : null,
  );
});

class CatIllustrationResult {
  const CatIllustrationResult({
    this.path,
    this.url,
  });

  final String? path;
  final String? url;

  bool get hasUsableValue => _notBlank(path) || _notBlank(url);

  static bool _notBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

class CatIllustrationService {
  const CatIllustrationService({
    required ActiveCatDexSession activeSession,
    SupabaseClient? supabaseClient,
    String endpoint = const String.fromEnvironment('CAT_ILLUSTRATION_API_URL'),
  }) : _activeSession = activeSession,
       _endpoint = endpoint,
       _supabaseClient = supabaseClient;

  static const String _bucketName =
      SupabaseCatPhotoStorageRepository.catPhotosBucketName;

  final ActiveCatDexSession _activeSession;
  final String _endpoint;
  final SupabaseClient? _supabaseClient;

  Future<CatIllustrationResult?> generateIllustratedCatImage({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
  }) async {
    debugPrint('CATDEX_AI_ILLUSTRATION_STARTED');
    final originalPhotoUrl = await _originalPhotoUrl(discovery);
    debugPrint(
      'CATDEX_AI_ILLUSTRATION_ORIGINAL_PHOTO_URL '
      '${_logValue(originalPhotoUrl)}',
    );
    debugPrint(
      'CATDEX_AI_ILLUSTRATION_ORIGINAL_PHOTO_VALID '
      '${_isAccessibleUrl(originalPhotoUrl)}',
    );

    if (!_isAccessibleUrl(originalPhotoUrl)) {
      debugPrint(
        'CATDEX_AI_ILLUSTRATION_ERROR missing accessible original photo',
      );
      debugPrint('CATDEX_AI_ILLUSTRATION_SUCCESS false');
      return null;
    }
    if (_endpoint.trim().isEmpty) {
      debugPrint('CATDEX_AI_ILLUSTRATION_NOT_IMPLEMENTED true');
      debugPrint(
        'CATDEX_AI_ILLUSTRATION_ERROR missing CAT_ILLUSTRATION_API_URL',
      );
      debugPrint('CATDEX_AI_ILLUSTRATION_SUCCESS false');
      return null;
    }

    try {
      final response = await _postJson(
        uri: Uri.parse(_endpoint),
        payload: _payload(
          discovery: discovery,
          displayData: displayData,
          originalPhotoUrl: originalPhotoUrl!,
        ),
      );

      final result = await _resultFromResponse(
        discovery: discovery,
        response: response,
      );
      if (result == null || !result.hasUsableValue) {
        debugPrint('CATDEX_AI_ILLUSTRATION_ERROR missing generated image');
        debugPrint('CATDEX_AI_ILLUSTRATION_SUCCESS false');
        return null;
      }

      debugPrint('CATDEX_AI_ILLUSTRATION_SUCCESS true');
      debugPrint('CATDEX_AI_ILLUSTRATION_SAVED_PATH ${_logValue(result.path)}');
      debugPrint('CATDEX_AI_ILLUSTRATION_PUBLIC_URL ${_logValue(result.url)}');

      return result;
    } on Object catch (error) {
      debugPrint('CATDEX_AI_ILLUSTRATION_ERROR $error');
      debugPrint('CATDEX_AI_ILLUSTRATION_SUCCESS false');
      return null;
    }
  }

  Map<String, Object?> _payload({
    required CatDiscovery discovery,
    required CatDisplayData displayData,
    required String originalPhotoUrl,
  }) {
    return {
      'discoveryId': discovery.id,
      'photoUrl': originalPhotoUrl,
      'displayName': displayData.displayName,
      'displaySpecies': displayData.displaySpecies,
      'displayCoatColor': displayData.displayCoatColor,
      'displayCoatPattern': displayData.displayCoatPattern,
      'displayEyeColor': displayData.displayEyeColor,
      'displayHairLength': displayData.displayHairLength,
      'displayPersonality': displayData.displayPersonality,
      'displayRarity': displayData.displayRarity,
      'prompt': _prompt(displayData),
    };
  }

  String _prompt(CatDisplayData displayData) {
    return '''
Create a polished fantasy mobile game illustration of this cat based on the uploaded photo.

Preserve the real cat identity, coat colors and markings, eye color, hair length, and body shape as much as possible.
Use a cute premium collectible companion style, clean digital illustration, full cat body visible, centered, suitable to be placed on a collectible card.
No text, no card frame, no labels, no stars, no fake stats. Use a plain or transparent background if possible.

Discovery details:
Name: ${displayData.displayName}
Species: ${displayData.displaySpecies}
Coat color: ${displayData.displayCoatColor}
Coat pattern: ${displayData.displayCoatPattern}
Eye color: ${displayData.displayEyeColor}
Hair length: ${displayData.displayHairLength}
Personality: ${displayData.displayPersonality}
Rarity: ${displayData.displayRarity}

Very important: the generated cat must match the actual discovery. A tabby cat must not become black/white. A black/white bicolor cat must remain black/white. A longhair cat must remain longhair.''';
  }

  Future<String?> _originalPhotoUrl(CatDiscovery discovery) async {
    final candidates = [
      discovery.card?.originalPhotoPath,
      discovery.displayPhotoPath,
      discovery.originalPhotoPath,
      discovery.photoPath,
    ];

    for (final candidate in candidates) {
      if (_isAccessibleUrl(candidate)) {
        return candidate;
      }
      final signedUrl = await _tryCreateSignedPhotoUrl(candidate);
      if (_isAccessibleUrl(signedUrl)) {
        return signedUrl;
      }
    }

    return null;
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

    try {
      return await client.storage
          .from(_bucketName)
          .createSignedUrl(normalized, 60 * 60);
    } on Object catch (error) {
      debugPrint('CATDEX_AI_ILLUSTRATION_ERROR photo_signed_url $error');
      return null;
    }
  }

  Future<CatIllustrationResult?> _resultFromResponse({
    required CatDiscovery discovery,
    required _IllustrationResponse response,
  }) async {
    if (response.contentType?.mimeType == 'image/png') {
      final path = await _saveLocalPng(
        discoveryId: discovery.id,
        bytes: response.bytes,
      );
      final publicUrl = await _tryUploadToSupabase(
        discovery: discovery,
        bytes: response.bytes,
      );

      return CatIllustrationResult(path: path, url: publicUrl);
    }

    final decoded =
        jsonDecode(utf8.decode(response.bytes)) as Map<String, Object?>;
    final imageUrl =
        decoded['imageUrl'] as String? ??
        decoded['illustrationUrl'] as String? ??
        decoded['url'] as String?;
    if (_isAccessibleUrl(imageUrl)) {
      return CatIllustrationResult(url: imageUrl);
    }

    final pngBase64 =
        decoded['pngBase64'] as String? ?? decoded['imageBase64'] as String?;
    if (pngBase64 != null && pngBase64.trim().isNotEmpty) {
      final normalized = pngBase64.contains(',')
          ? pngBase64.split(',').last
          : pngBase64;
      final bytes = base64Decode(normalized);
      final path = await _saveLocalPng(discoveryId: discovery.id, bytes: bytes);
      final publicUrl = await _tryUploadToSupabase(
        discovery: discovery,
        bytes: bytes,
      );

      return CatIllustrationResult(path: path, url: publicUrl);
    }

    return null;
  }

  Future<String> _saveLocalPng({
    required String discoveryId,
    required List<int> bytes,
  }) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/catdex/illustrations');
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final path = '${directory.path}/illustration_$discoveryId.png';
    await File(path).writeAsBytes(bytes, flush: true);

    return path;
  }

  Future<String?> _tryUploadToSupabase({
    required CatDiscovery discovery,
    required List<int> bytes,
  }) async {
    final client = _supabaseClient;
    if (client == null) {
      return null;
    }

    try {
      final storagePath =
          'catdex/illustrations/${_activeSession.playerId}/${discovery.id}.png';
      await client.storage
          .from(_bucketName)
          .uploadBinary(
            storagePath,
            Uint8List.fromList(bytes),
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      debugPrint('CATDEX_AI_ILLUSTRATION_SAVED_PATH $storagePath');

      return await client.storage
          .from(_bucketName)
          .createSignedUrl(storagePath, 60 * 60 * 24);
    } on Object catch (error) {
      debugPrint('CATDEX_AI_ILLUSTRATION_ERROR supabase_upload $error');
      return null;
    }
  }

  Future<_IllustrationResponse> _postJson({
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
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'Cat illustration failed with HTTP ${response.statusCode}: '
          '${utf8.decode(bytes, allowMalformed: true)}',
          uri: uri,
        );
      }

      return _IllustrationResponse(
        bytes: bytes,
        contentType: response.headers.contentType,
      );
    } finally {
      client.close(force: true);
    }
  }

  bool _isAccessibleUrl(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == '-') {
      return false;
    }
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasAbsolutePath &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  String _logValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }
}

class _IllustrationResponse {
  const _IllustrationResponse({
    required this.bytes,
    required this.contentType,
  });

  final List<int> bytes;
  final ContentType? contentType;
}
