import 'dart:async';

import 'package:catdex/features/analysis/application/cat_analysis_controller.dart';
import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_confidence.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/cat_breed_candidate.dart';
import 'package:catdex/features/analysis/domain/entities/cat_visual_traits.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:catdex/features/catdex/data/seeds/catdex_seed_data.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts idle', () {
    final container = _container(repository: _SuccessAnalysisRepository());
    addTearDown(container.dispose);

    expect(
      container.read(catAnalysisControllerProvider).status,
      AnalysisStatus.idle,
    );
  });

  test('moves from analyzing to success', () async {
    final repository = _CompletingAnalysisRepository();
    final container = _container(repository: repository);
    addTearDown(container.dispose);

    final analysis = container
        .read(catAnalysisControllerProvider.notifier)
        .analyze(_photo());

    expect(
      container.read(catAnalysisControllerProvider).status,
      AnalysisStatus.analyzing,
    );

    repository.complete(_result());
    await analysis;

    final state = container.read(catAnalysisControllerProvider);
    expect(state.status, AnalysisStatus.success);
    expect(state.result, isNotNull);
  });

  test('moves to failure when repository throws', () async {
    final container = _container(repository: _FailingAnalysisRepository());
    addTearDown(container.dispose);

    await container
        .read(catAnalysisControllerProvider.notifier)
        .analyze(_photo());

    final state = container.read(catAnalysisControllerProvider);
    expect(state.status, AnalysisStatus.failure);
    expect(state.failure?.message, isNotEmpty);
  });
}

ProviderContainer _container({required CatAnalysisRepository repository}) {
  return ProviderContainer(
    overrides: [
      catAnalysisRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

CapturedPhoto _photo() {
  return CapturedPhoto(
    path: 'cat.jpg',
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}

CatAnalysisResult _result() {
  final species = CatDexSeedData.species.first;
  final variant = CatDexSeedData.variants.first;
  const confidence = CatAnalysisConfidence(0.9);

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
    story: 'A curious local cat watches the world with bright eyes.',
    analyzedAt: DateTime.utc(2026),
  );
}

class _CompletingAnalysisRepository implements CatAnalysisRepository {
  final _completer = Completer<CatAnalysisResult>();

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) {
    return _completer.future;
  }

  void complete(CatAnalysisResult result) {
    _completer.complete(result);
  }
}

class _SuccessAnalysisRepository implements CatAnalysisRepository {
  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) async {
    return _result();
  }
}

class _FailingAnalysisRepository implements CatAnalysisRepository {
  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) {
    throw StateError('analysis failed');
  }
}
