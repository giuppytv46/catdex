import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/rarity_debug_controls.dart';
import 'package:catdex/features/cards/presentation/widgets/catdex_card_preview.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/presentation/monetization_limit_dialog.dart';
import 'package:catdex/features/premium/presentation/usage_status_chip.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<CatRarity> _albumRarities = [
  CatRarity.common,
  CatRarity.uncommon,
  CatRarity.rare,
  CatRarity.epic,
  CatRarity.legendary,
];

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
  final Set<String> _generatingDiscoveryIds = {};
  final Set<String> _failedGenerationIds = {};
  final Map<String, String> _generationLabels = {};
  final Map<String, int> _cardImageRefreshVersions = {};
  final Map<String, CatRarity> _debugRarityOverrides = {};
  bool _regeneratingAll = false;
  bool _limitDialogVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(catDexControllerProvider);
    final cards = _cardEntries(state.entries);
    final usageSummary = ref.watch(monetizationStatusSummaryProvider);
    debugPrint('CATDEX_CARDS_ALBUM_MAIN_OPENED');
    debugPrint(
      'CATDEX_DEBUG_RARITY_UI_ENABLED $showRarityDebugControls',
    );
    for (final rarity in _albumRarities) {
      debugPrint(
        'CATDEX_CARDS_RARITY_GROUP_COUNT '
        '${_rarityValue(rarity)} ${_entriesForRarity(cards, rarity).length}',
      );
    }
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
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.backgroundGray,
            surfaceTintColor: Colors.transparent,
            foregroundColor: const Color(0xFF1E243B),
            title: Text(
              l10n.cardsTitle,
              style: const TextStyle(color: Color(0xFF1E243B)),
            ),
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
                const CatDexBannerAdWidget(
                  placementLog: 'CATDEX_AD_BANNER_PLACEMENT_TOP_CARDS_MAIN',
                ),
                const SizedBox(height: AppSpacing.lg),
                if (usageSummary.maybeWhen(
                      data: (summary) => summary,
                      orElse: () => null,
                    )
                    case final summary?)
                  UsageStatusChip(
                    summary: summary,
                    label: summary.isPremium
                        ? l10n.premiumCardsUnlimited
                        : l10n.cardGenerationsRemainingToday(
                            summary.remainingDailyCardGenerations,
                            summary.maxDailyCardGenerations,
                            summary.extraCardGenerationCredits,
                          ),
                    icon: Icons.style_rounded,
                  ),
                const SizedBox(height: AppSpacing.md),
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
                            ? '${l10n.regenerateCards}...'
                            : l10n.regenerateCards,
                      ),
                    ),
                  ],
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
              AppSpacing.lg,
            ),
            sliver: SliverList.separated(
              itemCount: _albumRarities.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final rarity = _albumRarities[index];
                final rarityEntries = _entriesForRarity(cards, rarity);
                return _RarityAlbumFolder(
                  rarity: rarity,
                  entries: rarityEntries,
                  onTap: () => _openRarityAlbum(
                    context,
                    rarity: rarity,
                    entries: rarityEntries,
                  ),
                );
              },
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              128,
            ),
            sliver: SliverToBoxAdapter(
              child: CatDexBannerAdWidget(
                placementLog: 'CATDEX_AD_BANNER_PLACEMENT_BOTTOM_CARDS_MAIN',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<CatDexCollectionEntry> _cardEntries(
    List<CatDexCollectionEntry> entries,
  ) {
    return entries
        .where((entry) {
          if (!entry.discovered || entry.discovery == null) {
            return false;
          }

          final discovery = entry.discovery!;
          if (!_canBecomeCard(discovery)) {
            return false;
          }

          return true;
        })
        .toList(growable: false)
      ..sort((a, b) {
        final generatedSort = _generatedSortValue(b).compareTo(
          _generatedSortValue(a),
        );
        if (generatedSort != 0) {
          return generatedSort;
        }
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

  List<CatDexCollectionEntry> _entriesForRarity(
    List<CatDexCollectionEntry> entries,
    CatRarity rarity,
  ) {
    return entries
        .where((entry) => entry.discovery?.rarity == rarity)
        .toList(growable: false);
  }

  void _openRarityAlbum(
    BuildContext context, {
    required CatRarity rarity,
    required List<CatDexCollectionEntry> entries,
  }) {
    debugPrint('CATDEX_CARDS_RARITY_ALBUM_OPENED ${_rarityValue(rarity)}');
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => RarityCardsAlbumPage(
            rarity: rarity,
            entries: entries,
            cacheBustVersions: _cardImageRefreshVersions,
            onOpenCard: (entry) => _openCard(context, entry),
            onGenerateCard: (entry) => _generateCard(
              entry,
              force: true,
              showSnackBar: false,
            ),
            onRegenerateCard: (entry) {
              final discovery = entry.discovery;
              return _generateCard(
                entry,
                force: true,
                showSnackBar: false,
                debugRarityOverride: discovery == null
                    ? null
                    : _debugRarityValue(_debugRarityOverrides[discovery.id]),
              );
            },
            onCanStartCardGeneration: _canStartCardGeneration,
            debugRarityOverrides: _debugRarityOverrides,
            onDebugRarityOverrideSelected: _selectDebugRarityOverride,
          ),
        ),
      ),
    );
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
          builder: (_) => CatDexTradingCardPage(
            entry: entry,
            cacheBustVersion: discovery == null
                ? null
                : _cardImageRefreshVersions[discovery.id],
            onGenerate: () => _generateCard(
              entry,
              force: true,
              showSnackBar: false,
            ),
            onRegenerate: () => _generateCard(
              entry,
              force: true,
              showSnackBar: false,
              debugRarityOverride: discovery == null
                  ? null
                  : _debugRarityValue(_debugRarityOverrides[discovery.id]),
            ),
          ),
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
            debugRarityOverride: _debugRarityValue(
              _debugRarityOverrides[discovery.id],
            ),
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
      SnackBar(
        content: Text(CatDexLocalizations.of(context).cardsUpdatedMessage),
      ),
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

  int _generatedSortValue(CatDexCollectionEntry entry) {
    final discovery = entry.discovery;
    if (discovery == null) {
      return 0;
    }

    return _hasFinalCardImage(discovery) ? 1 : 0;
  }

  Future<String?> _generateCard(
    CatDexCollectionEntry entry, {
    bool force = false,
    bool showSnackBar = true,
    String? debugRarityOverride,
    bool resumeAfterLimit = true,
  }) async {
    final l10n = CatDexLocalizations.of(context);
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

    final monetization = ref.read(monetizationServiceProvider);
    final allowed = await monetization.canGenerateCard();
    if (!allowed) {
      debugPrint('CATDEX_CARD_GENERATION_BLOCKED_LIMIT_OPEN_PAYWALL');
      await _showCardGenerationLimitDialog();
      if (resumeAfterLimit && await monetization.canGenerateCard()) {
        return _generateCard(
          entry,
          force: force,
          showSnackBar: showSnackBar,
          debugRarityOverride: debugRarityOverride,
          resumeAfterLimit: false,
        );
      }
      return null;
    }

    final oldDisplayedImageUrl = _networkCardImageSourceForDiscovery(discovery);
    setState(() {
      _generatingDiscoveryIds.add(discovery.id);
      _generationLabels[discovery.id] = l10n.generatingIllustration;
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
            debugRarityOverride: showRarityDebugControls
                ? debugRarityOverride
                : null,
            onStageChanged: (stage) {
              if (!mounted) {
                return;
              }
              setState(() {
                _generationLabels[discovery.id] =
                    stage == CardGenerationStage.illustration
                    ? l10n.generatingIllustration
                    : '${l10n.generateCard}...';
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
                : CatDexLocalizations.of(context).cardUpdatedMessage,
          ),
        ),
      );
    }
    if (result == null) {
      _failedGenerationIds.add(discovery.id);
    } else {
      final route = ModalRoute.of(context);
      if (!await monetization.consumeCardGeneration()) {
        debugPrint('CATDEX_CARD_GENERATION_BLOCKED_LIMIT_OPEN_PAYWALL');
        await _showCardGenerationLimitDialog();
        return null;
      }
      final evicted = _evictCardImage(oldDisplayedImageUrl);
      final version = DateTime.now().millisecondsSinceEpoch;
      setState(() {
        _cardImageRefreshVersions[discovery.id] = version;
      });
      debugPrint('CATDEX_CARD_IMAGE_CACHE_EVICTED $evicted');
      debugPrint('CATDEX_CARD_TILE_REBUILT ${discovery.id}');
      unawaited(
        ref
            .read(adMobServiceProvider)
            .recordSuccessfulCardGenerationAndMaybeShow(
              safeForAds:
                  route?.isCurrent == true &&
                  !_regeneratingAll &&
                  _generatingDiscoveryIds.isEmpty,
            ),
      );
    }

    return result;
  }

  void _selectDebugRarityOverride(
    CatDexCollectionEntry entry,
    CatRarity rarity,
  ) {
    if (!showRarityDebugControls) {
      return;
    }

    final discovery = entry.discovery;
    if (discovery == null) {
      return;
    }

    final selectedLabel = _debugRarityLabel(rarity);
    final selectedValue = _debugRarityValue(rarity);
    debugPrint('CATDEX_DEBUG_RARITY_OVERRIDE_ENABLED true');
    debugPrint('CATDEX_DEBUG_RARITY_OVERRIDE_SELECTED_LABEL $selectedLabel');
    debugPrint('CATDEX_DEBUG_RARITY_OVERRIDE_SELECTED_VALUE $selectedValue');
    setState(() {
      _debugRarityOverrides[discovery.id] = rarity;
    });
    unawaited(
      _generateCard(
        entry,
        force: true,
        debugRarityOverride: selectedValue,
      ),
    );
  }

  String? _debugRarityValue(CatRarity? rarity) {
    return switch (rarity) {
      CatRarity.common => 'common',
      CatRarity.uncommon => 'uncommon',
      CatRarity.rare => 'rare',
      CatRarity.epic => 'epic',
      CatRarity.legendary => 'legendary',
      CatRarity.mythic => 'legendary',
      null => null,
    };
  }

  String _debugRarityLabel(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => 'Comune',
      CatRarity.uncommon => 'Non comune',
      CatRarity.rare => 'Rara',
      CatRarity.epic => 'Epica',
      CatRarity.legendary => 'Leggendaria',
      CatRarity.mythic => 'Leggendaria',
    };
  }

  String? _networkCardImageSourceForDiscovery(CatDiscovery discovery) {
    final card = discovery.card;
    final candidates = [card?.cardImageUrl, card?.cardImagePath];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (isFinalGeneratedCardImageSource(value)) {
        final version = _cardImageRefreshVersions[discovery.id];
        return cacheBustedCardImageUrl(source: value!, version: version);
      }
    }

    return null;
  }

  bool _evictCardImage(String? url) {
    if (url == null || !isNetworkCardImageUrl(url)) {
      return false;
    }

    final baseUri = Uri.parse(url);
    final withoutCacheBust = baseUri.replace(
      queryParameters: Map<String, String>.from(baseUri.queryParameters)
        ..remove('v'),
    );
    final evictedDisplayed = imageCache.evict(NetworkImage(url));
    final evictedBase = imageCache.evict(
      NetworkImage(withoutCacheBust.toString()),
    );
    return evictedDisplayed || evictedBase;
  }

  Future<void> _showCardGenerationLimitDialog() async {
    if (!mounted || _limitDialogVisible) {
      return;
    }

    _limitDialogVisible = true;
    await showMonetizationLimitDialog(
      context,
      kind: MonetizationLimitKind.cardGeneration,
    );
    _limitDialogVisible = false;
  }

  Future<bool> _canStartCardGeneration() async {
    final allowed = await ref
        .read(monetizationServiceProvider)
        .canGenerateCard();
    if (!allowed) {
      debugPrint('CATDEX_CARD_GENERATION_BLOCKED_LIMIT_OPEN_PAYWALL');
      await _showCardGenerationLimitDialog();
      return ref.read(monetizationServiceProvider).canGenerateCard();
    }

    return true;
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
    return isFinalGeneratedCardImageSource(card?.cardImageUrl) ||
        isFinalGeneratedCardImageSource(card?.cardImagePath);
  }
}

class _CardsHeader extends StatelessWidget {
  const _CardsHeader({required this.entries});

  final List<CatDexCollectionEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
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
              l10n.cardsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.cardsSubtitle,
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
                  label: l10n.cardsFound,
                  value: '${cards.length}',
                ),
                _CardsStatChip(
                  label: l10n.localizeDisplayValue('common'),
                  value: '${_count(cards, CatRarity.common)}',
                ),
                _CardsStatChip(
                  label: l10n.localizeDisplayValue('uncommon'),
                  value: '${_count(cards, CatRarity.uncommon)}',
                ),
                _CardsStatChip(
                  label: l10n.localizeDisplayValue('rare'),
                  value: '${_count(cards, CatRarity.rare)}',
                ),
                _CardsStatChip(
                  label: l10n.localizeDisplayValue('epic'),
                  value: '${_count(cards, CatRarity.epic)}',
                ),
                _CardsStatChip(
                  label: l10n.localizeDisplayValue('legendary'),
                  value: '${_count(cards, CatRarity.legendary)}',
                ),
              ],
            ),
            if (cards.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.noGeneratedCards,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.emptyRarityAlbumHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.84),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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

