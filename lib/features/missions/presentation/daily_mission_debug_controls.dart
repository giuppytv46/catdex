import 'dart:async';

import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_controls.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyMissionDebugControls extends ConsumerWidget {
  const DailyMissionDebugControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showMonetizationDebug) return const SizedBox.shrink();
    final state = ref.watch(dailyMissionControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          color: AppColors.white.withValues(alpha: 0.24),
          height: AppSpacing.xl,
        ),
        Text(
          'Debug Missioni giornaliere',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text(
            'Mission state unavailable',
            style: TextStyle(color: AppColors.white),
          ),
          data: (ledger) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Date: ${ledger.assignedDate} · '
                'Completed: ${ledger.completedCount}/${ledger.missions.length} '
                '· Claims: ${ledger.claimTransactions.length}',
                style: const TextStyle(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton(
                    onPressed: () => unawaited(
                      ref
                          .read(dailyMissionControllerProvider.notifier)
                          .resetTodayProgressForDebug(),
                    ),
                    child: const Text('Reset mission progress'),
                  ),
                  OutlinedButton(
                    onPressed: () => unawaited(
                      ref
                          .read(dailyMissionControllerProvider.notifier)
                          .regenerateTodayForDebug(),
                    ),
                    child: const Text('Regenerate missions'),
                  ),
                  OutlinedButton(
                    onPressed: () => unawaited(
                      ref
                          .read(dailyMissionControllerProvider.notifier)
                          .simulateNextMissionEventForDebug(),
                    ),
                    child: const Text('Simulate mission event'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
