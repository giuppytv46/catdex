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

  testWidgets('Analysis page renders backend analysis fields', (tester) async {
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
    await _expectVisibleText(tester, 'Razza');
    await _expectVisibleText(tester, 'Confidenza');
    await _expectVisibleText(tester, 'Colore mantello');
    await _expectVisibleText(tester, 'Pattern mantello');
    await _expectVisibleText(tester, 'Colore occhi');
    await _expectVisibleText(tester, 'Lunghezza pelo');
    await _expectVisibleText(tester, 'Eta stimata');
    await _expectVisibleText(tester, 'Tratti');
    await _expectVisibleText(tester, 'Rarita');
    await _expectVisibleText(tester, 'Variante');
    await _expectVisibleText(tester, 'Umore');
    await _expectVisibleText(tester, 'Storia');
    await _expectVisibleText(tester, 'Curiosita');
    await _expectVisibleText(tester, 'Brown');
    await _expectVisibleText(tester, 'Tabby');
    await _expectVisibleText(tester, 'Amber eyes');
    await _expectVisibleText(tester, 'Short hair');
    await _expectVisibleText(tester, 'adult');
    await _expectVisibleText(
      tester,
      'Posture: watching, Mood: alert',
    );
    await _expectVisibleText(tester, 'calm_observer');
    await _expectVisibleText(tester, 'ordinary');
    await _expectVisibleText(tester, 'standard');
    await _expectVisibleText(
      tester,
      'Un gatto arancione osserva il mondo con calma.',
    );
    await _expectVisibleText(
      tester,
      'I mantelli arancioni sono spesso tabby.',
    );
    expect(find.textContaining('European Shorthair'), findsNothing);
    expect(find.textContaining('Tortoiseshell'), findsNothing);
    expect(find.textContaining('Soft hair'), findsNothing);
    expect(find.textContaining('curved whiskers'), findsNothing);
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
    'breed': 'domestic_orange_cat',
    'confidence': 0.91,
    'candidates': [
      {'breed': 'domestic_orange_cat', 'confidence': 0.91},
    ],
    'coatColor': 'Brown',
    'coatPattern': 'Tabby',
    'eyeColor': 'Amber eyes',
    'hairLength': 'Short hair',
    'estimatedAge': 'adult',
    'traits': [
      {'name': 'Posture', 'value': 'watching', 'rarityWeight': 1},
      {'name': 'Mood', 'value': 'alert', 'rarityWeight': 1},
    ],
    'personality': 'calm_observer',
    'rarity': 'ordinary',
    'variant': 'standard',
    'story': 'Un gatto arancione osserva il mondo con calma.',
    'funFact': 'I mantelli arancioni sono spesso tabby.',
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
