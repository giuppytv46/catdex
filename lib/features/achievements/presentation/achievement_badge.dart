import 'package:catdex/features/achievements/domain/achievement_models.dart';
import 'package:flutter/material.dart';

@immutable
class AchievementTierStyle {
  const AchievementTierStyle({
    required this.border,
    required this.fill,
    required this.highlight,
  });

  final Color border;
  final Color fill;
  final Color highlight;
}

AchievementTierStyle achievementTierStyle(AchievementTier tier) {
  return switch (tier) {
    AchievementTier.bronze => const AchievementTierStyle(
      border: Color(0xFFB87333),
      fill: Color(0xFF3A241C),
      highlight: Color(0xFFF2B880),
    ),
    AchievementTier.silver => const AchievementTierStyle(
      border: Color(0xFFB8D8E8),
      fill: Color(0xFF1C3442),
      highlight: Color(0xFF67E8F9),
    ),
    AchievementTier.gold => const AchievementTierStyle(
      border: Color(0xFFFACC15),
      fill: Color(0xFF3D2B0B),
      highlight: Color(0xFFFFF3A3),
    ),
    AchievementTier.platinum => const AchievementTierStyle(
      border: Color(0xFFE9D5FF),
      fill: Color(0xFF262044),
      highlight: Color(0xFF99F6E4),
    ),
  };
}

IconData achievementIcon(String iconKey) => switch (iconKey) {
  'compass' => Icons.explore_rounded,
  'eye' => Icons.visibility_rounded,
  'map' => Icons.map_rounded,
  'binoculars' => Icons.travel_explore_rounded,
  'crown' || 'legendary' => Icons.workspace_premium_rounded,
  'card' => Icons.style_rounded,
  'cards' || 'album' || 'crown_card' => Icons.collections_bookmark_rounded,
  'sparkle' || 'magic' => Icons.auto_awesome_rounded,
  'diamond' => Icons.diamond_rounded,
  'pin' => Icons.location_on_rounded,
  'city' => Icons.location_city_rounded,
  'globe' => Icons.public_rounded,
  'check' => Icons.task_alt_rounded,
  'calendar' => Icons.calendar_month_rounded,
  'streak' => Icons.local_fire_department_rounded,
  'event' => Icons.celebration_rounded,
  'pumpkin' => Icons.nightlight_round,
  'witch' => Icons.auto_fix_high_rounded,
  'level' => Icons.trending_up_rounded,
  _ => Icons.pets_rounded,
};

class AchievementBadge extends StatelessWidget {
  const AchievementBadge({
    required this.definition,
    required this.unlocked,
    this.size = 56,
    super.key,
  });

  final AchievementDefinition definition;
  final bool unlocked;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = achievementTierStyle(definition.tier);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: unlocked ? style.fill : const Color(0xFF374151),
        border: Border.all(
          color: unlocked ? style.border : const Color(0xFF6B7280),
          width: 2.5,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: style.highlight.withValues(alpha: 0.28),
                  blurRadius:
                      definition.tier == AchievementTier.gold ||
                          definition.tier == AchievementTier.platinum
                      ? 16
                      : 8,
                ),
              ]
            : null,
      ),
      child: Icon(
        achievementIcon(definition.iconKey),
        size: size * 0.46,
        color: unlocked ? style.highlight : const Color(0xFF9CA3AF),
      ),
    );
  }
}
