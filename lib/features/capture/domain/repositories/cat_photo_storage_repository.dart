import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

abstract interface class CatPhotoStorageRepository {
  String get bucketName;

  Future<String> uploadCatPhoto({
    required CapturedPhoto photo,
    required String userId,
  });
}