class _RarityAlbumFolder extends StatelessWidget {
  const _RarityAlbumFolder({
    required this.rarity,
    required this.entries,
    required this.onTap,
  });

  final CatRarity rarity;
  final List<CatDexCollectionEntry> entries;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final generatedCount = entries.where(_entryHasFinalCardImage).length;
    final previewEntries = entries.take(3).toList(growable: false);
    final colors = _rarityColors(rarity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.localizeDisplayValue(_rarityLabel(rarity)),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.generatedCardsProgress(
                          generatedCount,
                          entries.length,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.white.withValues(alpha: 0.82),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AlbumCountBadge(value: '${entries.length}'),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            l10n.openAlbum,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _AlbumPreviewStack(
                  entries: previewEntries,
                  rarity: rarity,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlbumPreviewStack extends StatelessWidget {
  const _AlbumPreviewStack({
    required this.entries,
    required this.rarity,
  });

  final List<CatDexCollectionEntry> entries;
  final CatRarity rarity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 124,
      child: entries.isEmpty
          ? _AlbumEmptyPreview(rarity: rarity)
          : Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < entries.length; index++)
                  Positioned(
                    right: index * 18,
                    top: index * 12,
                    child: _AlbumPreviewThumbnail(
                      entry: entries[index],
                      rarity: rarity,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AlbumPreviewThumbnail extends StatelessWidget {
  const _AlbumPreviewThumbnail({
    required this.entry,
    required this.rarity,
  });

  final CatDexCollectionEntry entry;
  final CatRarity rarity;

  @override
  Widget build(BuildContext context) {
    final source = _entryCardImageSource(entry, cacheBustVersion: null);
    final placeholderColor = _rarityPreviewColor(rarity);
    final accentColor = _rarityAccentColor(rarity);
    return Transform.rotate(
      angle: source == null ? -0.05 : 0.04,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: source == null ? placeholderColor : AppColors.ink,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.54)),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.26),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 58,
            height: 82,
            child: source == null
                ? const Icon(
                    Icons.lock_rounded,
                    color: AppColors.white,
                    size: 22,
                  )
                : _AlbumPreviewImage(source: source),
          ),
        ),
      ),
    );
  }
}

