import 'package:catdex/features/capture/application/capture_controller.dart';
import 'package:catdex/features/capture/application/photo_upload_state.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_upload_result.dart';
import 'package:catdex/features/capture/domain/entities/photo_validation_result.dart';
import 'package:catdex/features/capture/domain/repositories/cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catPhotoStorageRepositoryProvider = Provider<CatPhotoStorageRepository>((
  ref,
) {
  return SupabaseCatPhotoStorageRepository(ref.watch(supabaseClientProvider));
});

final photoUploadControllerProvider =
    NotifierProvider<PhotoUploadController, PhotoUploadState>(
      PhotoUploadController.new,
    );

class PhotoUploadController extends Notifier<PhotoUploadState> {
  @override
  PhotoUploadState build() {
    return const PhotoUploadState.idle();
  }

  Future<PhotoUploadResult?> prepareForAnalysis(CapturedPhoto photo) async {
    final validationResult = ref.read(photoValidatorProvider).validate(photo);
    if (validationResult case InvalidPhotoValidationResult(:final message)) {
      state = PhotoUploadState(
        status: PhotoUploadStatus.failed,
        message: message,
      );
      return null;
    }

    final activeSession = ref.read(activeCatDexSessionProvider);
    if (!activeSession.cloudSyncEnabled) {
      final result = PhotoUploadResult.local(photo);
      state = PhotoUploadState(
        status: PhotoUploadStatus.uploaded,
        result: result,
      );
      return result;
    }

    state = const PhotoUploadState(status: PhotoUploadStatus.uploading);

    try {
      final storagePath = await ref
          .read(catPhotoStorageRepositoryProvider)
          .uploadCatPhoto(photo: photo, userId: activeSession.playerId);
      final uploadedPhoto = CapturedPhoto(
        path: storagePath,
        source: photo.source,
        sizeBytes: photo.sizeBytes,
        capturedAt: photo.capturedAt,
        localPath: photo.bestLocalPath,
        storagePath: storagePath,
      );
      final result = PhotoUploadResult.cloud(
        photo: uploadedPhoto,
        storagePath: storagePath,
      );

      state = PhotoUploadState(
        status: PhotoUploadStatus.uploaded,
        result: result,
      );
      return result;
    } on Object {
      state = const PhotoUploadState(
        status: PhotoUploadStatus.failed,
        message: 'CatDex could not upload this photo. Please retry.',
      );
      return null;
    }
  }

  void reset() {
    state = const PhotoUploadState.idle();
  }
}
