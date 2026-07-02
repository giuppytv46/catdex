import 'package:catdex/features/cards/presentation/widgets/catdex_image_resolver.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class CatDexCardArtwork extends StatelessWidget {
  const CatDexCardArtwork({
    required this.resolvedImage,
    this.logPrefix = 'CATDEX_CARD_IMAGE_SOURCE',
    this.compact = false,
    this.showPlaceholderLabel = true,
    super.key,
  });

  final CatDexResolvedImage resolvedImage;
  final String logPrefix;
  final bool compact;
  final bool showPlaceholderLabel;

  @override
  Widget build(BuildContext context) {
    // TODO(CatDex): remove background from cat photo
    // TODO(CatDex): generate cutoutImagePath
    // TODO(CatDex): place cat cutout over illustrated card background
    debugPrint(
      'CATDEX_CARD_DISCOVERY_JSON ${resolvedImage.discoveryDebugJson}',
    );
    debugPrint('CATDEX_CARD_IMAGE_CANDIDATES ${resolvedImage.candidates}');
    debugPrint('$logPrefix ${resolvedImage.source}');
    debugPrint('CATDEX_CARD_SELECTED_IMAGE ${resolvedImage.path ?? '-'}');
    debugPrint(
      'CATDEX_CARD_CUTOUT_PATH '
      '${resolvedImage.isCutout ? resolvedImage.path : '-'}',
    );
    debugPrint(
      'CATDEX_CARD_DISPLAY_PHOTO_PATH ${_candidateValue('displayPhotoPath')}',
    );
    debugPrint(
      'CATDEX_CARD_ORIGINAL_PHOTO_PATH ${_candidateValue('originalPhotoPath')}',
    );
    debugPrint(
      'CATDEX_CARD_USING_PLACEHOLDER ${resolvedImage.usesPlaceholder}',
    );
    if (resolvedImage.usesPlaceholder) {
      debugPrint(
        'CATDEX_CARD_PLACEHOLDER_REASON ${resolvedImage.placeholderReason}',
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(compact ? 10 : 18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (resolvedImage.provider == null)
            _PawPlaceholder(showLabel: showPlaceholderLabel)
          else
            Image(
              image: resolvedImage.provider!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  _PawPlaceholder(showLabel: showPlaceholderLabel),
            ),
        ],
      ),
    );
  }

  String _candidateValue(String source) {
    for (final candidate in resolvedImage.candidates) {
      if (candidate.startsWith('$source=')) {
        return candidate.substring(source.length + 1);
      }
    }

    return '-';
  }
}

class _PawPlaceholder extends StatelessWidget {
  const _PawPlaceholder({required this.showLabel});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryGreen.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pets_rounded,
              color: AppColors.white,
              size: 54,
            ),
            if (showLabel) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Foto mancante',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
