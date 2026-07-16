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
  await runZonedGuarded(
    () async {
      final startedAt = DateTime.now();
      debugPrint('CATDEX_STARTUP_BEGIN');
      WidgetsFlutterBinding.ensureInitialized();
      await _runStartupStep(
        name: 'PREFERENCES',
        action: AppConfig.loadDotEnv,
        timeout: const Duration(seconds: 2),
      );
      await _runStartupStep(
        name: 'SUPABASE',
        action: SupabaseInitializer.initialize,
        timeout: const Duration(seconds: 6),
      );
      debugPrint('CATDEX_STARTUP_ADS_DEFERRED');
      debugPrint('CATDEX_STARTUP_READY');
      debugPrint(
        'CATDEX_STARTUP_DURATION_MS '
        '${DateTime.now().difference(startedAt).inMilliseconds}',
      );
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
      unawaited(_initializeDeferredStartupServices());
    },
    (error, stackTrace) {
      debugPrint('CATDEX_STARTUP_UNCAUGHT_ASYNC_ERROR $error');
    },
  );
}

Future<void> _runStartupStep({
  required String name,
  required Future<void> Function() action,
  required Duration timeout,
}) async {
  try {
    await action().timeout(timeout);
    debugPrint('CATDEX_STARTUP_${name}_OK');
  } on Object catch (error) {
    if (name == 'SUPABASE') {
      AppConfig.markSupabaseUnavailable();
    }
    debugPrint('CATDEX_STARTUP_${name}_FALLBACK $error');
    if (name == 'SUPABASE') {
      debugPrint('CATDEX_STARTUP_SUPABASE_FAILED $error');
    }
  }
}

Future<void> _initializeDeferredStartupServices() async {
  await AdMobService.initialize().timeout(
    const Duration(seconds: 6),
    onTimeout: () {
      debugPrint('CATDEX_STARTUP_ADS_FAILED timeout');
    },
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
      unawaited(_preloadAdsAfterInitialization());
    }
  }

  Future<void> _preloadAdsAfterInitialization() async {
    await AdMobService.initialize().timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        debugPrint('CATDEX_STARTUP_ADS_FAILED timeout');
      },
    );
    final adMobService = ref.read(adMobServiceProvider);
    unawaited(adMobService.preloadRewardedAd());
    unawaited(adMobService.preloadInterstitialAd());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
