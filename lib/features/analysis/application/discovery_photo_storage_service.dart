import 'dart:io';

import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryPhotoStorageServiceProvider =
    Provider<DiscoveryPhotoStorageService>((_) {
      return const DiscoveryPhotoStorageService();
    });

class DiscoveryPhotoStorageService {
  const DiscoveryPhotoStorageService();

  Future<String?> persistDiscoveryPhoto({
    required String discoveryId,
    required String sourceImagePath,
  }) async {
    final trimmed = sourceImagePath.trim();
    debugPrint('CATDEX_PHOTO_SOURCE_PATH ${_logValue(trimmed)}');
    debugPrint('CATDEX_ORIGINAL_PHOTO_TEMP_PATH ${_logValue(trimmed)}');
    debugPrint('CATDEX_PHOTO_PERSIST_STARTED');
    debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_STARTED');
    if (trimmed.isEmpty || _isRemoteOrAsset(trimmed)) {
      debugPrint('CATDEX_PHOTO_SOURCE_EXISTS true');
      debugPrint('CATDEX_PHOTO_PERSISTED_LOCAL_PATH ${_logValue(trimmed)}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_TEMP_EXISTS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSISTED_PATH ${_logValue(trimmed)}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_SUCCESS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_ERROR -');
      return trimmed;
    }

    final rebuiltSourcePath =
        await CatDexPersistedPhotoPath.rebuildAbsolutePath(
          trimmed,
        );
    final source = File(rebuiltSourcePath ?? trimmed);
    final sourceExists = source.existsSync();
    debugPrint('CATDEX_PHOTO_SOURCE_EXISTS $sourceExists');
    debugPrint('CATDEX_ORIGINAL_PHOTO_TEMP_EXISTS $sourceExists');
    if (!sourceExists) {
      debugPrint('CATDEX_PHOTO_PERSISTED_LOCAL_PATH -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSISTED_PATH -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_SUCCESS false');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_ERROR source_missing');
      debugPrint(
        'CATDEX_PHOTO_STORAGE_SOURCE_MISSING '
        'discovery=$discoveryId path=$trimmed',
      );
      return null;
    }

    final documents = await CatDexPersistedPhotoPath.documentsDirectory();
    final relativePath = CatDexPersistedPhotoPath.originalPhotoRelativePath(
      discoveryId,
    );
    final photosDirectory = Directory('${documents.path}/catdex/originals');
    if (!photosDirectory.existsSync()) {
      photosDirectory.createSync(recursive: true);
    }

    final destination = File(
      '${photosDirectory.path}/original_$discoveryId.jpg',
    );
    if (destination.path == source.path) {
      debugPrint('CATDEX_PHOTO_PERSISTED_LOCAL_PATH ${destination.path}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSISTED_PATH ${destination.path}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_SUCCESS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_ERROR -');
      return relativePath;
    }

    try {
      await source.copy(destination.path);
      debugPrint('CATDEX_PHOTO_PERSISTED_LOCAL_PATH ${destination.path}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSISTED_PATH ${destination.path}');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_SUCCESS true');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_ERROR -');
      debugPrint(
        'CATDEX_PHOTO_STORAGE_COPIED '
        'discovery=$discoveryId path=${destination.path}',
      );
      return relativePath;
    } on Object catch (error) {
      debugPrint('CATDEX_PHOTO_PERSISTED_LOCAL_PATH -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSISTED_PATH -');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_SUCCESS false');
      debugPrint('CATDEX_ORIGINAL_PHOTO_PERSIST_ERROR $error');
      return null;
    }
  }

  Future<String?> storePhoto({
    required String discoveryId,
    required String? sourcePath,
  }) async {
    final trimmed = sourcePath?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return persistDiscoveryPhoto(
      discoveryId: discoveryId,
      sourceImagePath: trimmed,
    );
  }

  Future<String?> resolveRuntimePath(String? storedPath) {
    return CatDexPersistedPhotoPath.rebuildAbsolutePath(storedPath);
  }

  bool _isRemoteOrAsset(String value) {
    final uri = Uri.tryParse(value);
    return (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) ||
        value.startsWith('assets/') ||
        value.startsWith('asset:');
  }

  String _logValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '-';
    }

    return value;
  }
}
