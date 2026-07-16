import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:flutter/material.dart';

enum CatDexResolvedImageType { local, network, none }

class CatDexResolvedImage {
  CatDexResolvedImage.localFile({
    required String path,
    required this.source,
    required this.candidates,
    required this.isCutout,
    required this.discoveryDebugJson,
  }) : type = CatDexResolvedImageType.local,
       path = path,
       networkUrl = null,
       provider = FileImage(File(path)),
       placeholderReason = null;

  CatDexResolvedImage.networkUrl({
    required String url,
    required this.path,
    required this.source,
    required this.candidates,
    required this.isCutout,
    required this.discoveryDebugJson,
  }) : type = CatDexResolvedImageType.network,
       networkUrl = url,
       provider = NetworkImage(url),
       placeholderReason = null;

  const CatDexResolvedImage.none({
    required this.source,
    required this.candidates,
    required this.placeholderReason,
    required this.discoveryDebugJson,
  }) : type = CatDexResolvedImageType.none,
       provider = null,
       path = null,
       networkUrl = null,
       isCutout = false;

  final CatDexResolvedImageType type;
  final ImageProvider<Object>? provider;
  final String? path;
  final String? networkUrl;
  final String source;
  final List<String> candidates;
  final bool isCutout;
  final String? placeholderReason;
  final Map<String, Object?> discoveryDebugJson;

  bool get usesPlaceholder => type == CatDexResolvedImageType.none;
  bool get isLocalFile => type == CatDexResolvedImageType.local;
  bool get isNetworkUrl => type == CatDexResolvedImageType.network;
}

class CatDexImageResolver {
  const CatDexImageResolver._();

  static final Map<String, _SignedUrlCacheEntry> _signedUrlCache = {};

  static Future<CatDexResolvedImage> resolveForEntry(
    CatDexCollectionEntry entry, {
    Future<String?> Function(String storagePath)? signedUrlForStoragePath,
    Future<String?> Function(String storagePath)? cacheFileForStoragePath,
  }) {
    return resolveBestImagePath(
      discovery: entry.discovery,
      discoveredPhotoPath: entry.discoveredPhotoPath,
      signedUrlForStoragePath: signedUrlForStoragePath,
      cacheFileForStoragePath: cacheFileForStoragePath,
    );
  }

  static String? resolveBestPhotoPath(CatDiscovery discovery) {
    final candidates = [
      discovery.displayPhotoPath,
      discovery.originalPhotoPath,
      discovery.photoPath,
      discovery.originalPhotoStoragePath,
      discovery.card?.originalPhotoPath,
    ];

    for (final candidate in candidates) {
      final trimmed = candidate?.trim();
      if (trimmed == null || trimmed.isEmpty || trimmed == '-') {
        continue;
      }

      if (isHttpUrl(trimmed)) {
        return trimmed;
      }
      final localPath = isAbsoluteLocalPath(trimmed)
          ? CatDexPersistedPhotoPath.normalizeForPersistence(trimmed) == null
                ? _localFilePath(trimmed)
                : CatDexPersistedPhotoPath.rebuildAbsolutePathSync(trimmed)
          : CatDexPersistedPhotoPath.rebuildAbsolutePathSync(trimmed);
      if (localPath != null && File(localPath).existsSync()) {
        return localPath;
      }
      if (CatDexPersistedPhotoPath.isPersistedLocalPhotoPath(trimmed)) {
        continue;
      }
      if (isSupabaseStorageObjectPath(trimmed)) {
        return trimmed;
      }
    }

    return null;
  }

  static bool hasUsablePhoto(CatDiscovery discovery) {
    return resolveBestPhotoPath(discovery) != null;
  }

  static Widget buildImage(String path, {BoxFit fit = BoxFit.cover}) {
    final provider = _syncImageProviderForPath(path);
    if (provider == null) {
      return const SizedBox.shrink();
    }

    return Image(image: provider, fit: fit);
  }

