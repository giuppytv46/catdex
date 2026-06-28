import 'package:catdex/features/auth/domain/entities/auth_failure.dart';
import 'package:catdex/features/auth/domain/entities/auth_user.dart';

enum AuthSessionStatus {
  guest,
  loading,
  authenticated,
  failure,
}

class AuthSession {
  const AuthSession({
    required this.status,
    this.user,
    this.failureCode,
  });

  const AuthSession.guest() : this(status: AuthSessionStatus.guest);

  const AuthSession.loading({AuthUser? user})
    : this(status: AuthSessionStatus.loading, user: user);

  const AuthSession.authenticated(AuthUser user)
    : this(status: AuthSessionStatus.authenticated, user: user);

  const AuthSession.failure(AuthFailureCode code, {AuthUser? user})
    : this(
        status: AuthSessionStatus.failure,
        user: user,
        failureCode: code,
      );

  final AuthSessionStatus status;
  final AuthUser? user;
  final AuthFailureCode? failureCode;

  bool get isAuthenticated => user != null;
  bool get isLoading => status == AuthSessionStatus.loading;
}
