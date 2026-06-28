import 'package:catdex/features/capture/application/photo_upload_controller.dart';
import 'package:catdex/features/capture/application/photo_upload_state.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/repositories/cat_photo_storage_repository.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest mode does not upload and keeps local path', () async {
    final storageRepository = _RecordingStorageRepository();
    final container = _container(
      session: const ActiveCatDexSession.guest(playerId: 'local-explorer'),
      storageRepository: storageRepository,
    );
    addTearDown(container.dispose);

    final result = await container
        .read(photoUploadControllerProvider.notifier)
        .prepareForAnalysis(_photo());

    expect(result?.photo.path, 'cat.jpg');
    expect(result?.storagePath, isNull);
    expect(storageRepository.uploadCount, 0);
    expect(
      container.read(photoUploadControllerProvider).status,
      PhotoUploadStatus.uploaded,
    );
  });

  test('logged-in mode uploads with storage repository', () async {
    final storageRepository = _RecordingStorageRepository(
      storagePath: 'cloud-user/123.jpg',
    );
    final container = _container(
      session: const ActiveCatDexSession.cloud(playerId: 'cloud-user'),
      storageRepository: storageRepository,
    );
    addTearDown(container.dispose);

    final result = await container
        .read(photoUploadControllerProvider.notifier)
        .prepareForAnalysis(_photo());

    expect(result?.photo.path, 'cloud-user/123.jpg');
    expect(result?.storagePath, 'cloud-user/123.jpg');
    expect(storageRepository.uploadCount, 1);
    expect(storageRepository.lastUserId, 'cloud-user');
  });

  test('upload failure maps to friendly failed state', () async {
    final container = _container(
      session: const ActiveCatDexSession.cloud(playerId: 'cloud-user'),
      storageRepository: _FailingStorageRepository(),
    );
    addTearDown(container.dispose);

    final result = await container
        .read(photoUploadControllerProvider.notifier)
        .prepareForAnalysis(_photo());
    final state = container.read(photoUploadControllerProvider);

    expect(result, isNull);
    expect(state.status, PhotoUploadStatus.failed);
    expect(state.message, contains('retry'));
  });

  test('rejects oversized images before upload', () async {
    final storageRepository = _RecordingStorageRepository();
    final container = _container(
      session: const ActiveCatDexSession.cloud(playerId: 'cloud-user'),
      storageRepository: storageRepository,
    );
    addTearDown(container.dispose);

    final result = await container
        .read(photoUploadControllerProvider.notifier)
        .prepareForAnalysis(_photo(sizeBytes: 11 * 1024 * 1024));

    expect(result, isNull);
    expect(storageRepository.uploadCount, 0);
    expect(
      container.read(photoUploadControllerProvider).status,
      PhotoUploadStatus.failed,
    );
  });
}

ProviderContainer _container({
  required ActiveCatDexSession session,
  required CatPhotoStorageRepository storageRepository,
}) {
  return ProviderContainer(
    overrides: [
      activeCatDexSessionProvider.overrideWithValue(session),
      catPhotoStorageRepositoryProvider.overrideWithValue(storageRepository),
    ],
  );
}

CapturedPhoto _photo({
  String path = 'cat.jpg',
  int sizeBytes = 1024,
}) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: sizeBytes,
    capturedAt: DateTime.utc(2026),
  );
}

class _RecordingStorageRepository implements CatPhotoStorageRepository {
  _RecordingStorageRepository({this.storagePath = 'uploaded/cat.jpg'});

  final String storagePath;
  int uploadCount = 0;
  String? lastUserId;

  @override
  String get bucketName => 'cat-photos';

  @override
  Future<String> uploadCatPhoto({
    required CapturedPhoto photo,
    required String userId,
  }) async {
    uploadCount += 1;
    lastUserId = userId;
    return storagePath;
  }
}

class _FailingStorageRepository implements CatPhotoStorageRepository {
  @override
  String get bucketName => 'cat-photos';

  @override
  Future<String> uploadCatPhoto({
    required CapturedPhoto photo,
    required String userId,
  }) async {
    throw StateError('storage unavailable');
  }
}
