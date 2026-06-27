// Sprint 4 requires a repository boundary for local image picking.
// ignore_for_file: one_member_abstracts

import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';

abstract interface class PhotoPickerRepository {
  Future<CapturedPhoto?> pickPhoto(PhotoSource source);
}
