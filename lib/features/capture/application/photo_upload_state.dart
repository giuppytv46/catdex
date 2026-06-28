import 'package:catdex/features/capture/domain/entities/photo_upload_result.dart';

enum PhotoUploadStatus {
  idle,
  uploading,
  uploaded,
  failed,
}

class PhotoUploadState {
  const PhotoUploadState({
    required this.status,
    this.result,
    this.message,
  });

  const PhotoUploadState.idle() : this(status: PhotoUploadStatus.idle);

  final PhotoUploadStatus status;
  final PhotoUploadResult? result;
  final String? message;
}
