import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_photo_recovery_service.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Riverpod's family builder returns an internal implementation type.
// ignore: specify_nonobvious_property_types
final mapDiscoveryImageProvider = FutureProvider.autoDispose
    .family<CatDexResolvedImage, CatDiscovery>(
      (ref, discovery) {
        return CatDexImageResolver.resolveBestImagePath(
          discovery: discovery,
          signedUrlForStoragePath: (path) => _createSignedUrl(ref, path),
          cacheFileForStoragePath: (path) => ref
              .read(catDexPhotoRecoveryServiceProvider)
              .recoverFromStorage(discovery: discovery, storagePath: path),
        );
      },
    );

Future<String?> _createSignedUrl(Ref ref, String storagePath) async {
  if (!ref.read(supabaseConfiguredProvider)) return null;
  try {
    return await ref
        .read(supabaseClientProvider)
        .storage
        .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
        .createSignedUrl(storagePath, 60 * 60 * 24);
  } on Object catch (error) {
    debugPrint('CATDEX_MAP_PREVIEW_IMAGE_SIGNED_URL_FAILED $error');
    return null;
  }
}
