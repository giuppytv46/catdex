import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app launches and Home page renders', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const CatDexApp()),
    );
    await tester.pumpAndSettle();

    container.read(appRouterProvider).go(AppRoute.home.path);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Explorer'), findsOneWidget);
  });
}
