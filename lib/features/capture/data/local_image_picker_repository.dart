import 'dart:io';

import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/capture/domain/repositories/photo_picker_repository.dart';
import 'package:image_picker/image_picker.dart';

class LocalImagePickerRepository implements PhotoPickerRepository {
  LocalImagePickerRepository({
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  @override
  Future<CapturedPhoto?> pickPhoto(PhotoSource source) async {
    final pickedImage = await _imagePicker.pickImage(
      source: switch (source) {
        PhotoSource.camera => ImageSource.camera,
        PhotoSource.gallery => ImageSource.gallery,
      },
      imageQuality: 95,
    );

    if (pickedImage == null) {
      return null;
    }

    final file = File(pickedImage.path);

    return CapturedPhoto(
      path: pickedImage.path,
      source: source,
      sizeBytes: await file.length(),
      capturedAt: DateTime.now(),
    );
  }
}
