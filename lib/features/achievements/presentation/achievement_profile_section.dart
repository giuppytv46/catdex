import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/achievements/application/achievement_controller.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/presentation/achievement_badge.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AchievementProfileSection extends ConsumerStatefulWidget {
  const AchievementProfileSection({super.key});

  @override
  ConsumerState<AchievementProfileSection> createState() =>
      _AchievementProfileSectionState();
}

class _AchievementProfileSectionState
    extends ConsumerState<AchievementProfileSection> {
  @override
  void initState() {
    super.initState();
    debugPrint('CATDEX_ACHIEVEMENTS_PROFILE_VISIBLE');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(achievementControllerProvider);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: state.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Text(l10n.achievementsProfileEmpty),
          data: (value) {
            final total = AchievementCatalogV1.definitions.length;
            final unlocked =
                AchievementCatalogV1.definitions
                    .where(
                      (definition) =>
                          value
                              .ledger
                              .achievements[definition.achievementId]
                              ?.isUnlocked ==
                          true,
                    )
                    .toList(growable: false)
                  ..sort((a, b) {
                    final aDate =
                        value.ledger.achievements[a.achievementId]?.unlockedAt;
                    final bDate =
                        value.ledger.achievements[b.achievementId]?.unlockedAt;
                    return (bDate ?? DateTime.fromMillisecondsSinceEpoch(0))
                        .compareTo(
                          aDate ?? DateTime.fromMillisecondsSinceEpoch(0),
                        );
                  });
            final closest = _closest(value.ledger);
            final displayed = unlocked.isNotEmpty
                ? unlocked.take(3).toList(growable: false)
                : closest == null
                ? const <AchievementDefinition>[]
                : [closest];
            final overall = total == 0 ? 0.0 : unlocked.length / total;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.achievementsProfileTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${unlocked.length} / $total',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: overall, minHeight: 7),
                const SizedBox(height: AppSpacing.md),
                if (displayed.isEmpty)
                  Text(l10n.achievementsProfileEmpty)
                else
                  Row(
                    children: [
                      for (final definition in displayed) ...[
                        AchievementBadge(
                          definition: definition,
                          unlocked:
                              value
                                  .ledger
                                  .achievements[definition.achievementId]
                                  ?.isUnlocked ==
                              true,
                          size: 48,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (unlocked.isEmpty && closest != null)
                        Expanded(
                          child: Text(
                            l10n.achievementText(closest.localizedTitleKey),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoute.achievements.name),
                  icon: const Icon(Icons.emoji_events_rounded),
                  label: Text(l10n.achievementsProfileAction),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

AchievementDefinition? _closest(AchievementLedger ledger) {
  AchievementDefinition? best;
  var bestProgress = -1.0;
  for (final definition in AchievementCatalogV1.definitions) {
    final achievement = ledger.achievements[definition.achievementId];
    if (achievement?.isUnlocked == true) continue;
    final progress = achievement?.progress ?? 0;
    if (progress > bestProgress) {
      best = definition;
      bestProgress = progress;
    }
  }
  return best;
}
