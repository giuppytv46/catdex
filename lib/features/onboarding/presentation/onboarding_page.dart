import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return CatDexPlaceholderPage(
      title: l10n.onboardingTitle,
      icon: Icons.auto_awesome_rounded,
      action: IconButton(
        tooltip: l10n.loginTitle,
        icon: const Icon(Icons.arrow_forward_rounded),
        onPressed: () => context.goNamed(AppRoute.login.name),
      ),
    );
  }
}
