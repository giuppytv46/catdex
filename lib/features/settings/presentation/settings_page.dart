import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatDexPlaceholderPage(
      title: CatDexLocalizations.of(context).settingsTitle,
      icon: Icons.settings_rounded,
    );
  }
}
