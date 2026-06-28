import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

class PhotoUploadResult {
  const PhotoUploadResult.local(this.photo) : storagePath = null;

  const PhotoUploadResult.cloud({
    required this.photo,
    required this.storagePath,
  });

  final CapturedPhoto photo;
  final String? storagePath;
}
