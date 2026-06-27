import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/entities/photo_validation_result.dart';
import 'package:catdex/features/capture/domain/services/photo_validator.dart';
import 'package:test/test.dart';

void main() {
  group('PhotoValidator', () {
    const validator = PhotoValidator();

    test('accepts supported image formats under 10 MB', () {
      for (final extension in ['jpg', 'jpeg', 'png', 'heic']) {
        final result = validator.validate(
          _photo(path: 'cat.$extension'),
        );

        expect(result, isA<ValidPhotoValidationResult>());
      }
    });

    test('rejects null photos', () {
      final result = validator.validate(null);

      expect(result, isA<InvalidPhotoValidationResult>());
    });

    test('rejects empty files', () {
      final result = validator.validate(_photo(path: 'cat.jpg', sizeBytes: 0));

      expect(result, isA<InvalidPhotoValidationResult>());
    });

    test('rejects unsupported formats', () {
      final result = validator.validate(_photo(path: 'cat.gif'));

      expect(result, isA<InvalidPhotoValidationResult>());
    });

    test('rejects files over 10 MB', () {
      final result = validator.validate(
        _photo(path: 'cat.png', sizeBytes: PhotoValidator.maxFileSizeBytes + 1),
      );

      expect(result, isA<InvalidPhotoValidationResult>());
    });
  });
}

CapturedPhoto _photo({
  required String path,
  int sizeBytes = 1024,
}) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: sizeBytes,
    capturedAt: DateTime.utc(2026),
  );
}
