import 'dart:async';

import 'package:catdex/core/localization/app_locale_controller.dart';
import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/auth/application/auth_controller.dart';
import 'package:catdex/features/auth/domain/entities/auth_session.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_controls.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_panel.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final localeState = ref.watch(appLocaleControllerProvider);
    final selectedLocale = switch (localeState) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final authState = ref.watch(authControllerProvider);
    final session = switch (authState) {
      AsyncData(:final value) => value,
      _ => const AuthSession.guest(),
    };
    final user = session.user;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: const Color(0xFF1E243B),
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(color: Color(0xFF1E243B)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            128,
          ),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _ProfileBadge(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      user == null
                          ? l10n.guestModeTitle
                          : l10n.signedInEmailLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      user?.email ?? l10n.guestModeMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (user == null)
                      FilledButton.icon(
                        onPressed: () => context.goNamed(AppRoute.login.name),
                        icon: const Icon(Icons.login_rounded),
                        label: Text(l10n.loginAction),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: session.isLoading
                            ? null
                            : () {
                                unawaited(
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .signOut(),
                                );
                              },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.logoutAction),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: DropdownButtonFormField<Locale>(
                  key: ValueKey(localeTag(selectedLocale)),
                  initialValue: selectedLocale,
                  decoration: InputDecoration(
                    labelText: l10n.settingsLanguage,
                    prefixIcon: const Icon(Icons.language_rounded),
                  ),
                  items: CatDexLocalizations.languageOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option.locale,
                          child: Text(option.nativeName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (locale) {
                    if (locale != null && locale != selectedLocale) {
                      unawaited(
                        ref
                            .read(appLocaleControllerProvider.notifier)
                            .selectLocale(
                              locale,
                              changedFromSettings: true,
                            ),
                      );
                    }
                  },
                ),
              ),
            ),
            const CatDexBannerAdWidget(
              placementLog: 'CATDEX_AD_BANNER_PLACEMENT_TOP_PROFILE',
            ),
            const SizedBox(height: AppSpacing.lg),
            _AlphaTesterInfoCard(selectedLocale: selectedLocale),
            if (showMonetizationDebug) ...[
              const SizedBox(height: AppSpacing.lg),
              const MonetizationDebugPanel(),
            ],
            const CatDexBannerAdWidget(
              placementLog: 'CATDEX_AD_BANNER_PLACEMENT_BOTTOM_PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}

class _AlphaTesterInfoCard extends ConsumerWidget {
  const _AlphaTesterInfoCard({required this.selectedLocale});

  final Locale? selectedLocale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final languageName = _languageName(selectedLocale);
    final premiumStatus = showMonetizationDebug
        ? ref.watch(monetizationStatusProvider)
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.science_rounded,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.alphaInfoTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _AlphaInfoLine(label: l10n.alphaBuildLabel, value: 'Alpha 0.1.0'),
            _AlphaInfoLine(
              label: l10n.alphaCurrentLanguageLabel,
              value: languageName,
            ),
            if (showMonetizationDebug && premiumStatus != null)
              _AlphaInfoLine(
                label: l10n.alphaPremiumDebugLabel,
                value: premiumStatus.maybeWhen(
                  data: (status) => status.isPremium ? 'ON' : 'OFF',
                  orElse: () => '-',
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.alphaTesterMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _languageName(Locale? locale) {
    if (locale == null) {
      return '-';
    }

    for (final option in CatDexLocalizations.languageOptions) {
      if (option.locale.languageCode == locale.languageCode &&
          option.locale.countryCode == locale.countryCode) {
        return option.nativeName;
      }
    }

    return locale.toLanguageTag();
  }
}

class _AlphaInfoLine extends StatelessWidget {
  const _AlphaInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.skyBlue, AppColors.primaryPurple],
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: AppColors.white,
          size: 44,
        ),
      ),
    );
  }
}
