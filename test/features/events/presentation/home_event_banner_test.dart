import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/events/application/event_ui_state.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:catdex/features/events/presentation/home_event_banner.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('Home event banner appears for active event', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeEventUiStateProvider.overrideWith((ref) async => _state()),
        ],
        child: _app(
          HomeActiveEventSection(onOpen: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home_event_banner')), findsOneWidget);
    expect(find.text('Halloween CatDex'), findsOneWidget);
  });

  testWidgets('Home event banner is absent without active event', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeEventUiStateProvider.overrideWith((ref) async => null),
        ],
        child: _app(
          HomeActiveEventSection(onOpen: (_) {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('home_event_banner')), findsNothing);
  });

  testWidgets('Home banner opens the matching event route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: HomeEventBanner(
              state: _state(),
              onOpen: () => context.go('/events/halloween_2026'),
            ),
          ),
        ),
        GoRoute(
          path: '/events/:eventKey',
          builder: (_, state) => Text(
            'event:${state.pathParameters['eventKey']}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('it'),
        localizationsDelegates: CatDexLocalizations.localizationsDelegates,
        supportedLocales: CatDexLocalizations.supportedLocales,
      ),
    );

    await tester.tap(find.byKey(const Key('home_event_open_button')));
    await tester.pumpAndSettle();

    expect(find.text('event:halloween_2026'), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('it'),
    localizationsDelegates: CatDexLocalizations.localizationsDelegates,
    supportedLocales: CatDexLocalizations.supportedLocales,
    theme: AppTheme.light(),
    home: Scaffold(body: child),
  );
}

EventUiState _state() {
  return EventUiState(
    event: halloween2026Event,
    active: true,
    debugMode: false,
    isPremium: false,
    usage: const EventUsageSnapshot(),
    discoveries: const [],
    ownedCards: const [],
    rendererConfigured: true,
  );
}
