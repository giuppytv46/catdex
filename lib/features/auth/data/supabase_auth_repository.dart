import 'package:catdex/features/auth/domain/entities/auth_failure.dart';
import 'package:catdex/features/auth/domain/entities/auth_user.dart';
import 'package:catdex/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository(this._client);

  final supabase.SupabaseClient _client;

  @override
  Future<AuthUser?> currentUser() async {
    return _mapUser(_client.auth.currentUser);
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((state) {
      return _mapUser(state.session?.user);
    });
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return _requiredUser(response.user);
    } on supabase.AuthException {
      throw const AuthFailure(AuthFailureCode.invalidCredentials);
    } on Object {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      return _requiredUser(response.user);
    } on supabase.AuthException {
      throw const AuthFailure(AuthFailureCode.invalidCredentials);
    } on Object {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AuthUser _requiredUser(supabase.User? user) {
    final authUser = _mapUser(user);
    if (authUser == null) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }

    return authUser;
  }

  AuthUser? _mapUser(supabase.User? user) {
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      return null;
    }

    return AuthUser(id: user.id, email: email);
  }
}
