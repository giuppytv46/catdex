import 'dart:async';

import 'package:catdex/shared/celebrations/catdex_celebration_feedback.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_overlay.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CatDexCelebrationLease {
  CatDexCelebrationLease._(this._coordinator, this.type);

  final CatDexCelebrationCoordinator _coordinator;
  final CatDexCelebrationType type;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _coordinator._releaseLease();
  }
}

class CatDexCelebrationCoordinator {
  CatDexCelebrationCoordinator({
    this.haptics = const SystemCatDexCelebrationHaptics(),
    this.soundHooks = const NoOpCatDexCelebrationSoundHooks(),
  });

  static final CatDexCelebrationCoordinator instance =
      CatDexCelebrationCoordinator();

  final CatDexCelebrationHaptics haptics;
  final CatDexCelebrationSoundHooks soundHooks;

  Future<void> _queue = Future<void>.value();
  final List<Completer<void>> _idleWaiters = [];
  final ValueNotifier<int> _activityVersion = ValueNotifier<int>(0);
  bool _activitySignalScheduled = false;
  int _activeLeases = 0;
  int _queuedOverlays = 0;
  bool _overlayActive = false;
  OverlayState? _activeOverlay;
  OverlayEntry? _activeEntry;
  Completer<void>? _activeAnimationCompletion;

  bool get isBusy => _activeLeases > 0 || _queuedOverlays > 0 || _overlayActive;
  ValueListenable<int> get activityListenable => _activityVersion;

  CatDexCelebrationLease acquire(CatDexCelebrationType type) {
    _activeLeases += 1;
    _signalActivityChange();
    return CatDexCelebrationLease._(this, type);
  }

  Future<void> celebrate(
    BuildContext context,
    CatDexCelebrationRequest request, {
    VoidCallback? onEssentialCompleted,
  }) {
    final requestedOverlay = Overlay.maybeOf(context, rootOverlay: true);
    if (_overlayActive &&
        requestedOverlay != null &&
        requestedOverlay != _activeOverlay) {
      _cancelActiveOverlay();
    }
    final result = Completer<void>();
    _queuedOverlays += 1;
    _signalActivityChange();
    _queue = _queue
        .then((_) async {
          _queuedOverlays -= 1;
          _signalActivityChange();
          if (!context.mounted) {
            if (!result.isCompleted) result.complete();
            _notifyIdleIfNeeded();
            return;
          }
          final overlay = Overlay.maybeOf(context, rootOverlay: true);
          if (overlay == null) {
            if (!result.isCompleted) result.complete();
            _notifyIdleIfNeeded();
            return;
          }
          _overlayActive = true;
          _signalActivityChange();
          final animationCompleted = Completer<void>();
          late final OverlayEntry entry;
          entry = OverlayEntry(
            builder: (_) => CatDexCelebrationOverlay(
              request: request,
              haptics: haptics,
              soundHooks: soundHooks,
              onEssentialCompleted: onEssentialCompleted,
              onCompleted: () {
                if (!animationCompleted.isCompleted) {
                  animationCompleted.complete();
                }
              },
            ),
          );
          _activeOverlay = overlay;
          _activeEntry = entry;
          _activeAnimationCompletion = animationCompleted;
          overlay.insert(entry);
          try {
            await animationCompleted.future;
          } finally {
            if (entry.mounted) {
              entry
                ..remove()
                ..dispose();
              debugPrint('CATDEX_CELEBRATION_OVERLAY_REMOVED');
            }
            if (identical(_activeEntry, entry)) {
              _activeOverlay = null;
              _activeEntry = null;
              _activeAnimationCompletion = null;
            }
            _overlayActive = false;
            _signalActivityChange();
            if (!result.isCompleted) result.complete();
            _notifyIdleIfNeeded();
          }
        })
        .catchError((Object error, StackTrace stackTrace) {
          _overlayActive = false;
          _signalActivityChange();
          if (!result.isCompleted) result.complete();
          _notifyIdleIfNeeded();
          debugPrint(
            'CATDEX_CELEBRATION_COMPLETED '
            'type=${request.type.name} fallback=${error.runtimeType}',
          );
        });
    return result.future;
  }

  Future<void> waitUntilIdle() {
    if (!isBusy) return Future<void>.value();
    final waiter = Completer<void>();
    _idleWaiters.add(waiter);
    return waiter.future;
  }

  void _releaseLease() {
    if (_activeLeases > 0) _activeLeases -= 1;
    _signalActivityChange();
    _notifyIdleIfNeeded();
  }

  void _cancelActiveOverlay() {
    final completion = _activeAnimationCompletion;
    if (completion != null && !completion.isCompleted) {
      completion.complete();
    }
  }

  void _notifyIdleIfNeeded() {
    if (isBusy || _idleWaiters.isEmpty) return;
    final waiters = List<Completer<void>>.of(_idleWaiters);
    _idleWaiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
  }

  void _signalActivityChange() {
    if (_activitySignalScheduled) return;
    _activitySignalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _activitySignalScheduled = false;
      _activityVersion.value += 1;
    });
  }
}
