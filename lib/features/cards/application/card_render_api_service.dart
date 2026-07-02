import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/cards/application/card_text_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final cardRenderApiServiceProvider = Provider<CardRenderApiService>((_) {
  return const CardRenderApiService();
});

class CardRenderApiService {
  const CardRenderApiService({
    String endpoint = const String.fromEnvironment('CARD_RENDER_API_URL'),
  }) : _endpoint = endpoint;

  static const debugFallbackCatImageUrl =
      'http://localhost:3000/cards/test_illustrated_cat.png';

  final String _endpoint;

  Future<String?> generateCard({
    required CatDiscovery discovery,
    required CatDisplayData display,
    int collectionNumber = 1,
    String? debugFallbackReason,
  }) async {
    debugPrint('CATDEX_CARD_RENDER_API_STARTED');
    debugPrint('CATDEX_CARD_RENDERER external_api');
    debugPrint(
      'CATDEX_CARD_RENDER_API_URL ${_endpoint.isEmpty ? '-' : _endpoint}',
    );
    debugPrint('CATDEX_CARD_RENDER_API_DISCOVERY_ID ${discovery.id}');

    if (_endpoint.trim().isEmpty) {
      debugPrint('CATDEX_CARD_RENDER_API_MISSING_URL');
      return null;
    }

    try {
      final uri = Uri.parse(_endpoint);
      final payload = _payload(
        discovery: discovery,
        display: display,
        collectionNumber: collectionNumber,
        debugFallbackReason: debugFallbackReason,
      );
      final response = await _postJson(
        uri: uri,
        payload: payload,
      );
      if (response.contentType?.mimeType == 'image/png') {
        final path = await _savePngBytes(
          discoveryId: discovery.id,
          bytes: response.bytes,
        );
        debugPrint('CATDEX_CARD_RENDER_API_SUCCESS');
        debugPrint('CATDEX_CARD_RENDER_API_IMAGE_URL $path');
        return path;
      }

      final decoded =
          jsonDecode(utf8.decode(response.bytes)) as Map<String, Object?>;
      final imageUrl = decoded['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.trim().isNotEmpty) {
        debugPrint('CATDEX_CARD_RENDER_API_SUCCESS');
        debugPrint('CATDEX_CARD_RENDER_API_IMAGE_URL $imageUrl');
        return imageUrl;
      }

      final pngBase64 = decoded['pngBase64'] as String?;
      if (pngBase64 != null && pngBase64.trim().isNotEmpty) {
        final path = await _savePngBase64(
          discoveryId: discovery.id,
          pngBase64: pngBase64,
        );
        debugPrint('CATDEX_CARD_RENDER_API_SUCCESS');
        debugPrint('CATDEX_CARD_RENDER_API_IMAGE_URL $path');
        return path;
      }

      debugPrint('CATDEX_CARD_RENDER_API_ERROR missing imageUrl/pngBase64');
      return null;
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_RENDER_API_ERROR $error');
      return null;
    }
  }

  Map<String, Object?> _payload({
    required CatDiscovery discovery,
    required CatDisplayData display,
    required int collectionNumber,
    required String? debugFallbackReason,
  }) {
    final textData = const CardTextFormatter().fromDiscovery(
      discovery: discovery,
      display: display,
      collectionNumber: collectionNumber,
    );
    final imageSelection = _catImageSelection(
      discovery: discovery,
      debugFallbackReason: debugFallbackReason,
    );
    final catImageUrl = imageSelection.url;

    final payload = {
      'cardNumber': textData.cardNumber,
      'catName': textData.catName,
      'species': textData.species,
      'rarity': discovery.rarity.name,
      'starCount': textData.starCount,
      'template': 'common',
      'catImageUrl': catImageUrl,
      'cardStyle': 'catdex_common',
    };
    debugPrint(
      'CATDEX_CARD_RENDER_PAYLOAD_CARD_NUMBER ${payload['cardNumber']}',
    );
    debugPrint('CATDEX_CARD_RENDER_PAYLOAD_CAT_NAME ${payload['catName']}');
    debugPrint('CATDEX_CARD_RENDER_PAYLOAD_SPECIES ${payload['species']}');
    debugPrint('CATDEX_CARD_RENDER_PAYLOAD_RARITY ${payload['rarity']}');
    debugPrint(
      'CATDEX_CARD_RENDER_PAYLOAD_STAR_COUNT ${payload['starCount']}',
    );
    debugPrint(
      'CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL '
      '$catImageUrl',
    );
    debugPrint(
      'CATDEX_CARD_IMAGE_USING_DEBUG_FALLBACK '
      '${imageSelection.usesDebugFallback}',
    );
    debugPrint(
      'CATDEX_CARD_IMAGE_DEBUG_FALLBACK_REASON '
      '${imageSelection.debugFallbackReason ?? '-'}',
    );
    debugPrint(
      'CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL_EMPTY '
      '${catImageUrl.trim().isEmpty}',
    );
    debugPrint(
      'CATDEX_CARD_RENDER_PAYLOAD_CAT_IMAGE_URL_VALID '
      '${_isAccessibleUrl(catImageUrl)}',
    );

    return payload;
  }

