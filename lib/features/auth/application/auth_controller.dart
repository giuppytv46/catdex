import 'dart:async';

import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/features/auth/data/fake_auth_repository.dart';
import 'package:catdex/features/auth/data/supabase_auth_repository.dart';
import 'package:catdex/features/auth/domain/entities/auth_failure.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:catdex/features/auth/domain/entities/auth_user.dart';
import 'package:catdex/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

final authRepositoryProvider = Provider<AuthRepository>((_) {
  if (AppConfig.hasSupabaseConfig) {
    return SupabaseAuthRepository(supabase.Supabase.instance.client);
  }

  return FakeAuthRepository();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession> {
  StreamSubscription<AuthUser?>? _subscription;

  @override
  Future<AuthSession> build() async {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });

    final repository = ref.watch(authRepositoryProvider);
    _subscription = repository.authStateChanges().listen((user) {
      state = AsyncData(_sessionForUser(user));
    });

    return _sessionForUser(await repository.currentUser());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      email: email,
      password: password,
      action: ref.read(authRepositoryProvider).signInWithEmail,
    );
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    await _authenticate(
      email: email,
      password: password,
      action: ref.read(authRepositoryProvider).signUpWithEmail,
    );
  }

  Future<void> signOut() async {
    final previousUser = state.value?.user;
    state = AsyncData(AuthSession.loading(user: previousUser));

    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(AuthSession.guest());
    } on Object {
      state = AsyncData(
        AuthSession.failure(AuthFailureCode.unknown, user: previousUser),
      );
    }
  }

  Future<void> _authenticate({
    required String email,
    required String password,
    required Future<AuthUser> Function({
      required String email,
      required String password,
    })
    action,
  }) async {
    final trimmedEmail = email.trim();
    final previousUser = state.value?.user;
    final validationFailure = _validateCredentials(
      email: trimmedEmail,
      password: password,
    );

    if (validationFailure != null) {
      state = AsyncData(
        AuthSession.failure(validationFailure, user: previousUser),
      );
      return;
    }

    state = AsyncData(AuthSession.loading(user: previousUser));

    try {
      final user = await action(email: trimmedEmail, password: password);
      state = AsyncData(AuthSession.authenticated(user));
    } on AuthFailure catch (failure) {
      state = AsyncData(
        AuthSession.failure(failure.code, user: previousUser),
      );
    } on Object {
      state = AsyncData(
        AuthSession.failure(AuthFailureCode.unknown, user: previousUser),
      );
    }
  }

  AuthFailureCode? _validateCredentials({
    required String email,
    required String password,
  }) {
    if (email.isEmpty) {
      return AuthFailureCode.missingEmail;
    }

    if (password.isEmpty) {
      return AuthFailureCode.missingPassword;
    }

    return null;
  }

  AuthSession _sessionForUser(AuthUser? user) {
    if (user == null) {
      return const AuthSession.guest();
    }

    return AuthSession.authenticated(user);
  }
}
