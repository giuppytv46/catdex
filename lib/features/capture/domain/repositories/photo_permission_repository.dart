// Sprint 4 requires a repository boundary for permission access.
// ignore_for_file: one_member_abstracts

import 'package:catdex/features/capture/domain/entities/photo_source.dart';

abstract interface class PhotoPermissionRepository {
  Future<bool> requestPermission(PhotoSource source);
}
