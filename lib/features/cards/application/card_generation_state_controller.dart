import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CardGenerationSharedPhase {
  idle,
  generating,
  failed,
  completed,
}

@immutable
class CardGenerationSharedState {
  const CardGenerationSharedState({
    required this.phase,
    this.label,
    this.revision = 0,
  });

  static const idle = CardGenerationSharedState(
    phase: CardGenerationSharedPhase.idle,
  );

  final CardGenerationSharedPhase phase;
  final String? label;
  final int revision;

  bool get isGenerating => phase == CardGenerationSharedPhase.generating;
  bool get hasFailed => phase == CardGenerationSharedPhase.failed;
  bool get isCompleted => phase == CardGenerationSharedPhase.completed;

  @override
  bool operator ==(Object other) {
    return other is CardGenerationSharedState &&
        other.phase == phase &&
        other.label == label &&
        other.revision == revision;
  }

  @override
  int get hashCode => Object.hash(phase, label, revision);
}

final cardGenerationStateProvider =
    NotifierProvider<
      CardGenerationStateController,
      Map<String, CardGenerationSharedState>
    >(CardGenerationStateController.new);

class CardGenerationStateController
    extends Notifier<Map<String, CardGenerationSharedState>> {
  @override
  Map<String, CardGenerationSharedState> build() => const {};

  bool begin(String discoveryId, {required String label}) {
    final current = forDiscovery(discoveryId);
    if (current.isGenerating) {
      debugPrint('CATDEX_CARD_GENERATION_BUTTON_DISABLED $discoveryId');
      return false;
    }

    _set(
      discoveryId,
      CardGenerationSharedState(
        phase: CardGenerationSharedPhase.generating,
        label: label,
        revision: current.revision + 1,
      ),
    );
    debugPrint('CATDEX_CARD_GENERATION_STATE_GENERATING $discoveryId');
    return true;
  }

  void ensureGenerating(String discoveryId, {required String label}) {
    final current = forDiscovery(discoveryId);
    if (current.isGenerating) {
      if (current.label != label) {
        updateLabel(discoveryId, label);
      }
      return;
    }
    begin(discoveryId, label: label);
  }

  void updateLabel(String discoveryId, String label) {
    final current = forDiscovery(discoveryId);
    if (!current.isGenerating || current.label == label) {
      return;
    }
    _set(
      discoveryId,
      CardGenerationSharedState(
        phase: CardGenerationSharedPhase.generating,
        label: label,
        revision: current.revision,
      ),
    );
  }

  void complete(String discoveryId) {
    final current = forDiscovery(discoveryId);
    _set(
      discoveryId,
      CardGenerationSharedState(
        phase: CardGenerationSharedPhase.completed,
        revision: current.revision,
      ),
    );
    debugPrint('CATDEX_CARD_GENERATION_COMPLETED_REFRESH $discoveryId');
  }

  void fail(String discoveryId) {
    final current = forDiscovery(discoveryId);
    _set(
      discoveryId,
      CardGenerationSharedState(
        phase: CardGenerationSharedPhase.failed,
        revision: current.revision,
      ),
    );
  }

  void reset(String discoveryId) {
    if (!state.containsKey(discoveryId)) {
      return;
    }
    final next = Map<String, CardGenerationSharedState>.of(state)
      ..remove(discoveryId);
    state = next;
    debugPrint(
      'CATDEX_CARD_GENERATION_STATE_SHARED $discoveryId idle',
    );
  }

  CardGenerationSharedState forDiscovery(String discoveryId) {
    return state[discoveryId] ?? CardGenerationSharedState.idle;
  }

  bool get hasAnyGenerating => state.values.any((item) => item.isGenerating);

  void _set(String discoveryId, CardGenerationSharedState value) {
    state = {...state, discoveryId: value};
    debugPrint(
      'CATDEX_CARD_GENERATION_STATE_SHARED '
      '$discoveryId ${value.phase.name}',
    );
  }
}
