class ScanLimit {
  const ScanLimit({
    required this.dailyLimit,
    required this.scansUsedToday,
  }) : assert(scansUsedToday >= 0, 'scansUsedToday cannot be negative');

  const ScanLimit.unlimited({int scansUsedToday = 0})
    : this(dailyLimit: null, scansUsedToday: scansUsedToday);

  final int? dailyLimit;
  final int scansUsedToday;

  bool get unlimited => dailyLimit == null;

  int? get scansRemaining {
    final limit = dailyLimit;
    if (limit == null) {
      return null;
    }

    return (limit - scansUsedToday).clamp(0, limit);
  }

  bool get canScan {
    return unlimited || (scansRemaining ?? 0) > 0;
  }
}
