import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/application/card_generation_pipeline.dart';
import 'package:catdex/features/cards/application/card_generation_state_controller.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/application/remote_card_generation_service.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/rarity_debug_controls.dart';
import 'package:catdex/features/cards/presentation/widgets/catdex_card_preview.dart';
import 'package:catdex/features/catdex/application/catdex_controller.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/features/events/application/event_providers.dart';
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

const String _cardGenerationPendingLabel = 'Creazione della carta in corso…';
const String _cardGenerationLongWaitLabel =
    'La creazione sta richiedendo più tempo del previsto, '
    'ma è ancora in corso.';
const Duration _cardGenerationLongWaitThreshold = Duration(seconds: 20);

class CardsBinderPage extends ConsumerStatefulWidget {
  const CardsBinderPage({
    this.autoGenerateMissingCards = false,
    super.key,
  });

  final bool autoGenerateMissingCards;

  @override
  ConsumerState<CardsBinderPage> createState() => _CardsBinderPageState();
}

class _CardsBinderPageState extends ConsumerState<CardsBinderPage> {
  final Map<String, Future<String?>> _inFlightGenerationFutures = {};
  final Map<String, int> _cardImageRefreshVersions = {};
  final Map<String, CatRarity> _debugRarityOverrides = {};
  bool _limitDialogVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoGenerateMissingCards) {
      debugPrint(
        'CATDEX_CARD_GENERATION_AUTO_START_BLOCKED '
        'reason=explicit_user_action_required',
      );
    }
  }

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
  }) {
    debugPrint('CATDEX_CARDS_RARITY_ALBUM_OPENED ${_rarityValue(rarity)}');
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => RarityCardsAlbumPage(
            rarity: rarity,
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
    if (discovery == null) {
      return;
    }
    final displayData = const CatDisplayFormatter().fromDiscovery(
      discovery,
      fallbackName: entry.displayName,
    );
    debugPrint('CATDEX_CARD_OPENED_ID ${discovery.id}');
    debugPrint(
      'CATDEX_CARD_OPENED_NAME '
      '${displayData.displayName}',
    );
    debugPrint('CATDEX_CARD_OPENED_SPECIES_RAW ${discovery.speciesId}');
    debugPrint(
      'CATDEX_CARD_OPENED_SPECIES_DISPLAY '
      '${displayData.displaySpecies}',
    );
    debugPrint('CATDEX_CARD_RENDER_MODE external_image');
    debugPrint(
      'CATDEX_CARD_OPENED_CREATED_AT '
      '${discovery.discoveredAt.toIso8601String()}',
    );

    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexTradingCardPage(
            discoveryId: discovery.id,
            cardId: entry.cardRecord?.cardId,
            collectionNumber: entry.collectionNumber,
            cacheBustVersion: _cardImageRefreshVersions[discovery.id],
            onGenerate: () {
              final latestEntry = _currentEntry(discovery.id);
              if (latestEntry == null) {
                return Future<String?>.value();
              }
              return _generateCard(
                latestEntry,
                force: true,
                showSnackBar: false,
              );
            },
            onRegenerate: () {
              final latestEntry = _currentEntry(discovery.id);
              if (latestEntry == null) {
                return Future<String?>.value();
              }
              return _generateCard(
                latestEntry,
                force: true,
                showSnackBar: false,
                debugRarityOverride: _debugRarityValue(
                  _debugRarityOverrides[discovery.id],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  CatDexCollectionEntry? _currentEntry(String discoveryId) {
    for (final entry in ref.read(catDexControllerProvider).entries) {
      if (entry.discovery?.id == discoveryId) {
        return entry;
      }
    }
    return null;
  }

  bool _canBecomeCard(CatDiscovery discovery) {
    return discovery.id.trim().isNotEmpty;
  }

  int _generatedSortValue(CatDexCollectionEntry entry) {
    return _entryHasFinalCardImage(entry) ? 1 : 0;
  }

  Future<String?> _generateCard(
    CatDexCollectionEntry entry, {
    bool force = false,
    bool showSnackBar = true,
    String? debugRarityOverride,
    bool resumeAfterLimit = true,
  }) {
    final discovery = entry.discovery;
    if (discovery == null) {
      return Future<String?>.value();
    }

    final existingFuture = _inFlightGenerationFutures[discovery.id];
    if (existingFuture != null) {
      debugPrint('CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED ${discovery.id}');
      debugPrint('CATDEX_CARD_GENERATION_BUTTON_DISABLED ${discovery.id}');
      return existingFuture;
    }

    ref
        .read(cardGenerationStateProvider.notifier)
        .ensureGenerating(
          discovery.id,
          label: _cardGenerationPendingLabel,
        );

    debugPrint(
      'CATDEX_CARD_GENERATION_REQUEST_DISCOVERY_ID ${discovery.id}',
    );

    final future = _performCardGeneration(
      entry,
      force: force,
      showSnackBar: showSnackBar,
      debugRarityOverride: debugRarityOverride,
      resumeAfterLimit: resumeAfterLimit,
    );
    _inFlightGenerationFutures[discovery.id] = future;
    unawaited(
      future.whenComplete(() {
        if (identical(_inFlightGenerationFutures[discovery.id], future)) {
          final removedFuture = _inFlightGenerationFutures.remove(discovery.id);
          if (removedFuture != null) {
            unawaited(removedFuture);
          }
        }
      }),
    );
    return future;
  }

  Future<String?> _performCardGeneration(
    CatDexCollectionEntry entry, {
    required bool force,
    required bool showSnackBar,
    required String? debugRarityOverride,
    required bool resumeAfterLimit,
  }) async {
    final l10n = CatDexLocalizations.of(context);
    final discovery = entry.discovery;
    if (discovery == null) {
      return null;
    }

    if (!force && _entryHasFinalCardImage(entry)) {
      ref.read(cardGenerationStateProvider.notifier).reset(discovery.id);
      return null;
    }

    final monetization = ref.read(monetizationServiceProvider);
    final oldDisplayedImageUrl = _entryCardImageSource(
      entry,
      cacheBustVersion: _cardImageRefreshVersions[discovery.id],
    );
    ref
        .read(cardGenerationStateProvider.notifier)
        .ensureGenerating(discovery.id, label: l10n.generatingIllustration);

    final eventGeneration =
        ref
            .read(eventRuntimeConfigurationProvider)
            .activeEvent(DateTime.now().toUtc()) !=
        null;
    final reservation = eventGeneration
        ? CardGenerationCreditReservationResult.reserved
        : await monetization.reserveCardGenerationCredit(discovery.id);
    if (reservation != CardGenerationCreditReservationResult.reserved) {
      ref.read(cardGenerationStateProvider.notifier).reset(discovery.id);
      if (reservation == CardGenerationCreditReservationResult.duplicate) {
        debugPrint(
          'CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED ${discovery.id}',
        );
        return null;
      }

      debugPrint('CATDEX_CARD_GENERATION_BLOCKED_LIMIT_OPEN_PAYWALL');
      await _showCardGenerationLimitDialog();
      if (resumeAfterLimit && await monetization.canGenerateCard()) {
        return _performCardGeneration(
          entry,
          force: force,
          showSnackBar: showSnackBar,
          debugRarityOverride: debugRarityOverride,
          resumeAfterLimit: false,
        );
      }
      return null;
    }

    String? result;
    RemoteCardGenerationFailureReason? failureReason;
    var reservationOpen = !eventGeneration;
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
              ref.read(cardGenerationStateProvider.notifier).updateLabel(
                discovery.id,
                switch (stage) {
                  CardGenerationStage.illustration =>
                    l10n.generatingIllustration,
                  CardGenerationStage.recovery => _cardGenerationPendingLabel,
                  CardGenerationStage.render => '${l10n.generateCard}...',
                },
              );
            },
          );
      result = generationResult.generatedCardPathOrUrl;
      failureReason = generationResult.failureReason;
      if (result == null) {
        debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_FAILURE ${discovery.id}');
        if (!eventGeneration) {
          monetization.releaseCardGenerationCredit(discovery.id);
        }
        reservationOpen = false;
      } else {
        if (!eventGeneration) {
          await monetization.commitCardGenerationCredit(discovery.id);
        }
        debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_SUCCESS ${discovery.id}');
        reservationOpen = false;
      }
    } on Object catch (error) {
      debugPrint('CATDEX_CARD_GENERATION_FAILED $error');
      debugPrint('CATDEX_CARD_UI_SERVICE_COMPLETED_FAILURE ${discovery.id}');
      failureReason = RemoteCardGenerationFailureReason.remoteApiFailure;
      result = null;
    } finally {
      if (reservationOpen) {
        monetization.releaseCardGenerationCredit(discovery.id);
      }
    }

    final sharedGenerationState = ref.read(
      cardGenerationStateProvider.notifier,
    );
    if (result == null) {
      sharedGenerationState.fail(discovery.id);
    } else {
      sharedGenerationState.complete(discovery.id);
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
    if (result != null) {
      final route = ModalRoute.of(context);
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
                  !ref
                      .read(cardGenerationStateProvider.notifier)
                      .hasAnyGenerating,
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
    if (ref
            .read(eventRuntimeConfigurationProvider)
            .activeEvent(DateTime.now().toUtc()) !=
        null) {
      return true;
    }
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
      RemoteCardGenerationFailureReason.missingPhoto =>
        'Foto gatto non accessibile',
      RemoteCardGenerationFailureReason.photoUploadFailed =>
        'Caricamento foto non riuscito',
      RemoteCardGenerationFailureReason.storagePermissionDenied =>
        'Accesso alla foto non disponibile',
      RemoteCardGenerationFailureReason.signedUrlFailed =>
        'Preparazione foto non riuscita',
      RemoteCardGenerationFailureReason.network =>
        'Connessione non disponibile',
      RemoteCardGenerationFailureReason.remoteApiFailure =>
        'Errore generazione carta',
      null => 'Errore generazione carta',
    };
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
  final Map<String, Timer> _longWaitTimers = {};
  final Map<String, int> _localCacheBustVersions = {};

  @override
  void dispose() {
    for (final timer in _longWaitTimers.values) {
      timer.cancel();
    }
    _longWaitTimers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final entries = _liveEntriesForRarity(
      ref.watch(catDexControllerProvider).entries,
    );
    final generatedCount = entries.where(_hasGeneratedCardInAlbum).length;
    final usageSummary = ref.watch(monetizationStatusSummaryProvider);
    final generationStates = ref.watch(cardGenerationStateProvider);

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
            ..._rarityAlbumGridSlivers(
              entries,
              usageSummary,
              generationStates,
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
    Map<String, CardGenerationSharedState> generationStates,
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
              final entry = chunk[index];
              final discovery = entry.discovery;
              final discoveryId = discovery?.id;
              final summary = usageSummary.maybeWhen(
                data: (summary) => summary,
                orElse: () => null,
              );
              final generationState = discoveryId == null
                  ? CardGenerationSharedState.idle
                  : generationStates[discoveryId] ??
                        CardGenerationSharedState.idle;
              return _CardsBinderTile(
                entry: entry,
                generating: generationState.isGenerating,
                generatingLabel: generationState.label,
                hasGenerationError: generationState.hasFailed,
                cacheBustVersion: discoveryId == null
                    ? null
                    : _localCacheBustVersions[discoveryId] ??
                          widget.cacheBustVersions[discoveryId],
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
                  loadingLabel: _cardGenerationPendingLabel,
                ),
                onRegenerate: () => _runCardAction(
                  entry,
                  callback: widget.onRegenerateCard,
                  loadingLabel: _cardGenerationPendingLabel,
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
    if (discoveryId == null) {
      return;
    }

    final generationController = ref.read(
      cardGenerationStateProvider.notifier,
    );
    if (!generationController.begin(discoveryId, label: loadingLabel)) {
      debugPrint('CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED $discoveryId');
      return;
    }

    debugPrint('CATDEX_CARD_GENERATION_USER_TAP');
    debugPrint('CATDEX_CARD_UI_SINGLE_TAP_HANDLED $discoveryId');
    debugPrint('CATDEX_CARD_UI_GENERATING_STARTED $discoveryId');
    _startLongWaitMessage(discoveryId);

    if (!await widget.onCanStartCardGeneration()) {
      _cancelLongWaitMessage(discoveryId);
      generationController.reset(discoveryId);
      return;
    }

    String? result;
    try {
      result = await callback(entry);
    } finally {
      _cancelLongWaitMessage(discoveryId);
    }

    if (!mounted) {
      return;
    }

    if (result == null || result.trim().isEmpty) {
      if (generationController.forDiscovery(discoveryId).isGenerating) {
        generationController.fail(discoveryId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cardGenerationError)),
      );
      return;
    }

    final version = DateTime.now().millisecondsSinceEpoch;
    await ref
        .read(localDiscoverySessionProvider.notifier)
        .refreshDiscoveryById(discoveryId);
    if (!mounted) {
      return;
    }
    final persistedCards = await ref
        .read(catCardRepositoryProvider)
        .getCardsForDiscovery(discoveryId);
    if (!mounted) {
      return;
    }
    final persistedResult = persistedCards.any(
      (card) => card.isCompleted && card.finalCardUrl == result,
    );
    if (!persistedResult) {
      generationController.fail(discoveryId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.cardGenerationError)),
      );
      return;
    }
    if (generationController.forDiscovery(discoveryId).isGenerating) {
      generationController.complete(discoveryId);
    }
    setState(() {
      _localCacheBustVersions[discoveryId] = version;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.cardUpdatedMessage)),
    );
  }

  void _startLongWaitMessage(String discoveryId) {
    _cancelLongWaitMessage(discoveryId);
    _longWaitTimers[discoveryId] = Timer(
      _cardGenerationLongWaitThreshold,
      () {
        if (!mounted ||
            !ref
                .read(cardGenerationStateProvider.notifier)
                .forDiscovery(discoveryId)
                .isGenerating) {
          return;
        }
        ref
            .read(cardGenerationStateProvider.notifier)
            .updateLabel(discoveryId, _cardGenerationLongWaitLabel);
        debugPrint('CATDEX_CARD_UI_LONG_WAIT_MESSAGE_SHOWN $discoveryId');
        debugPrint('CATDEX_CARD_UI_PREMATURE_TIMEOUT_BLOCKED $discoveryId');
      },
    );
  }

  void _cancelLongWaitMessage(String discoveryId) {
    _longWaitTimers.remove(discoveryId)?.cancel();
  }

  bool _hasGeneratedCardInAlbum(CatDexCollectionEntry entry) {
    return _entryHasFinalCardImage(entry);
  }

  List<CatDexCollectionEntry> _liveEntriesForRarity(
    List<CatDexCollectionEntry> entries,
  ) {
    final liveEntries = entries
        .where((entry) {
          final discovery = entry.discovery;
          return entry.discovered &&
              discovery != null &&
              discovery.id.trim().isNotEmpty &&
              discovery.rarity == widget.rarity;
        })
        .toList(growable: false);

    return liveEntries..sort((a, b) {
      final generated = (_entryHasFinalCardImage(b) ? 1 : 0).compareTo(
        _entryHasFinalCardImage(a) ? 1 : 0,
      );
      if (generated != 0) {
        return generated;
      }
      final aDate = a.discovery?.discoveredAt;
      final bDate = b.discovery?.discoveredAt;
      if (aDate == null || bDate == null) {
        return 0;
      }
      return bDate.compareTo(aDate);
    });
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
  return entry.cardRecord?.isCompleted == true || _hasLegacyNormalCard(entry);
}

String? _entryCardImageSource(
  CatDexCollectionEntry entry, {
  required int? cacheBustVersion,
}) {
  final source = entry.cardRecord?.isCompleted == true
      ? entry.cardRecord!.finalCardUrl
      : _hasLegacyNormalCard(entry)
      ? canonicalGeneratedCardUrl(entry.discovery)
      : null;
  return source == null
      ? null
      : cacheBustedCardImageUrl(
          source: source,
          version: cacheBustVersion,
        );
}

bool _hasLegacyNormalCard(CatDexCollectionEntry entry) {
  final card = entry.discovery?.card;
  return entry.cardRecord == null &&
      card != null &&
      !card.isEventCard &&
      hasPersistedGeneratedCard(entry.discovery);
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
    this.generateLabel,
  });

  final CatDexCollectionEntry entry;
  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final int? cacheBustVersion;
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
        debugRarityOverride: debugRarityOverride,
        onDebugRarityOverrideSelected: onDebugRarityOverrideSelected,
        onGenerate: onGenerate,
        onRegenerate: onRegenerate,
        onTap: onTap,
      ),
    );
  }
}
