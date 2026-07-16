import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daily usage credits and premium survive service recreation', () async {
    final service = MonetizationService(() {});
    expect(await service.consumeAnalysis(), isTrue);
    expect(await service.consumeCardGeneration(), isTrue);
    expect(await service.consumeCardGeneration(), isTrue);
    await service.addAnalysisCredits(4);
    await service.addCardGenerationCredits(6);
    await service.setPremiumForDebug(true);

    final restartedService = MonetizationService(() {});
    final restored = await restartedService.getStatus();

    expect(restored.isPremium, isTrue);
    expect(restored.dailyAnalysisCount, 1);
    expect(restored.dailyCardGenerationCount, 2);
    expect(restored.extraAnalysisCredits, 4);
    expect(restored.extraCardGenerationCredits, 6);
    expect(restored.lastLimitResetDate, isNotEmpty);
  });
}
