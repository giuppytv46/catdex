import 'dart:async';

import 'package:catdex/features/auth/domain/entities/auth_failure.dart';
import 'package:catdex/features/auth/domain/entities/auth_user.dart';
import 'package:catdex/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initialUser}) : _currentUser = initialUser;

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  Future<AuthUser?> currentUser() async {
    return _currentUser;
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _controller.stream;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return _authenticate(email: email, password: password);
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return _authenticate(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  AuthUser _authenticate({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty) {
      throw const AuthFailure(AuthFailureCode.missingEmail);
    }

    if (password.isEmpty) {
      throw const AuthFailure(AuthFailureCode.missingPassword);
    }

    final user = AuthUser(id: 'local-${email.trim()}', email: email.trim());
    _currentUser = user;
    _controller.add(user);

    return user;
  }
}
