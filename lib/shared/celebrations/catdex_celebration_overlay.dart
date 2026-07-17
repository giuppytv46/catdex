import 'dart:async';
import 'dart:math' as math;

import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_painters.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';

class CatDexCelebrationOverlay extends StatefulWidget {
  const CatDexCelebrationOverlay({
    required this.request,
    required this.onCompleted,
    this.onEssentialCompleted,
    this.haptics = const SystemCatDexCelebrationHaptics(),
    this.soundHooks = const NoOpCatDexCelebrationSoundHooks(),
    super.key,
  });

  final CatDexCelebrationRequest request;
  final VoidCallback onCompleted;
  final VoidCallback? onEssentialCompleted;
  final CatDexCelebrationHaptics haptics;
  final CatDexCelebrationSoundHooks soundHooks;

  @override
  State<CatDexCelebrationOverlay> createState() =>
      _CatDexCelebrationOverlayState();
}

class _CatDexCelebrationOverlayState extends State<CatDexCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CatDexCelebrationTheme _theme;
  late CatDexCelebrationScene _scene;
  late CatDexCelebrationPainter _painter;
  bool _reduceMotion = false;
  bool _essentialCompleted = false;
  bool _explosionTriggered = false;
  bool _fireworksTriggered = false;
  bool _revealHapticTriggered = false;
  bool _premiumHapticTriggered = false;
  bool _reportedCompleted = false;

  @override
  void initState() {
    super.initState();
    _theme = widget.request.theme.boundedForType(widget.request.type);
    _scene = CatDexCelebrationScene.generate(
      theme: _theme,
      seed: widget.request.seed,
    );
    _controller = AnimationController(vsync: this, duration: _theme.duration)
      ..addListener(_handleProgress)
      ..addStatusListener(_handleStatus);
    _painter = CatDexCelebrationPainter(
      progress: _controller,
      scene: _scene,
      theme: _theme,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.maybeOf(context);
    final nextReduceMotion =
        widget.request.reduceMotion ||
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (_controller.isAnimating || nextReduceMotion == _reduceMotion) return;
    _reduceMotion = nextReduceMotion;
    _theme = CatDexCelebrationTheme.forPalette(
      widget.request.theme.palette,
      intensity: widget.request.intensity,
      reduceMotion: _reduceMotion,
    ).boundedForType(widget.request.type);
    _scene = CatDexCelebrationScene.generate(
      theme: _theme,
      seed: widget.request.seed,
    );
    _controller.duration = _theme.duration;
    _painter = CatDexCelebrationPainter(
      progress: _controller,
      scene: _scene,
      theme: _theme,
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleProgress)
      ..removeStatusListener(_handleStatus)
      ..dispose();
    widget.soundHooks.stopAll();
    widget.haptics.cancel();
    _complete();
    debugPrint('CATDEX_CELEBRATION_CONTROLLERS_DISPOSED');
    super.dispose();
  }

  void _start() {
    if (!mounted) return;
    if (_reduceMotion) {
      debugPrint('CATDEX_CELEBRATION_REDUCE_MOTION_ACTIVE');
    }
    debugPrint(
      'CATDEX_CELEBRATION_STARTED '
      'type=${widget.request.type.name} '
      'intensity=${_reduceMotion ? 'reduced' : widget.request.intensity.name}',
    );
    debugPrint(
      'CATDEX_CELEBRATION_MEMORY_PROFILE type=${widget.request.type.name}',
    );
    debugPrint(
      'CATDEX_CELEBRATION_PARTICLE_COUNT count=${_scene.totalParticleCount}',
    );
    unawaited(_triggerHaptic(CatDexCelebrationHapticEvent.preparation));
    widget.soundHooks.play(_chargeSound(widget.request.type));
    unawaited(_controller.forward(from: 0));
  }

  void _handleProgress() {
    final progress = _controller.value;
    if (!_explosionTriggered && progress >= 0.16) {
      _explosionTriggered = true;
      debugPrint(
        'CATDEX_CELEBRATION_EXPLOSION_TRIGGERED '
        'type=${widget.request.type.name}',
      );
      debugPrint('CATDEX_CELEBRATION_SHOCKWAVE_TRIGGERED');
      widget.soundHooks.play(_explosionSound(widget.request.type));
      unawaited(
        _triggerHaptic(
          _isCard(widget.request.type)
              ? CatDexCelebrationHapticEvent.impact
              : CatDexCelebrationHapticEvent.mediumImpact,
        ),
      );
    }
    if (!_essentialCompleted && progress >= 0.34) {
      _essentialCompleted = true;
      widget.onEssentialCompleted?.call();
    }
    if (!_fireworksTriggered && progress >= 0.36) {
      _fireworksTriggered = true;
      for (var index = 0; index < _theme.fireworkCount; index += 1) {
        debugPrint('CATDEX_CELEBRATION_FIREWORK_TRIGGERED index=$index');
      }
      widget.soundHooks.play(CatDexCelebrationSoundEvent.fireworks);
    }
    if (!_revealHapticTriggered && progress >= 0.50) {
      _revealHapticTriggered = true;
      unawaited(
        _triggerHaptic(
          widget.request.type == CatDexCelebrationType.addedToCatDex
              ? CatDexCelebrationHapticEvent.successStamp
              : CatDexCelebrationHapticEvent.reveal,
        ),
      );
      if (_isCard(widget.request.type)) {
        widget.soundHooks.play(CatDexCelebrationSoundEvent.cardFlip);
      }
    }
    if (!_premiumHapticTriggered &&
        _theme.extraHapticPulse &&
        progress >= 0.68) {
      _premiumHapticTriggered = true;
      unawaited(_triggerHaptic(CatDexCelebrationHapticEvent.premiumAccent));
      widget.soundHooks.play(CatDexCelebrationSoundEvent.legendaryReveal);
    }
  }

  void _handleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    debugPrint(
      'CATDEX_CELEBRATION_COMPLETED type=${widget.request.type.name}',
    );
    _complete();
  }

  void _complete() {
    if (_reportedCompleted) return;
    _reportedCompleted = true;
    widget.onCompleted();
  }

  Future<void> _triggerHaptic(CatDexCelebrationHapticEvent event) async {
    debugPrint(
      'CATDEX_CELEBRATION_HAPTIC_TRIGGERED type=${event.name}',
    );
    await widget.haptics.trigger(event);
  }

  void _speedUp() {
    if (!_essentialCompleted || !_controller.isAnimating) return;
    unawaited(
      _controller.animateTo(
        1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        liveRegion: true,
        label: widget.request.semanticLabel ?? widget.request.title,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final dim = _reduceMotion
                ? 0.10 * (1 - progress)
                : 0.24 * math.sin(math.pi * progress).clamp(0.0, 1.0);
            final shake = _shakeOffset(progress);
            final titleProgress = const Interval(
              0.28,
              0.66,
              curve: Curves.easeOutBack,
            ).transform(progress);
            final titleFade = progress <= 0.78
                ? titleProgress
                : (1 - ((progress - 0.78) / 0.22)).clamp(0.0, 1.0);
            final titleOpacity = titleFade.clamp(0.0, 1.0);
            return Stack(
              key: const Key('catdex_celebration_overlay'),
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: ColoredBox(
                    color: const Color(0xFF060A14).withValues(alpha: dim),
                  ),
                ),
                Transform.translate(
                  key: const Key('catdex_celebration_foreground'),
                  offset: shake,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        key: const Key('catdex_celebration_painter'),
                        painter: _painter,
                      ),
                    ),
                  ),
                ),
                if (titleOpacity > 0)
                  Align(
                    alignment: const Alignment(0, 0.58),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _speedUp,
                      child: Opacity(
                        opacity: titleOpacity,
                        child: Transform.scale(
                          scale: _reduceMotion
                              ? 1
                              : 0.78 + (0.22 * titleProgress),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 340),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xE6111827),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _theme.colors.first.withValues(
                                  alpha: 0.86,
                                ),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _theme.colors.first.withValues(
                                    alpha: 0.32,
                                  ),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.request.badgeIcon
                                    case final icon?) ...[
                                  Icon(
                                    icon,
                                    key: const Key(
                                      'catdex_celebration_badge_icon',
                                    ),
                                    color: _theme.colors.first,
                                    size: 42,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.request.title.toUpperCase(),
                                    key: const Key(
                                      'catdex_celebration_title',
                                    ),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (widget.request.subtitle case final value?)
                                  Text(
                                    value,
                                    key: const Key(
                                      'catdex_celebration_subtitle',
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.fade,
                                    style: TextStyle(
                                      color: _theme.colors.first,
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
              ],
            );
          },
        ),
      ),
    );
  }

  Offset _shakeOffset(double progress) {
    if (_reduceMotion || _theme.shakeAmplitude <= 0) return Offset.zero;
    if (progress < 0.15 || progress > 0.28) return Offset.zero;
    final local = ((progress - 0.15) / 0.13).clamp(0.0, 1.0);
    final strength = _theme.shakeAmplitude * (1 - local);
    return Offset(
      math.sin(local * math.pi * 9) * strength,
      math.cos(local * math.pi * 7) * strength * 0.55,
    );
  }
}

bool _isCard(CatDexCelebrationType type) =>
    type == CatDexCelebrationType.normalCardGenerated ||
    type == CatDexCelebrationType.eventCardGenerated;

CatDexCelebrationSoundEvent _chargeSound(CatDexCelebrationType type) {
  return switch (type) {
    CatDexCelebrationType.discoveryComplete =>
      CatDexCelebrationSoundEvent.discoveryCharge,
    CatDexCelebrationType.addedToCatDex =>
      CatDexCelebrationSoundEvent.addToCatDexWhoosh,
    _ => CatDexCelebrationSoundEvent.cardCharge,
  };
}

CatDexCelebrationSoundEvent _explosionSound(CatDexCelebrationType type) {
  return switch (type) {
    CatDexCelebrationType.discoveryComplete =>
      CatDexCelebrationSoundEvent.discoveryExplosion,
    CatDexCelebrationType.addedToCatDex =>
      CatDexCelebrationSoundEvent.addToCatDexSuccess,
    _ => CatDexCelebrationSoundEvent.cardExplosion,
  };
}
