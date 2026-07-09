import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/application/cat_analysis_state.dart';
import 'package:catdex/features/analysis/data/backend_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/data/fake_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/data/supabase_cat_analysis_backend_client.dart';
import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/presentation/monetization_limit_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final catAnalysisRepositoryProvider = Provider<CatAnalysisRepository>((ref) {
  if (ref.watch(supabaseConfiguredProvider)) {
    return BackendCatAnalysisRepository(
      client: SupabaseCatAnalysisBackendClient(
        ref.watch(supabaseClientProvider),
      ),
    );
  }

  return const FakeCatAnalysisRepository();
});

final catAnalysisControllerProvider =
    NotifierProvider<CatAnalysisController, CatAnalysisState>(
      CatAnalysisController.new,
    );

class CatAnalysisController extends Notifier<CatAnalysisState> {
  @override
  CatAnalysisState build() {
    return const CatAnalysisState.idle();
  }

  Future<void> analyze(CapturedPhoto photo) async {
    final monetization = ref.read(monetizationServiceProvider);
    final allowed = await monetization.canAnalyzeCat();
    if (!allowed) {
      debugPrint('CATDEX_ANALYSIS_BLOCKED_LIMIT_OPEN_PAYWALL');
      state = CatAnalysisState(
        status: AnalysisStatus.failure,
        photo: photo,
        failure: const CatAnalysisFailure(message: monetizationLimitMessage),
      );
      return;
    }

    state = CatAnalysisState(
      status: AnalysisStatus.analyzing,
      photo: photo,
    );

    try {
      final repository = ref.read(catAnalysisRepositoryProvider);
      final result = await repository.analyzePhoto(photo);
      final colorCheckedResult = await _resultWithCoatColorRecheck(
        photo: photo,
        result: result,
        repository: repository,
      );
      final updatedResult = await _resultWithEyeColorRecheck(
        photo: photo,
        result: colorCheckedResult,
        repository: repository,
      );
      debugPrint(
        'CATDEX_AI_PARSED ${_safeJson(_analysisDebugJson(updatedResult))}',
      );
      if (!await monetization.consumeAnalysis()) {
        debugPrint('CATDEX_ANALYSIS_BLOCKED_LIMIT_OPEN_PAYWALL');
        state = CatAnalysisState(
          status: AnalysisStatus.failure,
          photo: photo,
          failure: const CatAnalysisFailure(message: monetizationLimitMessage),
        );
        return;
      }
      state = CatAnalysisState(
        status: AnalysisStatus.success,
        photo: photo,
        result: updatedResult,
      );
    } on CatAnalysisException catch (error) {
      state = CatAnalysisState(
        status: AnalysisStatus.failure,
        photo: photo,
        failure: error.failure,
      );
    } on Object {
      state = CatAnalysisState(
        status: AnalysisStatus.failure,
        photo: photo,
        failure: const CatAnalysisFailure(
          message: 'CatDex could not analyze this photo yet.',
        ),
      );
    }
  }

  void reset() {
    state = const CatAnalysisState.idle();
  }

  Future<CatAnalysisResult> _resultWithCoatColorRecheck({
    required CapturedPhoto photo,
    required CatAnalysisResult result,
    required CatAnalysisRepository repository,
  }) async {
    final coatColor = result.visualTraits.coatColor;
    final coatPattern = result.visualTraits.coatPattern;
    final needsRecheck = _needsCoatColorRecheck(
      coatColor: coatColor,
      coatPattern: coatPattern,
    );
    debugPrint('CATDEX_COAT_COLOR_RECHECK_STARTED $needsRecheck');

    if (!needsRecheck) {
      debugPrint('CATDEX_COAT_COLOR_RECHECK_RESULT -');
      debugPrint('CATDEX_COAT_COLOR_RECHECK_APPLIED false');
      return result;
    }

    if (repository is! BackendCatAnalysisRepository) {
      debugPrint('CATDEX_COAT_COLOR_RECHECK_RESULT backend_not_supported');
      debugPrint('CATDEX_COAT_COLOR_RECHECK_APPLIED false');
      return result;
    }

    final recheckedCoatColor = await repository.recheckCoatColor(photo);
    debugPrint(
      'CATDEX_COAT_COLOR_RECHECK_RESULT ${recheckedCoatColor ?? 'null'}',
    );

    if (!_isValidRecheckedCoatColor(recheckedCoatColor)) {
      debugPrint('CATDEX_COAT_COLOR_RECHECK_APPLIED false');
      return result;
    }

    debugPrint('CATDEX_COAT_COLOR_RECHECK_APPLIED true');
    return result.copyWith(
      visualTraits: result.visualTraits.copyWith(
        coatColor: recheckedCoatColor,
        coatPattern: recheckedCoatColor == 'arancione tigrato'
            ? 'tigrato'
            : null,
      ),
    );
  }

