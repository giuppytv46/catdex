import 'dart:async';
import 'dart:math' as math;

import 'package:catdex/features/cards/presentation/reveal/card_reveal_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_painters.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';

enum CardRevealEffect {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  event,
  premiumEvent,
}

typedef CardArtworkPreloader = Future<void> Function(BuildContext context);

Future<void> preloadCardArtwork<T extends Object>(
  BuildContext context,
  ImageProvider<T> provider,
) {
  final completer = Completer<void>();
  final stream = provider.resolve(createLocalImageConfiguration(context));
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (image, synchronousCall) {
      if (!completer.isCompleted) completer.complete();
      stream.removeListener(listener);
    },
    onError: (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace ?? StackTrace.current);
      }
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  return completer.future;
}

class CardRevealSurface extends StatefulWidget {
  const CardRevealSurface({
    required this.artwork,
    required this.fallback,
    required this.effect,
    this.isGenerating = false,
    this.hasError = false,
    this.forceNewReveal = false,
    this.playExistingEntrance = true,
    this.rewardCue,
    this.celebrationLabel,
    this.celebrationCoordinator,
    this.revealKey,
    this.prepareArtwork,
    this.onArtworkPreloadError,
    this.controller,
    this.onRevealCompleted,
    this.onRewardSequenceCompleted,
    super.key,
  });

  final Widget? artwork;
  final Widget fallback;
  final CardRevealEffect effect;
  final bool isGenerating;
  final bool hasError;
  final bool forceNewReveal;
  final bool playExistingEntrance;
  final CardRevealRewardCue? rewardCue;
  final String? celebrationLabel;
  final CatDexCelebrationCoordinator? celebrationCoordinator;
  final Object? revealKey;
  final CardArtworkPreloader? prepareArtwork;
  final ValueChanged<Object>? onArtworkPreloadError;
  final CardRevealController? controller;
  final VoidCallback? onRevealCompleted;
  final ValueChanged<CardRevealRewardCue>? onRewardSequenceCompleted;

  @override
  State<CardRevealSurface> createState() => _CardRevealSurfaceState();
}

