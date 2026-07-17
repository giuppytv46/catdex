import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/application/daily_mission_service.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DailyMissionsHomeSection extends ConsumerStatefulWidget {
  const DailyMissionsHomeSection({required this.onSeeAll, super.key});

  final VoidCallback onSeeAll;

  @override
  ConsumerState<DailyMissionsHomeSection> createState() =>
      _DailyMissionsHomeSectionState();
}

class _DailyMissionsHomeSectionState
    extends ConsumerState<DailyMissionsHomeSection> {
  final Set<String> _claiming = {};
  bool _loggedVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(dailyMissionControllerProvider);
    if (!_loggedVisible) {
      _loggedVisible = true;
      debugPrint('CATDEX_MISSIONS_HOME_VISIBLE');
    }
    return DecoratedBox(
      key: const ValueKey('home-daily-missions-section'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: state.when(
          loading: () => const SizedBox(
            height: 112,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _MissionLoadError(
            onRetry: () {
              ref.invalidate(dailyMissionControllerProvider);
            },
          ),
          data: (ledger) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.dailyMissionsTodayTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${ledger.completedCount}/${ledger.missions.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.dailyMissionsSubtitle,
                maxLines: 2,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final mission in ledger.missions.take(3)) ...[
                CompactDailyMissionRow(
                  mission: mission,
                  claiming: _claiming.contains(mission.missionId),
                  onClaim: mission.isClaimable
                      ? () => _claim(mission.missionId)
                      : null,
                ),
                if (mission != ledger.missions.take(3).last)
                  const Divider(height: AppSpacing.md),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const ValueKey('daily-missions-see-all'),
                  onPressed: widget.onSeeAll,
                  child: Text(l10n.dailyMissionsSeeAll),
                ),
              ),
            ],
          ),
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

class CompactDailyMissionRow extends StatelessWidget {
  const CompactDailyMissionRow({
    required this.mission,
    required this.claiming,
    this.onClaim,
    super.key,
  });

  final DailyMission mission;
  final bool claiming;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final claimed = mission.isClaimed;
    final color = claimed || mission.isCompleted
        ? AppColors.success
        : Theme.of(context).colorScheme.primary;
    return Padding(
      key: ValueKey('daily-mission-row-${mission.missionId}'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(
            claimed
                ? Icons.check_circle_rounded
                : mission.isCompleted
                ? Icons.redeem_rounded
                : _missionIcon(mission.missionType),
            color: color,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dailyMissionTitle(l10n, mission.localizedTitleKey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: mission.progress,
                    minHeight: 5,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${mission.currentValue}/${mission.targetValue} · '
                  '${dailyMissionRewardLabel(l10n, mission)}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (claimed)
            Text(
              l10n.dailyMissionClaimed,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            )
          else if (mission.isClaimable)
            SizedBox(
              width: 104,
              child: FilledButton(
                key: ValueKey('daily-mission-claim-${mission.missionId}'),
                onPressed: claiming ? null : onClaim,
                child: claiming
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.dailyMissionClaim),
              ),
            ),
        ],
      ),
    );
  }
}

class _MissionLoadError extends StatelessWidget {
  const _MissionLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.dailyMissionsLoadError, textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: Text(l10n.retryAction)),
      ],
    );
  }
}

String dailyMissionTitle(
  CatDexLocalizations l10n,
  DailyMissionTextKey key,
) {
  return switch (key) {
    DailyMissionTextKey.discoverOneCatTitle => l10n.dailyMissionDiscoverOneCat,
    DailyMissionTextKey.discoverTwoCatsTitle =>
      l10n.dailyMissionDiscoverTwoCats,
    DailyMissionTextKey.generateNormalCardTitle =>
      l10n.dailyMissionGenerateCard,
    DailyMissionTextKey.openMapTitle => l10n.dailyMissionOpenMap,
    DailyMissionTextKey.discoverWithLocationTitle =>
      l10n.dailyMissionDiscoverWithLocation,
    DailyMissionTextKey.discoverCommonTitle => l10n.dailyMissionDiscoverCommon,
    DailyMissionTextKey.discoverUncommonTitle =>
      l10n.dailyMissionDiscoverUncommon,
    DailyMissionTextKey.generateEventCardTitle =>
      l10n.dailyMissionGenerateEventCard,
    _ => dailyMissionDescription(l10n, key),
  };
}

String dailyMissionDescription(
  CatDexLocalizations l10n,
  DailyMissionTextKey key,
) {
  return switch (key) {
    DailyMissionTextKey.discoverOneCatDescription =>
      l10n.dailyMissionDiscoverOneCatDescription,
    DailyMissionTextKey.discoverTwoCatsDescription =>
      l10n.dailyMissionDiscoverTwoCatsDescription,
    DailyMissionTextKey.generateNormalCardDescription =>
      l10n.dailyMissionGenerateCardDescription,
    DailyMissionTextKey.openMapDescription =>
      l10n.dailyMissionOpenMapDescription,
    DailyMissionTextKey.discoverWithLocationDescription =>
      l10n.dailyMissionDiscoverWithLocationDescription,
    DailyMissionTextKey.discoverCommonDescription =>
      l10n.dailyMissionDiscoverCommonDescription,
    DailyMissionTextKey.discoverUncommonDescription =>
      l10n.dailyMissionDiscoverUncommonDescription,
    DailyMissionTextKey.generateEventCardDescription =>
      l10n.dailyMissionGenerateEventCardDescription,
    _ => '',
  };
}

String dailyMissionRewardLabel(
  CatDexLocalizations l10n,
  DailyMission mission,
) {
  return switch (mission.rewardType) {
    DailyMissionRewardType.xp => '${mission.rewardAmount} XP',
    DailyMissionRewardType.analysisCredit =>
      l10n.dailyMissionAnalysisCreditReward(mission.rewardAmount),
    DailyMissionRewardType.cardCredit => l10n.dailyMissionCardCreditReward(
      mission.rewardAmount,
    ),
  };
}

IconData _missionIcon(DailyMissionType type) {
  return switch (type) {
    DailyMissionType.discoverCats => Icons.camera_alt_rounded,
    DailyMissionType.generateNormalCard => Icons.style_rounded,
    DailyMissionType.openMap => Icons.map_rounded,
    DailyMissionType.discoverWithLocation => Icons.add_location_alt_rounded,
    DailyMissionType.discoverRarity => Icons.auto_awesome_rounded,
    DailyMissionType.generateEventCard => Icons.celebration_rounded,
  };
}
