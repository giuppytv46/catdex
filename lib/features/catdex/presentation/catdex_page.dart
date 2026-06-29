import 'dart:async';
import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
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
          builder: (_) => CatDexTradingCardPage(entry: entry),
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
    final speciesLabel = _speciesLabel(entry);
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
    required this.style,
  });

  final CatDexCollectionEntry entry;
  final String name;
  final _TradingCardStyle style;

  @override
  Widget build(BuildContext context) {
    final rarity = _entryRarity(entry);
    final speciesLabel = _speciesLabel(entry);
    final hasPhoto = _hasUsablePhoto(entry.discoveredPhotoPath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: _CatPhotoFrame(
                  photoPath: entry.discoveredPhotoPath,
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
    required this.photoPath,
    required this.rarity,
    this.frameStyle,
  });

  final String? photoPath;
  final CatRarity rarity;
  final String? frameStyle;

  @override
  Widget build(BuildContext context) {
    final image = _imageProviderForPath(photoPath);

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
          child: image == null
              ? const _PhotoPlaceholder()
              : Image(
                  image: image,
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

class CatDexTradingCardPage extends StatelessWidget {
  const CatDexTradingCardPage({required this.entry, super.key});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    // TODO(CatDex): remove background from cat image
    // TODO(CatDex): generate cat cutout image
    // TODO(CatDex): place cat cutout over illustrated card background
    // TODO(CatDex): create night card background
    // TODO(CatDex): create seasonal event cards
    // TODO(CatDex): Halloween card frame
    // TODO(CatDex): Christmas card frame
    // TODO(CatDex): Summer card frame
    // TODO(CatDex): rainy weather card frame
    // TODO(CatDex): create animated legendary card frame
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('CatDex Card'),
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth.clamp(0, 430).toDouble();

                return SizedBox(
                  width: cardWidth,
                  child: AspectRatio(
                    aspectRatio: 2.5 / 3.5,
                    child: CatDexTradingCard(entry: entry, width: cardWidth),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CollectibleCatCardPage extends CatDexTradingCardPage {
  const CollectibleCatCardPage({required super.entry, super.key});
}

class CatDexTradingCard extends StatelessWidget {
  const CatDexTradingCard({
    required this.entry,
    required this.width,
    this.compact = false,
    super.key,
  });

  final CatDexCollectionEntry entry;
  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final discovery = entry.discovery;
    final rarity = _entryRarity(entry);
    final style = _cardStyleForRarity(rarity);
    final name = entry.displayName ?? _speciesLabel(entry);
    final backgroundStyle = discovery?.card?.cardBackgroundStyle ?? 'default';
    final isNight = backgroundStyle == 'night';
    final isEvent = discovery?.card?.isEventCard ?? false;
    final photoPaths = _CardPhotoPaths.fromDiscovery(discovery);

    return _CollectibleCardFrame(
      rarity: rarity,
      backgroundStyle: backgroundStyle,
      compact: compact,
      child: ConstrainedBox(
        constraints: compact
            ? const BoxConstraints.expand()
            : BoxConstraints(minHeight: width * 1.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TradingCardHeader(
              number: entry.collectionNumber,
              name: name,
              style: style,
              compact: compact,
            ),
            const SizedBox(height: AppSpacing.md),
            _CardImageWindow(
              photoPaths: photoPaths,
              rarity: rarity,
              frameStyle: entry.cardFrameStyle,
              hasPhoto: photoPaths.hasAnyUsablePhoto,
              compact: compact,
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
            _CardTypeLine(
              species: _speciesLabel(entry),
              hairLength: _formatOptional(discovery?.hairLength),
              isNight: isNight,
              isEvent: isEvent,
              compact: compact,
            ),
            if (!compact) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _CardRewardPill(
                      icon: Icons.bolt_rounded,
                      label: '+${discovery?.xpEarned ?? 0} XP',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _CardRewardPill(
                      icon: Icons.paid_rounded,
                      label: '+${discovery?.coinsEarned ?? 0} Monete',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _CardAbility(personality: discovery?.personality.name),
              const SizedBox(height: AppSpacing.md),
              _TraitSection(discovery: discovery),
              const SizedBox(height: AppSpacing.md),
              _LoreBox(story: _shortStory(discovery?.story)),
              const SizedBox(height: AppSpacing.lg),
              _CardFooter(
                cardId: discovery?.card?.cardId ?? 'card-${entry.species.id}',
                discoveredAt: discovery?.discoveredAt,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TradingCardHeader extends StatelessWidget {
  const _TradingCardHeader({
    required this.number,
    required this.name,
    required this.style,
    required this.compact,
  });

  final int number;
  final String name;
  final _TradingCardStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${number.toString().padLeft(4, '0')}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                _StarRow(count: style.starCount, size: compact ? 11 : 16),
              ],
            ),
            SizedBox(height: compact ? 2 : AppSpacing.xs),
            Text(
              name,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
              style:
                  (compact
                          ? Theme.of(context).textTheme.titleSmall
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
            ),
            SizedBox(height: compact ? 2 : AppSpacing.xs),
            Text(
              style.cardLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImageWindow extends StatelessWidget {
  const _CardImageWindow({
    required this.photoPaths,
    required this.rarity,
    required this.frameStyle,
    required this.hasPhoto,
    required this.compact,
  });

  final _CardPhotoPaths photoPaths;
  final CatRarity rarity;
  final String? frameStyle;
  final bool hasPhoto;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: compact ? 1.05 : 1.2,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.ink.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: _CardArtwork(
                  photoPaths: photoPaths,
                  rarity: rarity,
                  frameStyle: frameStyle,
                ),
              ),
            ),
          ),
          if (!hasPhoto && !compact)
            const Positioned(
              left: AppSpacing.md,
              bottom: AppSpacing.md,
              child: _LegacyDiscoveryBadge(),
            ),
        ],
      ),
    );
  }
}

class _CardArtwork extends StatelessWidget {
  const _CardArtwork({
    required this.photoPaths,
    required this.rarity,
    required this.frameStyle,
  });

  final _CardPhotoPaths photoPaths;
  final CatRarity rarity;
  final String? frameStyle;

  @override
  Widget build(BuildContext context) {
    final cutoutImage = _imageProviderForPath(photoPaths.cutoutImagePath);
    if (cutoutImage == null) {
      return _CatPhotoFrame(
        photoPath: photoPaths.displayPhotoPath ?? photoPaths.originalPhotoPath,
        rarity: rarity,
        frameStyle: frameStyle,
      );
    }

    // TODO(CatDex): remove background from cat photo
    // TODO(CatDex): generate cat cutout image
    // TODO(CatDex): use cutoutImagePath when available
    // TODO(CatDex): place cat silhouette/cutout over illustrated backgrounds
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _rarityColor(rarity), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _rarityColor(rarity).withValues(alpha: 0.85),
                    AppColors.skyBlue.withValues(alpha: 0.72),
                    AppColors.primaryPurple.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Image(
                image: cutoutImage,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => _CatPhotoFrame(
                  photoPath:
                      photoPaths.displayPhotoPath ??
                      photoPaths.originalPhotoPath,
                  rarity: rarity,
                  frameStyle: frameStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTypeLine extends StatelessWidget {
  const _CardTypeLine({
    required this.species,
    required this.hairLength,
    required this.isNight,
    required this.isEvent,
    required this.compact,
  });

  final String species;
  final String hairLength;
  final bool isNight;
  final bool isEvent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          '$species • $hairLength',
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (isNight) const _CardTag(label: 'Carta Notturna'),
        if (isEvent) const _CardTag(label: 'Evento speciale'),
      ],
    );
  }
}

class _CardTag extends StatelessWidget {
  const _CardTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 3,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _TraitSection extends StatelessWidget {
  const _TraitSection({required this.discovery});

  final CatDiscovery? discovery;

  @override
  Widget build(BuildContext context) {
    final speciesId = discovery?.speciesId;
    final coatColor = discovery?.coatColor;
    final coatPattern = discovery?.coatPattern;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            _TraitRow(
              label: 'Mantello',
              value: _coatColorLabel(
                speciesId: speciesId,
                coatColor: coatColor,
                coatPattern: coatPattern,
              ),
            ),
            _TraitRow(
              label: 'Pattern',
              value: _coatPatternLabel(
                speciesId: speciesId,
                coatColor: coatColor,
                coatPattern: coatPattern,
              ),
            ),
            _TraitRow(
              label: 'Occhi',
              value: _formatOptional(discovery?.eyeColor),
            ),
            _TraitRow(
              label: 'Età',
              value: _formatOptional(discovery?.estimatedAge),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraitRow extends StatelessWidget {
  const _TraitRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.cardId, required this.discoveredAt});

  final String cardId;
  final DateTime? discoveredAt;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            _CardMetaRow(label: 'ID carta', value: _shortCardId(cardId)),
            _CardMetaRow(
              label: 'Scoperto il',
              value: _formatDate(discoveredAt),
            ),
            Text(
              'CatDex Card',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.74),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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

class _CollectibleCardFrame extends StatelessWidget {
  const _CollectibleCardFrame({
    required this.rarity,
    required this.backgroundStyle,
    required this.child,
    required this.compact,
  });

  final CatRarity rarity;
  final String backgroundStyle;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final frameColor = _rarityColor(rarity);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _frameGradient(rarity),
        borderRadius: BorderRadius.circular(compact ? 24 : 38),
        boxShadow: [
          BoxShadow(
            color: frameColor.withValues(alpha: 0.34),
            blurRadius: compact ? 18 : 34,
            offset: Offset(0, compact ? 8 : 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 3 : 5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _cardBackground(backgroundStyle, rarity),
            borderRadius: BorderRadius.circular(compact ? 21 : 33),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }

  LinearGradient _frameGradient(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => const LinearGradient(
        colors: [AppColors.primaryGreen, Color(0xFF86EFAC)],
      ),
      CatRarity.uncommon => const LinearGradient(
        colors: [AppColors.skyBlue, Color(0xFF1D4ED8)],
      ),
      CatRarity.rare => const LinearGradient(
        colors: [AppColors.primaryPurple, Color(0xFFC084FC)],
      ),
      CatRarity.epic => const LinearGradient(
        colors: [AppColors.warning, AppColors.primaryPurple],
      ),
      CatRarity.legendary => const LinearGradient(
        colors: [Color(0xFFFFFBEB), AppColors.warning, Color(0xFFB45309)],
      ),
      CatRarity.mythic => const LinearGradient(
        colors: [Color(0xFFEF4444), AppColors.warning, AppColors.primaryPurple],
      ),
    };
  }

  LinearGradient _cardBackground(String style, CatRarity rarity) {
    if (style == 'night') {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF111827), Color(0xFF312E81), Color(0xFF581C87)],
      );
    }

    if (style == 'event') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.primaryGreen,
          _rarityColor(rarity),
          AppColors.primaryPurple,
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _rarityColor(rarity).withValues(alpha: 0.92),
        AppColors.skyBlue,
        AppColors.primaryPurple,
      ],
    );
  }
}

class _CardRewardPill extends StatelessWidget {
  const _CardRewardPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.warning, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardAbility extends StatelessWidget {
  const _CardAbility({required this.personality});

  final String? personality;

  @override
  Widget build(BuildContext context) {
    final title = _abilityTitle(personality);
    final description = _abilityDescription(personality);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.white),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Abilità',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoreBox extends StatelessWidget {
  const _LoreBox({required this.story});

  final String story;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storia',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              story,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardMetaRow extends StatelessWidget {
  const _CardMetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.white.withValues(alpha: 0.72),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
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

class _CardPhotoPaths {
  const _CardPhotoPaths({
    required this.cutoutImagePath,
    required this.displayPhotoPath,
    required this.originalPhotoPath,
  });

  factory _CardPhotoPaths.fromDiscovery(CatDiscovery? discovery) {
    return _CardPhotoPaths(
      cutoutImagePath: discovery?.card?.cutoutImagePath,
      displayPhotoPath: discovery?.displayPhotoPath,
      originalPhotoPath:
          discovery?.card?.originalPhotoPath ?? discovery?.originalPhotoPath,
    );
  }

  final String? cutoutImagePath;
  final String? displayPhotoPath;
  final String? originalPhotoPath;

  bool get hasAnyUsablePhoto {
    return _hasUsablePhoto(cutoutImagePath) ||
        _hasUsablePhoto(displayPhotoPath) ||
        _hasUsablePhoto(originalPhotoPath);
  }
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

String _speciesLabel(CatDexCollectionEntry entry) {
  final discovery = entry.discovery;
  return const CatAnalysisDisplayFormatter().speciesLabel(
    speciesId: discovery?.speciesId ?? entry.species.id,
    coatColor: discovery?.coatColor,
    coatPattern: discovery?.coatPattern,
  );
}

String _format(String value) {
  return const CatAnalysisDisplayFormatter().value(value);
}

String _formatOptional(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '-';
  }

  return _format(trimmed);
}

String _coatColorLabel({
  required String? speciesId,
  required String? coatColor,
  required String? coatPattern,
}) {
  return const CatAnalysisDisplayFormatter().coatColorLabel(
    speciesId: speciesId,
    coatColor: coatColor,
    coatPattern: coatPattern,
    fallback: '-',
  );
}

String _coatPatternLabel({
  required String? speciesId,
  required String? coatColor,
  required String? coatPattern,
}) {
  return const CatAnalysisDisplayFormatter().coatPatternLabel(
    speciesId: speciesId,
    coatColor: coatColor,
    coatPattern: coatPattern,
    fallback: '-',
  );
}

String _abilityTitle(String? personality) {
  return switch (personality?.trim().toLowerCase()) {
    'curious' => 'Curioso osservatore',
    'relaxed' => 'Animo tranquillo',
    'playful' => 'Spirito giocherellone',
    _ => 'Animo curioso',
  };
}

String _abilityDescription(String? personality) {
  return switch (personality?.trim().toLowerCase()) {
    'curious' => 'Ama osservare il mondo prima di avvicinarsi.',
    'relaxed' => 'Porta calma nella collezione CatDex.',
    'playful' => 'Trasforma ogni scoperta in un piccolo gioco.',
    _ => 'Aggiunge carattere alla tua collezione CatDex.',
  };
}

String _shortStory(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return 'Una nuova storia CatDex sta prendendo forma.';
  }

  if (trimmed.length <= 128) {
    return trimmed;
  }

  return '${trimmed.substring(0, 125).trimRight()}...';
}

String _shortCardId(String cardId) {
  if (cardId.length <= 14) {
    return cardId;
  }

  return '${cardId.substring(0, 6)}...${cardId.substring(cardId.length - 4)}';
}

bool _hasUsablePhoto(String? path) {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return false;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return true;
  }

  return File(trimmed).existsSync();
}

ImageProvider<Object>? _imageProviderForPath(String? path) {
  final trimmed = path?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  final file = File(trimmed);
  return file.existsSync() ? FileImage(file) : null;
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
