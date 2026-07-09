import 'package:catdex/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CatDex app smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CatDexApp()),
    );

    expect(find.byType(CatDexApp), findsOneWidget);
  });
}
