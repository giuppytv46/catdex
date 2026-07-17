import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/presentation/daily_mission_widgets.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyMissionsPage extends ConsumerStatefulWidget {
  const DailyMissionsPage({super.key});

  @override
  ConsumerState<DailyMissionsPage> createState() => _DailyMissionsPageState();
}

class _DailyMissionsPageState extends ConsumerState<DailyMissionsPage> {
  final Set<String> _claiming = {};

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(dailyMissionControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dailyMissionsTodayTitle)),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dailyMissionsLoadError,
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(
                    dailyMissionControllerProvider,
                  ),
                  child: Text(l10n.retryAction),
                ),
              ],
            ),
          ),
        ),
        data: (ledger) => ListView(
          key: const ValueKey('daily-missions-page-list'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            48,
          ),
          children: [
            Text(
              l10n.dailyMissionsSubtitle,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${ledger.completedCount}/${ledger.missions.length} · '
              '${l10n.dailyMissionsNewTomorrow}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final mission in ledger.missions) ...[
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CompactDailyMissionRow(
                        mission: mission,
                        claiming: _claiming.contains(mission.missionId),
                        onClaim: mission.isClaimable
                            ? () => _claim(mission.missionId)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        dailyMissionDescription(
                          l10n,
                          mission.localizedDescriptionKey,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (mission.isCompleted) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.dailyMissionCompleted,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _claim(String missionId) async {
    if (!_claiming.add(missionId)) return;
    setState(() {});
    final result = await ref
        .read(dailyMissionControllerProvider.notifier)
        .claim(missionId);
    if (!mounted) return;
    setState(() => _claiming.remove(missionId));
    if (result == DailyMissionClaimResultType.failed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CatDexLocalizations.of(context).dailyMissionClaimError,
          ),
        ),
      );
    }
  }
}
