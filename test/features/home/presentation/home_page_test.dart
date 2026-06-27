import 'package:catdex/features/capture/presentation/capture_page.dart';
import 'package:catdex/main.dart';
import 'package:catdex/routing/app_router.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home renders the player level', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Level 5'), findsOneWidget);
    expect(find.text('Explorer'), findsOneWidget);
    expect(find.text('420 Paw Points'), findsOneWidget);
  });

  testWidgets('Home renders daily missions', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Daily Missions'), findsOneWidget);
    expect(find.text('Discover 1 cat'), findsOneWidget);
    expect(find.text('Import 1 photo'), findsOneWidget);
    expect(find.text('Visit your CatDex'), findsOneWidget);
  });

  testWidgets('Home renders recent discoveries', (tester) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.textContaining('Recent Discoveries'),
      240,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Discoveries'), findsOneWidget);
    expect(find.textContaining('Mochi'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('Pixel'),
      180,
      scrollable: _horizontalScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pixel'), findsOneWidget);
  });

  testWidgets('Capture button navigates to Capture route', (tester) async {
    await _pumpHome(tester);

    await tester.scrollUntilVisible(
      find.textContaining('Capture Cat'),
      240,
      scrollable: _verticalScrollable(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Capture Cat'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Capture'), findsWidgets);
    expect(find.byType(CapturePage), findsOneWidget);
  });
}

Future<void> _pumpHome(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const CatDexApp()),
  );
  await tester.pumpAndSettle();

  container.read(appRouterProvider).go(AppRoute.home.path);
  await tester.pumpAndSettle();
}

Finder _verticalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
    description: 'vertical Scrollable',
  );
}

Finder _horizontalScrollable() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.right,
    description: 'horizontal Scrollable',
  );
}