  Future<CatAnalysisResult> _resultWithEyeColorRecheck({
    required CapturedPhoto photo,
    required CatAnalysisResult result,
    required CatAnalysisRepository repository,
  }) async {
    final mainEyeColor = result.visualTraits.eyeColor;
    final needsRecheck = _needsEyeColorRecheck(mainEyeColor);
    debugPrint('CATDEX_EYE_COLOR_MAIN_ANALYSIS $mainEyeColor');
    debugPrint('CATDEX_EYE_COLOR_RECHECK_STARTED $needsRecheck');

    if (!needsRecheck) {
      debugPrint('CATDEX_EYE_COLOR_RECHECK_IMAGE_SOURCE ${photo.path}');
      debugPrint(
        'CATDEX_EYE_COLOR_RECHECK_IMAGE_AVAILABLE ${_photoAvailable(photo)}',
      );
      debugPrint('CATDEX_EYE_COLOR_RECHECK_RESULT -');
      debugPrint('CATDEX_EYE_COLOR_RECHECK_APPLIED false');
      return result;
    }

    debugPrint('CATDEX_EYE_COLOR_RECHECK_IMAGE_SOURCE ${photo.path}');
    debugPrint(
      'CATDEX_EYE_COLOR_RECHECK_IMAGE_AVAILABLE ${_photoAvailable(photo)}',
    );

    if (repository is! BackendCatAnalysisRepository) {
      debugPrint('CATDEX_EYE_COLOR_RECHECK_RESULT backend_not_supported');
      debugPrint('CATDEX_EYE_COLOR_RECHECK_APPLIED false');
      return result;
    }

    final recheckedEyeColor = await repository.recheckEyeColor(photo);
    debugPrint(
      'CATDEX_EYE_COLOR_RECHECK_RESULT ${recheckedEyeColor ?? 'null'}',
    );

    if (!_isValidEyeColor(recheckedEyeColor)) {
      debugPrint('CATDEX_EYE_COLOR_RECHECK_APPLIED false');
      return result;
    }

    debugPrint('CATDEX_EYE_COLOR_RECHECK_APPLIED true');
    return result.copyWith(
      visualTraits: result.visualTraits.copyWith(eyeColor: recheckedEyeColor),
    );
  }

  bool _needsEyeColorRecheck(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null ||
        normalized.isEmpty ||
        normalized == '-' ||
        normalized == 'unknown' ||
        normalized == 'null' ||
        normalized == 'non rilevato';
  }

  bool _needsCoatColorRecheck({
    required String? coatColor,
    required String? coatPattern,
  }) {
    final color = coatColor?.trim().toLowerCase() ?? '';
    final pattern = coatPattern?.trim().toLowerCase() ?? '';
    final tabbyPattern =
        pattern.contains('tigrato') ||
        pattern.contains('tabby') ||
        pattern.contains('mackerel') ||
        color.contains('tigrato') ||
        color.contains('tabby');
    final ambiguousColor =
        color.isEmpty ||
        color == '-' ||
        color == 'unknown' ||
        color == 'null' ||
        color.contains('marrone/grigio') ||
        color.contains('brown/gray') ||
        color.contains('brown/grey') ||
        color.contains('grigio') ||
        color.contains('gray') ||
        color.contains('grey');

    return tabbyPattern && ambiguousColor;
  }

  bool _isValidRecheckedCoatColor(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'arancione tigrato' ||
        normalized == 'marrone/grigio tigrato' ||
        normalized == 'grigio tigrato' ||
        normalized == 'nero tigrato';
  }

  bool _isValidEyeColor(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == 'occhi ambrati' ||
        normalized == 'occhi gialli' ||
        normalized == 'occhi verdi' ||
        normalized == 'occhi azzurri' ||
        normalized == 'occhi eterocromi';
  }

  bool _photoAvailable(CapturedPhoto photo) {
    if (photo.path.startsWith('http://') ||
        photo.path.startsWith('https://') ||
        photo.path.startsWith('data:image/')) {
      return true;
    }

    return File(photo.path).existsSync() || photo.path.trim().isNotEmpty;
  }

  Map<String, Object?> _analysisDebugJson(CatAnalysisResult result) {
    return {
      'breed': result.displayBreed,
      'coatColor': result.visualTraits.coatColor,
      'coatPattern': result.visualTraits.coatPattern,
      'eyeColor': result.visualTraits.eyeColor,
      'hairLength': result.visualTraits.hairLength,
      'estimatedAge': result.estimatedAge,
      'traits': result.visualTraits.notableTraits
          .map(
            (trait) => {
              'name': trait.name,
              'value': trait.value,
              'rarityWeight': trait.rarityWeight,
            },
          )
          .toList(growable: false),
      'personality': result.displayPersonality,
      'rarity': result.displayRarity,
      'variant': result.displayVariant,
      'story': result.story,
      'funFact': result.funFact,
    };
  }

  String _safeJson(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }
}
