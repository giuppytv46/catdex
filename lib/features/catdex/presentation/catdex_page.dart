import 'dart:async';

import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatDexPage extends ConsumerWidget {
  const CatDexPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catDexControllerProvider);
    final controller = ref.read(catDexControllerProvider.notifier);
    final progress = ref.watch(localPlayerProgressSessionProvider);
    final levelCalculator = ref.watch(levelCalculatorProvider);
    final levelStartXp = levelCalculator.xpRequiredForLevel(progress.level);
    final nextLevelXp = levelCalculator.xpRequiredForLevel(progress.level + 1);
    final levelSpan = nextLevelXp - levelStartXp;
    final levelXp = progress.totalXp - levelStartXp;
    final xpProgress = levelSpan <= 0 ? 1.0 : levelXp / levelSpan;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: CustomScrollView(
        key: const Key('catdex_collection_scroll'),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundGray,
            surfaceTintColor: Colors.transparent,
            title: const Text('CatDex'),
            actions: [
              IconButton(
                tooltip: 'Profilo',
                onPressed: () {},
                icon: const Icon(Icons.person_rounded),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            sliver: SliverList.list(
              children: [
                _PlayerCollectionHeader(
                  level: progress.level,
                  totalXp: progress.totalXp,
                  levelXp: levelXp.clamp(0, levelSpan),
                  nextLevelXp: levelSpan,
                  xpProgress: xpProgress.clamp(0, 1),
                  coins: progress.coins,
                  found: state.discoveredCount,
                  total: state.totalCount,
                  completion: state.completionPercentage,
                ),
                const SizedBox(height: AppSpacing.lg),
                _SearchBar(onChanged: controller.updateSearchQuery),
                const SizedBox(height: AppSpacing.md),
                _CollectionFilters(
                  state: state,
                  onAll: () {
                    controller
                      ..setDiscoveryFilter(CatDexDiscoveryFilter.all)
                      ..clearRarityFilter();
                  },
                  onRarity: controller.toggleRarity,
                  onFavorites: () {
                    controller
                      ..clearRarityFilter()
                      ..setDiscoveryFilter(CatDexDiscoveryFilter.favorites);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              128,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 268,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
              ),
              itemCount: state.visibleEntries.length,
              itemBuilder: (context, index) {
                final entry = state.visibleEntries[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 260 + (index % 8) * 45),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: _CatCollectionCard(
                    key: ValueKey('catdex_card_${entry.species.id}'),
                    entry: entry,
                    onTap: () => _openEntry(context, entry),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEntry(BuildContext context, CatDexCollectionEntry entry) {
    if (!entry.discovered || entry.discovery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: const Text(
            'Continua a esplorare per scoprire questo gatto.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      );
      return;
    }

    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexDetailPage(entry: entry),
        ),
      ),
    );
  }
}

class CatDexDetailPage extends StatelessWidget {
  const CatDexDetailPage({required this.entry, super.key});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final discovery = entry.discovery;
    final rarity = _entryRarity(entry);
    final displayData = _displayDataForEntry(entry);
    final speciesLabel =
        displayData?.displaySpecies ?? entry.species.displayName;
    final name = displayData?.displayName ?? entry.displayName ?? speciesLabel;
    final resolvedImage = CatDexImageResolver.resolveBestImagePath(
      discovery: discovery,
      discoveredPhotoPath: entry.discoveredPhotoPath,
    );
    debugPrint('CATDEX_DETAIL_DISCOVERY_ID ${discovery?.id ?? '-'}');
    debugPrint('CATDEX_DETAIL_IMAGE_PATH ${resolvedImage.path ?? '-'}');
    debugPrint(
      'CATDEX_DETAIL_SHOWING_PLACEHOLDER ${resolvedImage.usesPlaceholder}',
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        title: Text(name),
        backgroundColor: AppColors.backgroundGray,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          AspectRatio(
            aspectRatio: 1.15,
            child: _CatPhotoFrame(
              resolvedImage: resolvedImage,
              rarity: rarity,
              frameStyle: entry.cardFrameStyle,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _CatDetailHeader(
            name: name,
            species: speciesLabel,
            rarity: rarity,
            personality: displayData?.displayPersonality ?? '-',
          ),
          const SizedBox(height: AppSpacing.lg),
          _CatDetailSection(
            title: 'Dettagli',
            rows: [
              _CatDetailRow(
                label: 'Mantello',
                value: displayData?.displayCoatColor ?? '-',
              ),
              _CatDetailRow(
                label: 'Pattern',
                value: displayData?.displayCoatPattern ?? '-',
              ),
              _CatDetailRow(
                label: 'Occhi',
                value: displayData?.displayEyeColor ?? '-',
              ),
              _CatDetailRow(
                label: 'Pelo',
                value: displayData?.displayHairLength ?? '-',
              ),
              _CatDetailRow(
                label: 'Età',
                value: displayData?.displayAge ?? '-',
              ),
              _CatDetailRow(
                label: 'Scoperto il',
                value: _formatDate(discovery?.discoveredAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _CatDetailTextCard(
            title: 'Storia',
            value:
                displayData?.displayStory ??
                'Una nuova storia CatDex sta prendendo forma.',
          ),
          const SizedBox(height: AppSpacing.md),
          _CatDetailTextCard(
            title: 'Curiosità',
            value:
                displayData?.displayFunFact ??
                'Continua a esplorare per scoprire altri dettagli.',
          ),
        ],
      ),
    );
  }
}

class _CatDetailHeader extends StatelessWidget {
  const _CatDetailHeader({
    required this.name,
    required this.species,
    required this.rarity,
    required this.personality,
  });

  final String name;
  final String species;
  final CatRarity rarity;
  final String personality;

  @override
  Widget build(BuildContext context) {
    final style = _cardStyleForRarity(rarity);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              species,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RarityBadge(rarity: rarity, color: style.frameColor),
                _DetailChip(icon: Icons.psychology_rounded, label: personality),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatDetailSection extends StatelessWidget {
  const _CatDetailSection({required this.title, required this.rows});

  final String title;
  final List<_CatDetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final row in rows) row,
          ],
        ),
      ),
    );
  }
}

class _CatDetailRow extends StatelessWidget {
  const _CatDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatDetailTextCard extends StatelessWidget {
  const _CatDetailTextCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primaryPurple),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerCollectionHeader extends StatelessWidget {
  const _PlayerCollectionHeader({
    required this.level,
    required this.totalXp,
    required this.levelXp,
    required this.nextLevelXp,
    required this.xpProgress,
    required this.coins,
    required this.found,
    required this.total,
    required this.completion,
  });

  final int level;
  final int totalXp;
  final int levelXp;
  final int nextLevelXp;
  final double xpProgress;
  final int coins;
  final int found;
  final int total;
  final double completion;

  @override
  Widget build(BuildContext context) {
    final completionPercent = (completion * 100).round();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.skyBlue,
            AppColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.24),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.white,
                  child: Icon(
                    Icons.pets_rounded,
                    color: AppColors.primaryPurple,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        '$totalXp XP totali',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.86),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderCoinPill(coins: coins),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: xpProgress,
                backgroundColor: AppColors.white.withValues(alpha: 0.26),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$levelXp / $nextLevelXp XP',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    label: 'Trovati',
                    value: '$found / $total Gatti',
                    icon: Icons.style_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _HeaderStat(
                    label: 'Completato',
                    value: '$completionPercent%',
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCoinPill extends StatelessWidget {
  const _HeaderCoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.44)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.paid_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '$coins',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.white, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('catdex_search_field'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Cerca per nome',
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _CollectionFilters extends StatelessWidget {
  const _CollectionFilters({
    required this.state,
    required this.onAll,
    required this.onRarity,
    required this.onFavorites,
  });

  final CatDexCollectionState state;
  final VoidCallback onAll;
  final ValueChanged<CatRarity> onRarity;
  final VoidCallback onFavorites;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: 'Tutti',
            selected:
                state.selectedRarity == null &&
                state.discoveryFilter == CatDexDiscoveryFilter.all,
            onTap: onAll,
          ),
          _FilterChipButton(
            label: 'Comune',
            selected: state.selectedRarity == CatRarity.common,
            onTap: () => onRarity(CatRarity.common),
          ),
          _FilterChipButton(
            label: 'Raro',
            selected: state.selectedRarity == CatRarity.rare,
            onTap: () => onRarity(CatRarity.rare),
          ),
          _FilterChipButton(
            label: 'Epico',
            selected: state.selectedRarity == CatRarity.epic,
            onTap: () => onRarity(CatRarity.epic),
          ),
          _FilterChipButton(
            label: 'Leggendario',
            selected: state.selectedRarity == CatRarity.legendary,
            onTap: () => onRarity(CatRarity.legendary),
          ),
          _FilterChipButton(
            label: 'Preferiti',
            selected: state.discoveryFilter == CatDexDiscoveryFilter.favorites,
            onTap: onFavorites,
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryPurple.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          color: selected ? AppColors.primaryPurple : AppColors.ink,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

class _CatCollectionCard extends StatelessWidget {
  const _CatCollectionCard({
    required this.entry,
    required this.onTap,
    super.key,
  });

  final CatDexCollectionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discovered = entry.discovered;
    final rarity = _entryRarity(entry);
    final style = _cardStyleForRarity(rarity);
    final displayData = _displayDataForEntry(entry);
    final speciesLabel =
        displayData?.displaySpecies ?? entry.species.displayName;
    final name = entry.displayName ?? speciesLabel;

    return Semantics(
      button: true,
      label: discovered ? name : 'Locked cat',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              gradient: discovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.white,
                        style.frameColor.withValues(alpha: 0.22),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF111827), Color(0xFF374151)],
                    ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: discovered
                    ? style.frameColor.withValues(alpha: 0.8)
                    : Colors.transparent,
                width: discovered ? 3 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: discovered
                      ? style.frameColor.withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: discovered
                  ? _DiscoveredCardContent(
                      entry: entry,
                      name: name,
                      displayData: displayData,
                      style: style,
                    )
                  : const _LockedCardContent(),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveredCardContent extends StatelessWidget {
  const _DiscoveredCardContent({
    required this.entry,
    required this.name,
    required this.displayData,
    required this.style,
  });

  final CatDexCollectionEntry entry;
  final String name;
  final CatDisplayData? displayData;
  final _TradingCardStyle style;

  @override
  Widget build(BuildContext context) {
    final rarity = _entryRarity(entry);
    final speciesLabel =
        displayData?.displaySpecies ?? entry.species.displayName;
    final resolvedImage = CatDexImageResolver.resolveForEntry(entry);
    final hasPhoto = !resolvedImage.usesPlaceholder;
    debugPrint('CATDEX_GRID_DISCOVERY_ID ${entry.discovery?.id ?? '-'}');
    debugPrint('CATDEX_GRID_IMAGE_PATH ${resolvedImage.path ?? '-'}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _CatPhotoFrame(
                  resolvedImage: resolvedImage,
                  rarity: rarity,
                  frameStyle: entry.cardFrameStyle,
                ),
              ),
              if (!hasPhoto)
                const Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: _LegacyDiscoveryBadge(),
                ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Icon(
                  entry.favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: entry.favorite ? AppColors.danger : AppColors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          speciesLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.ink.withValues(alpha: 0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _RarityBadge(
                rarity: rarity,
                color: style.frameColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _StarRow(count: style.starCount, size: 13),
            if (entry.cardFrameStyle != null) ...[
              const SizedBox(width: AppSpacing.xs),
              _CardFrameChip(style: entry.cardFrameStyle!),
            ],
          ],
        ),
      ],
    );
  }
}

class _LegacyDiscoveryBadge extends StatelessWidget {
  const _LegacyDiscoveryBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        child: Text(
          'Scoperta legacy',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _LockedCardContent extends StatelessWidget {
  const _LockedCardContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: Icon(
                Icons.pets_rounded,
                color: Colors.black,
                size: 72,
                shadows: [
                  Shadow(color: AppColors.white, blurRadius: 22),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '????',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Icon(Icons.lock_rounded, color: AppColors.white),
      ],
    );
  }
}

class _CatPhotoFrame extends StatelessWidget {
  const _CatPhotoFrame({
    required this.resolvedImage,
    required this.rarity,
    this.frameStyle,
  });

  final CatDexResolvedImage resolvedImage;
  final CatRarity rarity;
  final String? frameStyle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: _frameColor(frameStyle, rarity),
          width: frameStyle == null ? 0 : 4,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _rarityColor(rarity).withValues(alpha: 0.9),
                AppColors.primaryPurple.withValues(alpha: 0.76),
              ],
            ),
          ),
          child: resolvedImage.provider == null
              ? const _PhotoPlaceholder()
              : Image(
                  image: resolvedImage.provider!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _PhotoPlaceholder(),
                ),
        ),
      ),
    );
  }

  Color _frameColor(String? style, CatRarity rarity) {
    return switch (style) {
      'green_simple_frame' => AppColors.primaryGreen,
      'blue_frame' => AppColors.skyBlue,
      'purple_frame' => AppColors.primaryPurple,
      'gold_purple_frame' => AppColors.warning,
      'gold_animated_style_frame' => AppColors.warning,
      _ => _rarityColor(rarity),
    };
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.pets_rounded,
        color: AppColors.white,
        size: 62,
      ),
    );
  }
}

