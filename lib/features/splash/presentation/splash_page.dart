import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_redirectAfterOnboardingCheck());
    });
  }

  Future<void> _redirectAfterOnboardingCheck() async {
    final completed = await ref
        .read(onboardingControllerProvider.future)
        .catchError((_) => false);
    if (!mounted) {
      return;
    }

    context.goNamed(completed ? AppRoute.home.name : AppRoute.onboarding.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return CatDexPlaceholderPage(
      title: l10n.splashTitle,
      icon: Icons.pets_rounded,
      message: l10n.onboardingLoadingMessage,
      primaryAction: const Padding(
        padding: EdgeInsets.only(top: AppSpacing.sm),
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ),
    );
  }
}
