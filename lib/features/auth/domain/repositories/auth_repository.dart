import 'package:catdex/features/auth/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> currentUser();

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
