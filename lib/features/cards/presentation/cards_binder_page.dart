import 'dart:async';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/widgets/catdex_card_preview.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardsBinderPage extends ConsumerStatefulWidget {
  const CardsBinderPage({
    this.autoGenerateMissingCards = true,
    super.key,
  });

  final bool autoGenerateMissingCards;

  @override
  ConsumerState<CardsBinderPage> createState() => _CardsBinderPageState();
}

class _CardsBinderPageState extends ConsumerState<CardsBinderPage> {
  String _searchQuery = '';
  CatRarity? _selectedRarity;
  final Set<String> _generatingDiscoveryIds = {};
  final Set<String> _failedGenerationIds = {};
  final Map<String, String> _generationLabels = {};
  bool _regeneratingAll = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catDexControllerProvider);
    final cards = _filteredCards(state.entries);
    for (final entry in cards) {
      final discovery = entry.discovery;
      debugPrint('CATDEX_CARDS_DISCOVERY_ID ${discovery?.id ?? '-'}');
      debugPrint('CATDEX_CARDS_RENDER_MODE external_image');
    }
    _scheduleAutoGeneration(cards);

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
                  onAll: () => setState(() {
                    _selectedRarity = null;
                  }),
                  onRarity: (rarity) => setState(() {
                    _selectedRarity = _selectedRarity == rarity ? null : rarity;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: cards.isEmpty || _regeneratingAll
                          ? null
                          : () => _regenerateCards(cards),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _regeneratingAll
                            ? 'Creo illustrazioni e carte...'
                            : 'Rigenera carte',
                      ),
                    ),
                  ],
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
                    generating:
                        entry.discovery != null &&
                        _generatingDiscoveryIds.contains(entry.discovery!.id),
                    generatingLabel: entry.discovery == null
                        ? null
                        : _generationLabels[entry.discovery!.id],
                    onGenerate: () => _generateCard(entry),
                    onRegenerate: () {
                      final discovery = entry.discovery;
                      debugPrint(
                        'CATDEX_UI_REGENERATE_SINGLE_BUTTON_TAPPED '
                        '${discovery?.id ?? '-'}',
                      );
                      unawaited(_generateCard(entry, force: true));
                    },
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
          if (!_canBecomeCard(discovery)) {
            return false;
          }

          final matchesSearch =
              normalizedSearch.isEmpty ||
              (entry.displayName?.toLowerCase().contains(normalizedSearch) ??
                  false) ||
              discovery.speciesId
                  .replaceAll('_', ' ')
                  .contains(normalizedSearch);
          final matchesRarity =
              _selectedRarity == null || discovery.rarity == _selectedRarity;

          return matchesSearch && matchesRarity;
        })
        .toList(growable: false)
      ..sort((a, b) {
        final aDate = a.discovery?.discoveredAt;
        final bDate = b.discovery?.discoveredAt;
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return 1;
        }
        if (bDate == null) {
          return -1;
        }
        return bDate.compareTo(aDate);
      });
  }

  void _openCard(BuildContext context, CatDexCollectionEntry entry) {
    final discovery = entry.discovery;
    final displayData = discovery == null
        ? null
        : const CatDisplayFormatter().fromDiscovery(
            discovery,
            fallbackName: entry.displayName,
          );
    debugPrint('CATDEX_CARD_OPENED_ID ${discovery?.id ?? '-'}');
    debugPrint(
      'CATDEX_CARD_OPENED_NAME '
      '${displayData?.displayName ?? entry.displayName ?? '-'}',
    );
    debugPrint('CATDEX_CARD_OPENED_SPECIES_RAW ${discovery?.speciesId ?? '-'}');
    debugPrint(
      'CATDEX_CARD_OPENED_SPECIES_DISPLAY '
      '${displayData?.displaySpecies ?? entry.species.displayName}',
    );
    debugPrint('CATDEX_CARD_RENDER_MODE external_image');
    debugPrint(
      'CATDEX_CARD_OPENED_CREATED_AT '
      '${discovery?.discoveredAt.toIso8601String() ?? '-'}',
    );

    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexTradingCardPage(entry: entry),
        ),
      ),
    );
  }

  Future<void> _regenerateCards(List<CatDexCollectionEntry> cards) async {
    debugPrint('CATDEX_UI_REGENERATE_ALL_BUTTON_TAPPED');
    debugPrint('CATDEX_REGENERATE_ALL_STARTED count=${cards.length}');
    setState(() {
      _regeneratingAll = true;
    });

    try {
      for (final entry in cards) {
        final discovery = entry.discovery;
        if (discovery == null) {
          debugPrint('CATDEX_REGENERATE_ALL_ITEM_ERROR - missing_discovery');
          continue;
        }
        debugPrint('CATDEX_REGENERATE_ALL_ITEM_STARTED ${discovery.id}');
        try {
          final result = await _generateCard(
            entry,
            force: true,
            showSnackBar: false,
          );
          if (result == null) {
            debugPrint(
              'CATDEX_REGENERATE_ALL_ITEM_ERROR '
              '${discovery.id} generation_failed',
            );
            continue;
          }
          debugPrint('CATDEX_REGENERATE_ALL_ITEM_DONE ${discovery.id}');
        } on Object catch (error) {
          debugPrint(
            'CATDEX_REGENERATE_ALL_ITEM_ERROR ${discovery.id} $error',
          );
        }
      }
      debugPrint('CATDEX_REGENERATE_ALL_DONE');
    } finally {
      if (mounted) {
        setState(() {
          _regeneratingAll = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Carte aggiornate')),
    );
  }

  void _scheduleAutoGeneration(List<CatDexCollectionEntry> cards) {
    if (!widget.autoGenerateMissingCards) {
      return;
    }

    for (final entry in cards) {
      final discovery = entry.discovery;
      if (discovery == null ||
          _hasFinalCardImage(discovery) ||
          _generatingDiscoveryIds.contains(discovery.id) ||
          _failedGenerationIds.contains(discovery.id)) {
        continue;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_generateCard(entry));
        }
      });
    }
  }

  bool _canBecomeCard(CatDiscovery discovery) {
    return discovery.id.trim().isNotEmpty;
  }

  Future<String?> _generateCard(
    CatDexCollectionEntry entry, {
    bool force = false,
    bool showSnackBar = true,
  }) async {
    final discovery = entry.discovery;
    if (discovery == null) {
      return null;
    }
    if (force) {
      _failedGenerationIds.remove(discovery.id);
    }
    if (!force && _hasFinalCardImage(discovery)) {
      return null;
    }
    if (!force && _generatingDiscoveryIds.contains(discovery.id)) {
      return null;
    }

    setState(() {
      _generatingDiscoveryIds.add(discovery.id);
      _generationLabels[discovery.id] = 'Creo illustrazione...';
    });

    String? result;
    RemoteCardGenerationFailureReason? failureReason;
    try {
      final display = const CatDisplayFormatter().fromDiscovery(
        discovery,
        fallbackName: entry.displayName,
      );
      final generationResult = await ref
          .read(cardGenerationPipelineProvider)
          .regenerateCardWithAiIllustration(
            discovery: discovery,
            displayData: display,
            collectionNumber: entry.collectionNumber,
            onStageChanged: (stage) {
              if (!mounted) {
                return;
              }
              setState(() {
                _generationLabels[discovery.id] =
                    stage == CardGenerationStage.illustration
                    ? 'Creo illustrazione...'
                    : 'Genero carta...';
              });
            },
          );
      result = generationResult.generatedCardPathOrUrl;
      failureReason = generationResult.failureReason;
    } finally {
      if (mounted) {
        setState(() {
          _generatingDiscoveryIds.remove(discovery.id);
          _generationLabels.remove(discovery.id);
        });
      }
    }

    if (!mounted) {
      return result;
    }

    if (showSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? _generationFailureMessage(failureReason)
                : 'Carta aggiornata',
          ),
        ),
      );
    }
    if (result == null) {
      _failedGenerationIds.add(discovery.id);
    }

    return result;
  }

  String _generationFailureMessage(
    RemoteCardGenerationFailureReason? failureReason,
  ) {
    return switch (failureReason) {
      RemoteCardGenerationFailureReason.missingEndpoint =>
        'Generatore carte non configurato',
      RemoteCardGenerationFailureReason.invalidPhotoUrl =>
        'Foto gatto non accessibile',
      RemoteCardGenerationFailureReason.remoteApiFailure =>
        'Errore generazione carta',
      null => 'Errore generazione carta',
    };
  }

  bool _hasFinalCardImage(CatDiscovery discovery) {
    final card = discovery.card;
    return _notBlank(card?.cardImageUrl) || _notBlank(card?.cardImagePath);
  }

  bool _notBlank(String? value) {
    return value != null && value.trim().isNotEmpty;
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
                  label: 'Comuni',
                  value: '${_count(cards, CatRarity.common)}',
                ),
                _CardsStatChip(
                  label: 'Non comuni',
                  value: '${_count(cards, CatRarity.uncommon)}',
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
    required this.onAll,
    required this.onRarity,
  });

  final CatRarity? selectedRarity;
  final VoidCallback onAll;
  final ValueChanged<CatRarity> onRarity;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _CardsFilterChip(
            label: 'Tutte',
            selected: selectedRarity == null,
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
  const _CardsBinderTile({
    required this.entry,
    required this.generating,
    required this.generatingLabel,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onTap,
  });

  final CatDexCollectionEntry entry;
  final bool generating;
  final String? generatingLabel;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: entry.displayName ?? 'Carta CatDex',
      child: CatDexMiniCardPreview(
        entry: entry,
        generating: generating,
        generatingLabel: generatingLabel,
        onGenerate: onGenerate,
        onRegenerate: onRegenerate,
        onTap: onTap,
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
