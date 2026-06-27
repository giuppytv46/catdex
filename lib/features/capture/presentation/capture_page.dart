import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';

class CapturePage extends StatelessWidget {
  const CapturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatDexPlaceholderPage(
      title: CatDexLocalizations.of(context).captureTitle,
      icon: Icons.center_focus_strong_rounded,
    );
  }
}
