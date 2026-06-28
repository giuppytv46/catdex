enum AuthFailureCode {
  missingEmail,
  missingPassword,
  invalidCredentials,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final AuthFailureCode code;
}
