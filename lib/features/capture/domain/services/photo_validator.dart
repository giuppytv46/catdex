import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_validation_result.dart';

class PhotoValidator {
  const PhotoValidator();

  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const Set<String> allowedExtensions = {'jpg', 'jpeg', 'png', 'heic'};

  PhotoValidationResult validate(CapturedPhoto? photo) {
    if (photo == null) {
      return const InvalidPhotoValidationResult(
        'Choose a cat photo before continuing.',
      );
    }

    if (photo.path.trim().isEmpty || photo.sizeBytes == 0) {
      return const InvalidPhotoValidationResult(
        'That image looks empty. Please choose another photo.',
      );
    }

    if (!allowedExtensions.contains(photo.extension)) {
      return const InvalidPhotoValidationResult(
        'CatDex supports JPG, PNG, and HEIC images.',
      );
    }

    if (photo.sizeBytes > maxFileSizeBytes) {
      return const InvalidPhotoValidationResult(
        'That image is too large. Please choose one under 10 MB.',
      );
    }

    return const ValidPhotoValidationResult();
  }
}
