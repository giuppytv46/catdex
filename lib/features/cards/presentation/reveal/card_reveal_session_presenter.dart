import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_session.dart';
import 'package:catdex/features/cards/presentation/reveal/card_reveal_surface.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum CardRevealSessionAction { openCard, continueToAlbum }

class CardRevealSessionPresenter {
  CardRevealSessionPresenter({CatDexCelebrationCoordinator? coordinator})
    : _coordinator = coordinator ?? CatDexCelebrationCoordinator.instance;

  static final CardRevealSessionPresenter instance =
      CardRevealSessionPresenter();

  final CatDexCelebrationCoordinator _coordinator;
  Future<void> _queue = Future<void>.value();
  int _activeOverlayCount = 0;

  int get activeOverlayCount => _activeOverlayCount;

  Future<CardRevealSessionAction> show({
    required OverlayState rootOverlay,
    required CardRevealSession session,
    ValueChanged<CardRevealRewardCue>? onRewardSequenceCompleted,
  }) {
    final result = Completer<CardRevealSessionAction>();
    final firstFrame = Completer<void>();
    _queue = _queue.then((_) async {
      final sessionLease = _coordinator.acquire(
        session.cardType == CardRevealSessionType.normal
            ? CatDexCelebrationType.normalCardGenerated
            : CatDexCelebrationType.eventCardGenerated,
      );
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => CardRevealSessionOverlay(
          session: session,
          celebrationCoordinator: _coordinator,
          onFirstFrame: () {
            if (!firstFrame.isCompleted) firstFrame.complete();
          },
          onAction: (action) {
            if (!result.isCompleted) result.complete(action);
          },
          onRewardSequenceCompleted: onRewardSequenceCompleted,
        ),
      );
      _activeOverlayCount += 1;
      rootOverlay.insert(entry);
      debugPrint('CATDEX_CARD_REVEAL_OVERLAY_MOUNTED');
      try {
        await firstFrame.future;
        await result.future;
      } finally {
        if (entry.mounted) {
          entry
            ..remove()
            ..dispose();
        }
        _activeOverlayCount = (_activeOverlayCount - 1).clamp(0, 1 << 20);
        sessionLease.release();
        await _coordinator.waitUntilIdle();
        debugPrint('CATDEX_CELEBRATION_OVERLAY_REMOVED');
      }
    });
    return result.future;
  }
}

class CardRevealSessionOverlay extends StatefulWidget {
  const CardRevealSessionOverlay({
    required this.session,
    required this.celebrationCoordinator,
    required this.onFirstFrame,
    required this.onAction,
    this.onRewardSequenceCompleted,
    super.key,
  });

  final CardRevealSession session;
  final CatDexCelebrationCoordinator celebrationCoordinator;
  final VoidCallback onFirstFrame;
  final ValueChanged<CardRevealSessionAction> onAction;
  final ValueChanged<CardRevealRewardCue>? onRewardSequenceCompleted;

  @override
  State<CardRevealSessionOverlay> createState() =>
      _CardRevealSessionOverlayState();
}

class _CardRevealSessionOverlayState extends State<CardRevealSessionOverlay> {
  bool _revealReady = false;
  bool _imageFailed = false;