class _CardRevealSurfaceState extends State<CardRevealSurface>
    with TickerProviderStateMixin {
  late final CardRevealController _controller;
  late final bool _ownsController;
  late final AnimationController _revealController;
  late final AnimationController _existingController;
  late final AnimationController _glowController;
  late final AnimationController _xpController;
  late final AnimationController _rewardController;
  late final AnimationController _levelController;

  bool _sawGeneration = false;
  bool _pendingGeneratedArtworkReveal = false;
  bool _forceRevealPlayed = false;
  bool _sequenceRunning = false;
  bool _preparingArtwork = false;
  bool _artworkReady = false;
  bool _showXpReward = false;
  bool _showMissionReward = false;
  bool _showLevelUp = false;
  String? _lastRewardId;
  CardRevealRewardCue? _activeRewardCue;
  Timer? _sequenceDelayTimer;
  Completer<void>? _sequenceDelayCompleter;

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? CardRevealController();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _existingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _xpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    );
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 820),
    );
    _sawGeneration = widget.isGenerating;
    if (widget.isGenerating) {
      debugPrint('CATDEX_CARD_GENERATION_ANIMATION_LOADING');
    }
    _artworkReady = widget.artwork != null && widget.prepareArtwork == null;
    _preparingArtwork = widget.artwork != null && widget.prepareArtwork != null;
    if (widget.rewardCue case final cue?) _controller.queueReward(cue);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startInitialState());
  }

  @override
  void didUpdateWidget(covariant CardRevealSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rewardCue != null && widget.rewardCue != oldWidget.rewardCue) {
      _controller.queueReward(widget.rewardCue!);
      if (!_sequenceRunning &&
          (_controller.state == CardRevealState.revealed ||
              _controller.state == CardRevealState.completed)) {
        unawaited(_playRewardOnly());
      }
    }
    if (widget.hasError && !oldWidget.hasError) {
      _stopGlow();
      _controller.showError();
    }
    final artworkBecameAvailable =
        oldWidget.artwork == null && widget.artwork != null;
    final generatedArtworkChanged =
        oldWidget.revealKey != widget.revealKey && widget.artwork != null;
    if (artworkBecameAvailable || generatedArtworkChanged) {
      _artworkReady = widget.prepareArtwork == null;
      _preparingArtwork = widget.prepareArtwork != null;
      if (widget.isGenerating) {
        _pendingGeneratedArtworkReveal = true;
      }
    }
    if (widget.isGenerating) {
      _sawGeneration = true;
      if (!oldWidget.isGenerating) {
        debugPrint('CATDEX_CARD_GENERATION_ANIMATION_LOADING');
      }
      _controller.showLoading();
      _startGlow();
      return;
    }
    if (oldWidget.isGenerating && !widget.isGenerating) {
      _stopGlow();
    }
    final shouldForceReveal =
        widget.forceNewReveal && !_forceRevealPlayed && widget.artwork != null;
    if (((artworkBecameAvailable || generatedArtworkChanged) &&
            _sawGeneration) ||
        _pendingGeneratedArtworkReveal ||
        shouldForceReveal) {
      _forceRevealPlayed = true;
      _pendingGeneratedArtworkReveal = false;
      unawaited(_playFullReveal());
    } else if (artworkBecameAvailable && widget.playExistingEntrance) {
      unawaited(_playExistingEntrance());
    }
  }

  @override
  void dispose() {
    _sequenceDelayTimer?.cancel();
    final delayCompleter = _sequenceDelayCompleter;
    if (delayCompleter != null && !delayCompleter.isCompleted) {
      delayCompleter.complete();
    }
    _revealController.dispose();
    _existingController.dispose();
    _glowController.dispose();
    _xpController.dispose();
    _rewardController.dispose();
    _levelController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _startInitialState() {
    if (!mounted) return;
    if (widget.isGenerating) {
      _controller.showLoading();
      _startGlow();
      return;
    }
    if (widget.hasError) {
      _controller.showError();
      return;
    }
    if (widget.artwork != null && widget.forceNewReveal) {
      _forceRevealPlayed = true;
      unawaited(_playFullReveal());
      return;
    }
    if (widget.artwork != null && widget.playExistingEntrance) {
      unawaited(_playExistingEntrance());
    }
  }

  Future<void> _playFullReveal() async {
    if (!mounted || _sequenceRunning || widget.artwork == null) return;
    _sequenceRunning = true;
    final celebrationType = _revealType == 'event'
        ? CatDexCelebrationType.eventCardGenerated
        : CatDexCelebrationType.normalCardGenerated;
    final coordinator =
        widget.celebrationCoordinator ?? CatDexCelebrationCoordinator.instance;
    final lease = coordinator.acquire(celebrationType);
    try {
      if (_artworkReady) {
        debugPrint('CATDEX_CARD_REVEAL_IMAGE_READY');
      } else if (!await _prepareArtworkIfNeeded()) {
        return;
      }
      if (!mounted) return;
      final theme = CatDexCelebrationTheme.forPalette(
        _celebrationPalette(widget.effect),
        reduceMotion: _reduceMotion,
      );
      final celebration = coordinator.celebrate(
        context,
        CatDexCelebrationRequest(
          type: celebrationType,
          theme: theme,
          title: widget.celebrationLabel ?? _defaultCelebrationLabel,
          semanticLabel: widget.celebrationLabel ?? 'Carta generata',
          seed: _stableRevealSeed(widget.revealKey),
          reduceMotion: _reduceMotion,
        ),
      );
      debugPrint('CATDEX_CARD_REVEAL_STARTED type=$_revealType');
      _controller.startReveal();
      _revealController.duration = _reduceMotion
          ? const Duration(milliseconds: 420)
          : theme.duration;
      await Future.wait<void>([
        _revealController.forward(from: 0),
        celebration,
      ]);
      if (!mounted) return;
      _controller.markRevealed();
      widget.onRevealCompleted?.call();
      await _waitForSequenceDelay(
        _reduceMotion
            ? const Duration(milliseconds: 40)
            : const Duration(milliseconds: 180),
      );
      if (!mounted) return;
      await _playQueuedReward();
      if (!mounted) return;
      _controller.complete();
      debugPrint('CATDEX_CARD_REVEAL_COMPLETED');
    } on Object {
      // Disposal can cancel a ticker. Generation and persisted rewards remain
      // authoritative and are intentionally untouched by visual cleanup.
    } finally {
      _sequenceRunning = false;
      lease.release();
    }
  }

  Future<void> _playExistingEntrance() async {
    if (!_artworkReady && !await _prepareArtworkIfNeeded()) return;
    _existingController.duration = _reduceMotion
        ? const Duration(milliseconds: 160)
        : const Duration(milliseconds: 420);
    await _existingController.forward(from: 0);
    if (!mounted) return;
    _controller
      ..markRevealed()
      ..complete();
  }

  Future<void> _playRewardOnly() async {
    if (!mounted || _sequenceRunning) return;
    _sequenceRunning = true;
    await _playQueuedReward();
    if (mounted) {
      _controller.complete();
      _sequenceRunning = false;
    }
  }

  Future<void> _playQueuedReward() async {
    var cue = _controller.takeQueuedReward();
    if (cue == null || cue.id == _lastRewardId) return;
    _lastRewardId = cue.id;
    _activeRewardCue = cue;
    if (cue.hasEarnedXp) {
      (widget.celebrationCoordinator ?? CatDexCelebrationCoordinator.instance)
          .soundHooks
          .play(
            CatDexCelebrationSoundEvent.xpGain,
          );
      setState(() => _showXpReward = true);
      _xpController.duration = _reduceMotion
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 520);
      await _xpController.forward(from: 0);
      if (!mounted) return;
      await _waitForSequenceDelay(
        _reduceMotion
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 320),
      );
      if (!mounted) return;
      setState(() => _showXpReward = false);
    }
    cue = _takeMergedQueuedReward(cue);
    _activeRewardCue = cue;
    if (cue.hasMissionReward) {
      setState(() => _showMissionReward = true);
      _rewardController.duration = _reduceMotion
          ? const Duration(milliseconds: 220)
          : const Duration(milliseconds: 560);
      await _rewardController.forward(from: 0);
      if (!mounted) return;
      await _waitForSequenceDelay(
        _reduceMotion
            ? const Duration(milliseconds: 120)
            : const Duration(milliseconds: 420),
      );
      if (!mounted) return;
      setState(() => _showMissionReward = false);
    }
    cue = _takeMergedQueuedReward(cue);
    _activeRewardCue = cue;
    if (cue.hasLevelUp) {
      debugPrint(
        'CATDEX_LEVEL_UP_CELEBRATION_STARTED level=${cue.newLevel}',
      );
      setState(() => _showLevelUp = true);
      _levelController.duration = _reduceMotion
          ? const Duration(milliseconds: 240)
          : const Duration(milliseconds: 820);
      await _levelController.forward(from: 0);
      if (!mounted) return;
      await _waitForSequenceDelay(
        _reduceMotion
            ? const Duration(milliseconds: 140)
            : const Duration(milliseconds: 520),
      );
      if (!mounted) return;
      setState(() => _showLevelUp = false);
      debugPrint('CATDEX_LEVEL_UP_CELEBRATION_COMPLETED');
    }
    _lastRewardId = cue.id;
    widget.onRewardSequenceCompleted?.call(cue);
    _activeRewardCue = null;
  }

  Future<void> _waitForSequenceDelay(Duration duration) {
    _sequenceDelayTimer?.cancel();
    final previousCompleter = _sequenceDelayCompleter;
    if (previousCompleter != null && !previousCompleter.isCompleted) {
      previousCompleter.complete();
    }
    final completer = Completer<void>();
    _sequenceDelayCompleter = completer;
    _sequenceDelayTimer = Timer(duration, () {
      if (!completer.isCompleted) completer.complete();
      if (identical(_sequenceDelayCompleter, completer)) {
        _sequenceDelayCompleter = null;
        _sequenceDelayTimer = null;
      }
    });
    return completer.future;
  }

  CardRevealRewardCue _takeMergedQueuedReward(CardRevealRewardCue cue) {
    final queued = _controller.takeQueuedReward();
    return queued == null ? cue : cue.merge(queued);
  }

  Future<bool> _prepareArtworkIfNeeded() async {
    if (widget.artwork == null) return false;
    if (_artworkReady) {
      debugPrint('CATDEX_CARD_REVEAL_IMAGE_READY');
      return true;
    }
    final prepareArtwork = widget.prepareArtwork;
    if (prepareArtwork == null) {
      _artworkReady = true;
      _preparingArtwork = false;
      debugPrint('CATDEX_CARD_REVEAL_IMAGE_READY');
      return true;
    }
    if (mounted) {
      setState(() => _preparingArtwork = true);
    }
    try {
      await prepareArtwork(context);
      if (!mounted) return false;
      setState(() {
        _artworkReady = true;
        _preparingArtwork = false;
      });
      debugPrint('CATDEX_CARD_REVEAL_IMAGE_READY');
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      setState(() {
        _artworkReady = false;
        _preparingArtwork = false;
      });
      widget.onArtworkPreloadError?.call(error);
      _controller.showError();
      debugPrint(
        'CATDEX_CARD_REVEAL_IMAGE_PRELOAD_FAILED '
        'reason=${error.runtimeType}',
      );
      return false;
    }
  }

  String get _revealType => switch (widget.effect) {
    CardRevealEffect.event || CardRevealEffect.premiumEvent => 'event',
    _ => 'normal',
  };

  void _startGlow() {
    if (!_glowController.isAnimating) {
      unawaited(_glowController.repeat(reverse: true));
    }
  }

  void _stopGlow() {
    if (_glowController.isAnimating) _glowController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _revealController,
          _existingController,
          _glowController,
          _xpController,
          _rewardController,
          _levelController,
        ]),
        builder: (context, _) {
          final artwork = widget.artwork;
          final content = artwork == null || !_artworkReady
              ? _preparingArtwork
                    ? const _PreloadingCardBack()
                    : widget.fallback
              : _buildArtwork(artwork);
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              content,
              if (widget.isGenerating && !_reduceMotion)
                IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: const Key('card_generation_energy_buildup'),
                      painter: CatDexEnergyBuildupPainter(
                        progress: _glowController.value,
                        color: _effectColor(widget.effect),
                      ),
                    ),
                  ),
                ),
              if (_showXpReward)
                _XpRewardOverlay(
                  amount: _activeRewardCue?.earnedXp ?? 0,
                  animation: _xpController,
                ),
              if (_showMissionReward)
                _MissionRewardOverlay(
                  cue: _activeRewardCue,
                  animation: _rewardController,
                ),
              if (_showLevelUp)
                _LevelUpOverlay(
                  level: _activeRewardCue?.newLevel,
                  animation: _levelController,
                  reduceMotion: _reduceMotion,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArtwork(Widget artwork) {
    if (_controller.state == CardRevealState.revealing) {
      if (_reduceMotion) {
        return FadeTransition(
          key: const Key('card_reveal_reduce_motion_fade'),
          opacity: CurvedAnimation(
            parent: _revealController,
            curve: Curves.easeOut,
          ),
          child: artwork,
        );
      }
      final progress = Curves.easeInOutCubic.transform(
        _revealController.value,
      );
      final flip = const Interval(0.18, 0.78).transform(progress);
      final angle = math.pi * (1 - flip);
      final showingBack = angle > math.pi / 2;
      final transform = Matrix4.identity()
        ..setEntry(3, 2, 0.0014)
        ..rotateY(angle);
      final scale = 0.92 + (0.08 * Curves.easeOutBack.transform(progress));
      return Opacity(
        opacity: const Interval(0, 0.16).transform(progress),
        child: Transform.scale(
          scale: scale,
          child: Transform(
            key: const Key('card_reveal_3d_flip'),
            alignment: Alignment.center,
            transform: transform,
            child: showingBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: const _CardBack(),
                  )
                : artwork,
          ),
        ),
      );
    }

    if (widget.isGenerating) {
      final glow = 0.10 + (_glowController.value * 0.12);
      return DecoratedBox(
        key: const Key('card_reveal_loading_glow'),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: _effectColor(widget.effect).withValues(alpha: glow),
              blurRadius: 18 + (_glowController.value * 14),
            ),
          ],
        ),
        child: artwork,
      );
    }

    if (_existingController.value < 1 && widget.playExistingEntrance) {
      final curved = CurvedAnimation(
        parent: _existingController,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        key: const Key('card_existing_open_fade'),
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _effectColor(widget.effect).withValues(
                    alpha: 0.18 * (1 - _existingController.value),
                  ),
                  blurRadius: 22,
                ),
              ],
            ),
            child: artwork,
          ),
        ),
      );
    }
    return artwork;
  }

  String get _defaultCelebrationLabel => switch (widget.effect) {
    CardRevealEffect.common => 'COMUNE',
    CardRevealEffect.uncommon => 'NON COMUNE',
    CardRevealEffect.rare => 'RARA',
    CardRevealEffect.epic => 'EPICA',
    CardRevealEffect.legendary => 'LEGGENDARIA',
    CardRevealEffect.event => 'EVENTO',
    CardRevealEffect.premiumEvent => 'EVENTO PREMIUM',
  };
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('card_reveal_back'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF2F245D), Color(0xFF0B1020)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB7A7FF), width: 2),
      ),
      child: const Center(
        child: Icon(Icons.pets_rounded, color: Color(0xFFF8FAFC), size: 52),
      ),
    );
  }
}

