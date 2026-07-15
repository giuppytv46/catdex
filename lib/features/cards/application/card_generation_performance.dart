import 'package:flutter/foundation.dart';

class CardGenerationPerformanceSpan {
  CardGenerationPerformanceSpan._({
    required this.event,
    required this.context,
    required DateTime startedAt,
    required Stopwatch stopwatch,
  }) : _startedAt = startedAt,
       _stopwatch = stopwatch;

  factory CardGenerationPerformanceSpan.start(
    String event, {
    String? discoveryId,
    String? detail,
  }) {
    final startedAt = DateTime.now().toUtc();
    final context = [
      if (discoveryId != null && discoveryId.isNotEmpty)
        'discoveryId=$discoveryId',
      if (detail != null && detail.isNotEmpty) detail,
    ].join(' ');
    debugPrint(
      '${event}_START timestamp=${startedAt.toIso8601String()} $context',
    );
    return CardGenerationPerformanceSpan._(
      event: event,
      context: context,
      startedAt: startedAt,
      stopwatch: Stopwatch()..start(),
    );
  }

  final String event;
  final String context;
  final DateTime _startedAt;
  final Stopwatch _stopwatch;
  bool _finished = false;

  DateTime get startedAt => _startedAt;

  int finish() {
    if (_finished) {
      return _stopwatch.elapsedMilliseconds;
    }
    _finished = true;
    _stopwatch.stop();
    final endedAt = DateTime.now().toUtc();
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    debugPrint(
      '${event}_END timestamp=${endedAt.toIso8601String()} '
      'elapsedMs=$elapsedMs $context',
    );
    return elapsedMs;
  }
}
