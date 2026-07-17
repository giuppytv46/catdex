import 'package:flutter/material.dart';

enum CatDexCelebrationType {
  discoveryComplete,
  addedToCatDex,
  normalCardGenerated,
  eventCardGenerated,
  missionComplete,
  achievementUnlocked,
  levelUp,
}

enum CatDexCelebrationIntensity { reduced, standard, intense }

enum CatDexCelebrationPalette {
  discovery,
  catDex,
  common,
  uncommon,
  rare,
  epic,
  legendary,
  halloween,
  halloweenPremium,
}

@immutable
class CatDexCelebrationTheme {
  const CatDexCelebrationTheme({
    required this.palette,
    required this.colors,
    required this.particleCount,
    required this.fireworkCount,
    required this.shockwaveCount,
    required this.shakeAmplitude,
    required this.duration,
    this.longTrails = false,
    this.lightRays = false,
    this.extraHapticPulse = false,
  });

  factory CatDexCelebrationTheme.forPalette(
    CatDexCelebrationPalette palette, {
    CatDexCelebrationIntensity intensity = CatDexCelebrationIntensity.intense,
    bool reduceMotion = false,
  }) {
    final base = switch (palette) {
      CatDexCelebrationPalette.discovery => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.discovery,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFF7C3AED),
          Color(0xFF54D2A5),
          Color(0xFFFACC15),
        ],
        particleCount: 24,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 3,
        duration: Duration(milliseconds: 1800),
      ),
      CatDexCelebrationPalette.catDex => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.catDex,
        colors: [
          Color(0xFF54D2A5),
          Color(0xFF7C3AED),
          Color(0xFFFACC15),
          Color(0xFFFFFFFF),
        ],
        particleCount: 28,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 3.4,
        duration: Duration(milliseconds: 1850),
        lightRays: true,
      ),
      CatDexCelebrationPalette.common => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.common,
        colors: [Color(0xFFFFFFFF), Color(0xFF86EFAC), Color(0xFF54D2A5)],
        particleCount: 20,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 2.4,
        duration: Duration(milliseconds: 2200),
      ),
      CatDexCelebrationPalette.uncommon => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.uncommon,
        colors: [Color(0xFF67E8F9), Color(0xFF22D3EE), Color(0xFFFFFFFF)],
        particleCount: 24,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 2.8,
        duration: Duration(milliseconds: 2250),
      ),
      CatDexCelebrationPalette.rare => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.rare,
        colors: [Color(0xFF60A5FA), Color(0xFF2563EB), Color(0xFFFFFFFF)],
        particleCount: 28,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 3.4,
        duration: Duration(milliseconds: 2350),
        longTrails: true,
        lightRays: true,
      ),
      CatDexCelebrationPalette.epic => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.epic,
        colors: [Color(0xFFC084FC), Color(0xFF7C3AED), Color(0xFFFFFFFF)],
        particleCount: 30,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 4,
        duration: Duration(milliseconds: 2450),
        longTrails: true,
        lightRays: true,
      ),
      CatDexCelebrationPalette.legendary => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.legendary,
        colors: [
          Color(0xFFFFF3A3),
          Color(0xFFFACC15),
          Color(0xFFF59E0B),
          Color(0xFFFFFFFF),
        ],
        particleCount: 32,
        fireworkCount: 2,
        shockwaveCount: 2,
        shakeAmplitude: 5,
        duration: Duration(milliseconds: 2650),
        longTrails: true,
        lightRays: true,
        extraHapticPulse: true,
      ),
      CatDexCelebrationPalette.halloween => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.halloween,
        colors: [Color(0xFFFFB347), Color(0xFFF97316), Color(0xFFFACC15)],
        particleCount: 36,
        fireworkCount: 2,
        shockwaveCount: 1,
        shakeAmplitude: 4,
        duration: Duration(milliseconds: 2500),
        longTrails: true,
        lightRays: true,
      ),
      CatDexCelebrationPalette.halloweenPremium => const CatDexCelebrationTheme(
        palette: CatDexCelebrationPalette.halloweenPremium,
        colors: [
          Color(0xFFF97316),
          Color(0xFFA855F7),
          Color(0xFFFACC15),
          Color(0xFFFFFFFF),
        ],
        particleCount: 36,
        fireworkCount: 2,
        shockwaveCount: 2,
        shakeAmplitude: 4.6,
        duration: Duration(milliseconds: 2650),
        longTrails: true,
        lightRays: true,
        extraHapticPulse: true,
      ),
    };
    return base._withAccessibility(
      intensity: intensity,
      reduceMotion: reduceMotion,
    );
  }

  final CatDexCelebrationPalette palette;
  final List<Color> colors;
  final int particleCount;
  final int fireworkCount;
  final int shockwaveCount;
  final double shakeAmplitude;
  final Duration duration;
  final bool longTrails;
  final bool lightRays;
  final bool extraHapticPulse;

  CatDexCelebrationTheme boundedForType(CatDexCelebrationType type) {
    final particleLimit = switch (type) {
      CatDexCelebrationType.discoveryComplete => 24,
      CatDexCelebrationType.addedToCatDex => 28,
      CatDexCelebrationType.normalCardGenerated => 32,
      CatDexCelebrationType.eventCardGenerated => 36,
      CatDexCelebrationType.missionComplete ||
      CatDexCelebrationType.levelUp => 24,
      CatDexCelebrationType.achievementUnlocked => 16,
    };
    return CatDexCelebrationTheme(
      palette: palette,
      colors: colors,
      particleCount: particleCount.clamp(0, particleLimit),
      fireworkCount: fireworkCount.clamp(0, 2),
      shockwaveCount: shockwaveCount.clamp(0, 2),
      shakeAmplitude: shakeAmplitude,
      duration: duration,
      longTrails: longTrails,
      lightRays: lightRays,
      extraHapticPulse: extraHapticPulse,
    );
  }

  CatDexCelebrationTheme _withAccessibility({
    required CatDexCelebrationIntensity intensity,
    required bool reduceMotion,
  }) {
    if (reduceMotion || intensity == CatDexCelebrationIntensity.reduced) {
      return CatDexCelebrationTheme(
        palette: palette,
        colors: colors,
        particleCount: particleCount.clamp(0, 8),
        fireworkCount: 0,
        shockwaveCount: 1,
        shakeAmplitude: 0,
        duration: const Duration(milliseconds: 760),
      );
    }
    if (intensity == CatDexCelebrationIntensity.standard) {
      return CatDexCelebrationTheme(
        palette: palette,
        colors: colors,
        particleCount: (particleCount * 0.7).round(),
        fireworkCount: (fireworkCount * 0.65).ceil(),
        shockwaveCount: 1,
        shakeAmplitude: shakeAmplitude * 0.55,
        duration: Duration(
          milliseconds: (duration.inMilliseconds * 0.88).round(),
        ),
        lightRays: lightRays,
      );
    }
    return this;
  }
}

@immutable
class CatDexCelebrationRequest {
  const CatDexCelebrationRequest({
    required this.type,
    required this.theme,
    required this.title,
    this.subtitle,
    this.semanticLabel,
    this.seed = 73021,
    this.intensity = CatDexCelebrationIntensity.intense,
    this.reduceMotion = false,
    this.badgeIcon,
  });

  final CatDexCelebrationType type;
  final CatDexCelebrationTheme theme;
  final String title;
  final String? subtitle;
  final String? semanticLabel;
  final int seed;
  final CatDexCelebrationIntensity intensity;
  final bool reduceMotion;
  final IconData? badgeIcon;
}
