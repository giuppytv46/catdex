import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/capture/data/supabase_cat_photo_storage_repository.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/cards/presentation/catdex_trading_card_page.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_reward_bridge.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_session.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_session_presenter.dart';
import 'package:catdex/features/catdex/application/catdex_photo_recovery_service.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/events/application/event_card_ui_generation_controller.dart';
import 'package:catdex/features/events/application/event_providers.dart';
import 'package:catdex/features/events/application/event_ui_state.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_controls.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EventPage extends ConsumerStatefulWidget {
  const EventPage({required this.eventKey, super.key});

  final String eventKey;

  @override
  ConsumerState<EventPage> createState() => _EventPageState();
}

class _EventPageState extends ConsumerState<EventPage> {
  String? _selectedDiscoveryId;
  String? _selectedVariantId;

  @override
  void initState() {
    super.initState();
    attachCardRevealMissionBridge(ref);
    debugPrint('CATDEX_EVENT_UI_PAGE_OPENED eventKey=${widget.eventKey}');
  }

  @override
  void didUpdateWidget(covariant EventPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventKey != widget.eventKey) {
      _selectedDiscoveryId = null;
      _selectedVariantId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(eventUiStateProvider(widget.eventKey));
    return Scaffold(
      appBar: AppBar(
        title: Text(CatDexLocalizations.of(context).eventHalloweenTitle),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _EventUnavailable(
          onRetry: () => ref.invalidate(eventUiStateProvider(widget.eventKey)),
        ),
        data: _buildEvent,
      ),
    );
  }

