import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GlobalErrorPage extends StatelessWidget {
  const GlobalErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return CatDexPlaceholderPage(
      title: l10n.globalErrorTitle,
      icon: Icons.error_rounded,
      message: l10n.globalErrorMessage,
      primaryAction: FilledButton.icon(
        onPressed: () => context.goNamed(AppRoute.home.name),
        icon: const Icon(Icons.home_rounded),
        label: Text(l10n.backHomeAction),
      ),
    );
  }
}