class _PreloadingCardBack extends StatelessWidget {
  const _PreloadingCardBack();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      key: Key('card_reveal_preloading_artwork'),
      fit: StackFit.expand,
      children: [
        _CardBack(),
        Center(
          child: SizedBox.square(
            dimension: 34,
            child: CircularProgressIndicator(
              color: Color(0xFFF8FAFC),
              strokeWidth: 2.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _XpRewardOverlay extends StatelessWidget {
  const _XpRewardOverlay({required this.amount, required this.animation});

  final int amount;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: '$amount XP ottenuti',
        child: Center(
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.18),
                end: Offset.zero,
              ).animate(curved),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xEE111827),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFACC15), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x66FACC15), blurRadius: 24),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                  child: Text(
                    '+$amount XP',
                    key: const Key('card_reveal_earned_xp'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionRewardOverlay extends StatelessWidget {
  const _MissionRewardOverlay({required this.cue, required this.animation});

  final CardRevealRewardCue? cue;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutBack,
    );
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1).animate(curved),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xEE111827),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF54D2A5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Missione completata',
                      key: Key('card_reveal_mission_completed'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((cue?.xp ?? 0) > 0)
                      Text(
                        '+${cue!.xp} XP',
                        style: const TextStyle(
                          color: Color(0xFF86EFAC),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelUpOverlay extends StatelessWidget {
  const _LevelUpOverlay({
    required this.level,
    required this.animation,
    required this.reduceMotion,
  });

  final int? level;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        liveRegion: true,
        label: level == null ? 'Nuovo livello' : 'Nuovo livello $level',
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!reduceMotion)
              CustomPaint(
                painter: _CelebrationPainter(progress: animation.value),
              ),
            Center(
              child: FadeTransition(
                opacity: animation,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xEE2F245D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFACC15),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LEVEL UP',
                          key: Key('card_reveal_level_up'),
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (level != null)
                          Text(
                            'Livello $level',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [
      Color(0xFFFACC15),
      Color(0xFF54D2A5),
      Color(0xFFA78BFA),
    ];
    for (var index = 0; index < 12; index += 1) {
      final x = ((index * 37) % 100) / 100 * size.width;
      final y =
          ((index * 19) % 35) / 100 * size.height +
          progress * size.height * 0.58;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 4, height: 8),
        Paint()
          ..color = colors[index % colors.length].withValues(
            alpha: 1 - progress,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

Color _effectColor(CardRevealEffect effect) {
  return switch (effect) {
    CardRevealEffect.common => Colors.white,
    CardRevealEffect.uncommon => const Color(0xFF54D2A5),
    CardRevealEffect.rare => const Color(0xFF60A5FA),
    CardRevealEffect.epic => const Color(0xFFA78BFA),
    CardRevealEffect.legendary => const Color(0xFFFACC15),
    CardRevealEffect.event => const Color(0xFFFB923C),
    CardRevealEffect.premiumEvent => const Color(0xFFF97316),
  };
}

CatDexCelebrationPalette _celebrationPalette(CardRevealEffect effect) {
  return switch (effect) {
    CardRevealEffect.common => CatDexCelebrationPalette.common,
    CardRevealEffect.uncommon => CatDexCelebrationPalette.uncommon,
    CardRevealEffect.rare => CatDexCelebrationPalette.rare,
    CardRevealEffect.epic => CatDexCelebrationPalette.epic,
    CardRevealEffect.legendary => CatDexCelebrationPalette.legendary,
    CardRevealEffect.event => CatDexCelebrationPalette.halloween,
    CardRevealEffect.premiumEvent => CatDexCelebrationPalette.halloweenPremium,
  };
}

int _stableRevealSeed(Object? value) {
  final source = value?.toString() ?? 'catdex-card';
  var result = 41;
  for (final codeUnit in source.codeUnits) {
    result = ((result * 43) + codeUnit) & 0x7FFFFFFF;
  }
  return result;
}

CardRevealEffect cardRevealEffectFor({
  required CatRarity rarity,
  bool event = false,
  bool premiumEvent = false,
}) {
  if (premiumEvent) return CardRevealEffect.premiumEvent;
  if (event) return CardRevealEffect.event;
  return switch (rarity) {
    CatRarity.common => CardRevealEffect.common,
    CatRarity.uncommon => CardRevealEffect.uncommon,
    CatRarity.rare => CardRevealEffect.rare,
    CatRarity.epic => CardRevealEffect.epic,
    CatRarity.legendary || CatRarity.mythic => CardRevealEffect.legendary,
  };
}
