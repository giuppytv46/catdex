import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class UsageStatusChip extends StatelessWidget {
  const UsageStatusChip({
    required this.summary,
    required this.label,
    required this.icon,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.textColor,
    super.key,
  });

  final MonetizationStatusSummary summary;
  final String label;
  final IconData icon;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final premium = summary.isPremium;
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (premium
                ? AppColors.primaryPurple.withValues(alpha: 0.12)
                : AppColors.skyBlue.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              borderColor ??
              (premium
                  ? AppColors.primaryPurple.withValues(alpha: 0.30)
                  : AppColors.skyBlue.withValues(alpha: 0.30)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color:
                  iconColor ??
                  (premium ? AppColors.primaryPurple : AppColors.skyBlue),
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: textColor ?? AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
