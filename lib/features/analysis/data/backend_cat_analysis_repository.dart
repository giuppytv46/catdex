import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/analysis/data/backend_cat_analysis_client.dart';
import 'package:catdex/features/analysis/data/cat_analysis_error_mapper.dart';
import 'package:catdex/features/analysis/data/cat_analysis_result_json_parser.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:flutter/foundation.dart';

class BackendCatAnalysisRepository implements CatAnalysisRepository {
  const BackendCatAnalysisRepository({
    required CatAnalysisBackendClient client,
    CatAnalysisResultJsonParser parser = const CatAnalysisResultJsonParser(),
    CatAnalysisErrorMapper errorMapper = const CatAnalysisErrorMapper(),
    Duration timeout = const Duration(seconds: 20),
  }) : _client = client,
       _parser = parser,
       _errorMapper = errorMapper,
       _timeout = timeout;

  final CatAnalysisBackendClient _client;
  final CatAnalysisResultJsonParser _parser;
  final CatAnalysisErrorMapper _errorMapper;
  final Duration _timeout;

  @override
  Future<CatAnalysisResult> analyzePhoto(CapturedPhoto photo) async {
    try {
      final response = await _client
          .analyzeCatPhoto(_requestBody(photo))
          .timeout(_timeout);

      debugPrint('CATDEX_RAW_HTTP ${_safeJson(response)}');
      final result = _parser.parse(response);
      debugPrint('CATDEX_MODEL ${_safeJson(_analysisDebugJson(result))}');

      return result;
    } on CatAnalysisException {
      rethrow;
    } on Object catch (error) {
      throw CatAnalysisException(_errorMapper.map(error));
    }
  }

  Future<String?> recheckEyeColor(CapturedPhoto photo) async {
    try {
      final response = await _client
          .analyzeCatPhoto({
            ..._requestBody(photo),
            'task': 'eye_color_only',
            'mode': 'eye_color_recheck',
            'instruction': _eyeColorRecheckInstruction,
          })
          .timeout(_timeout);
      debugPrint('CATDEX_EYE_COLOR_RECHECK_HTTP ${_safeJson(response)}');

      return _eyeColorFromResponse(response);
    } on Object catch (error) {
      debugPrint('CATDEX_EYE_COLOR_RECHECK_ERROR $error');
      return null;
    }
  }

  Future<String?> recheckCoatColor(CapturedPhoto photo) async {
    try {
      final response = await _client
          .analyzeCatPhoto({
            ..._requestBody(photo),
            'task': 'coat_color_only',
            'mode': 'coat_color_recheck',
            'instruction': _coatColorRecheckInstruction,
          })
          .timeout(_timeout);
      debugPrint('CATDEX_COAT_COLOR_RECHECK_HTTP ${_safeJson(response)}');

      return _coatColorFromResponse(response);
    } on Object catch (error) {
      debugPrint('CATDEX_COAT_COLOR_RECHECK_ERROR $error');
      return null;
    }
  }

  static const _coatColorRecheckInstruction = '''
Look only at the cat's coat color.

Is this cat orange/ginger/red tabby or brown/gray tabby?

Return exactly one:
- arancione tigrato
- marrone/grigio tigrato
- grigio tigrato
- nero tigrato
- altro

If the fur is orange, ginger, marmalade, golden-orange, or red, return:
arancione tigrato
''';

  static const _eyeColorRecheckInstruction = '''
Look only at the cat's eyes in this image.

Are the irises visible?

Return exactly one of:
- occhi ambrati
- occhi gialli
- occhi verdi
- occhi azzurri
- occhi eterocromi
- Non rilevato

Rules:
- orange / copper / amber / yellow-orange / golden-orange = occhi ambrati
- yellow / gold = occhi gialli
- green = occhi verdi
- blue = occhi azzurri
- mixed / heterochromia = occhi eterocromi

If the eyes are visible, do NOT return Non rilevato.
''';

  Map<String, Object?> _requestBody(CapturedPhoto photo) {
    return {
      if (photo.path.startsWith('http://') || photo.path.startsWith('https://'))
        'image_url': photo.path
      else if (photo.path.startsWith('data:image/'))
        'base64_image': photo.path
      else if (File(photo.path).existsSync())
        'base64_image': _localPhotoDataUrl(photo)
      else
        'photoReference': photo.path,
      'metadata': {
        'source': photo.source.name,
        'sizeBytes': photo.sizeBytes,
        'capturedAt': photo.capturedAt.toIso8601String(),
      },
      'locale': 'it',
    };
  }

  String? _eyeColorFromResponse(Object? response) {
    final decoded = response is String ? _decodeJson(response) : response;
    if (decoded is String) {
      return decoded.trim().isEmpty ? null : decoded.trim();
    }
    if (decoded is Map) {
      final eyeColor = decoded['eyeColor'];
      if (eyeColor is String && eyeColor.trim().isNotEmpty) {
        return eyeColor.trim();
      }
    }

    return null;
  }

  String? _coatColorFromResponse(Object? response) {
    final decoded = response is String ? _decodeJson(response) : response;
    if (decoded is String) {
      return decoded.trim().isEmpty ? null : decoded.trim();
    }
    if (decoded is Map) {
      final coatColor = decoded['coatColor'];
      if (coatColor is String && coatColor.trim().isNotEmpty) {
        return coatColor.trim();
      }
    }

    return null;
  }

  Object? _decodeJson(String value) {
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  String _localPhotoDataUrl(CapturedPhoto photo) {
    final bytes = File(photo.path).readAsBytesSync();
    final contentType = switch (photo.extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };

    return 'data:$contentType;base64,${base64Encode(bytes)}';
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
