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
