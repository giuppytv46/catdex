import 'package:catdex/features/cards/presentation/widgets/card_generation_status_panel.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact album status wraps fully on a small phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.ink,
          body: Center(
            child: SizedBox(
              width: 136,
              height: 176,
              child: CardGenerationStatusContent(
                stateLabel: cardGenerationStatusLongWaitMessage,
                compact: true,
              ),
            ),
          ),
        ),
      ),
    );

    _expectWrappedText(tester, find.text(cardGenerationStatusTitle), 1);
    _expectWrappedText(
      tester,
      find.text(cardGenerationStatusLongWaitMessage),
      1,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail status wraps fully on a small phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.ink,
          body: Center(
            child: SizedBox(
              width: 280,
              height: 340,
              child: CardGenerationStatusContent(
                stateLabel: cardGenerationStatusLongWaitMessage,
              ),
            ),
          ),
        ),
      ),
    );

    _expectWrappedText(tester, find.text(cardGenerationStatusTitle), 1);
    _expectWrappedText(
      tester,
      find.text(cardGenerationStatusLongWaitMessage),
      1,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _expectWrappedText(WidgetTester tester, Finder finder, int count) {
  expect(finder, findsNWidgets(count));
  for (final text in tester.widgetList<Text>(finder)) {
    expect(text.textAlign, TextAlign.center);
    expect(text.softWrap, isNot(false));
    expect(text.maxLines, isNot(1));
    expect(text.overflow, isNot(TextOverflow.ellipsis));
  }
}