class _AlbumPreviewImage extends StatelessWidget {
  const _AlbumPreviewImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(source, fit: BoxFit.cover);
    }

    return Image.file(File(source), fit: BoxFit.cover);
  }
}

class _AlbumEmptyPreview extends StatelessWidget {
  const _AlbumEmptyPreview({required this.rarity});

  final CatRarity rarity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _rarityPreviewColor(rarity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _rarityAccentColor(rarity).withValues(alpha: 0.42),
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.style_rounded,
          color: AppColors.white,
          size: 34,
        ),
      ),
    );
  }
}

class _AlbumCountBadge extends StatelessWidget {
  const _AlbumCountBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          value,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

typedef AlbumCardCallback =
    Future<String?> Function(CatDexCollectionEntry entry);
typedef AlbumOpenCardCallback = void Function(CatDexCollectionEntry entry);
typedef AlbumCanStartCardGenerationCallback = Future<bool> Function();

class RarityCardsAlbumPage extends ConsumerStatefulWidget {
  const RarityCardsAlbumPage({
    required this.rarity,
    required this.entries,
    required this.cacheBustVersions,
    required this.onOpenCard,
    required this.onGenerateCard,
    required this.onRegenerateCard,
    required this.onCanStartCardGeneration,
    required this.debugRarityOverrides,
    required this.onDebugRarityOverrideSelected,
    super.key,
  });

