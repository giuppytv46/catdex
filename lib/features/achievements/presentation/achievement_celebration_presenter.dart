import 'dart:math' as math;

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/achievements/domain/achievement_catalog.dart';
import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:catdex/features/achievements/presentation/achievement_badge.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:flutter/material.dart';

class AchievementCelebrationPresenter {
  const AchievementCelebrationPresenter._();

  static Future<void> present(
    BuildContext context,
    AchievementUnlockResult unlock,
  ) async {
    final definition = AchievementCatalogV1.definitions.firstWhere(
      (candidate) => candidate.achievementId == unlock.achievementId,
    );
    final l10n = CatDexLocalizations.of(context);
    debugPrint(
      'CATDEX_ACHIEVEMENT_CELEBRATION_STARTED id=${unlock.achievementId}',
    );
    final coordinator = CatDexCelebrationCoordinator.instance;
    await coordinator.waitUntilIdle();
    if (!context.mounted) return;
    await coordinator.celebrate(
      context,
      CatDexCelebrationRequest(
        type: CatDexCelebrationType.achievementUnlocked,
        theme: _achievementTheme(definition.tier),
        title: l10n.achievementUnlockedCelebration,
        subtitle:
            '${l10n.achievementText(definition.localizedTitleKey)}\n'
            '${l10n.achievementXpReward(unlock.rewardXp)}',
        badgeIcon: achievementIcon(definition.iconKey),
        semanticLabel: l10n.achievementText(definition.localizedTitleKey),
      ),
    );
    debugPrint(
      'CATDEX_ACHIEVEMENT_CELEBRATION_COMPLETED id=${unlock.achievementId}',
    );
    if (!context.mounted || !unlock.causedLevelUp) return;
    await coordinator.celebrate(
      context,
      CatDexCelebrationRequest(
        type: CatDexCelebrationType.levelUp,
        theme: _compactTheme(CatDexCelebrationPalette.legendary),
        title: 'LEVEL UP',
        subtitle: '${unlock.updatedLevel}',
        badgeIcon: Icons.trending_up_rounded,
      ),
    );
  }

  static CatDexCelebrationTheme _achievementTheme(AchievementTier tier) {
    final palette = switch (tier) {
      AchievementTier.bronze => CatDexCelebrationPalette.common,
      AchievementTier.silver => CatDexCelebrationPalette.uncommon,
      AchievementTier.gold => CatDexCelebrationPalette.legendary,
      AchievementTier.platinum => CatDexCelebrationPalette.epic,
    };
    return _compactTheme(palette);
  }

  static CatDexCelebrationTheme _compactTheme(
    CatDexCelebrationPalette palette,
  ) {
    final base = CatDexCelebrationTheme.forPalette(palette);
    return CatDexCelebrationTheme(
      palette: base.palette,
      colors: base.colors,
      particleCount: math.min(base.particleCount, 16),
      fireworkCount: 1,
      shockwaveCount: 1,
      shakeAmplitude: math.min(base.shakeAmplitude, 2),
      duration: const Duration(milliseconds: 1450),
      lightRays: base.lightRays,
    );
  }
}