class _CardFrameChip extends StatelessWidget {
  const _CardFrameChip({required this.style});

  final String style;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _frameLabel(style),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 16,
            color: AppColors.primaryPurple,
          ),
        ),
      ),
    );
  }

  String _frameLabel(String style) {
    return switch (style) {
      'green_simple_frame' => 'Cornice verde',
      'blue_frame' => 'Cornice blu',
      'purple_frame' => 'Cornice viola',
      'gold_purple_frame' => 'Cornice oro e viola',
      'gold_animated_style_frame' => 'Cornice oro leggendaria',
      _ => 'Cornice collezionabile',
    };
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({required this.rarity, required this.color});

  final CatRarity rarity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Text(
          _rarityLabel(rarity),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.count, this.size = 16});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 5; index++)
          Icon(
            index < count ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: AppColors.warning,
          ),
      ],
    );
  }
}

class _TradingCardStyle {
  const _TradingCardStyle({
    required this.frameColor,
    required this.starCount,
    required this.cardLabel,
  });

  final Color frameColor;
  final int starCount;
  final String cardLabel;
}

Color _rarityColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => AppColors.primaryGreen,
    CatRarity.uncommon => AppColors.skyBlue,
    CatRarity.rare => AppColors.primaryPurple,
    CatRarity.epic => AppColors.warning,
    CatRarity.legendary => AppColors.warning,
    CatRarity.mythic => const Color(0xFFEF4444),
  };
}

