import 'package:catdex/features/auth/application/auth_controller.dart';
import 'package:catdex/features/auth/data/fake_auth_repository.dart';
import 'package:catdex/features/auth/domain/entities/auth_failure.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts in guest mode when no user is signed in', () async {
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    final session = await container.read(authControllerProvider.future);

    expect(session.status, AuthSessionStatus.guest);
    expect(session.user, isNull);
  });

  test('signs in with email using fake repository', () async {
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    await container.read(authControllerProvider.future);
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: 'explorer@catdex.test',
          password: 'secret',
        );

    final session = container.read(authControllerProvider).value;

    expect(session?.status, AuthSessionStatus.authenticated);
    expect(session?.user?.email, 'explorer@catdex.test');
  });

  test('signs up with email using fake repository', () async {
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    await container.read(authControllerProvider.future);
    await container
        .read(authControllerProvider.notifier)
        .signUpWithEmail(
          email: 'new@catdex.test',
          password: 'secret',
        );

    final session = container.read(authControllerProvider).value;

    expect(session?.status, AuthSessionStatus.authenticated);
    expect(session?.user?.email, 'new@catdex.test');
  });

  test('shows friendly failure state for missing email', () async {
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);

    await container.read(authControllerProvider.future);
    await container
        .read(authControllerProvider.notifier)
        .signInWithEmail(
          email: '',
          password: 'secret',
        );

    final session = container.read(authControllerProvider).value;

    expect(session?.status, AuthSessionStatus.failure);
    expect(session?.failureCode, AuthFailureCode.missingEmail);
  });

  test('logs out authenticated fake user', () async {
    final repository = FakeAuthRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    addTearDown(repository.dispose);
    final notifier = container.read(authControllerProvider.notifier);

    await container.read(authControllerProvider.future);
    await notifier.signInWithEmail(
      email: 'explorer@catdex.test',
      password: 'secret',
    );
    await notifier.signOut();

    final session = container.read(authControllerProvider).value;

    expect(session?.status, AuthSessionStatus.guest);
    expect(session?.user, isNull);
  });
}

ProviderContainer _container(FakeAuthRepository repository) {
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
    ],
  );
}
