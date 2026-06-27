import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
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
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(catDexControllerProvider);
    final controller = ref.read(catDexControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.catDexTitle)),
      body: CustomScrollView(
        key: const Key('catdex_collection_scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverList.list(
              children: [
                _CollectionProgressHeader(state: state),
                const SizedBox(height: AppSpacing.lg),
                _SearchBar(onChanged: controller.updateSearchQuery),
                const SizedBox(height: AppSpacing.lg),
                _DiscoveryFilterChips(
                  selectedFilter: state.discoveryFilter,
                  onSelected: controller.setDiscoveryFilter,
                ),
                const SizedBox(height: AppSpacing.md),
                _RarityFilterChips(
                  selectedRarity: state.selectedRarity,
                  onClear: controller.clearRarityFilter,
                  onSelected: controller.toggleRarity,
                ),
                const SizedBox(height: AppSpacing.md),
                _VariantFilterChips(
                  variants: state.availableVariants,
                  selectedVariantId: state.selectedVariantId,
                  onClear: controller.clearVariantFilter,
                  onSelected: controller.toggleVariant,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              120,
            ),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisExtent: 264,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
              ),
              itemCount: state.visibleEntries.length,
              itemBuilder: (context, index) {
                final entry = state.visibleEntries[index];
                return _CatCollectionCard(
                  key: ValueKey('catdex_card_${entry.species.id}'),
                  entry: entry,
                  onTap: () {
                    unawaited(
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CatDexDetailPage(entry: entry),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CollectionProgressHeader extends StatelessWidget {
  const _CollectionProgressHeader({required this.state});

  final CatDexCollectionState state;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final percent = (state.completionPercentage * 100).round();

    return DecoratedBox(
      decoration: _collectionDecoration(
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
            Text(
              l10n.collectionProgressTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: state.completionPercentage,
                backgroundColor: AppColors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _ProgressPill(
                  label: l10n.totalEntriesLabel,
                  value: '${state.totalCount}',
                ),
                _ProgressPill(
                  label: l10n.discoveredLabel,
                  value: '${state.discoveredCount}',
                ),
                _ProgressPill(label: l10n.completionLabel, value: '$percent%'),
              ],
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
    final l10n = CatDexLocalizations.of(context);

    return TextField(
      key: const Key('catdex_search_field'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: l10n.searchCatDexLabel,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _DiscoveryFilterChips extends StatelessWidget {
  const _DiscoveryFilterChips({
    required this.selectedFilter,
    required this.onSelected,
  });

  final CatDexDiscoveryFilter selectedFilter;
  final ValueChanged<CatDexDiscoveryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          key: const Key('catdex_discovery_filter_all'),
          label: Text(l10n.allFilterLabel),
          selected: selectedFilter == CatDexDiscoveryFilter.all,
          onSelected: (_) => onSelected(CatDexDiscoveryFilter.all),
        ),
        ChoiceChip(
          key: const Key('catdex_discovery_filter_discovered'),
          label: Text(l10n.discoveredLabel),
          selected: selectedFilter == CatDexDiscoveryFilter.discovered,
          onSelected: (_) => onSelected(CatDexDiscoveryFilter.discovered),
        ),
        ChoiceChip(
          key: const Key('catdex_discovery_filter_undiscovered'),
          label: Text(l10n.undiscoveredLabel),
          selected: selectedFilter == CatDexDiscoveryFilter.undiscovered,
          onSelected: (_) => onSelected(CatDexDiscoveryFilter.undiscovered),
        ),
      ],
    );
  }
}

class _RarityFilterChips extends StatelessWidget {
  const _RarityFilterChips({
    required this.selectedRarity,
    required this.onClear,
    required this.onSelected,
  });

  final CatRarity? selectedRarity;
  final VoidCallback onClear;
  final ValueChanged<CatRarity> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterTitle(title: l10n.rarityFiltersTitle),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              key: const Key('catdex_rarity_all'),
              label: Text(l10n.allFilterLabel),
              selected: selectedRarity == null,
              onSelected: (_) => onClear(),
            ),
            for (final rarity in CatRarity.values)
              ChoiceChip(
                key: ValueKey('catdex_rarity_${rarity.name}'),
                label: Text(l10n.rarityName(rarity.name)),
                selected: selectedRarity == rarity,
                onSelected: (_) => onSelected(rarity),
              ),
          ],
        ),
      ],
    );
  }
}

class _VariantFilterChips extends StatelessWidget {
  const _VariantFilterChips({
    required this.variants,
    required this.selectedVariantId,
    required this.onClear,
    required this.onSelected,
  });

  final List<CatDexVariantFilter> variants;
  final String? selectedVariantId;
  final VoidCallback onClear;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterTitle(title: l10n.variantFiltersTitle),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  key: const Key('catdex_variant_all'),
                  label: Text(l10n.allFilterLabel),
                  selected: selectedVariantId == null,
                  onSelected: (_) => onClear(),
                ),
              ),
              for (final variant in variants)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    key: ValueKey('catdex_variant_${variant.id}'),
                    label: Text(variant.name),
                    selected: selectedVariantId == variant.id,
                    onSelected: (_) => onSelected(variant.id),
                  ),
                ),
            ],
          ),
        ),
      ],
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
    final l10n = CatDexLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final discovered = entry.discovered;
    final foreground = discovered ? AppColors.ink : AppColors.white;

    return Semantics(
      button: true,
      label: entry.species.displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: onTap,
          child: Ink(
            decoration: _collectionDecoration(
              gradient: discovered
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.white,
                        _rarityColor(entry.species.baseRarity).withValues(
                          alpha: 0.2,
                        ),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4B5563), AppColors.darkBackground],
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    child: _CatVisual(
                      discovered: discovered,
                      rarity: entry.species.baseRarity,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    discovered
                        ? entry.species.displayName
                        : l10n.notDiscoveredYetLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.rarityName(entry.species.baseRarity.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: discovered ? AppColors.primaryPurple : foreground,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${l10n.originLabel}: ${entry.species.originCountry}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: foreground),
                  ),
                  const Spacer(),
                  _CardFooter(entry: entry, foreground: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatVisual extends StatelessWidget {
  const _CatVisual({required this.discovered, required this.rarity});

  final bool discovered;
  final CatRarity rarity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: discovered
            ? _rarityColor(rarity).withValues(alpha: 0.9)
            : AppColors.white.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(
        discovered ? Icons.pets_rounded : Icons.lock_rounded,
        color: AppColors.white,
        size: 38,
      ),
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({required this.entry, required this.foreground});

  final CatDexCollectionEntry entry;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            entry.variantName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '#${entry.collectionNumber.toString().padLeft(3, '0')}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class CatDexDetailPage extends StatelessWidget {
  const CatDexDetailPage({required this.entry, super.key});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final discovered = entry.discovered;

    return Scaffold(
      appBar: AppBar(
        title: Text(discovered ? entry.species.displayName : l10n.catDexTitle),
      ),
      body: ListView(
        key: const Key('catdex_detail_page'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          DecoratedBox(
            decoration: _collectionDecoration(
              gradient: discovered
                  ? const LinearGradient(
                      colors: [AppColors.skyBlue, AppColors.primaryPurple],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF4B5563), AppColors.darkBackground],
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _CatVisual(
                    discovered: discovered,
                    rarity: entry.species.baseRarity,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    discovered
                        ? entry.species.displayName
                        : l10n.notDiscoveredYetLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (discovered)
            _DiscoveredDetail(entry: entry)
          else
            _LockedDetail(entry: entry),
        ],
      ),
    );
  }
}

class _DiscoveredDetail extends StatelessWidget {
  const _DiscoveredDetail({required this.entry});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailRow(
          label: l10n.rarityFiltersTitle,
          value: l10n.rarityName(entry.species.baseRarity.name),
        ),
        _DetailRow(label: l10n.originLabel, value: entry.species.originCountry),
        _DetailRow(label: l10n.variantFiltersTitle, value: entry.variantName),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.catDexDetailDescription(
            speciesName: entry.species.displayName,
            origin: entry.species.originCountry,
          ),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        _DetailRow(label: l10n.traitsLabel, value: l10n.placeholderTraitsLabel),
      ],
    );
  }
}

class _LockedDetail extends StatelessWidget {
  const _LockedDetail({required this.entry});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notDiscoveredYetLabel,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: AppSpacing.md),
        _DetailRow(
          label: l10n.rarityFiltersTitle,
          value: l10n.rarityName(entry.species.baseRarity.name),
        ),
        _DetailRow(label: l10n.originLabel, value: entry.species.originCountry),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _FilterTitle extends StatelessWidget {
  const _FilterTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  const _ProgressPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          '$label $value',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _collectionDecoration({required Gradient gradient}) {
  return BoxDecoration(
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

Color _rarityColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => AppColors.primaryGreen,
    CatRarity.uncommon => AppColors.skyBlue,
    CatRarity.rare => AppColors.primaryPurple,
    CatRarity.epic => const Color(0xFFEC4899),
    CatRarity.legendary => AppColors.warning,
    CatRarity.mythic => const Color(0xFFEF4444),
  };
}
