import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatDexPlaceholderPage(
      title: CatDexLocalizations.of(context).offlineTitle,
      icon: Icons.wifi_off_rounded,
    );
  }
}
