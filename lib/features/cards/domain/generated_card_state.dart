import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

String? canonicalGeneratedCardUrl(CatDiscovery? discovery) {
  final card = discovery?.card;
  for (final candidate in [card?.cardImageUrl, card?.cardImagePath]) {
    final value = candidate?.trim();
    if (isFinalGeneratedCardImageSource(value)) {
      return value;
    }
  }

  return null;
}

bool hasPersistedGeneratedCard(CatDiscovery? discovery) {
  return canonicalGeneratedCardUrl(discovery) != null;
}

bool isFinalGeneratedCardImageSource(String? source) {
  final value = source?.trim();
  if (value == null || value.isEmpty || value == '-') {
    return false;
  }

  final uri = Uri.tryParse(value);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
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