  final CatRarity rarity;
  final List<CatDexCollectionEntry> entries;
  final Map<String, int> cacheBustVersions;
  final AlbumOpenCardCallback onOpenCard;
  final AlbumCardCallback onGenerateCard;
  final AlbumCardCallback onRegenerateCard;
  final AlbumCanStartCardGenerationCallback onCanStartCardGeneration;
  final Map<String, CatRarity> debugRarityOverrides;
  final void Function(CatDexCollectionEntry entry, CatRarity rarity)
  onDebugRarityOverrideSelected;

  @override
  ConsumerState<RarityCardsAlbumPage> createState() =>
      _RarityCardsAlbumPageState();
}

class _RarityCardsAlbumPageState extends ConsumerState<RarityCardsAlbumPage> {
  final Set<String> _generatingIds = {};
  final Set<String> _failedIds = {};
  final Map<String, String> _generationLabels = {};
  final Map<String, String> _localImageSources = {};
  final Map<String, int> _localCacheBustVersions = {};

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final entries = widget.entries;
    final generatedCount = entries.where(_hasGeneratedCardInAlbum).length;
    final usageSummary = ref.watch(monetizationStatusSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundGray,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF1E243B),
        title: Text(
          '${l10n.albumTitle} '
          '${l10n.localizeDisplayValue(_rarityLabel(widget.rarity))}',
          style: const TextStyle(color: Color(0xFF1E243B)),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverList.list(
              children: [
                _AlbumHeader(
                  rarity: widget.rarity,
                  totalCount: entries.length,
                  generatedCount: generatedCount,
                ),
                const SizedBox(height: AppSpacing.md),
                const CatDexBannerAdWidget(
                  placementLog: 'CATDEX_AD_BANNER_PLACEMENT_TOP_RARITY_ALBUM',
                ),
                const SizedBox(height: AppSpacing.md),
                if (usageSummary.maybeWhen(
                      data: (summary) => summary,
                      orElse: () => null,
                    )
                    case final summary?)
                  UsageStatusChip(
                    summary: summary,
                    label: summary.isPremium
                        ? l10n.premiumCardsUnlimited
                        : l10n.cardGenerationsRemainingToday(
                            summary.remainingDailyCardGenerations,
                            summary.maxDailyCardGenerations,
                            summary.extraCardGenerationCredits,
                          ),
                    icon: Icons.style_rounded,
                  ),
              ],
            ),
          ),
          if (entries.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: _RarityAlbumEmptyState(),
            )
          else
            ..._rarityAlbumGridSlivers(entries, usageSummary),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              128,
            ),
            sliver: SliverToBoxAdapter(
              child: CatDexBannerAdWidget(
                placementLog: 'CATDEX_AD_BANNER_PLACEMENT_BOTTOM_RARITY_ALBUM',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _rarityAlbumGridSlivers(
    List<CatDexCollectionEntry> entries,
    AsyncValue<MonetizationStatusSummary> usageSummary,
  ) {
    final slivers = <Widget>[];
    for (var start = 0; start < entries.length; start += 6) {
      final end = start + 6 > entries.length ? entries.length : start + 6;
      final chunk = entries.sublist(start, end);
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 2.5 / 3.5,
            ),
            itemCount: chunk.length,
            itemBuilder: (context, index) {
              final l10n = CatDexLocalizations.of(context);
              final entry = chunk[index];
              final discovery = entry.discovery;
              final discoveryId = discovery?.id;
              final summary = usageSummary.maybeWhen(
                data: (summary) => summary,
                orElse: () => null,
              );
              return _CardsBinderTile(
                entry: entry,
                generating:
                    discoveryId != null && _generatingIds.contains(discoveryId),
                generatingLabel: discoveryId == null
                    ? null
                    : _generationLabels[discoveryId],
                hasGenerationError:
                    discoveryId != null && _failedIds.contains(discoveryId),
                cacheBustVersion: discoveryId == null
                    ? null
                    : _localCacheBustVersions[discoveryId] ??
                          widget.cacheBustVersions[discoveryId],
                imageSourceOverride: discoveryId == null
                    ? null
                    : _localImageSources[discoveryId],
                debugRarityOverride: discoveryId == null
                    ? null
                    : widget.debugRarityOverrides[discoveryId],
                onDebugRarityOverrideSelected:
                    discoveryId == null || !showRarityDebugControls
                    ? null
                    : (rarity) => widget.onDebugRarityOverrideSelected(
                        entry,
                        rarity,
                      ),
                generateLabel: _cardGenerateButtonLabel(summary),
                onGenerate: () => _runCardAction(
                  entry,
                  callback: widget.onGenerateCard,
                  loadingLabel: '${l10n.generateCard}...',
                ),
                onRegenerate: () => _runCardAction(
                  entry,
                  callback: widget.onRegenerateCard,
                  loadingLabel: '${l10n.regenerateCard}...',
                ),
                onTap: () => widget.onOpenCard(entry),
              );
            },
          ),
        ),
      );

