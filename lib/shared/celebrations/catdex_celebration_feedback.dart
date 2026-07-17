import 'package:flutter/services.dart';

enum CatDexCelebrationHapticEvent {
  preparation,
  mediumImpact,
  impact,
  reveal,
  premiumAccent,
  successStamp,
}

abstract interface class CatDexCelebrationHaptics {
  Future<void> trigger(CatDexCelebrationHapticEvent event);

  void cancel();
}

class SystemCatDexCelebrationHaptics implements CatDexCelebrationHaptics {
  const SystemCatDexCelebrationHaptics();

  @override
  Future<void> trigger(CatDexCelebrationHapticEvent event) async {
    try {
      await switch (event) {
        CatDexCelebrationHapticEvent.preparation =>
          HapticFeedback.lightImpact(),
        CatDexCelebrationHapticEvent.mediumImpact =>
          HapticFeedback.mediumImpact(),
        CatDexCelebrationHapticEvent.impact => HapticFeedback.heavyImpact(),
        CatDexCelebrationHapticEvent.reveal => HapticFeedback.mediumImpact(),
        CatDexCelebrationHapticEvent.premiumAccent =>
          HapticFeedback.mediumImpact(),
        CatDexCelebrationHapticEvent.successStamp =>
          HapticFeedback.selectionClick(),
      };
    } on Object {
      // Haptics are optional and must never interrupt the success flow.
    }
  }

  @override
  void cancel() {}
}

class NoOpCatDexCelebrationHaptics implements CatDexCelebrationHaptics {
  const NoOpCatDexCelebrationHaptics();

  @override
  Future<void> trigger(CatDexCelebrationHapticEvent event) async {}

  @override
  void cancel() {}
}

enum CatDexCelebrationSoundEvent {
  discoveryCharge,
  discoveryExplosion,
  addToCatDexWhoosh,
  addToCatDexSuccess,
  cardCharge,
  cardExplosion,
  cardFlip,
  fireworks,
  xpGain,
  legendaryReveal,
}

abstract interface class CatDexCelebrationSoundHooks {
  void play(CatDexCelebrationSoundEvent event);

  void stopAll();
}

class NoOpCatDexCelebrationSoundHooks implements CatDexCelebrationSoundHooks {
  const NoOpCatDexCelebrationSoundHooks();

  @override
  void play(CatDexCelebrationSoundEvent event) {}

  @override
  void stopAll() {}
}
