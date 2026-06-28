import 'dart:convert';
import 'dart:developer';

import 'package:catdex/features/analysis/data/backend_cat_analysis_client.dart';
import 'package:catdex/features/analysis/data/cat_analysis_error_mapper.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCatAnalysisBackendClient implements CatAnalysisBackendClient {
  const SupabaseCatAnalysisBackendClient(
    this._client, {
    CatAnalysisErrorMapper errorMapper = const CatAnalysisErrorMapper(),
  }) : _errorMapper = errorMapper;

  final SupabaseClient _client;
  final CatAnalysisErrorMapper _errorMapper;

  @override
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body) async {
    try {
      final response = await _client.functions.invoke(
        'analyze_cat_photo',
        body: body,
      );
      log(
        _safeJson(response.data),
        name: 'CatDexAI.rawSupabaseResponse',
      );

      return response.data;
    } on FunctionException catch (error) {
      throw CatAnalysisException(
        _errorMapper.mapFunctionFailure(
          status: error.status,
          details: error.details,
        ),
      );
    }
  }

  String _safeJson(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }
}
