import 'dart:async';

import 'package:catdex/features/analysis/data/backend_cat_analysis_client.dart';
import 'package:catdex/features/analysis/data/cat_analysis_error_mapper.dart';
import 'package:catdex/features/analysis/data/cat_analysis_result_json_parser.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/repositories/cat_analysis_repository.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';

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

      return _parser.parse(response);
    } on CatAnalysisException {
      rethrow;
    } on Object catch (error) {
      throw CatAnalysisException(_errorMapper.map(error));
    }
  }

  Map<String, Object?> _requestBody(CapturedPhoto photo) {
    return {
      if (photo.path.startsWith('http://') || photo.path.startsWith('https://'))
        'image_url': photo.path
      else if (photo.path.startsWith('data:image/'))
        'base64_image': photo.path
      else
        'photoReference': photo.path,
      'metadata': {
        'source': photo.source.name,
        'sizeBytes': photo.sizeBytes,
        'capturedAt': photo.capturedAt.toIso8601String(),
      },
    };
  }
}
