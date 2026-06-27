sealed class LocationValidationResult {
  const LocationValidationResult();

  bool get isValid => this is ValidLocationValidationResult;
}

class ValidLocationValidationResult extends LocationValidationResult {
  const ValidLocationValidationResult();
}

class InvalidLocationValidationResult extends LocationValidationResult {
  const InvalidLocationValidationResult(this.message);

  final String message;
}