      if (end < entries.length) {
        slivers.add(
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: CatDexBannerAdWidget(
                placementLog: 'CATDEX_AD_BANNER_PLACEMENT_INFEED_RARITY_ALBUM',
              ),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  Future<void> _runCardAction(
    CatDexCollectionEntry entry, {
    required AlbumCardCallback callback,
    required String loadingLabel,
  }) async {
    final l10n = CatDexLocalizations.of(context);
    final discoveryId = entry.discovery?.id;
    if (discoveryId == null || _generatingIds.contains(discoveryId)) {
      return;
    }

    if (!await widget.onCanStartCardGeneration()) {
      return;
    }

    setState(() {
      _failedIds.remove(discoveryId);
      _generatingIds.add(discoveryId);
      _generationLabels[discoveryId] = loadingLabel;
    });

    String? result;
    try {
      result = await callback(entry);
    } finally {
      if (mounted) {
        setState(() {
          _generatingIds.remove(discoveryId);
          _generationLabels.remove(discoveryId);
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (result == null || result.trim().isEmpty) {
      setState(() {
        _failedIds.add(discoveryId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cardGenerationError)),
      );
      return;
    }

    final version = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _localCacheBustVersions[discoveryId] = version;
      _localImageSources[discoveryId] = cacheBustedCardImageUrl(
        source: result!.trim(),
        version: version,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cardUpdatedMessage)),
    );
  }

  bool _hasGeneratedCardInAlbum(CatDexCollectionEntry entry) {
    final discoveryId = entry.discovery?.id;
    return _entryHasFinalCardImage(entry) ||
        (discoveryId != null && _localImageSources.containsKey(discoveryId));
  }
}

String? _cardGenerateButtonLabel(MonetizationStatusSummary? summary) {
  if (summary == null || summary.isPremium) {
    return null;
  }

  if (summary.remainingDailyCardGenerations == 0 &&
      summary.extraCardGenerationCredits > 0) {
    return 'Genera con credito extra';
  }

  return null;
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({
    required this.rarity,
    required this.totalCount,
    required this.generatedCount,
  });

  final CatRarity rarity;
  final int totalCount;
  final int generatedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final colors = _rarityColors(rarity);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.albumTitle} '
                    '${l10n.localizeDisplayValue(_rarityLabel(rarity))}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.generatedCardsProgress(generatedCount, totalCount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.84),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _AlbumCountBadge(value: '$totalCount'),
          ],
        ),
      ),
    );
  }
}

