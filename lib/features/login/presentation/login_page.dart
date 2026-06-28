import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/auth/application/auth_controller.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => const AuthSession.guest(),
    };
    final failureCode = session.failureCode;

    ref.listen(authControllerProvider, (_, next) {
      final nextSession = switch (next) {
        AsyncData(:final value) => value,
        _ => null,
      };
      if (nextSession?.status == AuthSessionStatus.authenticated) {
        context.goNamed(AppRoute.home.name);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.loginTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LoginBadge(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.authWelcomeTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.authWelcomeMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        prefixIcon: const Icon(Icons.email_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_rounded),
                      ),
                    ),
                    if (failureCode != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.authFailureMessage(failureCode.name),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: session.isLoading
                          ? null
                          : () {
                              unawaited(
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signInWithEmail(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    ),
                              );
                            },
                      icon: const Icon(Icons.login_rounded),
                      label: Text(l10n.loginAction),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: session.isLoading
                          ? null
                          : () {
                              unawaited(
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signUpWithEmail(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    ),
                              );
                            },
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: Text(l10n.signupAction),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginBadge extends StatelessWidget {
  const _LoginBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryPurple],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.lock_rounded, color: AppColors.white, size: 44),
      ),
    );
  }
}
