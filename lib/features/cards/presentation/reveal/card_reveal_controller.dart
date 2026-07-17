import 'package:flutter/foundation.dart';

enum CardRevealState {
  idle,
  loading,
  revealing,
  revealed,
  completed,
  error,
}

enum CardRevealKind {
  normal,
  event,
  premiumEvent,
}

@immutable
class CardRevealRewardCue {
  const CardRevealRewardCue({
    required this.id,
    this.missionCompleted = false,
    this.xp = 0,
    this.earnedXp = 0,
    this.newLevel,
  });

  final String id;
  final bool missionCompleted;

  /// XP configured as a mission reward, shown with the mission message.
  final int xp;

  /// XP earned by the card operation itself, shown before mission feedback.
  final int earnedXp;
  final int? newLevel;

  bool get hasEarnedXp => earnedXp > 0;
  bool get hasMissionReward => missionCompleted;
  bool get hasLevelUp => newLevel != null;

  CardRevealRewardCue merge(CardRevealRewardCue other) {
    final ids = <String>{...id.split('|'), ...other.id.split('|')}..remove('');
    final sortedIds = ids.toList()..sort();
    final mergedLevel = newLevel == null
        ? other.newLevel
        : other.newLevel == null
        ? newLevel
        : newLevel! > other.newLevel!
        ? newLevel
        : other.newLevel;
    return CardRevealRewardCue(
      id: sortedIds.join('|'),
      missionCompleted: missionCompleted || other.missionCompleted,
      xp: xp > other.xp ? xp : other.xp,
      earnedXp: earnedXp > other.earnedXp ? earnedXp : other.earnedXp,
      newLevel: mergedLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CardRevealRewardCue &&
        other.id == id &&
        other.missionCompleted == missionCompleted &&
        other.xp == xp &&
        other.earnedXp == earnedXp &&
        other.newLevel == newLevel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    missionCompleted,
    xp,
    earnedXp,
    newLevel,
  );
}

class CardRevealController extends ChangeNotifier {
  CardRevealController({this.kind = CardRevealKind.normal});

  final CardRevealKind kind;
  CardRevealState _state = CardRevealState.idle;
  CardRevealRewardCue? _queuedReward;
  bool _disposed = false;

  CardRevealState get state => _state;
  CardRevealRewardCue? get queuedReward => _queuedReward;

  void showLoading() => _setState(CardRevealState.loading);

  void startReveal() => _setState(CardRevealState.revealing);

  void markRevealed() => _setState(CardRevealState.revealed);

  void complete() => _setState(CardRevealState.completed);

  void showError() => _setState(CardRevealState.error);

  void reset() {
    _queuedReward = null;
    _setState(CardRevealState.idle);
  }

  void queueReward(CardRevealRewardCue cue) {
    if (_queuedReward == cue) return;
    _queuedReward = cue;
    if (!_disposed) notifyListeners();
  }

  CardRevealRewardCue? takeQueuedReward() {
    final reward = _queuedReward;
    _queuedReward = null;
    return reward;
  }

  void _setState(CardRevealState next) {
    if (_disposed || _state == next) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
