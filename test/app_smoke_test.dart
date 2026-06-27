import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the splash route first', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CatDexApp()));
    await tester.pumpAndSettle();

    expect(find.text('Splash'), findsWidgets);
  });

  testWidgets('navigates across bottom navigation tabs', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CatDexApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Onboarding'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Login'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Capture'), findsOneWidget);

    await tester.tap(find.byTooltip('CatDex'));
    await tester.pumpAndSettle();
    expect(find.text('CatDex'), findsWidgets);

    await tester.tap(find.byTooltip('Capture'));
    await tester.pumpAndSettle();
    expect(find.text('Capture'), findsWidgets);

    await tester.tap(find.byTooltip('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('Friends'), findsWidgets);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('shows the unknown route page for missing paths', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CatDexApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go('/missing-route');
    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsWidgets);
  });
}
