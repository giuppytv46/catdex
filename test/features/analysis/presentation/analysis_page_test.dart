import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/application/cat_analysis_controller.dart';
import 'package:catdex/features/analysis/data/cat_analysis_result_json_parser.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/analysis/presentation/analysis_page.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Analysis page builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catAnalysisRepositoryProvider.overrideWithValue(
            _BackendValueRepository(_backendJson()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: AnalysisPage(photo: _photo()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(AnalysisPage), findsOneWidget);
  });

  testWidgets('Analysis page renders premium discovery result', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catAnalysisRepositoryProvider.overrideWithValue(
            _BackendValueRepository(_backendJson()),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: AnalysisPage(photo: _photo()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await _expectVisibleText(tester, '✨ New Discovery!');
    await _expectVisibleText(tester, 'Gatto domestico tigrato');
    await _expectVisibleText(tester, 'Comune');
    await _expectVisibleText(tester, '+80');
    await _expectVisibleText(tester, 'XP');
    await _expectVisibleText(tester, '+15');
    await _expectVisibleText(tester, 'Coins');
    await _expectVisibleText(tester, 'Curioso');
    await _expectVisibleText(tester, 'Species');
    await _expectVisibleText(tester, 'Coat');
    await _expectVisibleText(tester, 'Marrone/grigio tigrato');
    await _expectVisibleText(tester, 'Eyes');
    await _expectVisibleText(tester, 'occhi gialli');
    await _expectVisibleText(tester, 'Personality');
    await _expectVisibleText(tester, '📖 Story');
    await _expectVisibleText(
      tester,
      'Un gatto tigrato osserva il mondo con calma.',
    );
    await _expectVisibleText(
      tester,
      'I mantelli tigrati sono molto comuni nei gatti domestici.',
    );
    await _expectVisibleText(tester, 'More details');
    expect(find.text('Tigrato mackerel'), findsNothing);
    expect(find.text('pelo corto'), findsNothing);
    expect(find.text('adult'), findsNothing);
    expect(find.text('Normale'), findsNothing);
    expect(
      find.text('Mantello: Marrone/grigio tigrato, Pattern: Tigrato mackerel'),
      findsNothing,
    );
    expect(find.textContaining('domestic_tabby_cat'), findsNothing);
    expect(find.textContaining('common'), findsNothing);
    expect(find.textContaining('normal'), findsNothing);
    expect(find.textContaining('European Shorthair'), findsNothing);
    expect(find.textContaining('Tortoiseshell'), findsNothing);
    expect(find.textContaining('Squama di tartaruga'), findsNothing);
    expect(find.textContaining('Bianco'), findsNothing);
    expect(find.textContaining('Calico'), findsNothing);
    expect(find.textContaining('Colorpoint'), findsNothing);
    expect(find.textContaining('Blue eyes'), findsNothing);
    expect(find.textContaining('Blu'), findsNothing);
    expect(find.textContaining('Lungo'), findsNothing);
    expect(find.textContaining('Soffice'), findsNothing);
    expect(find.textContaining('Soft hair'), findsNothing);
    expect(find.textContaining('curved whiskers'), findsNothing);
    expect(find.text('null'), findsNothing);
  });
}

Future<void> _expectVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.scrollUntilVisible(
    finder,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  expect(finder, findsOneWidget);
}

CapturedPhoto _photo() {
  return CapturedPhoto(
    path: 'missing-local-cat.jpg',
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}

Map<String, Object?> _backendJson() {
  return {
    'breed': 'domestic_tabby_cat',
    'confidence': 0.91,
    'candidates': [
      {'breed': 'domestic_tabby_cat', 'confidence': 0.91},
    ],
    'coatColor': 'marrone/grigio tigrato',
    'coatPattern': 'tigrato mackerel',
    'eyeColor': 'occhi gialli',
    'hairLength': 'pelo corto',
    'estimatedAge': 'adult',
    'traits': [
      {
        'name': 'Mantello',
        'value': 'marrone/grigio tigrato',
        'rarityWeight': 1,
      },
      {'name': 'Pattern', 'value': 'tigrato mackerel', 'rarityWeight': 1},
    ],
    'personality': 'curious',
    'rarity': 'common',
    'variant': 'normal',
    'story': 'Un gatto tigrato osserva il mondo con calma.',
    'funFact': 'I mantelli tigrati sono molto comuni nei gatti domestici.',
    'safetyStatus': 'safe',
    'analyzedAt': '2026-06-28T12:00:00.000Z',
  };
}

class _BackendValueRepository implements CatAnalysisRepository {
  const _BackendValueRepository(this.json);

  final Map<String, Object?> json;

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) async {
    return const CatAnalysisResultJsonParser().parse(json);
  }
}
