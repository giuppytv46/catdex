import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';

class CatDexPage extends StatelessWidget {
  const CatDexPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatDexPlaceholderPage(
      title: CatDexLocalizations.of(context).catDexTitle,
      icon: Icons.style_rounded,
    );
  }
}
