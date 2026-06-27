import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/widgets/catdex_placeholder_page.dart';
import 'package:flutter/material.dart';

class GlobalErrorPage extends StatelessWidget {
  const GlobalErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CatDexPlaceholderPage(
      title: CatDexLocalizations.of(context).globalErrorTitle,
      icon: Icons.error_rounded,
    );
  }
}
