class CatAnalysisFailure {
  const CatAnalysisFailure({
    required this.message,
    this.recoverable = true,
  });

  final String message;
  final bool recoverable;
}
