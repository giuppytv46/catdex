import 'dart:async';

import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/catdex/presentation/catdex_page.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardsBinderPage extends ConsumerStatefulWidget {
  const CardsBinderPage({super.key});

  @override
  ConsumerState<CardsBinderPage> createState() => _CardsBinderPageState();
}

class _CardsBinderPageState extends ConsumerState<CardsBinderPage> {
  String _searchQuery = '';
  CatRarity? _selectedRarity;
  bool _eventOnly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catDexControllerProvider);
    final cards = _filteredCards(state.entries);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundGray,
            surfaceTintColor: Colors.transparent,
            title: Text('Carte'),
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
                _CardsHeader(entries: state.entries),
                const SizedBox(height: AppSpacing.lg),
                _CardsSearchBar(
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: AppSpacing.md),
                _CardsFilters(
                  selectedRarity: _selectedRarity,
                  eventOnly: _eventOnly,
                  onAll: () => setState(() {
                    _selectedRarity = null;
                    _eventOnly = false;
                  }),
                  onRarity: (rarity) => setState(() {
                    _selectedRarity = _selectedRarity == rarity ? null : rarity;
                    _eventOnly = false;
                  }),
                  onEvent: () => setState(() {
                    _selectedRarity = null;
                    _eventOnly = !_eventOnly;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (cards.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _CardsEmptyState(),
            )
          else
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
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 2.5 / 3.5,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final entry = cards[index];
                  return _CardsBinderTile(
                    entry: entry,
                    onTap: () => _openCard(context, entry),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  List<CatDexCollectionEntry> _filteredCards(
    List<CatDexCollectionEntry> entries,
  ) {
    final normalizedSearch = _searchQuery.trim().toLowerCase();
    return entries
        .where((entry) {
          if (!entry.discovered || entry.discovery == null) {
            return false;
          }

          final discovery = entry.discovery!;
          final matchesSearch =
              normalizedSearch.isEmpty ||
              (entry.displayName?.toLowerCase().contains(normalizedSearch) ??
                  false) ||
              discovery.speciesId
                  .replaceAll('_', ' ')
                  .contains(normalizedSearch);
          final matchesRarity =
              _selectedRarity == null || discovery.rarity == _selectedRarity;
          final matchesEvent =
              !_eventOnly || (discovery.card?.isEventCard ?? false);

          return matchesSearch && matchesRarity && matchesEvent;
        })
        .toList(growable: false);
  }

  void _openCard(BuildContext context, CatDexCollectionEntry entry) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexTradingCardPage(entry: entry),
        ),
      ),
    );
  }
}

class _CardsHeader extends StatelessWidget {
  const _CardsHeader({required this.entries});

  final List<CatDexCollectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cards = entries.where((entry) => entry.discovered).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple,
            AppColors.skyBlue,
            AppColors.primaryGreen,
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
            Text(
              'Carte',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Il tuo mazzo di gatti scoperti',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.86),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _CardsStatChip(
                  label: 'Carte trovate',
                  value: '${cards.length}',
                ),
                _CardsStatChip(
                  label: 'Comune',
                  value: '${_count(cards, CatRarity.common)}',
                ),
                _CardsStatChip(
                  label: 'Rare',
                  value: '${_count(cards, CatRarity.rare)}',
                ),
                _CardsStatChip(
                  label: 'Epiche',
                  value: '${_count(cards, CatRarity.epic)}',
                ),
                _CardsStatChip(
                  label: 'Leggendarie',
                  value: '${_count(cards, CatRarity.legendary)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _count(List<CatDexCollectionEntry> cards, CatRarity rarity) {
    return cards.where((entry) => entry.discovery?.rarity == rarity).length;
  }
}

class _CardsStatChip extends StatelessWidget {
  const _CardsStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          '$label: $value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CardsSearchBar extends StatelessWidget {
  const _CardsSearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('cards_search_field'),
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded),
        hintText: 'Cerca carta o gatto',
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

class _CardsFilters extends StatelessWidget {
  const _CardsFilters({
    required this.selectedRarity,
    required this.eventOnly,
    required this.onAll,
    required this.onRarity,
    required this.onEvent,
  });

  final CatRarity? selectedRarity;
  final bool eventOnly;
  final VoidCallback onAll;
  final ValueChanged<CatRarity> onRarity;
  final VoidCallback onEvent;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CardsFilterChip(
            label: 'Tutte',
            selected: selectedRarity == null && !eventOnly,
            onTap: onAll,
          ),
          _CardsFilterChip(
            label: 'Comune',
            selected: selectedRarity == CatRarity.common,
            onTap: () => onRarity(CatRarity.common),
          ),
          _CardsFilterChip(
            label: 'Non comuni',
            selected: selectedRarity == CatRarity.uncommon,
            onTap: () => onRarity(CatRarity.uncommon),
          ),
          _CardsFilterChip(
            label: 'Rare',
            selected: selectedRarity == CatRarity.rare,
            onTap: () => onRarity(CatRarity.rare),
          ),
          _CardsFilterChip(
            label: 'Epiche',
            selected: selectedRarity == CatRarity.epic,
            onTap: () => onRarity(CatRarity.epic),
          ),
          _CardsFilterChip(
            label: 'Leggendarie',
            selected: selectedRarity == CatRarity.legendary,
            onTap: () => onRarity(CatRarity.legendary),
          ),
          _CardsFilterChip(
            label: 'Evento',
            selected: eventOnly,
            onTap: onEvent,
          ),
        ],
      ),
    );
  }
}

class _CardsFilterChip extends StatelessWidget {
  const _CardsFilterChip({
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

class _CardsBinderTile extends StatelessWidget {
  const _CardsBinderTile({required this.entry, required this.onTap});

  final CatDexCollectionEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: entry.displayName ?? 'Carta CatDex',
      child: GestureDetector(
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return CatDexTradingCard(
              entry: entry,
              width: constraints.maxWidth,
              compact: true,
            );
          },
        ),
      ),
    );
  }
}

class _CardsEmptyState extends StatelessWidget {
  const _CardsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.style_rounded,
                  size: 54,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nessuna carta ancora',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Scopri un gatto per generare la tua prima carta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.68),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
