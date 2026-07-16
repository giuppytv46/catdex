import 'dart:io';

import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/shared/images/catdex_persisted_photo_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catDexPhotoRecoveryServiceProvider = Provider<CatDexPhotoRecoveryService>(
  CatDexPhotoRecoveryService.new,
);

class CatDexPhotoRecoveryService {
  const CatDexPhotoRecoveryService(this._ref);

  final Ref _ref;

  Future<String?> recoverFromStorage({
    required CatDiscovery discovery,
    required String storagePath,
  }) async {
    if (!_ref.read(supabaseConfiguredProvider)) {
      return null;
    }

    try {
      final bytes = await _ref
          .read(supabaseClientProvider)
          .storage
          .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
          .download(storagePath);
      debugPrint(
        'CATDEX_IMAGE_DOWNLOADED_FROM_SUPABASE '
        'id=${discovery.id} storagePath=$storagePath bytes=${bytes.length}',
      );

      final relativePath = CatDexPersistedPhotoPath.originalPhotoRelativePath(
        discovery.id,
      );
      final runtimePath = await CatDexPersistedPhotoPath.rebuildAbsolutePath(
        relativePath,
      );
      if (runtimePath == null) {
        return null;
      }

      final file = File(runtimePath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);

      final updatedDiscovery = discovery.copyWithPhotoPaths(
        originalPhotoPath: relativePath,
        displayPhotoPath: relativePath,
      );
      _ref
          .read(localDiscoverySessionProvider.notifier)
          .replaceDiscovery(updatedDiscovery);
      try {
        await _ref
            .read(discoveryRepositoryProvider)
            .saveDiscovery(updatedDiscovery);
      } on Object catch (error) {
        debugPrint(
          'CATDEX_IMAGE_CACHE_PERSIST_FAILED '
          'id=${discovery.id} error=$error',
        );
      }
      debugPrint(
        'CATDEX_IMAGE_CACHE_UPDATED '
        'id=${discovery.id} path=$relativePath',
      );
      return runtimePath;
    } on Object catch (error) {
      debugPrint(
        'CATDEX_IMAGE_DOWNLOAD_FROM_SUPABASE_FAILED '
        'id=${discovery.id} storagePath=$storagePath error=$error',
      );
      return null;
    }
  }
}
