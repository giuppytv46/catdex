import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/home/application/home_controller.dart';
import 'package:catdex/features/home/domain/entities/home_dashboard.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final dashboard = ref.watch(homeControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => context.pushNamed(AppRoute.settings.name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          120,
        ),
        children: [
          _PlayerHeader(dashboard: dashboard),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: l10n.dailyMissionsTitle),
          const SizedBox(height: AppSpacing.md),
          for (final mission in dashboard.dailyMissions) ...[
            _MissionTile(mission: mission),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
          _SectionTitle(title: l10n.recentDiscoveriesTitle),
          const SizedBox(height: AppSpacing.md),
          _RecentDiscoveries(discoveries: dashboard.recentDiscoveries),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: l10n.currentEventTitle),
          const SizedBox(height: AppSpacing.md),
          _CurrentEventCard(event: dashboard.currentEvent),
          const SizedBox(height: AppSpacing.lg),
          _SectionTitle(title: l10n.quickActionsTitle),
          const SizedBox(height: AppSpacing.md),
          const _QuickActions(),
        ],
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  const _PlayerHeader({required this.dashboard});

  final HomeDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _softCardDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.skyBlue,
            AppColors.primaryPurple,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primaryPurple,
                    size: 40,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dashboard.playerName,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${l10n.playerLevelLabel} '
                        '${dashboard.playerProgress.level}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.xpProgressLabel,
              style: textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: dashboard.xpProgress,
                backgroundColor: AppColors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${dashboard.playerProgress.totalXp} XP',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Pill(
                  label: '${dashboard.pawPoints} ${l10n.pawPointsLabel}',
                  icon: Icons.stars_rounded,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _Pill(
              label:
                  '${l10n.completionLabel} '
                  '${(dashboard.collectionCompletion * 100).round()}%',
              icon: Icons.style_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  const _MissionTile({required this.mission});

  final DailyMission mission;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final completed = mission.completed;
    final statusColor = completed ? AppColors.success : AppColors.warning;
    final statusLabel = completed
        ? l10n.completedLabel
        : l10n.notCompletedLabel;
    final missionStatus =
        '${mission.progress}/${mission.goal} • '
        '${mission.xpReward} XP • '
        '$statusLabel';

    return DecoratedBox(
      decoration: _softCardDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                completed ? Icons.check_circle_rounded : Icons.flag_rounded,
                color: statusColor,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _missionTitle(l10n, mission.titleKey),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    missionStatus,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _missionTitle(
    CatDexLocalizations l10n,
    DailyMissionTitleKey titleKey,
  ) {
    return switch (titleKey) {
      DailyMissionTitleKey.discoverOneCat => l10n.discoverOneCatMission,
      DailyMissionTitleKey.importOnePhoto => l10n.importOnePhotoMission,
      DailyMissionTitleKey.visitYourCatDex => l10n.visitCatDexMission,
    };
  }
}

class _RecentDiscoveries extends StatelessWidget {
  const _RecentDiscoveries({required this.discoveries});

  final List<RecentDiscovery> discoveries;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 256,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: discoveries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return _DiscoveryCard(discovery: discoveries[index]);
        },
      ),
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.discovery});

  final RecentDiscovery discovery;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rarityColor = _rarityColor(discovery.rarityName);

    return Container(
      width: 196,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _softCardDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            rarityColor.withValues(alpha: 0.22),
            AppColors.primaryPurple.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: rarityColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: rarityColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: rarityColor.withValues(alpha: 0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rarityColor,
                  AppColors.primaryPurple.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            discovery.catName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            discovery.speciesName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MiniBadge(label: discovery.rarityName),
              _MiniBadge(label: discovery.variantName),
            ],
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discovery.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.ink),
                  ),
                  Text(
                    '${discovery.xpReward} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _rarityColor(String rarityName) {
  return switch (rarityName.toLowerCase()) {
    'common' => AppColors.primaryGreen,
    'uncommon' => AppColors.skyBlue,
    'rare' => AppColors.primaryPurple,
    'epic' => const Color(0xFFEC4899),
    'legendary' => AppColors.warning,
    'mythic' => AppColors.danger,
    _ => AppColors.primaryGreen,
  };
}

class _CurrentEventCard extends StatelessWidget {
  const _CurrentEventCard({required this.event});

  final CurrentEvent event;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: _softCardDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warning,
            AppColors.primaryGreen,
            AppColors.primaryPurple,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.warning,
                size: 36,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    event.dateRange,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Pill(label: event.badgeName, icon: Icons.workspace_premium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      children: [
        _GradientActionButton(
          label: l10n.captureCatAction,
          icon: Icons.center_focus_strong_rounded,
          onPressed: () => context.goNamed(AppRoute.capture.name),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActionButton(
          label: l10n.openCatDexAction,
          icon: Icons.style_rounded,
          onPressed: () => context.goNamed(AppRoute.catDex.name),
        ),
        const SizedBox(height: AppSpacing.sm),
        _SecondaryActionButton(
          label: l10n.viewProfileAction,
          icon: Icons.person_rounded,
          onPressed: () => context.goNamed(AppRoute.profile.name),
        ),
      ],
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryGreen, AppColors.primaryPurple],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.white, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _softCardDecoration({
  Color? color,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: color,
    gradient: gradient,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
