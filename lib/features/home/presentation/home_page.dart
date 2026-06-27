import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return CatDexPlaceholderPage(
      title: l10n.homeTitle,
      icon: Icons.home_rounded,
      action: IconButton(
        tooltip: l10n.settingsTitle,
        icon: const Icon(Icons.settings_rounded),
        onPressed: () => context.pushNamed(AppRoute.settings.name),
      ),
    );
  }
}
