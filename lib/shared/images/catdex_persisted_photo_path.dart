import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CatDexPersistedPhotoPath {
  const CatDexPersistedPhotoPath._();

  static String? _documentsDirectoryPath;

  static String originalPhotoRelativePath(String discoveryId) {
    return 'catdex/originals/original_$discoveryId.jpg';
  }

  static Future<Directory> documentsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    _documentsDirectoryPath = directory.path;
    return directory;
  }

  static String? normalizeForPersistence(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed == '-') {
      return trimmed;
    }

    final localPath = _fileUriPath(trimmed) ?? trimmed;
    if (!localPath.startsWith('/')) {
      return trimmed;
    }

    debugPrint('CATDEX_IMAGE_PATH_IS_ABSOLUTE $localPath');
    final relative = _relativePathFromAbsolute(localPath);
    if (relative != null) {
      debugPrint(
        'CATDEX_IMAGE_PATH_MIGRATED from=$localPath to=$relative',
      );
    }
    return relative;
  }

  static Future<String?> rebuildAbsolutePath(String? storedPath) async {
    final normalized = normalizeForPersistence(storedPath);
    if (!isRelativeApplicationPath(normalized)) {
      return null;
    }

    final documents = await documentsDirectory();
    final rebuilt = '${documents.path}/$normalized';
    debugPrint(
      'CATDEX_IMAGE_LOCAL_REBUILT stored=$normalized runtime=$rebuilt',
    );
    return rebuilt;
  }

  static String? rebuildAbsolutePathSync(String? storedPath) {
    final documentsPath = _documentsDirectoryPath;
    final normalized = normalizeForPersistence(storedPath);
    if (documentsPath == null || !isRelativeApplicationPath(normalized)) {
      return null;
    }

    return '$documentsPath/$normalized';
  }

  static bool isRelativeApplicationPath(String? value) {
    final normalized = value?.trim().replaceAll(r'\', '/');
    return normalized != null && normalized.startsWith('catdex/');
  }

  static bool isPersistedLocalPhotoPath(String value) {
    final normalized = value.trim().replaceAll(r'\', '/');
    return normalized.startsWith('catdex/originals/original_') ||
        normalized.startsWith('catdex/photos/photo_');
  }

  static String? _relativePathFromAbsolute(String absolutePath) {
    final normalized = absolutePath.replaceAll(r'\', '/');
    const documentsMarker = '/Documents/';
    final documentsIndex = normalized.lastIndexOf(documentsMarker);
    if (documentsIndex >= 0) {
      final relative = normalized.substring(
        documentsIndex + documentsMarker.length,
      );
      if (isRelativeApplicationPath(relative)) {
        return relative;
      }
    }

    const catDexMarker = '/catdex/';
    final catDexIndex = normalized.lastIndexOf(catDexMarker);
    if (catDexIndex >= 0) {
      return normalized.substring(catDexIndex + 1);
    }

    return null;
  }

  static String? _fileUriPath(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.isScheme('file')) {
      return null;
    }

    return uri.toFilePath();
  }
}