  Widget _buildEvent(EventUiState state) {
    final rewardCues = ref.watch(cardRevealRewardCueProvider);
    final showRevealRewards = ModalRoute.of(context)?.isCurrent ?? true;
    final generationStates = ref.watch(eventCardUiGenerationProvider);
    final selectedId =
        state.discoveries.any(
          (item) => item.id == _selectedDiscoveryId,
        )
        ? _selectedDiscoveryId
        : state.discoveries.firstOrNull?.id;
    final selected = state.discoveries
        .where((item) => item.id == selectedId)
        .firstOrNull;
    final selectedVariantId =
        state.isPremium &&
            _selectedVariantId != null &&
            state.event.isVariantEnabled(_selectedVariantId!)
        ? _selectedVariantId
        : null;
    if (_selectedVariantId != null && selectedVariantId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selectedVariantId != null) {
          setState(() => _selectedVariantId = null);
        }
      });
    }
    final selectedVariantCard = selected == null || selectedVariantId == null
        ? null
        : state.ownedCards
              .where(
                (card) =>
                    card.discoveryId == selected.id &&
                    card.eventArtworkVariantId == selectedVariantId &&
                    card.isCompleted,
              )
              .firstOrNull;
    final generation = selectedId == null
        ? EventUiGenerationState.idle
        : generationStates['${state.event.id}::$selectedId'] ??
              EventUiGenerationState.idle;
    final completedCard = generation.cardId == null
        ? null
        : ref
              .watch(catCardCollectionProvider)
              .where(
                (card) => card.cardId == generation.cardId,
              )
              .firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = ((constraints.maxWidth - 920) / 2).clamp(16.0, 32.0);
        final catColumns = constraints.maxWidth >= 700 ? 3 : 2;
        final albumColumns = constraints.maxWidth >= 760 ? 3 : 2;
        return RefreshIndicator(
          onRefresh: () async {
            await ref.read(catCardCollectionProvider.notifier).refresh();
            ref.read(eventUiRefreshProvider.notifier).refresh();
            await ref.read(eventUiStateProvider(widget.eventKey).future);
          },
          child: CustomScrollView(
            key: const Key('event_page_scroll'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(side, AppSpacing.md, side, 0),
                sliver: SliverList.list(
                  children: [
                    EventHeaderPanel(state: state),
                    const SizedBox(height: AppSpacing.lg),
                    EventProgressPanel(
                      state: state,
                      generationPending: generation.isInProgress,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeading(
                      title: state.isPremium
                          ? CatDexLocalizations.of(context).eventChooseArtwork
                          : CatDexLocalizations.of(context).eventFreeArtworks,
                      subtitle: state.isPremium && selectedVariantId != null
                          ? CatDexLocalizations.of(
                              context,
                            ).eventArtworkSelected
                          : CatDexLocalizations.of(
                              context,
                            ).eventFreeCollectionSummary(
                              state.collectedFreeArtworkCount,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    EventArtworkPreviewGrid(
                      state: state,
                      onOpenCard: _openCard,
                      onOpenPremium: () =>
                          context.pushNamed(AppRoute.premium.name),
                      selectedVariantId: selectedVariantId,
                      onSelectVariant: state.isPremium
                          ? (variantId) {
                              if (!state.event.isVariantEnabled(variantId)) {
                                return;
                              }
                              setState(() => _selectedVariantId = variantId);
                              debugPrint(
                                'CATDEX_EVENT_VARIANT_SELECTED_BY_USER '
                                'variant=$variantId',
                              );
                              if (variantId == 'halloween_pumpkin_king') {
                                debugPrint(
                                  'CATDEX_EVENT_VARIANT_PUMPKIN_KING_SELECTED',
                                );
                              } else if (variantId ==
                                  'halloween_night_spirit') {
                                debugPrint(
                                  'CATDEX_EVENT_VARIANT_NIGHT_SPIRIT_SELECTED',
                                );
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeading(
                      title: CatDexLocalizations.of(context).eventChooseCat,
                      subtitle: state.discoveries.isEmpty
                          ? CatDexLocalizations.of(context).eventDiscoverCatHint
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              if (state.discoveries.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: SliverToBoxAdapter(
                    child: _NoDiscoveries(
                      onCapture: () => context.goNamed(AppRoute.capture.name),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: SliverGrid.builder(
                    itemCount: state.discoveries.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: catColumns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.82,
                    ),
                    itemBuilder: (context, index) {
                      final discovery = state.discoveries[index];
                      return EventCatSelectionTile(
                        discovery: discovery,
                        selected: discovery.id == selectedId,
                        ownedEventCards: state.eventCardCountForDiscovery(
                          discovery.id,
                        ),
                        resolveImage: () =>
                            _resolveDiscoveryImage(ref, discovery),
                        onSelected: () {
                          setState(() => _selectedDiscoveryId = discovery.id);
                          debugPrint(
                            'CATDEX_EVENT_UI_CAT_SELECTED id=${discovery.id}',
                          );
                        },
                      );
                    },
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  side,
                  AppSpacing.lg,
                  side,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: EventGenerationPanel(
                    state: state,
                    selectedDiscovery: selected,
                    generation: generation,
                    completedCard: completedCard,
                    selectedVariantId: selectedVariantId,
                    existingSelectedVariantCard: selectedVariantCard,
                    onGenerate: selected == null
                        ? null
                        : () => _generate(
                            state,
                            selected,
                            selectedVariantId: selectedVariantId,
                          ),
                    onRetry: selected == null
                        ? null
                        : () {
                            ref
                                .read(eventCardUiGenerationProvider.notifier)
                                .reset(state.event.id, selected.id);
                            return _generate(
                              state,
                              selected,
                              selectedVariantId: selectedVariantId,
                            );
                          },
                    onOpenCard: completedCard == null
                        ? null
                        : () => _openCard(completedCard),
                    onBackToEvent: selected == null
                        ? null
                        : () => ref
                              .read(eventCardUiGenerationProvider.notifier)
                              .reset(state.event.id, selected.id),
                    onOpenExistingCard: selectedVariantCard == null
                        ? null
                        : () => _openCard(selectedVariantCard),
                    rewardCue: selectedId == null || !showRevealRewards
                        ? null
                        : rewardCues[selectedId],
                    onRewardSequenceCompleted:
                        selectedId == null || !showRevealRewards
                        ? null
                        : (cue) => ref
                              .read(cardRevealRewardCueProvider.notifier)
                              .consume(selectedId, cue.id),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: side),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeading(
                    title: CatDexLocalizations.of(context).eventAlbumTitle,
                    subtitle: CatDexLocalizations.of(
                      context,
                    ).eventCardsOwned(state.ownedCards.length),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
              if (state.ownedCards.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: const SliverToBoxAdapter(
                    child: _EmptyEventAlbum(),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: SliverGrid.builder(
                    key: const Key('event_album_grid'),
                    itemCount: state.ownedCards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: albumColumns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.68,
                    ),
                    itemBuilder: (context, index) => EventAlbumCard(
                      card: state.ownedCards[index],
                      onOpen: () => _openCard(state.ownedCards[index]),
                    ),
                  ),
                ),
              if (showMonetizationDebug && state.debugMode)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    AppSpacing.lg,
                    side,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _EventDebugControls(state: state),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _generate(
    EventUiState state,
    CatDiscovery discovery, {
    required String? selectedVariantId,
  }) async {
    debugPrint('CATDEX_EVENT_UI_GENERATE_TAPPED');
    final rootOverlay = Overlay.of(context, rootOverlay: true);
    final mediaQuery = MediaQuery.of(context);
    final result = await ref
        .read(eventCardUiGenerationProvider.notifier)
        .generate(
          event: state.event,
          discovery: discovery,
          collectionNumber: state.discoveries.indexOf(discovery) + 1,
          selectedVariantId: selectedVariantId,
        );
    if (!mounted ||
        result.phase != EventUiGenerationPhase.completed ||
        result.cardId == null) {
      return;
    }
    final card = await ref
        .read(catCardRepositoryProvider)
        .getCardById(result.cardId!);
    if (!mounted || card == null || !card.isCompleted) return;
    final rewardCue = ref.read(cardRevealRewardCueProvider)[discovery.id];
    final l10n = CatDexLocalizations.of(context);
    final session = CardRevealSession.fromRecord(
      card: card,
      localizedRarityLabel: card.isPremiumArtwork
          ? '${l10n.eventCardBadge} ${l10n.eventPremiumBadge}'
          : l10n.eventCardBadge,
      mediaQuery: mediaQuery,
      rewardCue: rewardCue,
    );
    debugPrint('CATDEX_CARD_REVEAL_ALBUM_REFRESH_DEFERRED');
    final action = await CardRevealSessionPresenter.instance.show(
      rootOverlay: rootOverlay,
      session: session,
      onRewardSequenceCompleted: (cue) {
        ref
            .read(cardRevealRewardCueProvider.notifier)
            .consume(discovery.id, cue.id);
      },
    );
    if (!mounted) return;
    debugPrint('CATDEX_CARD_REVEAL_ALBUM_REFRESH_STARTED');
    await ref.read(catCardCollectionProvider.notifier).refresh();
    ref.read(eventUiRefreshProvider.notifier).refresh();
    debugPrint('CATDEX_CARD_REVEAL_ALBUM_REFRESH_COMPLETED');
    if (action == CardRevealSessionAction.openCard) {
      _openCard(card);
    }
  }

  void _openCard(CatCardRecord card) {
    unawaited(
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => CatDexTradingCardPage(
            discoveryId: card.discoveryId,
            cardId: card.cardId,
          ),
        ),
      ),
    );
  }
}

class EventHeaderPanel extends StatelessWidget {
  const EventHeaderPanel({required this.state, super.key});

  final EventUiState state;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final dates = MaterialLocalizations.of(context);
    final start = dates.formatMediumDate(state.event.startsAt.toLocal());
    final end = dates.formatMediumDate(state.event.endsAt.toLocal());
    final days = _remainingDays(state.event.endsAt);
    return Semantics(
      header: true,
      child: Container(
        key: const Key('event_header'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _eventPanelDecoration(
          context,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF22103F), Color(0xFF5B21B6), Color(0xFF9A3412)],
          ),
          borderColor: const Color(0xFFF6C453),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFFFDE68A),
                  size: 30,
                ),
                Text(
                  l10n.eventHalloweenTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                _StatusBadge(
                  label: state.isPremium
                      ? l10n.eventPremiumBadge
                      : l10n.eventFreeBadge,
                  premium: state.isPremium,
                ),
                if (state.debugMode)
                  _StatusBadge(
                    key: const Key('event_debug_badge'),
                    label: l10n.eventTestBadge,
                    premium: false,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${state.event.edition}  •  $start – $end',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFFF3E8FF),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.eventHalloweenDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(
                  state.active ? Icons.schedule_rounded : Icons.event_busy,
                  color: const Color(0xFFFDE68A),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    state.active
                        ? l10n.eventDaysRemaining(days)
                        : l10n.eventEnded,
                    key: Key(state.active ? 'event_countdown' : 'event_ended'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
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

class EventProgressPanel extends StatelessWidget {
  const EventProgressPanel({
    required this.state,
    required this.generationPending,
    super.key,
  });

  final EventUiState state;
  final bool generationPending;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final ratio = state.generationLimit == 0
        ? 0.0
        : state.committedUsage / state.generationLimit;
    return Semantics(
      label:
          '${l10n.eventGenerations}. '
          '${l10n.eventUsage(state.committedUsage, state.generationLimit)}. '
          '${l10n.eventRemaining(state.remainingGenerations)}.',
      value: '${(ratio * 100).round()}%',
      child: Container(
        key: const Key('event_progress_panel'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _eventPanelDecoration(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.isPremium
                  ? l10n.eventPremiumGenerations
                  : l10n.eventGenerations,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.eventUsage(state.committedUsage, state.generationLimit),
              key: const Key('event_usage_text'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: ratio.clamp(0, 1),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(Color(0xFFEA580C)),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                Text(
                  l10n.eventRemaining(state.remainingGenerations),
                  key: const Key('event_remaining_text'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (generationPending)
                  Text(
                    l10n.eventAlreadyCreating,
                    key: const Key('event_pending_separate'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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

class EventArtworkPreviewGrid extends StatelessWidget {
  const EventArtworkPreviewGrid({
    required this.state,
    required this.onOpenCard,
    required this.onOpenPremium,
    this.selectedVariantId,
    this.onSelectVariant,
    super.key,
  });

  final EventUiState state;
  final ValueChanged<CatCardRecord> onOpenCard;
  final VoidCallback onOpenPremium;
  final String? selectedVariantId;
  final ValueChanged<String>? onSelectVariant;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final variants = state.event.enabledStandardVariantIds;
    final premiumVariants = state.event.enabledPremiumVariantIds;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 3 : 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.builder(
              key: const Key('event_artwork_preview_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: variants.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.67,
              ),
              itemBuilder: (context, index) {
                final variant = variants[index];
                final owned = state.cardsForVariant(variant);
                return EventArtworkSlot(
                  key: ValueKey('event_artwork_slot_$variant'),
                  variantId: variant,
                  collectedCard: owned.firstOrNull,
                  premium: false,
                  locked: false,
                  selectable: state.isPremium,
                  selected: selectedVariantId == variant,
                  onSelect: state.isPremium
                      ? () => onSelectVariant?.call(variant)
                      : null,
                  onOpen: owned.isEmpty ? null : () => onOpenCard(owned.first),
                );
              },
            ),
            if (!state.isPremium) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.eventFreeVariantsAutomatic,
                key: const Key('event_free_variants_automatic'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _SectionHeading(
              title: l10n.eventPremiumArtworks,
              subtitle: state.premiumArtworkCollected
                  ? l10n.eventPremiumCollected
                  : l10n.eventPremiumNotCollected,
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.builder(
              key: const Key('event_premium_artwork_preview_grid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: premiumVariants.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.67,
              ),
              itemBuilder: (context, index) {
                final variant = premiumVariants[index];
                final owned = state.cardsForVariant(variant);
                final locked = !state.isPremium && owned.isEmpty;
                return EventArtworkSlot(
                  key: ValueKey('event_artwork_slot_$variant'),
                  variantId: variant,
                  collectedCard: owned.firstOrNull,
                  premium: true,
                  locked: locked,
                  selectable: state.isPremium,
                  selected: selectedVariantId == variant,
                  onSelect: state.isPremium
                      ? () => onSelectVariant?.call(variant)
                      : null,
                  onOpen: owned.isEmpty ? null : () => onOpenCard(owned.first),
                  onPremium: locked ? onOpenPremium : null,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class EventArtworkSlot extends StatelessWidget {
  const EventArtworkSlot({
    required this.variantId,
    required this.collectedCard,
    required this.premium,
    required this.locked,
    this.selectable = false,
    this.selected = false,
    this.onSelect,
    this.onOpen,
    this.onPremium,
    super.key,
  });

  final String variantId;
  final CatCardRecord? collectedCard;
  final bool premium;
  final bool locked;
  final bool selectable;
  final bool selected;
  final VoidCallback? onSelect;
  final VoidCallback? onOpen;
  final VoidCallback? onPremium;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final details = _variantDetails(l10n, variantId);
    final collected = collectedCard != null;
    return Semantics(
      label:
          '${details.name}. '
          '${collected ? l10n.eventCollected : l10n.eventNotCollected}. '
          '${premium ? l10n.eventPremiumBadge : l10n.eventFreeBadge}',
      button: selectable || onOpen != null || onPremium != null,
      selected: selectable && selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: selectable ? onSelect : onOpen ?? onPremium,
          child: Ink(
            decoration: _eventPanelDecoration(
              context,
              borderColor: premium
                  ? const Color(0xFFF6C453)
                  : selected
                  ? const Color(0xFF54D2A5)
                  : const Color(0xFF8B5CF6),
              borderWidth: selected ? 3 : 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (collected)
                          _EventNetworkArtwork(
                            url: collectedCard!.finalCardUrl,
                            placeholderIcon: details.icon,
                          )
                        else
                          _EventArtworkPlaceholder(
                            variantId: variantId,
                            icon: details.icon,
                            premium: premium,
                          ),
                        if (locked)
                          const Positioned(
                            right: 10,
                            top: 10,
                            child: _LockedArtworkBadge(),
                          ),
                        if (selected)
                          const Positioned(
                            right: 10,
                            top: 10,
                            child: _SelectedArtworkCheck(),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        details.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _MiniBadge(
                            label: premium
                                ? l10n.eventPremiumBadge
                                : l10n.eventFreeBadge,
                            premium: premium,
                          ),
                          _MiniBadge(
                            label: collected
                                ? l10n.eventCollected
                                : l10n.eventNotCollected,
                            premium: false,
                          ),
                        ],
                      ),
                      if (locked && onPremium != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        TextButton(
                          onPressed: onPremium,
                          child: Text(l10n.eventDiscoverPremium),
                        ),
                      ],
                    ],
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

class EventCatSelectionTile extends StatefulWidget {
  const EventCatSelectionTile({
    required this.discovery,
    required this.selected,
    required this.ownedEventCards,
    required this.resolveImage,
    required this.onSelected,
    super.key,
  });

  final CatDiscovery discovery;
  final bool selected;
  final int ownedEventCards;
  final Future<CatDexResolvedImage> Function() resolveImage;
  final VoidCallback onSelected;

  @override
  State<EventCatSelectionTile> createState() => _EventCatSelectionTileState();
}

class _EventCatSelectionTileState extends State<EventCatSelectionTile> {
  late Future<CatDexResolvedImage> _image;

  @override
  void initState() {
    super.initState();
    _image = widget.resolveImage();
  }

  @override
  void didUpdateWidget(covariant EventCatSelectionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.discovery.id != widget.discovery.id) {
      _image = widget.resolveImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final display = const CatDisplayFormatter().fromDiscovery(widget.discovery);
    return Semantics(
      selected: widget.selected,
      button: true,
      label: '${display.displayName}, ${display.displaySpecies}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('event_cat_${widget.discovery.id}'),
          onTap: widget.onSelected,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: _eventPanelDecoration(
              context,
              borderColor: widget.selected
                  ? const Color(0xFF7C3AED)
                  : Theme.of(context).colorScheme.outlineVariant,
              borderWidth: widget.selected ? 2.2 : 1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(17),
                    ),
                    child: FutureBuilder<CatDexResolvedImage>(
                      future: _image,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const _CatImagePlaceholder(loading: true);
                        }
                        final image = snapshot.data;
                        if (image == null || image.usesPlaceholder) {
                          return const _CatImagePlaceholder();
                        }
                        return Image(
                          image: image.provider!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const _CatImagePlaceholder(),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        display.displaySpecies,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: [
                          _MiniBadge(
                            label: display.displayRarity,
                            premium: false,
                          ),
                          if (widget.ownedEventCards > 0)
                            _MiniBadge(
                              label: CatDexLocalizations.of(
                                context,
                              ).eventCardsOwned(widget.ownedEventCards),
                              premium: true,
                            ),
                        ],
                      ),
                    ],
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

class EventGenerationPanel extends StatelessWidget {
  const EventGenerationPanel({
    required this.state,
    required this.selectedDiscovery,
    required this.generation,
    required this.completedCard,
    required this.onGenerate,
    required this.onRetry,
    required this.onOpenCard,
    required this.onBackToEvent,
    this.selectedVariantId,
    this.existingSelectedVariantCard,
    this.onOpenExistingCard,
    this.rewardCue,
    this.onRewardSequenceCompleted,
    super.key,
  });

  final EventUiState state;
  final CatDiscovery? selectedDiscovery;
  final EventUiGenerationState generation;
  final CatCardRecord? completedCard;
  final Future<void> Function()? onGenerate;
  final Future<void> Function()? onRetry;
  final VoidCallback? onOpenCard;
  final VoidCallback? onBackToEvent;
  final String? selectedVariantId;
  final CatCardRecord? existingSelectedVariantCard;
  final VoidCallback? onOpenExistingCard;
  final CardRevealRewardCue? rewardCue;
  final ValueChanged<CardRevealRewardCue>? onRewardSequenceCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    if (generation.isInProgress) {
      return _GenerationProgress(generation: generation);
    }
    if (generation.phase == EventUiGenerationPhase.completed) {
      return _GenerationSuccess(
        card: completedCard,
        discovery: selectedDiscovery,
        onOpenCard: onOpenCard,
        onBackToEvent: onBackToEvent,
        rewardCue: rewardCue,
        onRewardSequenceCompleted: onRewardSequenceCompleted,
      );
    }
    if (generation.phase == EventUiGenerationPhase.failed ||
        generation.phase == EventUiGenerationPhase.blocked) {
      return _GenerationError(
        message: _failureMessage(
          l10n,
          generation.failureReason,
          premium: state.isPremium,
          generationLimit: state.generationLimit,
        ),
        canRetry: _canRetry(generation.failureReason),
        onRetry: onRetry,
      );
    }

    final unavailableMessage = existingSelectedVariantCard != null
        ? l10n.eventVariantAlreadyOwned
        : !state.active
        ? l10n.eventEnded
        : !state.rendererConfigured
        ? l10n.eventRendererUnavailable
        : state.limitReached
        ? state.isPremium
              ? l10n.eventLimitError(state.generationLimit)
              : l10n.eventFreeLimitError
        : selectedDiscovery == null
        ? l10n.eventDiscoverCatFirst
        : state.isPremium && selectedVariantId == null
        ? l10n.eventSelectArtworkFirst
        : null;
    final enabled = unavailableMessage == null && onGenerate != null;
    return Container(
      key: const Key('event_generation_panel'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _eventPanelDecoration(
        context,
        borderColor: const Color(0xFFEA580C),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (unavailableMessage != null) ...[
            Text(
              unavailableMessage,
              key: const Key('event_generation_unavailable_message'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (existingSelectedVariantCard != null)
            OutlinedButton.icon(
              key: const Key('event_open_existing_variant_button'),
              onPressed: onOpenExistingCard,
              icon: const Icon(Icons.open_in_new_rounded),
              label: Text(l10n.eventOpenExistingCard),
            )
          else
            FilledButton.icon(
              key: const Key('event_generate_button'),
              onPressed: enabled ? onGenerate : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                state.isPremium && selectedVariantId != null
                    ? l10n.eventGenerateVariant(
                        _variantDetails(l10n, selectedVariantId!).name,
                      )
                    : l10n.eventGenerateCard,
              ),
            ),
        ],
      ),
    );
  }
}

class _GenerationProgress extends StatelessWidget {
  const _GenerationProgress({required this.generation});

  final EventUiGenerationState generation;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final label = switch (generation.phase) {
      EventUiGenerationPhase.reserving => l10n.eventPreparingMagic,
      EventUiGenerationPhase.generating => l10n.eventCatEntering,
      EventUiGenerationPhase.recovering => l10n.eventCreatingCard,
      EventUiGenerationPhase.persisting => l10n.eventAlmostReady,
      _ => l10n.eventCreatingCard,
    };
    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        key: const Key('event_generation_progress'),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: _eventPanelDecoration(
          context,
          borderColor: const Color(0xFF7C3AED),
        ),
        child: Column(
          children: [
            const CircularProgressIndicator(color: Color(0xFFEA580C)),
            const SizedBox(height: AppSpacing.lg),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (generation.longWait) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.eventLongWait,
                key: const Key('event_generation_long_wait'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GenerationSuccess extends StatelessWidget {
  const _GenerationSuccess({
    required this.card,
    required this.discovery,
    required this.onOpenCard,
    required this.onBackToEvent,
    required this.rewardCue,
    required this.onRewardSequenceCompleted,
  });

  final CatCardRecord? card;
  final CatDiscovery? discovery;
  final VoidCallback? onOpenCard;
  final VoidCallback? onBackToEvent;
  final CardRevealRewardCue? rewardCue;
  final ValueChanged<CardRevealRewardCue>? onRewardSequenceCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final display = discovery == null
        ? null
        : const CatDisplayFormatter().fromDiscovery(discovery!);
    final details = _variantDetails(
      l10n,
      card?.eventArtworkVariantId ?? '',
    );
    return Container(
      key: const Key('event_generation_success'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _eventPanelDecoration(
        context,
        borderColor: const Color(0xFF22C55E),
      ),
      child: Column(
        children: [
          if (card != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 430),
              child: AspectRatio(
                aspectRatio: 1500 / 2100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _EventNetworkArtwork(
                    url: card!.finalCardUrl,
                    placeholderIcon: details.icon,
                  ),
                ),
              ),
            )
          else
            const SizedBox.square(
              dimension: 44,
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            display?.displayName ?? '',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(details.name, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          _MiniBadge(
            label: card?.isPremiumArtwork == true
                ? l10n.eventPremiumBadge
                : l10n.eventFreeBadge,
            premium: card?.isPremiumArtwork == true,
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('event_open_result_card'),
            onPressed: onOpenCard,
            icon: const Icon(Icons.open_in_new_rounded),
            label: Text(l10n.eventOpenCard),
          ),
          TextButton(
            onPressed: onBackToEvent,
            child: Text(l10n.eventBackToEvent),
          ),
        ],
      ),
    );
  }
}

class _GenerationError extends StatelessWidget {
  const _GenerationError({
    required this.message,
    required this.canRetry,
    required this.onRetry,
  });

  final String message;
  final bool canRetry;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Container(
      key: const Key('event_generation_error'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _eventPanelDecoration(
        context,
        borderColor: Theme.of(context).colorScheme.error,
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 36,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canRetry) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retryAction),
            ),
          ],
        ],
      ),
    );
  }
}

class EventAlbumCard extends StatelessWidget {
  const EventAlbumCard({required this.card, required this.onOpen, super.key});

  final CatCardRecord card;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final details = _variantDetails(l10n, card.eventArtworkVariantId ?? '');
    return Semantics(
      label: '${details.name}. ${l10n.eventCollected}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('event_album_card_${card.cardId}'),
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: _eventPanelDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: _EventNetworkArtwork(
                      url: card.finalCardUrl,
                      placeholderIcon: details.icon,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.displayName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        details.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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

class _EventNetworkArtwork extends StatelessWidget {
  const _EventNetworkArtwork({
    required this.url,
    required this.placeholderIcon,
  });

  final String url;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      key: ValueKey('event_artwork_$url'),
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const _CatImagePlaceholder(loading: true),
      errorBuilder: (_, error, _) {
        debugPrint('CATDEX_EVENT_UI_ERROR reason=artwork_image_load');
        return _EventArtworkPlaceholder(
          variantId: '',
          icon: placeholderIcon,
          premium: false,
        );
      },
    );
  }
}

class _EventArtworkPlaceholder extends StatelessWidget {
  const _EventArtworkPlaceholder({
    required this.variantId,
    required this.icon,
    required this.premium,
  });

  final String variantId;
  final IconData icon;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    if (variantId == 'halloween_haunted_frame') {
      return const _HauntedHouseArtworkPlaceholder();
    }
    if (variantId == 'halloween_pumpkin_king') {
      return const _PumpkinKingArtworkPlaceholder();
    }
    if (variantId == 'halloween_night_spirit') {
      return const _NightSpiritArtworkPlaceholder();
    }
    return DecoratedBox(
      key: const Key('event_artwork_placeholder'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: premium
              ? const [Color(0xFF3B245F), Color(0xFFB45309)]
              : const [Color(0xFF24143F), Color(0xFF6D28D9)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            top: 12,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          Icon(icon, color: const Color(0xFFFDE68A), size: 46),
        ],
      ),
    );
  }
}

class _SelectedArtworkCheck extends StatelessWidget {
  const _SelectedArtworkCheck();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('event_artwork_selected_check'),
      decoration: BoxDecoration(
        color: const Color(0xFF54D2A5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Padding(
        padding: EdgeInsets.all(5),
        child: Icon(Icons.check_rounded, size: 18, color: Color(0xFF172033)),
      ),
    );
  }
}

class _LockedArtworkBadge extends StatelessWidget {
  const _LockedArtworkBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF241A45).withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFF6C453), width: 1.5),
      ),
      child: const Padding(
        padding: EdgeInsets.all(7),
        child: Icon(Icons.lock_rounded, size: 18, color: Colors.white),
      ),
    );
  }
}

class _HauntedHouseArtworkPlaceholder extends StatelessWidget {
  const _HauntedHouseArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('event_artwork_placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15143F), Color(0xFF283B78), Color(0xFF173F45)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            right: 12,
            top: 12,
            child: Icon(
              Icons.nightlight_round,
              color: Color(0xFFD8C8FF),
              size: 28,
            ),
          ),
          const Positioned(
            left: 18,
            top: 34,
            child: Icon(
              Icons.flutter_dash_rounded,
              color: Color(0xFFB8C7FF),
              size: 18,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cottage_rounded,
                color: Color(0xFFB5DCC8),
                size: 66,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 9,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD66B),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(color: Color(0x99FFD66B), blurRadius: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 20,
            child: Column(
              children: [
                Container(
                  height: 13,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC5D7E8).withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                      Icons.local_florist_rounded,
                      color: Color(0xFFFFA63D),
                      size: 22,
                    ),
                    Icon(
                      Icons.light_rounded,
                      color: Color(0xFFFFD66B),
                      size: 21,
                    ),
                    Icon(
                      Icons.local_florist_rounded,
                      color: Color(0xFFFFA63D),
                      size: 22,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PumpkinKingArtworkPlaceholder extends StatelessWidget {
  const _PumpkinKingArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('event_artwork_placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF251044), Color(0xFF6D2475), Color(0xFF9A3F13)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFC857).withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            top: 18,
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFFD76A),
              size: 48,
            ),
          ),
          const Icon(
            Icons.chair_alt_rounded,
            color: Color(0xFF4A194F),
            size: 86,
          ),
          const Positioned(
            bottom: 18,
            left: 16,
            child: Icon(
              Icons.local_florist_rounded,
              color: Color(0xFFFF9B35),
              size: 36,
            ),
          ),
          const Positioned(
            bottom: 18,
            right: 16,
            child: Icon(
              Icons.local_florist_rounded,
              color: Color(0xFFFFB347),
              size: 36,
            ),
          ),
          const Positioned(
            right: 16,
            top: 54,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFFFE4A3),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _NightSpiritArtworkPlaceholder extends StatelessWidget {
  const _NightSpiritArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('event_artwork_placeholder'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF090D35), Color(0xFF312B81), Color(0xFF075A78)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 14,
            right: 18,
            child: Icon(
              Icons.nightlight_round,
              color: Color(0xFFD9E7FF),
              size: 46,
            ),
          ),
          Icon(
            Icons.local_fire_department_rounded,
            color: const Color(0xFF67E8F9).withValues(alpha: 0.78),
            size: 88,
          ),
          const Positioned(
            left: 20,
            top: 34,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFC4B5FD),
              size: 24,
            ),
          ),
          const Positioned(
            left: 35,
            bottom: 28,
            child: Icon(Icons.star_rounded, color: Color(0xFF9FE7FF), size: 20),
          ),
          const Positioned(
            right: 38,
            bottom: 38,
            child: Icon(Icons.star_rounded, color: Color(0xFFD8C8FF), size: 16),
          ),
        ],
      ),
    );
  }
}

class _CatImagePlaceholder extends StatelessWidget {
  const _CatImagePlaceholder({this.loading = false});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: Key(
        loading ? 'event_cat_image_loading' : 'event_cat_image_placeholder',
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: loading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Icon(
                Icons.pets_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 42,
              ),
      ),
    );
  }
}

class _NoDiscoveries extends StatelessWidget {
  const _NoDiscoveries({required this.onCapture});

  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Container(
      key: const Key('event_no_discoveries'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _eventPanelDecoration(context),
      child: Column(
        children: [
          const Icon(Icons.pets_rounded, size: 44, color: Color(0xFF7C3AED)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.eventDiscoverCatFirst,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.eventDiscoverCatHint, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('event_capture_cta'),
            onPressed: onCapture,
            icon: const Icon(Icons.camera_alt_rounded),
            label: Text(l10n.captureTitle),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventAlbum extends StatelessWidget {
  const _EmptyEventAlbum();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('event_empty_album'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _eventPanelDecoration(context),
      child: Text(
        CatDexLocalizations.of(context).eventNoOwnedCards,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EventUnavailable extends StatelessWidget {
  const _EventUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded, size: 46),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.eventInactiveError, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: Text(l10n.retryAction),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDebugControls extends ConsumerWidget {
  const _EventDebugControls({required this.state});

  final EventUiState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _eventPanelDecoration(
        context,
        borderColor: const Color(0xFF7FDBFF),
      ),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          OutlinedButton(
            onPressed: () async {
              final session = ref.read(activeCatDexSessionProvider);
              await ref
                  .read(eventUsageRepositoryProvider)
                  .saveSnapshot(
                    playerId: session.playerId,
                    eventId: state.event.id,
                    snapshot: const EventUsageSnapshot(),
                  );
              ref.read(eventUiRefreshProvider.notifier).refresh();
            },
            child: const Text('Reset event usage'),
          ),
          OutlinedButton(
            onPressed: () {
              ref.read(eventUiRefreshProvider.notifier).refresh();
              ref.invalidate(eventUiStateProvider(state.event.id));
            },
            child: const Text('Refresh event state'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.premium, super.key});

  final String label;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final accent = premium ? const Color(0xFFF6C453) : const Color(0xFFC4B5FD);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.premium});

  final String label;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final accent = premium ? const Color(0xFFB45309) : const Color(0xFF6D28D9);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VariantDetails {
  const _VariantDetails(this.name, this.description, this.icon);

  final String name;
  final String description;
  final IconData icon;
}

_VariantDetails _variantDetails(CatDexLocalizations l10n, String variantId) {
  return switch (variantId) {
    'halloween_pumpkins' => _VariantDetails(
      l10n.eventPumpkinsName,
      l10n.eventPumpkinsDescription,
      Icons.local_florist_rounded,
    ),
    'halloween_moonlight' => _VariantDetails(
      l10n.eventMoonlightName,
      l10n.eventMoonlightDescription,
      Icons.nightlight_round,
    ),
    'halloween_haunted_frame' => _VariantDetails(
      l10n.eventHauntedName,
      l10n.eventHauntedDescription,
      Icons.cottage_rounded,
    ),
    'halloween_witch_cat' => _VariantDetails(
      l10n.eventWitchName,
      l10n.eventWitchDescription,
      Icons.auto_fix_high_rounded,
    ),
    'halloween_pumpkin_king' => _VariantDetails(
      l10n.eventPumpkinKingName,
      l10n.eventPumpkinKingDescription,
      Icons.workspace_premium_rounded,
    ),
    'halloween_night_spirit' => _VariantDetails(
      l10n.eventNightSpiritName,
      l10n.eventNightSpiritDescription,
      Icons.local_fire_department_rounded,
    ),
    _ => _VariantDetails(
      l10n.eventHalloweenTitle,
      l10n.eventHalloweenDescription,
      Icons.auto_awesome_rounded,
    ),
  };
}

String _failureMessage(
  CatDexLocalizations l10n,
  EventUiFailureReason? reason, {
  required bool premium,
  required int generationLimit,
}) {
  return switch (reason) {
    EventUiFailureReason.eventInactive => l10n.eventInactiveError,
    EventUiFailureReason.freeEventLimitReached =>
      premium
          ? l10n.eventLimitError(generationLimit)
          : l10n.eventFreeLimitError,
    EventUiFailureReason.premiumRequired => l10n.eventPremiumRequiredError,
    EventUiFailureReason.premiumVerificationUnavailable =>
      l10n.eventPremiumVerificationError,
    EventUiFailureReason.eventGenerationPending => l10n.eventAlreadyCreating,
    EventUiFailureReason.eventArtworkValidationFailed => l10n.eventQualityError,
    EventUiFailureReason.eventPersistenceFailed => l10n.eventPersistenceError,
    EventUiFailureReason.variantSelectionRequired =>
      l10n.eventSelectArtworkFirst,
    EventUiFailureReason.eventVariantInvalid => l10n.eventVariantInvalidServer,
    EventUiFailureReason.eventVariantDisabled =>
      l10n.eventVariantDisabledServer,
    EventUiFailureReason.selectedVariantInvalid =>
      l10n.eventSelectedVariantInvalid,
    EventUiFailureReason.selectedVariantDisabled =>
      l10n.eventSelectedVariantDisabled,
    EventUiFailureReason.selectedVariantAlreadyOwned =>
      l10n.eventVariantAlreadyOwned,
    EventUiFailureReason.rendererUnavailable => l10n.eventRendererUnavailable,
    EventUiFailureReason.missingPhoto => l10n.eventMissingPhotoError,
    EventUiFailureReason.photoUploadFailed => l10n.eventPhotoUploadError,
    EventUiFailureReason.storagePermissionDenied =>
      l10n.eventStoragePermissionError,
    EventUiFailureReason.signedUrlFailed => l10n.eventSignedUrlError,
    EventUiFailureReason.network => l10n.eventNetworkError,
    EventUiFailureReason.unknown || null => l10n.eventGenerationUnknownError,
  };
}

bool _canRetry(EventUiFailureReason? reason) {
  return switch (reason) {
    EventUiFailureReason.network ||
    EventUiFailureReason.eventArtworkValidationFailed ||
    EventUiFailureReason.eventPersistenceFailed ||
    EventUiFailureReason.premiumVerificationUnavailable ||
    EventUiFailureReason.rendererUnavailable ||
    EventUiFailureReason.missingPhoto ||
    EventUiFailureReason.photoUploadFailed ||
    EventUiFailureReason.storagePermissionDenied ||
    EventUiFailureReason.signedUrlFailed ||
    EventUiFailureReason.eventVariantInvalid ||
    EventUiFailureReason.eventVariantDisabled ||
    EventUiFailureReason.unknown => true,
    _ => false,
  };
}

BoxDecoration _eventPanelDecoration(
  BuildContext context, {
  Gradient? gradient,
  Color? borderColor,
  double borderWidth = 1,
}) {
  return BoxDecoration(
    color: gradient == null ? Theme.of(context).colorScheme.surface : null,
    gradient: gradient,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: borderColor ?? const Color(0xFFD8D4E8),
      width: borderWidth,
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

int _remainingDays(DateTime endsAt) {
  final difference = endsAt.difference(DateTime.now().toUtc());
  if (difference.isNegative) return 0;
  return (difference.inHours / 24).ceil();
}

Future<CatDexResolvedImage> _resolveDiscoveryImage(
  WidgetRef ref,
  CatDiscovery discovery,
) {
  return CatDexImageResolver.resolveBestImagePath(
    discovery: discovery,
    signedUrlForStoragePath: (path) => _createSignedPhotoUrl(ref, path),
    cacheFileForStoragePath: (path) => ref
        .read(catDexPhotoRecoveryServiceProvider)
        .recoverFromStorage(discovery: discovery, storagePath: path),
  );
}

Future<String?> _createSignedPhotoUrl(WidgetRef ref, String storagePath) async {
  final trimmed = storagePath.trim();
  if (trimmed.isEmpty ||
      trimmed == '-' ||
      !ref.read(supabaseConfiguredProvider)) {
    return null;
  }
  try {
    return await ref
        .read(supabaseClientProvider)
        .storage
        .from(SupabaseCatPhotoStorageRepository.catPhotosBucketName)
        .createSignedUrl(trimmed, 60 * 60 * 24);
  } on Object {
    debugPrint('CATDEX_EVENT_UI_ERROR reason=photo_signed_url');
    return null;
  }
}
