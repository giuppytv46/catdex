import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/services/cat_photo_storage_path_builder.dart';
import 'package:test/test.dart';

void main() {
  test('maps photos to private user-prefixed storage paths', () {
    const builder = CatPhotoStoragePathBuilder();

    final path = builder.pathFor(
      userId: 'user-1',
      photo: _photo(path: '/tmp/cat.png'),
      uploadedAt: DateTime.utc(2026, 6, 28, 12),
    );

    expect(path, startsWith('user-1/'));
    expect(path, endsWith('.png'));
  });

  test('maps known image extensions to content types', () {
    const builder = CatPhotoStoragePathBuilder();

    expect(builder.contentTypeForExtension('jpg'), 'image/jpeg');
    expect(builder.contentTypeForExtension('png'), 'image/png');
    expect(builder.contentTypeForExtension('heic'), 'image/heic');
  });
}

CapturedPhoto _photo({required String path}) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}
