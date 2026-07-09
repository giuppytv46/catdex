import 'dart:async';

import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/core/localization/app_locale_controller.dart';
import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/core/localization/language_selection_page.dart';
import 'package:catdex/core/supabase/supabase_initializer.dart';
import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/features/onboarding/data/shared_preferences_onboarding_repository.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:catdex/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadDotEnv();
  await SupabaseInitializer.initialize();
  await AdMobService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        onboardingRepositoryProvider.overrideWithValue(
          const SharedPreferencesOnboardingRepository(),
        ),
      ],
      child: const CatDexApp(),
    ),
  );
}

class CatDexApp extends ConsumerWidget {
  const CatDexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final localeState = ref.watch(appLocaleControllerProvider);
    final selectedLocale = switch (localeState) {
      AsyncData(:final value) => value,
      _ => null,
    };

    return _RewardedAdPreloadScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: CatDexLocalizations.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: selectedLocale,
        routerConfig: router,
        localizationsDelegates: CatDexLocalizations.localizationsDelegates,
        supportedLocales: CatDexLocalizations.supportedLocales,
        builder: (context, child) {
          return switch (localeState) {
            AsyncLoading() => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            AsyncError() => const LanguageSelectionPage(),
            AsyncData(value: null) => const LanguageSelectionPage(),
            AsyncData() => child ?? const SizedBox.shrink(),
          };
        },
      ),
    );
  }
}

class _RewardedAdPreloadScope extends ConsumerStatefulWidget {
  const _RewardedAdPreloadScope({required this.child});

  final Widget child;

  @override
  ConsumerState<_RewardedAdPreloadScope> createState() =>
      _RewardedAdPreloadScopeState();
}

class _RewardedAdPreloadScopeState
    extends ConsumerState<_RewardedAdPreloadScope> {
  @override
  void initState() {
    super.initState();
    if (showAds) {
      final adMobService = ref.read(adMobServiceProvider);
      unawaited(adMobService.preloadRewardedAd());
      unawaited(adMobService.preloadInterstitialAd());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
