import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UnknownRoutePage extends StatelessWidget {
  const UnknownRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return CatDexPlaceholderPage(
      title: l10n.unknownRouteTitle,
      icon: Icons.explore_off_rounded,
      message: l10n.unknownRouteMessage,
      primaryAction: FilledButton.icon(
        onPressed: () => context.goNamed(AppRoute.home.name),
        icon: const Icon(Icons.home_rounded),
        label: Text(l10n.backHomeAction),
      ),
    );
  }
}
