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
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    await pumpAnalysisPage(tester);

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
    await pumpAnalysisPage(tester);

    expect(tester.takeException(), isNull);

    expect(find.text('✨ Nuova scoperta!'), findsNothing);
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
    expect(find.text('Dettagli'), findsOneWidget);

    await tester.tap(find.text('Dettagli'));
    await pumpAnalysisPage(tester);
    await dragAnalysisUntilVisible(tester, find.text('Eta stimata'));

    expect(find.text('Confidenza'), findsOneWidget);
    expect(find.text('Pattern mantello'), findsOneWidget);
    expect(find.text('Lunghezza pelo'), findsOneWidget);
    expect(find.text('Eta stimata'), findsOneWidget);
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
    await pumpAnalysisPage(tester);

    expect(find.text('Gatto domestico bicolore'), findsWidgets);
    await dragAnalysisUntilVisible(tester, find.text('Grigio/bianco'));

    expect(find.text('Grigio/bianco'), findsOneWidget);
    expect(find.textContaining('grigio e bianco'), findsOneWidget);
    expect(find.textContaining('marrone/grigio'), findsNothing);
    expect(find.textContaining('tigrato mackerel'), findsNothing);

    await tester.tap(find.text('Dettagli'));
    await pumpAnalysisPage(tester);

    expect(find.text('Bicolore'), findsWidgets);
  });

  testWidgets('successful analysis plays one discovery reveal before CTA', (
    tester,
  ) async {
    final messages = <String>[];
    final previousDebugPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) messages.add(message);
    };

    try {
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(
        find.byKey(const Key('analysis_discovery_scanning_light')),
        findsOneWidget,
      );
      final emblemFinder = find.byKey(
        const Key('analysis_discovery_emblem'),
      );
      for (
        var frame = 0;
        frame < 12 && emblemFinder.evaluate().isEmpty;
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(emblemFinder, findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('analysis_reveal_discovery_button')),
            )
            .onPressed,
        isNull,
      );

      final revealButtonFinder = find.byKey(
        const Key('analysis_reveal_discovery_button'),
      );
      for (var frame = 0; frame < 24; frame++) {
        final button = tester.widget<FilledButton>(revealButtonFinder);
        if (button.onPressed != null) break;
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        tester.widget<FilledButton>(revealButtonFinder).onPressed,
        isNotNull,
      );
      await tester.pump();
      expect(
        messages.where(
          (message) => message == 'CATDEX_DISCOVERY_REVEAL_STARTED',
        ),
        hasLength(1),
      );
    } finally {
      debugPrint = previousDebugPrint;
    }
  });

  testWidgets('failed analysis does not start discovery reveal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catAnalysisRepositoryProvider.overrideWithValue(
            const _FailingRepository(),
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('analysis_discovery_emblem')), findsNothing);
    expect(
      find.byKey(const Key('catdex_celebration_overlay')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('analysis_reveal_discovery_button')),
      findsNothing,
    );
  });
}

Future<void> pumpAnalysisPage(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> dragAnalysisUntilVisible(
  WidgetTester tester,
  Finder target,
) async {
  final analysisList = find.byKey(const Key('analysis_page'));
  for (var attempt = 0; attempt < 12 && !tester.any(target); attempt++) {
    await tester.drag(analysisList, const Offset(0, -240));
    await pumpAnalysisPage(tester);
  }
  if (tester.any(target)) {
    await tester.ensureVisible(target);
  }
  await pumpAnalysisPage(tester);
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

class _FailingRepository implements CatAnalysisRepository {
  const _FailingRepository();

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) {
    throw StateError('analysis failed');
  }
}