  static Future<CatDexResolvedImage> resolveBestImagePath({
    required CatDiscovery? discovery,
    String? discoveredPhotoPath,
    Future<String?> Function(String storagePath)? signedUrlForStoragePath,
    Future<String?> Function(String storagePath)? cacheFileForStoragePath,
  }) async {
    final candidates = <_ImageCandidate>[
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
      _ImageCandidate(
        'originalPhotoStoragePath',
        discovery?.originalPhotoStoragePath,
        isCutout: false,
      ),
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
        'cutoutImagePath',
        discovery?.card?.cutoutImagePath,
        isCutout: true,
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
      final resolution = await _resolveImageCandidate(
        candidate,
        signedUrlForStoragePath: signedUrlForStoragePath,
        cacheFileForStoragePath: cacheFileForStoragePath,
      );
      if (resolution.type != CatDexResolvedImageType.none) {
        debugPrint(
          'CATDEX_IMAGE_RESOLVER_CANDIDATE_ACCEPTED '
          '${candidate.source}=${resolution.path}',
        );
        debugPrint(
          'CATDEX_IMAGE_RESOLVER_SELECTED '
          '${candidate.source}=${resolution.path}',
        );
        debugPrint(
          'CATDEX_IMAGE_RESOLVER_RESULT_TYPE ${_typeLog(resolution.type)}',
        );
        if (resolution.type == CatDexResolvedImageType.local) {
          return CatDexResolvedImage.localFile(
            path: resolution.path!,
            source: candidate.source,
            candidates: candidateLog,
            isCutout: candidate.isCutout,
            discoveryDebugJson: _discoveryDebugJson(
              discovery,
              discoveredPhotoPath,
            ),
          );
        }

        return CatDexResolvedImage.networkUrl(
          url: resolution.networkUrl!,
          path: resolution.path,
          source: candidate.source,
          candidates: candidateLog,
          isCutout: candidate.isCutout,
          discoveryDebugJson: _discoveryDebugJson(
            discovery,
            discoveredPhotoPath,
          ),
        );
      }
      debugPrint(
        'CATDEX_IMAGE_RESOLVER_CANDIDATE_REJECTED '
        '${candidate.source}=${candidate.path ?? '-'} '
        'reason=${resolution.rejectionReason}',
      );
    }

    final reason = candidateLog.isEmpty
        ? 'no image paths found on discovery'
        : 'image paths found but none were usable';
    debugPrint('CATDEX_IMAGE_RESOLVER_SELECTED -');
    debugPrint('CATDEX_IMAGE_RESOLVER_REASON_IF_NULL $reason');
    debugPrint('CATDEX_IMAGE_RESOLVER_RESULT_TYPE none');
    debugPrint(
      'CATDEX_IMAGE_PLACEHOLDER_USED id=${discovery?.id ?? '-'} reason=$reason',
    );

    return CatDexResolvedImage.none(
      source: 'placeholder',
      candidates: candidateLog,
      placeholderReason: reason,
      discoveryDebugJson: _discoveryDebugJson(discovery, discoveredPhotoPath),
    );
  }

  static ImageProvider<Object>? _syncImageProviderForPath(String? path) {
    final trimmed = path?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '-') {
      return null;
    }

    if (isHttpUrl(trimmed)) {
      return NetworkImage(trimmed);
    }

