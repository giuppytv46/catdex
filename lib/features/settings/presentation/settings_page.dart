import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CatDexLocalizations.of(context).settingsTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ListTile(
              leading: const Icon(Icons.workspace_premium_rounded),
              title: const Text('CatDex Premium'),
              subtitle: const Text(
                'Plans, scan limits, and restore placeholder',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.pushNamed(AppRoute.premium.name),
            ),
          ],
        ),
      ),
    );
  }
}
