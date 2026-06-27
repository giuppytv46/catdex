import 'package:catdex/features/app_shell/presentation/catdex_app_shell.dart';
import 'package:catdex/features/capture/presentation/capture_page.dart';
import 'package:catdex/features/catdex/presentation/catdex_page.dart';
import 'package:catdex/features/error/presentation/global_error_page.dart';
import 'package:catdex/features/friends/presentation/friends_page.dart';
import 'package:catdex/features/home/presentation/home_page.dart';
import 'package:catdex/features/login/presentation/login_page.dart';
import 'package:catdex/features/offline/presentation/offline_page.dart';
import 'package:catdex/features/onboarding/presentation/onboarding_page.dart';
import 'package:catdex/features/profile/presentation/profile_page.dart';
import 'package:catdex/features/settings/presentation/settings_page.dart';
import 'package:catdex/features/splash/presentation/splash_page.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/widgets/unknown_route_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((_) {
  return GoRouter(
    initialLocation: AppRoute.splash.path,
    routes: [
      GoRoute(path: '/', redirect: _redirectToSplash),
      _animatedRoute(route: AppRoute.splash, child: const SplashPage()),
      _animatedRoute(route: AppRoute.onboarding, child: const OnboardingPage()),
      _animatedRoute(route: AppRoute.login, child: const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: _buildShell,
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.home.path,
                name: AppRoute.home.name,
                pageBuilder: (_, state) {
                  return _fadePage(state: state, child: const HomePage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.catDex.path,
                name: AppRoute.catDex.name,
                pageBuilder: (_, state) {
                  return _fadePage(state: state, child: const CatDexPage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.capture.path,
                name: AppRoute.capture.name,
                pageBuilder: (_, state) {
                  return _fadePage(state: state, child: const CapturePage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.friends.path,
                name: AppRoute.friends.name,
                pageBuilder: (_, state) {
                  return _fadePage(state: state, child: const FriendsPage());
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoute.profile.path,
                name: AppRoute.profile.name,
                pageBuilder: (_, state) {
                  return _fadePage(state: state, child: const ProfilePage());
                },
              ),
            ],
          ),
        ],
      ),
      _animatedRoute(route: AppRoute.settings, child: const SettingsPage()),
      _animatedRoute(route: AppRoute.offline, child: const OfflinePage()),
      _animatedRoute(
        route: AppRoute.globalError,
        child: const GlobalErrorPage(),
      ),
    ],
    errorPageBuilder: (_, state) {
      return _fadePage(state: state, child: const UnknownRoutePage());
    },
  );
});

GoRoute _animatedRoute({required AppRoute route, required Widget child}) {
  return GoRoute(
    path: route.path,
    name: route.name,
    pageBuilder: (_, state) {
      return CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionsBuilder: _slideTransition,
      );
    },
  );
}

CustomTransitionPage<void> _fadePage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 250),
    child: child,
    transitionsBuilder: _fadeTransition,
  );
}

String _redirectToSplash(BuildContext _, GoRouterState _) {
  return AppRoute.splash.path;
}

Widget _buildShell(
  BuildContext _,
  GoRouterState _,
  StatefulNavigationShell navigationShell,
) {
  return CatDexAppShell(navigationShell: navigationShell);
}

Widget _slideTransition(
  BuildContext _,
  Animation<double> animation,
  Animation<double> _,
  Widget child,
) {
  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: curvedAnimation,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation),
      child: child,
    ),
  );
}

Widget _fadeTransition(
  BuildContext _,
  Animation<double> animation,
  Animation<double> _,
  Widget child,
) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
    child: child,
  );
}