    final rebuiltPath = CatDexPersistedPhotoPath.rebuildAbsolutePathSync(
      trimmed,
    );
    final file = File(rebuiltPath ?? _localFilePath(trimmed));
    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }

  static Future<_ImageCandidateResolution> _resolveImageCandidate(
    _ImageCandidate candidate, {
    Future<String?> Function(String storagePath)? signedUrlForStoragePath,
    Future<String?> Function(String storagePath)? cacheFileForStoragePath,
  }) async {
    final trimmed = candidate.path?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const _ImageCandidateResolution.none('empty');
    }

    if (trimmed == '-') {
      return const _ImageCandidateResolution.none('placeholder_value');
    }

    if (isHttpUrl(trimmed)) {
      return _ImageCandidateResolution.network(
        url: trimmed,
        originalPath: trimmed,
      );
    }

    if (isAbsoluteLocalPath(trimmed)) {
      final migratedRuntimePath =
          await CatDexPersistedPhotoPath.rebuildAbsolutePath(trimmed);
      final localPath = migratedRuntimePath ?? _localFilePath(trimmed);
      return _resolveLocalFile(localPath);
    }

    final isStorageField = candidate.source == 'originalPhotoStoragePath';
    if (!isStorageField &&
        CatDexPersistedPhotoPath.isPersistedLocalPhotoPath(trimmed)) {
      final rebuiltPath = await CatDexPersistedPhotoPath.rebuildAbsolutePath(
        trimmed,
      );
      if (rebuiltPath == null) {
        return const _ImageCandidateResolution.none(
          'relative_path_rebuild_failed',
        );
      }
      return _resolveLocalFile(rebuiltPath);
    }

    if (isStorageField || isSupabaseStorageObjectPath(trimmed)) {
      debugPrint('CATDEX_IMAGE_RESOLVER_STORAGE_PATH_FOUND $trimmed');
      final cacheFile = cacheFileForStoragePath;
      if (cacheFile != null) {
        try {
          final cachedPath = await cacheFile(trimmed);
          if (cachedPath != null && cachedPath.trim().isNotEmpty) {
            final cachedResolution = await _resolveLocalFile(cachedPath);
            if (cachedResolution.type == CatDexResolvedImageType.local) {
              return cachedResolution;
            }
          }
        } on Object catch (error) {
          debugPrint('CATDEX_IMAGE_CACHE_RECOVERY_FAILED $error');
        }
      }
      final signedUrl = await _signedUrlForStoragePath(
        trimmed,
        signedUrlForStoragePath,
      );
      if (signedUrl == null || signedUrl.trim().isEmpty) {
        return const _ImageCandidateResolution.none('signed_url_failed');
      }
      debugPrint('CATDEX_IMAGE_RESOLVER_SIGNED_URL_CREATED $signedUrl');
      return _ImageCandidateResolution.network(
        url: signedUrl,
        originalPath: trimmed,
      );
    }

    return const _ImageCandidateResolution.none('unknown_path_type');
  }

  static Future<_ImageCandidateResolution> _resolveLocalFile(
    String localPath,
  ) async {
    // Async existence checking keeps container-path recovery off the UI thread.
    // ignore: avoid_slow_async_io
    final exists = await File(localPath).exists();
    debugPrint(
      'CATDEX_IMAGE_RESOLVER_LOCAL_FILE_CHECK '
      'path=$localPath exists=$exists',
    );
    if (!exists) {
      return const _ImageCandidateResolution.none('file_not_found');
    }

    debugPrint('CATDEX_IMAGE_LOCAL_FOUND $localPath');
    return _ImageCandidateResolution.local(path: localPath);
  }

  static Future<String?> _signedUrlForStoragePath(
    String path,
    Future<String?> Function(String storagePath)? signedUrlForStoragePath,
  ) async {
    final cached = _signedUrlCache[path];
    final now = DateTime.now();
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.url;
    }

    final signer = signedUrlForStoragePath;
    if (signer == null) {
      return null;
    }

    try {
      final signedUrl = await signer(path);
      if (signedUrl != null && signedUrl.trim().isNotEmpty) {
        _signedUrlCache[path] = _SignedUrlCacheEntry(
          url: signedUrl,
          expiresAt: now.add(const Duration(minutes: 55)),
        );
      }

      return signedUrl;
    } on Object catch (error) {
      debugPrint('CATDEX_IMAGE_RESOLVER_SIGNED_URL_FAILED $error');
      return null;
    }
  }

  static String _localFilePath(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.isScheme('file')) {
      return uri.toFilePath();
    }

    return value;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  static bool isAbsoluteLocalPath(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('/')) {
      return true;
    }

    final uri = Uri.tryParse(trimmed);
    return uri != null && uri.isScheme('file');
  }

  static bool isHttpUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  static bool isSupabaseStorageObjectPath(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty ||
        isAbsoluteLocalPath(normalized) ||
        isHttpUrl(normalized)) {
      return false;
    }

    return normalized.startsWith('catdex/originals/') ||
        normalized.startsWith('catdex/photos/') ||
        normalized.startsWith('uploads/');
  }

  static String _typeLog(CatDexResolvedImageType type) {
    return switch (type) {
      CatDexResolvedImageType.local => 'local',
      CatDexResolvedImageType.network => 'network',
      CatDexResolvedImageType.none => 'none',
    };
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
      'originalPhotoStoragePath': discovery?.originalPhotoStoragePath,
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

class _SignedUrlCacheEntry {
  const _SignedUrlCacheEntry({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}

class _ImageCandidate {
  const _ImageCandidate(this.source, this.path, {required this.isCutout});

  final String source;
  final String? path;
  final bool isCutout;
}

class _ImageCandidateResolution {
  const _ImageCandidateResolution._({
    required this.type,
    required this.path,
    required this.networkUrl,
    required this.rejectionReason,
  });

  const _ImageCandidateResolution.local({required String path})
    : this._(
        type: CatDexResolvedImageType.local,
        path: path,
        networkUrl: null,
        rejectionReason: null,
      );

  const _ImageCandidateResolution.network({
    required String url,
    required String originalPath,
  }) : this._(
         type: CatDexResolvedImageType.network,
         path: originalPath,
         networkUrl: url,
         rejectionReason: null,
       );

  const _ImageCandidateResolution.none(String reason)
    : this._(
        type: CatDexResolvedImageType.none,
        path: null,
        networkUrl: null,
        rejectionReason: reason,
      );

  final CatDexResolvedImageType type;
  final String? path;
  final String? networkUrl;
  final String? rejectionReason;
}
