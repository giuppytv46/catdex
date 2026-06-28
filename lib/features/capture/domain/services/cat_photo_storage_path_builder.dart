import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

class CatPhotoStoragePathBuilder {
  const CatPhotoStoragePathBuilder();

  String pathFor({
    required String userId,
    required CapturedPhoto photo,
    required DateTime uploadedAt,
  }) {
    final extension = photo.extension.isEmpty ? 'jpg' : photo.extension;
    final timestamp = uploadedAt.microsecondsSinceEpoch;

    return '$userId/$timestamp.$extension';
  }

  String contentTypeForExtension(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      _ => 'application/octet-stream',
    };
  }
}