class _RarityAlbumEmptyState extends StatelessWidget {
  const _RarityAlbumEmptyState();

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
                  Icons.inventory_2_rounded,
                  size: 54,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  CatDexLocalizations.of(context).emptyRarityAlbum,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CatDexLocalizations.of(context).emptyRarityAlbumHint,
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

bool _entryHasFinalCardImage(CatDexCollectionEntry entry) {
  final card = entry.discovery?.card;
  return isFinalGeneratedCardImageSource(card?.cardImageUrl) ||
      isFinalGeneratedCardImageSource(card?.cardImagePath);
}

String? _entryCardImageSource(
  CatDexCollectionEntry entry, {
  required int? cacheBustVersion,
}) {
  final card = entry.discovery?.card;
  final candidates = [card?.cardImageUrl, card?.cardImagePath];
  for (final candidate in candidates) {
    final value = candidate?.trim();
    if (isFinalGeneratedCardImageSource(value)) {
      return cacheBustedCardImageUrl(
        source: value!,
        version: cacheBustVersion,
      );
    }
  }

  return null;
}

String _rarityValue(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => 'common',
    CatRarity.uncommon => 'uncommon',
    CatRarity.rare => 'rare',
    CatRarity.epic => 'epic',
    CatRarity.legendary => 'legendary',
    CatRarity.mythic => 'legendary',
  };
}

