enum CatAnalysisFailureCode {
  noInternet,
  invalidImage,
  noCatDetected,
  backendUnavailable,
  aiFailed,
  timeout,
  malformedAiResponse,
  unknown,
}

class CatAnalysisFailure {
  const CatAnalysisFailure({
    required this.message,
    this.code = CatAnalysisFailureCode.unknown,
    this.recoverable = true,
  });

  final String message;
  final CatAnalysisFailureCode code;
  final bool recoverable;
}
