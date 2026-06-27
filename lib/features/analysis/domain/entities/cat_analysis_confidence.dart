class CatAnalysisConfidence {
  const CatAnalysisConfidence(this.score)
    : assert(score >= 0 && score <= 1, 'score must be between 0 and 1');

  final double score;

  int get percentage => (score * 100).round();

  bool get isHigh => score >= 0.8;

  bool get isMedium => score >= 0.5 && score < 0.8;

  String get label {
    if (isHigh) {
      return 'High';
    }

    if (isMedium) {
      return 'Medium';
    }

    return 'Low';
  }
}
