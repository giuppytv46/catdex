import 'dart:async';
import 'dart:io';

import 'package:catdex/features/analysis/data/cat_analysis_error_mapper.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:test/test.dart';

void main() {
  const mapper = CatAnalysisErrorMapper();

  test('maps no internet failures', () {
    final failure = mapper.map(const SocketException('offline'));

    expect(failure.code, CatAnalysisFailureCode.noInternet);
    expect(failure.message, isNotEmpty);
  });

  test('maps invalid image failures', () {
    final failure = mapper.map(const FormatException('bad image'));

    expect(failure.code, CatAnalysisFailureCode.invalidImage);
    expect(failure.message, isNotEmpty);
  });

  test('maps timeout failures', () {
    final failure = mapper.map(TimeoutException('slow'));

    expect(failure.code, CatAnalysisFailureCode.timeout);
    expect(failure.message, isNotEmpty);
  });

  test('maps backend unavailable failures', () {
    final failure = mapper.map(const FunctionException(status: 503));

    expect(failure.code, CatAnalysisFailureCode.backendUnavailable);
    expect(failure.message, isNotEmpty);
  });

  test('maps AI failed failures', () {
    final failure = mapper.map(const FunctionException(status: 429));

    expect(failure.code, CatAnalysisFailureCode.aiFailed);
    expect(failure.message, isNotEmpty);
  });
}
