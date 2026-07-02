import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:flutter/material.dart';

class CatDexResolvedImage {
  const CatDexResolvedImage({
    required this.provider,
    required this.path,
    required this.source,
    required this.candidates,
    required this.isCutout,
    required this.placeholderReason,
    required this.discoveryDebugJson,
  });

  final ImageProvider<Object>? provider;
  final String? path;
  final String source;
  final List<String> candidates;
  final bool isCutout;
  final String? placeholderReason;
  final Map<String, Object?> discoveryDebugJson;

  bool get usesPlaceholder => provider == null;
}

class CatDexImageResolver {
  const CatDexImageResolver._();

  static CatDexResolvedImage resolveForEntry(CatDexCollectionEntry entry) {
    return resolveBestImagePath(
      discovery: entry.discovery,
      discoveredPhotoPath: entry.discoveredPhotoPath,
    );
  }

  static String? resolveBestPhotoPath(CatDiscovery discovery) {
    return resolveBestImagePath(discovery: discovery).path;
  }

  static bool hasUsablePhoto(CatDiscovery discovery) {
    return resolveBestPhotoPath(discovery) != null;
  }

  static Widget buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    final provider = _imageProviderForPath(path);
    if (provider == null) {
      return const SizedBox.shrink();
    }

    return Image(image: provider, fit: fit);
  }

  static CatDexResolvedImage resolveBestImagePath({
    required CatDiscovery? discovery,
    String? discoveredPhotoPath,
  }) {
    final candidates = <_ImageCandidate>[
      _ImageCandidate(
        'cutoutImagePath',
        discovery?.card?.cutoutImagePath,
        isCutout: true,
      ),
      _ImageCandidate(
        'displayPhotoPath',
        discovery?.displayPhotoPath,
        isCutout: false,
      ),
      _ImageCandidate(
        'originalPhotoPath',
        discovery?.originalPhotoPath,
        isCutout: false,
      ),
      _ImageCandidate('photoPath', discovery?.photoPath, isCutout: false),
      const _ImageCandidate('imagePath', null, isCutout: false),
      const _ImageCandidate('localImagePath', null, isCutout: false),
      const _ImageCandidate('capturedImagePath', null, isCutout: false),
      const _ImageCandidate('photoUrl', null, isCutout: false),
      const _ImageCandidate('imageUrl', null, isCutout: false),
      const _ImageCandidate('storagePath', null, isCutout: false),
      _ImageCandidate(
        'discoveredPhotoPath',
        discoveredPhotoPath,
        isCutout: false,
      ),
      _ImageCandidate(
        'card.originalPhotoPath',
        discovery?.card?.originalPhotoPath,
        isCutout: false,
      ),
    ];

    final candidateLog = candidates
        .where((candidate) => _hasText(candidate.path))
        .map((candidate) => '${candidate.source}=${candidate.path}')
        .toList(growable: false);

    debugPrint(
      'CATDEX_IMAGE_RESOLVER_DISCOVERY_ID ${discovery?.id ?? '-'}',
    );
    debugPrint('CATDEX_IMAGE_RESOLVER_CANDIDATES $candidateLog');

    for (final candidate in candidates) {
      final provider = _imageProviderForPath(candidate.path);
      if (provider != null) {
        debugPrint(
          'CATDEX_IMAGE_RESOLVER_SELECTED '
          '${candidate.source}=${candidate.path}',
        );
        return CatDexResolvedImage(
          provider: provider,
          path: candidate.path,
          source: candidate.source,
          candidates: candidateLog,
          isCutout: candidate.isCutout,
          placeholderReason: null,
          discoveryDebugJson: _discoveryDebugJson(
            discovery,
            discoveredPhotoPath,
          ),
        );
      }
    }

    final reason = candidateLog.isEmpty
        ? 'no image paths found on discovery'
        : 'image paths found but none were usable';
    debugPrint('CATDEX_IMAGE_RESOLVER_SELECTED -');
    debugPrint('CATDEX_IMAGE_RESOLVER_REASON_IF_NULL $reason');

    return CatDexResolvedImage(
      provider: null,
      path: null,
      source: 'placeholder',
      candidates: candidateLog,
      isCutout: false,
      placeholderReason: reason,
      discoveryDebugJson: _discoveryDebugJson(discovery, discoveredPhotoPath),
    );
  }

  static ImageProvider<Object>? _imageProviderForPath(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      return NetworkImage(trimmed);
    }

    if (trimmed.startsWith('assets/') || trimmed.startsWith('asset:')) {
      return AssetImage(trimmed.replaceFirst('asset:', ''));
    }

    final file = File(trimmed);
    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static Map<String, Object?> _discoveryDebugJson(
    CatDiscovery? discovery,
    String? discoveredPhotoPath,
  ) {
    return {
      'id': discovery?.id,
      'speciesId': discovery?.speciesId,
      'customName': discovery?.customName,
      'cutoutImagePath': discovery?.card?.cutoutImagePath,
      'displayPhotoPath': discovery?.displayPhotoPath,
      'originalPhotoPath': discovery?.originalPhotoPath,
      'photoPath': discovery?.photoPath,
      'imagePath': null,
      'localImagePath': null,
      'capturedImagePath': null,
      'photoUrl': null,
      'imageUrl': null,
      'storagePath': null,
      'discoveredPhotoPath': discoveredPhotoPath,
      'card.originalPhotoPath': discovery?.card?.originalPhotoPath,
    };
  }
}

class _ImageCandidate {
  const _ImageCandidate(this.source, this.path, {required this.isCutout});

  final String source;
  final String? path;
  final bool isCutout;
}
