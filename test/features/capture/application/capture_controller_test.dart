import 'package:catdex/features/capture/application/capture_controller.dart';
import 'package:catdex/features/capture/application/capture_state.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/repositories/photo_permission_repository.dart';
import 'package:catdex/features/capture/domain/repositories/photo_picker_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaptureController', () {
    test('starts idle', () {
      final container = _container();
      addTearDown(container.dispose);

      expect(
        container.read(captureControllerProvider).status,
        CaptureStatus.idle,
      );
    });

    test('selects a valid gallery image', () async {
      final container = _container(
        picker: _FakePhotoPickerRepository(photo: _photo('cat.jpg')),
      );
      addTearDown(container.dispose);

      await container
          .read(captureControllerProvider.notifier)
          .importFromGallery();

      final state = container.read(captureControllerProvider);

      expect(state.status, CaptureStatus.selected);
      expect(state.canContinue, isTrue);
      expect(state.photo?.path, 'cat.jpg');
    });

    test('moves to invalid when validation fails', () async {
      final container = _container(
        picker: _FakePhotoPickerRepository(photo: _photo('cat.gif')),
      );
      addTearDown(container.dispose);

      await container.read(captureControllerProvider.notifier).takePhoto();

      final state = container.read(captureControllerProvider);

      expect(state.status, CaptureStatus.invalid);
      expect(state.canContinue, isFalse);
      expect(state.message, isNotEmpty);
    });

    test('moves to failure when permission is denied', () async {
      final container = _container(
        permissions: const _FakePhotoPermissionRepository(granted: false),
      );
      addTearDown(container.dispose);

      await container.read(captureControllerProvider.notifier).takePhoto();

      final state = container.read(captureControllerProvider);

      expect(state.status, CaptureStatus.failure);
      expect(state.canContinue, isFalse);
    });

    test('removes a selected image', () async {
      final container = _container(
        picker: _FakePhotoPickerRepository(photo: _photo('cat.png')),
      );
      addTearDown(container.dispose);

      final controller = container.read(captureControllerProvider.notifier);
      await controller.importFromGallery();
      controller.removeSelectedPhoto();

      final state = container.read(captureControllerProvider);

      expect(state.status, CaptureStatus.idle);
      expect(state.photo, isNull);
    });
  });
}

ProviderContainer _container({
  PhotoPickerRepository? picker,
  PhotoPermissionRepository? permissions,
}) {
  return ProviderContainer(
    overrides: [
      photoPickerRepositoryProvider.overrideWithValue(
        picker ?? _FakePhotoPickerRepository(photo: _photo('cat.jpg')),
      ),
      photoPermissionRepositoryProvider.overrideWithValue(
        permissions ?? const _FakePhotoPermissionRepository(),
      ),
    ],
  );
}

CapturedPhoto _photo(String path) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}

class _FakePhotoPickerRepository implements PhotoPickerRepository {
  const _FakePhotoPickerRepository({required this.photo});

  final CapturedPhoto? photo;

  @override
  Future<CapturedPhoto?> pickPhoto(PhotoSource source) async {
    return photo;
  }
}

class _FakePhotoPermissionRepository implements PhotoPermissionRepository {
  const _FakePhotoPermissionRepository({this.granted = true});

  final bool granted;

  @override
  Future<bool> requestPermission(PhotoSource source) async {
    return granted;
  }
}
