import 'package:flutter/foundation.dart';

export 'package:catdex/features/cards/domain/generated_card_state.dart';

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

bool _isNetworkUrl(String source) {
  return source.startsWith('http://') || source.startsWith('https://');
}
