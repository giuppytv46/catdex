import 'dart:async';

import 'package:catdex/features/achievements/application/achievement_controller.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/presentation/achievement_celebration_presenter.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementDebugControls extends ConsumerWidget {
  const AchievementDebugControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(achievementControllerProvider);
    final state = asyncState.value;
    final ledger = state?.ledger;
    final unlocked =
        ledger?.achievements.values
            .where((achievement) => achievement.isUnlocked)
            .length ??
        0;
    final transactionIds = ledger?.rewardTransactions.keys.toList() ?? const [];
    final transactionSummary = transactionIds.isEmpty
        ? '-'
        : transactionIds.join(', ');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.skyBlue.withValues(alpha: 0.5),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Debug Traguardi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sbloccati: $unlocked / '
                '${AchievementCatalogV1.definitions.length}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Transazioni: $transactionSummary',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: state?.isEvaluating == true
                        ? null
                        : () {
                            unawaited(
                              ref
                                  .read(achievementControllerProvider.notifier)
                                  .evaluate(source: 'debug_reconciliation'),
                            );
                          },
                    child: const Text('Run reconciliation'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      final definition = AchievementCatalogV1.definitions.first;
                      unawaited(
                        AchievementCelebrationPresenter.present(
                          context,
                          AchievementUnlockResult(
                            achievementId: definition.achievementId,
                            rewardXp: definition.rewardXp,
                            previousXp: 0,
                            updatedXp: definition.rewardXp,
                            previousLevel: 1,
                            updatedLevel: 1,
                            rewardTransactionId: 'debug_preview_only',
                            wasAlreadyUnlocked: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Simulate unlock'),
                  ),
                  TextButton(
                    onPressed: () {
                      unawaited(
                        ref
                            .read(achievementControllerProvider.notifier)
                            .resetDebugState(),
                      );
                    },
                    child: const Text('Reset debug state'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
