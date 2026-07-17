import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/achievements/application/achievement_controller.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/presentation/achievement_badge.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AchievementsPage extends ConsumerStatefulWidget {
  const AchievementsPage({super.key});

  @override
  ConsumerState<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends ConsumerState<AchievementsPage> {
  AchievementCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final achievementState = ref.watch(achievementControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: achievementState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(achievementControllerProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: Text(l10n.refreshAction),
          ),
        ),
        data: (state) {
          final definitions = AchievementCatalogV1.definitions
              .where(
                (definition) =>
                    _selectedCategory == null ||
                    definition.category == _selectedCategory,
              )
              .toList(growable: false);
          return RefreshIndicator(
            onRefresh: () => ref
                .read(achievementControllerProvider.notifier)
                .evaluate(source: 'achievement_page_refresh'),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _AchievementSummary(ledger: state.ledger),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoryFilters(
                    selected: _selectedCategory,
                    onSelected: (category) {
                      setState(() => _selectedCategory = category);
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    120,
                  ),
                  sliver: SliverList.builder(
                    itemCount: definitions.length,
                    itemBuilder: (context, index) {
                      final definition = definitions[index];
                      final previousCategory = index == 0
                          ? null
                          : definitions[index - 1].category;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (previousCategory != definition.category) ...[
                            Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : AppSpacing.md,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                l10n.achievementCategoryLabel(
                                  definition.category.name,
                                ),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                          _AchievementCard(
                            definition: definition,
                            achievement:
                                state.ledger.achievements[definition
                                    .achievementId] ??
                                PlayerAchievement.initial(definition),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AchievementSummary extends StatelessWidget {
  const _AchievementSummary({required this.ledger});

  final AchievementLedger ledger;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final total = AchievementCatalogV1.definitions.length;
    final unlocked = AchievementCatalogV1.definitions
        .where(
          (definition) =>
              ledger.achievements[definition.achievementId]?.isUnlocked == true,
        )
        .length;
    final overall = total == 0 ? 0.0 : unlocked / total;
    final closest = _closestLocked(ledger);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF172033),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.achievementsSummaryTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$unlocked / $total · ${(overall * 100).round()}%',
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(value: overall, minHeight: 8),
            if (closest != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.achievementText(closest.localizedTitleKey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF99F6E4),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({required this.selected, required this.onSelected});

  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onSelected;

  static const List<AchievementCategory> categories = [
    AchievementCategory.discoveries,
    AchievementCategory.cards,
    AchievementCategory.rarity,
    AchievementCategory.exploration,
    AchievementCategory.missions,
    AchievementCategory.events,
    AchievementCategory.progression,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(l10n.achievementsAllFilter),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: AppSpacing.xs),
            ChoiceChip(
              label: Text(l10n.achievementCategoryLabel(category.name)),
              selected: selected == category,
              onSelected: (_) => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({
    required this.definition,
    required this.achievement,
  });

  final AchievementDefinition definition;
  final PlayerAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final unlocked = achievement.isUnlocked;
    final current = achievement.currentValue.clamp(0, achievement.targetValue);
    final progress = achievement.targetValue <= 0
        ? 1.0
        : current / achievement.targetValue;
    return Semantics(
      label: l10n.achievementText(definition.localizedTitleKey),
      child: DecoratedBox(
        key: ValueKey('achievement-${definition.achievementId}'),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievementTierStyle(definition.tier).border.withValues(
              alpha: unlocked ? 0.82 : 0.25,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AchievementBadge(definition: definition, unlocked: unlocked),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.achievementText(
                              definition.localizedTitleKey,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (unlocked)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF22C55E),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.achievementText(
                        unlocked
                            ? definition.localizedDescriptionKey
                            : definition.localizedLockedHintKey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LinearProgressIndicator(value: progress, minHeight: 6),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$current / ${achievement.targetValue}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          l10n.achievementTierLabel(definition.tier.name),
                          style: TextStyle(
                            color: achievementTierStyle(definition.tier).border,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          l10n.achievementXpReward(definition.rewardXp),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (definition.achievementId ==
                            'halloween_premium_collection')
                          Chip(
                            visualDensity: VisualDensity.compact,
                            label: Text(l10n.achievementsPremiumLabel),
                          ),
                        if (unlocked && achievement.unlockedAt != null)
                          Text(_formatDate(achievement.unlockedAt!)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AchievementDefinition? _closestLocked(AchievementLedger ledger) {
  final locked = AchievementCatalogV1.definitions
      .where(
        (definition) =>
            ledger.achievements[definition.achievementId]?.isUnlocked != true,
      )
      .toList(growable: false);
  if (locked.isEmpty) return null;
  locked.sort((a, b) {
    final aProgress = ledger.achievements[a.achievementId]?.progress ?? 0.0;
    final bProgress = ledger.achievements[b.achievementId]?.progress ?? 0.0;
    return bProgress.compareTo(aProgress);
  });
  return locked.first;
}

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}