  bool get _rewardPending {
    final cue = widget.session.rewardCue;
    return cue != null &&
        (cue.hasEarnedXp || cue.hasMissionReward || cue.hasLevelUp);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      debugPrint('CATDEX_CARD_REVEAL_FIRST_FRAME');
      widget.onFirstFrame();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final effect = cardRevealEffectFor(
      rarity: widget.session.rarity,
      event: widget.session.cardType != CardRevealSessionType.normal,
      premiumEvent:
          widget.session.cardType == CardRevealSessionType.premiumEvent,
    );
    final accent = _accentFor(effect);
    return Material(
      key: const Key('card_reveal_session_overlay'),
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.session.cardType == CardRevealSessionType.normal
                ? const [
                    Color(0xFF111827),
                    Color(0xFF0B1020),
                    Color(0xFF050816),
                  ]
                : const [
                    Color(0xFF120A24),
                    Color(0xFF261147),
                    Color(0xFF090713),
                  ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 48).clamp(220.0, 420.0);
              final cardHeight = (cardWidth * 2100 / 1500).clamp(
                308.0,
                constraints.maxHeight * 0.68,
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: Column(
                  children: [
                    Text(
                      widget.session.cardType == CardRevealSessionType.normal
                          ? 'CATDEX'
                          : l10n.eventCardBadge.toUpperCase(),
                      style: TextStyle(
                        color: accent,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: cardWidth,
                          height: cardHeight,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CardRevealSurface(
                              key: ValueKey(widget.session.sessionId),
                              revealKey: widget.session.sessionId,
                              forceNewReveal: true,
                              playExistingEntrance: false,
                              prepareArtwork: (context) => preloadCardArtwork(
                                context,
                                widget.session.finalImageProvider,
                              ),
                              onArtworkPreloadError: (_) {
                                if (mounted) {
                                  setState(() => _imageFailed = true);
                                }
                              },
                              effect: effect,
                              celebrationCoordinator:
                                  widget.celebrationCoordinator,
                              celebrationLabel:
                                  widget.session.localizedRarityLabel,
                              rewardCue: widget.session.rewardCue,
                              onRevealCompleted: () {
                                if (!_rewardPending && mounted) {
                                  setState(() => _revealReady = true);
                                }
                              },
                              onRewardSequenceCompleted: (cue) {
                                widget.onRewardSequenceCompleted?.call(cue);
                                if (mounted) {
                                  setState(() => _revealReady = true);
                                }
                              },
                              fallback: const _RevealFallback(),
                              artwork: Image(
                                key: const Key('card_reveal_session_artwork'),
                                image: widget.session.finalImageProvider,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const _RevealImageError();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _imageFailed
                          ? _RevealActions(
                              key: const Key('card_reveal_error_actions'),
                              showOpen: false,
                              onOpen: null,
                              onContinue: () => widget.onAction(
                                CardRevealSessionAction.continueToAlbum,
                              ),
                            )
                          : _revealReady
                          ? _RevealActions(
                              key: const Key('card_reveal_actions'),
                              showOpen: true,
                              onOpen: () => widget.onAction(
                                CardRevealSessionAction.openCard,
                              ),
                              onContinue: () => widget.onAction(
                                CardRevealSessionAction.continueToAlbum,
                              ),
                            )
                          : const Text(
                              'Stiamo preparando la tua carta...',
                              key: Key('card_reveal_session_loading'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFFE5E7EB),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RevealActions extends StatelessWidget {
  const _RevealActions({
    required this.showOpen,
    required this.onOpen,
    required this.onContinue,
    super.key,
  });

  final bool showOpen;
  final VoidCallback? onOpen;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (showOpen)
          FilledButton.icon(
            key: const Key('card_reveal_open_card'),
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_full_rounded),
            label: Text(l10n.eventOpenCard),
          ),
        OutlinedButton(
          key: const Key('card_reveal_continue'),
          onPressed: onContinue,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF8FAFC),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          child: Text(l10n.continueAction),
        ),
      ],
    );
  }
}

class _RevealFallback extends StatelessWidget {
  const _RevealFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF111827),
      child: Center(
        child: Icon(Icons.pets_rounded, size: 58, color: Color(0xFFF8FAFC)),
      ),
    );
  }
}

class _RevealImageError extends StatelessWidget {
  const _RevealImageError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF111827),
      child: Center(
        child: Icon(Icons.broken_image_rounded, color: Color(0xFFF8FAFC)),
      ),
    );
  }
}

Color _accentFor(CardRevealEffect effect) {
  return switch (effect) {
    CardRevealEffect.common => const Color(0xFFF8FAFC),
    CardRevealEffect.uncommon => const Color(0xFF54D2A5),
    CardRevealEffect.rare => const Color(0xFF60A5FA),
    CardRevealEffect.epic => const Color(0xFFC084FC),
    CardRevealEffect.legendary => const Color(0xFFFACC15),
    CardRevealEffect.event => const Color(0xFFFB923C),
    CardRevealEffect.premiumEvent => const Color(0xFFA78BFA),
  };
}
