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
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

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

    expect(find.text('✨ Nuova scoperta!'), findsOneWidget);
    expect(find.text('Specie'), findsOneWidget);
    expect(find.text('Gatto domestico tigrato'), findsWidgets);
    expect(find.text('Comune'), findsOneWidget);
    expect(find.text('+80'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('+15'), findsOneWidget);
    expect(find.text('Monete'), findsOneWidget);
    expect(find.text('📖 Storia'), findsOneWidget);
    expect(
      find.text('Un gatto tigrato osserva il mondo con calma.'),
      findsOneWidget,
    );
    expect(find.text('Altri dettagli'), findsOneWidget);

    await tester.tap(find.text('Altri dettagli'));
    await tester.pumpAndSettle();

    expect(find.text('Confidenza'), findsOneWidget);
    expect(find.text('Pattern mantello'), findsOneWidget);
    expect(find.text('Lunghezza pelo'), findsOneWidget);
    expect(find.text('Età stimata'), findsOneWidget);
    expect(find.text('Variante'), findsOneWidget);
    expect(find.text('Tratti'), findsOneWidget);
  });

  testWidgets('Analysis page normalizes bicolor story and display values', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catAnalysisRepositoryProvider.overrideWithValue(
            _BackendValueRepository(_bicolorBackendJson()),
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

    expect(find.text('Gatto domestico bicolore'), findsWidgets);
    expect(find.text('Nero/bianco'), findsOneWidget);
    expect(find.textContaining('nero e bianco'), findsOneWidget);
    expect(find.textContaining('marrone/grigio'), findsNothing);
    expect(find.textContaining('tigrato mackerel'), findsNothing);

    await tester.tap(find.text('Altri dettagli'));
    await tester.pumpAndSettle();

    expect(find.text('Bicolore'), findsWidgets);
  });
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

Map<String, Object?> _bicolorBackendJson() {
  return {
    'breed': 'domestic_gray_cat',
    'confidence': 0.91,
    'candidates': [
      {'breed': 'domestic_gray_cat', 'confidence': 0.91},
    ],
    'coatColor': 'marrone/grigio',
    'coatPattern': 'bicolore',
    'eyeColor': 'occhi gialli',
    'hairLength': 'pelo corto',
    'estimatedAge': 'adult',
    'traits': [
      {'name': 'Mantello', 'value': 'marrone/grigio', 'rarityWeight': 1},
      {'name': 'Pattern', 'value': 'tigrato mackerel', 'rarityWeight': 1},
    ],
    'personality': 'curious',
    'rarity': 'common',
    'variant': 'normal',
    'story': 'Un gatto marrone/grigio tigrato osserva il mondo.',
    'funFact': 'Il mantello tigrato mackerel crea strisce sottili.',
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
