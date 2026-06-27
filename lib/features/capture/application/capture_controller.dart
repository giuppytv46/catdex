import 'package:catdex/features/capture/application/capture_state.dart';
import 'package:catdex/features/capture/data/local_image_picker_repository.dart';
import 'package:catdex/features/capture/data/permission_handler_photo_permission_repository.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/entities/photo_validation_result.dart';
import 'package:catdex/features/capture/domain/repositories/photo_permission_repository.dart';
import 'package:catdex/features/capture/domain/repositories/photo_picker_repository.dart';
import 'package:catdex/features/capture/domain/services/photo_validator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final photoValidatorProvider = Provider<PhotoValidator>((_) {
  return const PhotoValidator();
});

final photoPickerRepositoryProvider = Provider<PhotoPickerRepository>((_) {
  return LocalImagePickerRepository();
});

final photoPermissionRepositoryProvider = Provider<PhotoPermissionRepository>((
  _,
) {
  return const PermissionHandlerPhotoPermissionRepository();
});

final captureControllerProvider =
    NotifierProvider<CaptureController, CaptureState>(
      CaptureController.new,
    );

class CaptureController extends Notifier<CaptureState> {
  @override
  CaptureState build() {
    return const CaptureState.idle();
  }

  Future<void> takePhoto() {
    return _selectPhoto(PhotoSource.camera);
  }

  Future<void> importFromGallery() {
    return _selectPhoto(PhotoSource.gallery);
  }

  void removeSelectedPhoto() {
    state = const CaptureState.idle();
  }

  Future<void> _selectPhoto(PhotoSource source) async {
    state = state.copyWith(
      status: CaptureStatus.requestingPermission,
      clearMessage: true,
    );

    final permissionGranted = await ref
        .read(photoPermissionRepositoryProvider)
        .requestPermission(source);

    if (!permissionGranted) {
      state = const CaptureState(
        status: CaptureStatus.failure,
        message: 'CatDex needs photo access to continue.',
      );
      return;
    }

    state = state.copyWith(status: CaptureStatus.picking);

    try {
      final photo = await ref
          .read(photoPickerRepositoryProvider)
          .pickPhoto(
            source,
          );
      final validationResult = ref.read(photoValidatorProvider).validate(photo);

      switch (validationResult) {
        case ValidPhotoValidationResult():
          state = CaptureState(status: CaptureStatus.selected, photo: photo);
        case InvalidPhotoValidationResult(:final message):
          state = CaptureState(status: CaptureStatus.invalid, message: message);
      }
    } on Object {
      state = const CaptureState(
        status: CaptureStatus.failure,
        message: 'Something went wrong while choosing that photo.',
      );
    }
  }
}
