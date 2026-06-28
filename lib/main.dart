import 'package:catdex/core/config/app_config.dart';
import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/core/supabase/supabase_initializer.dart';
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

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: CatDexLocalizations.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: CatDexLocalizations.localizationsDelegates,
      supportedLocales: CatDexLocalizations.supportedLocales,
    );
  }
}
