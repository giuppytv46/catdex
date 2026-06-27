import 'dart:io';

import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/repositories/photo_permission_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerPhotoPermissionRepository
    implements PhotoPermissionRepository {
  const PermissionHandlerPhotoPermissionRepository();

  @override
  Future<bool> requestPermission(PhotoSource source) async {
    if (source == PhotoSource.gallery && !Platform.isIOS) {
      return true;
    }

    final permission = switch (source) {
      PhotoSource.camera => Permission.camera,
      PhotoSource.gallery => Permission.photos,
    };
    final status = await permission.request();

    return status.isGranted || status.isLimited;
  }
}
