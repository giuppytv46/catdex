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

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => const AuthSession.guest(),
    };
    final user = session.user;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
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
                    const _ProfileBadge(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      user == null
                          ? l10n.guestModeTitle
                          : l10n.signedInEmailLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user?.email ?? l10n.guestModeMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (user == null)
                      FilledButton.icon(
                        onPressed: () => context.goNamed(AppRoute.login.name),
                        icon: const Icon(Icons.login_rounded),
                        label: Text(l10n.loginAction),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: session.isLoading
                            ? null
                            : () {
                                unawaited(
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .signOut(),
                                );
                              },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.logoutAction),
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

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.skyBlue, AppColors.primaryPurple],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.white,
          size: 44,
        ),
      ),
    );
  }
}
