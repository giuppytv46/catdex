import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/domain/entities/discovery_reveal_args.dart';
import 'package:catdex/features/analysis/presentation/discovery_reveal_page.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';
import 'package:catdex/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Discovery reveal page builds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDiscoverySaveControllerProvider.overrideWith(
            _ResettingLocalDiscoverySaveController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: DiscoveryRevealPage(args: _args()),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(DiscoveryRevealPage), findsOneWidget);
  });

  testWidgets('Add to CatDex animates only after persistence success', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDiscoverySaveControllerProvider.overrideWith(
            _SuccessfulLocalDiscoverySaveController.new,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: DiscoveryRevealPage(args: _args()),
        ),
      ),
    );
    await tester.pump();

    await _scrollToAddButton(tester);
    await tester.tap(find.byKey(const Key('discovery_reveal_add_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('name_discovery_save_button')));
    await tester.pump();

    expect(find.byKey(const Key('catdex_add_success_label')), findsNothing);
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      find.byKey(const Key('catdex_add_success_label')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catdex_add_rectangular_discovery_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('catdex_collection_target')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('catdex_celebration_painter')), findsOneWidget);
    expect(find.text('AGGIUNTO AL CATDEX!'), findsOneWidget);
    expect(find.text('+100 XP'), findsOneWidget);
    expect(find.byType(DiscoveryRevealPage), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(DiscoveryRevealPage), findsOneWidget);
  });

  testWidgets('failed persistence does not show CatDex success animation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDiscoverySaveControllerProvider.overrideWith(
            _FailingLocalDiscoverySaveController.new,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('it'),
          theme: AppTheme.light(),
          localizationsDelegates: CatDexLocalizations.localizationsDelegates,
          supportedLocales: CatDexLocalizations.supportedLocales,
          home: DiscoveryRevealPage(args: _args()),
        ),
      ),
    );
    await tester.pump();

    await _scrollToAddButton(tester);
    await tester.tap(find.byKey(const Key('discovery_reveal_add_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('name_discovery_save_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('catdex_add_success_label')), findsNothing);
    expect(
      find.byKey(const Key('catdex_celebration_overlay')),
      findsNothing,
    );
    expect(find.text('+100 XP'), findsNothing);
  });
}

Future<void> _scrollToAddButton(WidgetTester tester) async {
  await tester.dragUntilVisible(
    find.byKey(const Key('discovery_reveal_add_button')),
    find.byType(Scrollable).first,
    const Offset(0, -300),
  );
  await tester.pump();
}

class _ResettingLocalDiscoverySaveController
    extends LocalDiscoverySaveController {
  @override
  Future<LocalDiscoverySaveState> build() async {
    return const LocalDiscoverySaveState(
      status: LocalDiscoverySaveStatus.failure,
      message: 'stale state',
    );
  }

  @override
  DiscoveryReward previewReward(CatAnalysisResult result) {
    return const DiscoveryReward(
      xp: 100,
      coins: 10,
      friendshipPoints: 20,
      duplicate: false,
    );
  }

  @override
  void reset() {
    state = const AsyncData(LocalDiscoverySaveState.idle());
  }
}

class _SuccessfulLocalDiscoverySaveController
    extends LocalDiscoverySaveController {
  @override
  Future<LocalDiscoverySaveState> build() async {
    return const LocalDiscoverySaveState.idle();
  }

  @override
  Future<void> save(
    CatAnalysisResult result, {
    String? photoPath,
    String? cloudStoragePath,
    String customName = 'Mochi',
    String suggestedName = 'Mochi',
    String? nickname,
    bool usesEditedDetails = false,
  }) async {
    state = const AsyncData(
      LocalDiscoverySaveState(status: LocalDiscoverySaveStatus.saving),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = const AsyncData(
      LocalDiscoverySaveState(
        status: LocalDiscoverySaveStatus.saved,
        reward: DiscoveryReward(
          xp: 100,
          coins: 10,
          friendshipPoints: 20,
          duplicate: false,
        ),
      ),
    );
  }
}

class _FailingLocalDiscoverySaveController
    extends LocalDiscoverySaveController {
  @override
  Future<LocalDiscoverySaveState> build() async {
    return const LocalDiscoverySaveState.idle();
  }

  @override
  Future<void> save(
    CatAnalysisResult result, {
    String? photoPath,
    String? cloudStoragePath,
    String customName = 'Mochi',
    String suggestedName = 'Mochi',
    String? nickname,
    bool usesEditedDetails = false,
  }) async {
    state = const AsyncData(
      LocalDiscoverySaveState(status: LocalDiscoverySaveStatus.saving),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    state = const AsyncData(
      LocalDiscoverySaveState(
        status: LocalDiscoverySaveStatus.failure,
        message: 'save failed',
      ),
    );
  }
}

DiscoveryRevealArgs _args() {
  return DiscoveryRevealArgs(photo: _photo(), result: _result());
}

CapturedPhoto _photo() {
  return CapturedPhoto(
    path: 'missing-local-cat.jpg',
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}

CatAnalysisResult _result() {
  final species = CatDexSeedData.species.first;
  final variant = CatDexSeedData.variants.first;
  const confidence = CatAnalysisConfidence(0.91);

  return CatAnalysisResult(
    primaryBreed: CatBreedCandidate(
      species: species,
      confidence: confidence,
    ),
    breedCandidates: [
      CatBreedCandidate(species: species, confidence: confidence),
    ],
    visualTraits: const CatVisualTraits(
      coatColor: 'Black',
      coatPattern: 'Solid',
      eyeColor: 'Green',
      hairLength: 'Short',
      notableTraits: [],
    ),
    confidence: confidence,
    rarity: CatRarity.common,
    variant: variant,
    personality: CatPersonality.curious,
    story: 'A calm local discovery.',
    analyzedAt: DateTime.utc(2026),
  );
}