_TradingCardStyle _cardStyleForRarity(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => const _TradingCardStyle(
      frameColor: AppColors.primaryGreen,
      starCount: 1,
      cardLabel: 'Carta Comune',
    ),
    CatRarity.uncommon => const _TradingCardStyle(
      frameColor: AppColors.skyBlue,
      starCount: 2,
      cardLabel: 'Carta Non comune',
    ),
    CatRarity.rare => const _TradingCardStyle(
      frameColor: AppColors.primaryPurple,
      starCount: 3,
      cardLabel: 'Carta Rara',
    ),
    CatRarity.epic => const _TradingCardStyle(
      frameColor: AppColors.warning,
      starCount: 4,
      cardLabel: 'Carta Epica',
    ),
    CatRarity.legendary || CatRarity.mythic => const _TradingCardStyle(
      frameColor: AppColors.warning,
      starCount: 5,
      cardLabel: 'Carta Leggendaria',
    ),
  };
}

String _rarityLabel(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => '🟢 Comune',
    CatRarity.uncommon => '🔵 Non comune',
    CatRarity.rare => '🟣 Raro',
    CatRarity.epic => '🟡 Epico',
    CatRarity.legendary => '🟡 Leggendario',
    CatRarity.mythic => '🟡 Leggendario',
  };
}

CatRarity _entryRarity(CatDexCollectionEntry entry) {
  return entry.discovery?.rarity ?? entry.species.baseRarity;
}

CatDisplayData? _displayDataForEntry(CatDexCollectionEntry entry) {
  final discovery = entry.discovery;
  if (discovery == null) {
    return null;
  }

  return const CatDisplayFormatter().fromDiscovery(
    discovery,
    fallbackName: entry.displayName,
  );
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return '-';
  }

  final localDate = date.toLocal();
  final day = localDate.day.toString().padLeft(2, '0');
  final month = localDate.month.toString().padLeft(2, '0');

  return '$day/$month/${localDate.year}';
}
