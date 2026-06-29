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
    await _expectVisibleText(tester, 'Gatto domestico tigrato');
    await _expectVisibleText(tester, 'Marrone/grigio tigrato');
    await _expectVisibleText(tester, 'Tigrato mackerel');
    await _expectVisibleText(tester, 'occhi gialli');
    await _expectVisibleText(tester, 'pelo corto');
    await _expectVisibleText(tester, 'adult');
    await _expectVisibleText(
      tester,
      'Mantello: Marrone/grigio tigrato, Pattern: Tigrato mackerel',
    );
    await _expectVisibleText(tester, 'Curioso');
    await _expectVisibleText(tester, 'Comune');
    await _expectVisibleText(tester, 'Normale');
    await _expectVisibleText(
      tester,
      'Un gatto arancione osserva il mondo con calma.',
    );
    await _expectVisibleText(
      tester,
      'I mantelli arancioni sono spesso tabby.',
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
