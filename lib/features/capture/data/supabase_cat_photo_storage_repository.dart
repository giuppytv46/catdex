import 'dart:io';
import 'dart:typed_data';

import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/repositories/cat_photo_storage_repository.dart';
import 'package:catdex/features/capture/domain/services/cat_photo_storage_path_builder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCatPhotoStorageRepository implements CatPhotoStorageRepository {
  const SupabaseCatPhotoStorageRepository(
    this._client, {
    CatPhotoStoragePathBuilder pathBuilder = const CatPhotoStoragePathBuilder(),
  }) : _pathBuilder = pathBuilder;

  static const catPhotosBucketName = 'cat-photos';

  final SupabaseClient _client;
  final CatPhotoStoragePathBuilder _pathBuilder;

  @override
  String get bucketName => catPhotosBucketName;

  @override
  Future<String> uploadCatPhoto({
    required CapturedPhoto photo,
    required String userId,
  }) async {
    final storagePath = _pathBuilder.pathFor(
      userId: userId,
      photo: photo,
      uploadedAt: DateTime.now().toUtc(),
    );
    final bytes = await File(photo.path).readAsBytes();

    await uploadBytes(
      storagePath: storagePath,
      bytes: bytes,
      contentType: _pathBuilder.contentTypeForExtension(photo.extension),
    );

    return storagePath;
  }

  Future<void> uploadBytes({
    required String storagePath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(bucketName)
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
  }
}