String _rarityLabel(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => 'Comune',
    CatRarity.uncommon => 'Non comune',
    CatRarity.rare => 'Rara',
    CatRarity.epic => 'Epica',
    CatRarity.legendary => 'Leggendaria',
    CatRarity.mythic => 'Leggendaria',
  };
}

List<Color> _rarityColors(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => const [Color(0xFF15803D), Color(0xFF22C55E)],
    CatRarity.uncommon => const [Color(0xFF0369A1), Color(0xFF38BDF8)],
    CatRarity.rare => const [Color(0xFF6D28D9), Color(0xFFA855F7)],
    CatRarity.epic => const [Color(0xFF0D2A66), Color(0xFF2563C9)],
    CatRarity.legendary => const [Color(0xFF92400E), Color(0xFFFACC15)],
    CatRarity.mythic => const [Color(0xFF92400E), Color(0xFFFACC15)],
  };
}

Color _rarityPreviewColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.epic => const Color(0xFF1B2F6B),
    _ => AppColors.ink.withValues(alpha: 0.34),
  };
}

Color _rarityAccentColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.epic => const Color(0xFF7EC8FF),
    _ => AppColors.white,
  };
}

class _CardsBinderTile extends StatelessWidget {
  const _CardsBinderTile({
    required this.entry,
    required this.generating,
    required this.generatingLabel,
    required this.hasGenerationError,
    required this.cacheBustVersion,
    required this.debugRarityOverride,
    required this.onDebugRarityOverrideSelected,
    required this.onGenerate,
    required this.onRegenerate,
    required this.onTap,
    this.imageSourceOverride,
    this.generateLabel,
  });

  final CatDexCollectionEntry entry;
  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final int? cacheBustVersion;
  final String? imageSourceOverride;
  final String? generateLabel;
  final CatRarity? debugRarityOverride;
  final ValueChanged<CatRarity>? onDebugRarityOverrideSelected;
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
        hasGenerationError: hasGenerationError,
        generateLabel: generateLabel,
        cacheBustVersion: cacheBustVersion,
        imageSourceOverride: imageSourceOverride,
        debugRarityOverride: debugRarityOverride,
        onDebugRarityOverrideSelected: onDebugRarityOverrideSelected,
        onGenerate: onGenerate,
        onRegenerate: onRegenerate,
        onTap: onTap,
      ),
    );
  }
}
