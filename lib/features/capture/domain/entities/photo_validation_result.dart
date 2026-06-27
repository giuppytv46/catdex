sealed class PhotoValidationResult {
  const PhotoValidationResult();

  bool get isValid => this is ValidPhotoValidationResult;
}

class ValidPhotoValidationResult extends PhotoValidationResult {
  const ValidPhotoValidationResult();
}

class InvalidPhotoValidationResult extends PhotoValidationResult {
  const InvalidPhotoValidationResult(this.message);

  final String message;
}
