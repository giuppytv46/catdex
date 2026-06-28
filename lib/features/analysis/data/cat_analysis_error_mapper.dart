import 'dart:async';
import 'dart:io';

import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CatAnalysisErrorMapper {
  const CatAnalysisErrorMapper();

  CatAnalysisFailure map(Object error) {
    if (error is TimeoutException) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.timeout,
        message: 'CatDex took too long to analyze this photo. Try again soon.',
      );
    }

    if (error is SocketException) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.noInternet,
        message: 'CatDex needs an internet connection for cloud analysis.',
      );
    }

    if (error is FormatException) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.invalidImage,
        message: 'That image could not be analyzed. Try another cat photo.',
      );
    }

    if (error is FunctionException) {
      return _mapFunctionException(error);
    }

    return const CatAnalysisFailure(
      message: 'CatDex could not analyze this photo yet.',
    );
  }

  CatAnalysisFailure _mapFunctionException(FunctionException error) {
    final status = error.status;
    if (status == 400 || status == 422) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.invalidImage,
        message: 'That image could not be analyzed. Try another cat photo.',
      );
    }

    if (status == 408 || status == 504) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.timeout,
        message: 'CatDex took too long to analyze this photo. Try again soon.',
      );
    }

    if (status >= 500) {
      return const CatAnalysisFailure(
        code: CatAnalysisFailureCode.backendUnavailable,
        message: 'CatDex analysis is resting right now. Try again soon.',
      );
    }

    return const CatAnalysisFailure(
      code: CatAnalysisFailureCode.aiFailed,
      message: 'CatDex could not finish the AI analysis. Try again.',
    );
  }
}
