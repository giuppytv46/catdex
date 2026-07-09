import 'package:catdex/core/localization/app_locale_controller.dart';
import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key});

  @override
  ConsumerState<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  late Locale _selectedLocale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedLocale = CatDexLocalizations.bestSupportedLocale(
      PlatformDispatcher.instance.locale,
    );
    debugPrint('CATDEX_LANGUAGE_SELECTION_SHOWN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.xl),
            const Icon(
              Icons.language_rounded,
              color: AppColors.primaryPurple,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Choose your language',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You can change it later in settings.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...CatDexLocalizations.languageOptions.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  title: Text(option.nativeName),
                  trailing: Icon(
                    option.locale == _selectedLocale
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: AppColors.primaryPurple,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  tileColor: Theme.of(context).colorScheme.surface,
                  onTap: _saving
                      ? null
                      : () => setState(
                          () => _selectedLocale = option.locale,
                        ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _saving ? null : _continue,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    await ref
        .read(appLocaleControllerProvider.notifier)
        .selectLocale(_selectedLocale);
  }
}