  _CardImageSelection _catImageSelection({
    required CatDiscovery discovery,
    required String? debugFallbackReason,
  }) {
    final aiIllustration = _firstValue([
      discovery.card?.aiIllustrationUrl,
      discovery.card?.illustratedCatImageUrl,
      discovery.card?.illustratedCatPath,
    ]);
    final aiIllustrationPath = _firstValue([
      discovery.card?.aiIllustrationPath,
      discovery.card?.illustratedCatImagePath,
    ]);
    final original = _firstValue([
      discovery.card?.originalPhotoPath,
      discovery.displayPhotoPath,
      discovery.originalPhotoPath,
      discovery.photoPath,
    ]);

    debugPrint(
      'CATDEX_CARD_IMAGE_SOURCE_AI_ILLUSTRATION '
      '${_logValue(aiIllustration)}',
    );
    debugPrint(
      'CATDEX_CARD_IMAGE_SOURCE_AI_ILLUSTRATION_PATH '
      '${_logValue(aiIllustrationPath)}',
    );
    debugPrint('CATDEX_CARD_IMAGE_SOURCE_ORIGINAL ${_logValue(original)}');

    if (_isAccessibleUrl(aiIllustration)) {
      debugPrint('CATDEX_CARD_IMAGE_SOURCE_SELECTED ai_illustration');
      return _CardImageSelection(
        url: aiIllustration!,
      );
    }
    if (_isAccessibleUrl(aiIllustrationPath)) {
      debugPrint('CATDEX_CARD_IMAGE_SOURCE_SELECTED ai_illustration');
      return _CardImageSelection(
        url: aiIllustrationPath!,
      );
    }
    if (_isAccessibleUrl(original)) {
      debugPrint('CATDEX_CARD_IMAGE_SOURCE_SELECTED original');
      return _CardImageSelection(
        url: original!,
      );
    }

    debugPrint('CATDEX_CARD_IMAGE_SOURCE_SELECTED debug_fallback');
    return _CardImageSelection(
      url: debugFallbackCatImageUrl,
      usesDebugFallback: true,
      debugFallbackReason:
          debugFallbackReason ??
          _debugFallbackReason(
            aiIllustration: aiIllustration,
            aiIllustrationPath: aiIllustrationPath,
            original: original,
          ),
    );
  }

  String _debugFallbackReason({
    required String? aiIllustration,
    required String? aiIllustrationPath,
    required String? original,
  }) {
    if (_firstValue([
          aiIllustration,
          aiIllustrationPath,
          original,
        ]) ==
        null) {
      return 'no_original_photo';
    }

    return 'invalid_url';
  }

  String? _firstValue(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty && value.trim() != '-') {
        return value;
      }
    }

    return null;
  }

  String _logValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
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

  Future<_RendererResponse> _postJson({
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
          'Card renderer failed with HTTP ${response.statusCode}: '
          '${utf8.decode(bytes, allowMalformed: true)}',
          uri: uri,
        );
      }

      return _RendererResponse(
        bytes: bytes,
        contentType: response.headers.contentType,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _savePngBytes({
    required String discoveryId,
    required List<int> bytes,
  }) async {
    final path = await _cardPath(discoveryId);
    await File(path).writeAsBytes(bytes);

    return path;
  }

  Future<String> _savePngBase64({
    required String discoveryId,
    required String pngBase64,
  }) async {
    final path = await _cardPath(discoveryId);
    final normalized = pngBase64.contains(',')
        ? pngBase64.split(',').last
        : pngBase64;
    await File(path).writeAsBytes(base64Decode(normalized));

    return path;
  }

  Future<String> _cardPath(String discoveryId) async {
    final directory = await getApplicationDocumentsDirectory();
    final cardsDirectory = Directory('${directory.path}/catdex/cards');
    if (!cardsDirectory.existsSync()) {
      cardsDirectory.createSync(recursive: true);
    }

    return '${cardsDirectory.path}/card_$discoveryId.png';
  }
}

class _CardImageSelection {
  const _CardImageSelection({
    required this.url,
    this.usesDebugFallback = false,
    this.debugFallbackReason,
  });

  final String url;
  final bool usesDebugFallback;
  final String? debugFallbackReason;
}

class _RendererResponse {
  const _RendererResponse({
    required this.bytes,
    required this.contentType,
  });

  final List<int> bytes;
  final ContentType? contentType;
}
