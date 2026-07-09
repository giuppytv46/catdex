import 'package:flutter/foundation.dart';

String cacheBustedCardImageUrl({
  required String source,
  required int? version,
}) {
  if (version == null || !_isNetworkUrl(source)) {
    return source;
  }

  final uri = Uri.parse(source);
  final updated = uri.replace(
    queryParameters: {
      ...uri.queryParameters,
      'v': version.toString(),
    },
  );
  final displayUrl = updated.toString();
  debugPrint('CATDEX_CARD_IMAGE_CACHE_BUSTED true');
  debugPrint('CATDEX_CARD_IMAGE_DISPLAY_URL $displayUrl');
  return displayUrl;
}

bool isNetworkCardImageUrl(String source) => _isNetworkUrl(source);

bool isFinalGeneratedCardImageSource(String? source) {
  final value = source?.trim();
  if (value == null || value.isEmpty || value == '-') {
    return false;
  }

  if (!_isNetworkUrl(value)) {
    return false;
  }

  return !looksLikeOriginalPhotoPath(value);
}

bool looksLikeOriginalPhotoPath(String source) {
  final normalized = source.trim().toLowerCase();
  if (normalized.isEmpty || normalized == '-') {
    return false;
  }

  if (normalized.startsWith('/') || normalized.startsWith('file://')) {
    return true;
  }

  const originalPhotoMarkers = [
    '/catdex/originals/',
    '/catdex/photos/',
    '/documents/catdex/photos/',
    '/tmp/image_picker',
    '/image_picker_',
    'image_picker',
    'originalphotopath',
    'displayphotopath',
    'photopath',
    'original-photo',
    'original_photo',
    'raw-photo',
    'raw_photo',
  ];

  return originalPhotoMarkers.any(normalized.contains);
}

bool _isNetworkUrl(String source) {
  return source.startsWith('http://') || source.startsWith('https://');
}
