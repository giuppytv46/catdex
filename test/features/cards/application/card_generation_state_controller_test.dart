import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('volatile generating state returns to retryable idle after restart', () {
    final firstProcess = ProviderContainer();
    expect(
      firstProcess
          .read(cardGenerationStateProvider.notifier)
          .begin('cat-1', label: 'Generazione'),
      isTrue,
    );
    expect(
      firstProcess
          .read(cardGenerationStateProvider.notifier)
          .forDiscovery('cat-1')
          .isGenerating,
      isTrue,
    );
    firstProcess.dispose();

    final restartedProcess = ProviderContainer();
    addTearDown(restartedProcess.dispose);

    final restored = restartedProcess
        .read(cardGenerationStateProvider.notifier)
        .forDiscovery('cat-1');
    expect(restored.phase, CardGenerationSharedPhase.idle);
    expect(restored.isGenerating, isFalse);
  });
}
