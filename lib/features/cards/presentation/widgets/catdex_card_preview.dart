import 'dart:io';

import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class CatDexMiniCardPreview extends StatelessWidget {
  const CatDexMiniCardPreview({
    required this.entry,
    required this.onTap,
    required this.onGenerate,
    required this.onRegenerate,
    required this.generating,
    this.generatingLabel,
    super.key,
  });

  final CatDexCollectionEntry entry;
  final VoidCallback onTap;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final bool generating;
  final String? generatingLabel;

  @override
  Widget build(BuildContext context) {
    final discovery = entry.discovery;
    final displayData = discovery == null
        ? null
        : const CatDisplayFormatter().fromDiscovery(
            discovery,
            fallbackName: entry.displayName,
          );
    final name =
        displayData?.displayName ??
        discovery?.customName ??
        entry.displayName ??
        'Carta CatDex';
    final species = displayData?.displaySpecies ?? entry.species.displayName;
    final imageSource = _cardImageSource(entry);

    debugPrint('CATDEX_BINDER_CARD_ID ${discovery?.id ?? '-'}');
    debugPrint('CATDEX_BINDER_CARD_NAME $name');
    debugPrint('CATDEX_BINDER_CARD_RENDER_MODE external_image');

    return Semantics(
      button: true,
      label: '$name, $species',
      child: GestureDetector(
        onTap: imageSource == null ? null : onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ink,
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: imageSource == null
                ? _GenerateCardPlaceholder(
                    generating: generating,
                    generatingLabel: generatingLabel,
                    name: name,
                    onGenerate: onGenerate,
                  )
                : _GeneratedCardPreview(
                    generating: generating,
                    generatingLabel: generatingLabel,
                    onRegenerate: onRegenerate,
                    source: imageSource,
                  ),
          ),
        ),
      ),
    );
  }
}

String? _cardImageSource(CatDexCollectionEntry entry) {
  final card = entry.discovery?.card;
  final candidates = [card?.cardImageUrl, card?.cardImagePath];
  for (final candidate in candidates) {
    if (candidate != null && candidate.trim().isNotEmpty) {
      return candidate;
    }
  }

  return null;
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _CardImageFallback(),
      );
    }

    return Image.file(
      File(source),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _CardImageFallback(),
    );
  }
}

class _GeneratedCardPreview extends StatelessWidget {
  const _GeneratedCardPreview({
    required this.generating,
    required this.generatingLabel,
    required this.onRegenerate,
    required this.source,
  });

  final bool generating;
  final String? generatingLabel;
  final VoidCallback onRegenerate;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _CardImage(source: source),
        Positioned(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: FilledButton(
            onPressed: generating ? null : onRegenerate,
            child: Text(
              generating ? generatingLabel ?? 'Rigenero...' : 'Rigenera carta',
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerateCardPlaceholder extends StatelessWidget {
  const _GenerateCardPlaceholder({
    required this.generating,
    required this.generatingLabel,
    required this.name,
    required this.onGenerate,
  });

  final bool generating;
  final String? generatingLabel;
  final String name;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primaryPurple,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.style_rounded,
              color: AppColors.white,
              size: 36,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: generating ? null : onGenerate,
              child: Text(
                generating ? generatingLabel ?? 'Genero...' : 'Genera carta',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.primaryPurple,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.white,
          size: 40,
        ),
      ),
    );
  }
}
