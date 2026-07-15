import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

const String cardGenerationStatusTitle = 'Stiamo creando la tua carta';
const String cardGenerationStatusDefaultMessage =
    "L'operazione può richiedere fino a un minuto.";
const String cardGenerationStatusLongWaitMessage =
    'La creazione sta richiedendo più tempo del previsto, '
    'ma è ancora in corso.';

class CardGenerationStatusContent extends StatelessWidget {
  const CardGenerationStatusContent({
    required this.stateLabel,
    this.compact = false,
    super.key,
  });

  final String? stateLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final secondaryText = _messageForStateLabel(stateLabel);
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cardGenerationStatusTitle,
                  softWrap: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            secondaryText,
            softWrap: true,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.palette_rounded,
          color: AppColors.warning,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          cardGenerationStatusTitle,
          softWrap: true,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          secondaryText,
          softWrap: true,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.white.withValues(alpha: 0.76),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const CircularProgressIndicator(color: AppColors.white),
      ],
    );
  }
}

String _messageForStateLabel(String? stateLabel) {
  if (stateLabel?.contains('più tempo del previsto') ?? false) {
    return cardGenerationStatusLongWaitMessage;
  }
  return cardGenerationStatusDefaultMessage;
}
