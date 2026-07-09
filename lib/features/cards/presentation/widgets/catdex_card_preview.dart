import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/cards/presentation/rarity_debug_controls.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
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
    required this.hasGenerationError,
    this.generatingLabel,
    this.generateLabel,
    this.cacheBustVersion,
    this.imageSourceOverride,
    this.debugRarityOverride,
    this.onDebugRarityOverrideSelected,
    super.key,
  });

  final CatDexCollectionEntry entry;
  final VoidCallback onTap;
  final VoidCallback onGenerate;
  final VoidCallback onRegenerate;
  final bool generating;
  final bool hasGenerationError;
  final String? generatingLabel;
  final String? generateLabel;
  final int? cacheBustVersion;
  final String? imageSourceOverride;
  final CatRarity? debugRarityOverride;
  final ValueChanged<CatRarity>? onDebugRarityOverrideSelected;

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
    final imageSource =
        imageSourceOverride ??
        _cardImageSource(
          entry,
          cacheBustVersion: cacheBustVersion,
        );

    debugPrint('CATDEX_BINDER_CARD_ID ${discovery?.id ?? '-'}');
    debugPrint('CATDEX_BINDER_CARD_NAME $name');
    debugPrint('CATDEX_BINDER_CARD_RENDER_MODE external_image');

    return Semantics(
      button: true,
      label: '$name, $species',
      child: GestureDetector(
        onTap: onTap,
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
                    hasGenerationError: hasGenerationError,
                    debugRarityOverride: debugRarityOverride,
                    onDebugRarityOverrideSelected:
                        onDebugRarityOverrideSelected,
                    generateLabel: generateLabel,
                    name: name,
                    onGenerate: onGenerate,
                  )
                : _GeneratedCardPreview(
                    generating: generating,
                    generatingLabel: generatingLabel,
                    debugRarityOverride: debugRarityOverride,
                    onDebugRarityOverrideSelected:
                        onDebugRarityOverrideSelected,
                    onRegenerate: onRegenerate,
                    source: imageSource,
                  ),
          ),
        ),
      ),
    );
  }
}

String? _cardImageSource(
  CatDexCollectionEntry entry, {
  required int? cacheBustVersion,
}) {
  final card = entry.discovery?.card;
  final candidates = [card?.cardImageUrl, card?.cardImagePath];
  for (final candidate in candidates) {
    final value = candidate?.trim();
    if (isFinalGeneratedCardImageSource(value)) {
      return cacheBustedCardImageUrl(
        source: value!,
        version: cacheBustVersion,
      );
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
    required this.debugRarityOverride,
    required this.onDebugRarityOverrideSelected,
    required this.onRegenerate,
    required this.source,
  });

  final bool generating;
  final String? generatingLabel;
  final CatRarity? debugRarityOverride;
  final ValueChanged<CatRarity>? onDebugRarityOverrideSelected;
  final VoidCallback onRegenerate;
  final String source;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        _CardImage(source: source),
        if (showRarityDebugControls && onDebugRarityOverrideSelected != null)
          Positioned(
            left: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _DebugRarityMenu(
              selected: debugRarityOverride,
              onSelected: onDebugRarityOverrideSelected!,
            ),
          ),
        Positioned(
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 8,
              ),
              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              backgroundColor: AppColors.ink.withValues(alpha: 0.86),
              foregroundColor: AppColors.white,
            ),
            onPressed: generating ? null : onRegenerate,
            icon: generating
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded, size: 15),
            label: Text(
              generating ? '${l10n.regenerateCard}...' : l10n.regenerateCard,
            ),
          ),
        ),
        if (generating)
          _CardLoadingVeil(
            label: generatingLabel ?? '${l10n.generateCard}...',
          ),
      ],
    );
  }
}

class _DebugRarityMenu extends StatelessWidget {
  const _DebugRarityMenu({
    required this.selected,
    required this.onSelected,
  });

  final CatRarity? selected;
  final ValueChanged<CatRarity> onSelected;

  @override
  Widget build(BuildContext context) {
    if (!showRarityDebugControls) {
      return const SizedBox.shrink();
    }

    debugPrint('CATDEX_DEBUG_RARITY_UI_ENABLED true');
    return PopupMenuButton<CatRarity>(
      tooltip: 'Test rarità',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: CatRarity.common, child: Text('Comune')),
        PopupMenuItem(value: CatRarity.uncommon, child: Text('Non comune')),
        PopupMenuItem(value: CatRarity.rare, child: Text('Rara')),
        PopupMenuItem(value: CatRarity.epic, child: Text('Epica')),
        PopupMenuItem(value: CatRarity.legendary, child: Text('Leggendaria')),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.science_rounded,
                size: 14,
                color: AppColors.white,
              ),
              const SizedBox(width: 4),
              Text(
                selected == null
                    ? 'Test rarità'
                    : 'Test ${_rarityLabel(selected!)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _rarityLabel(CatRarity rarity) {
    return switch (rarity) {
      CatRarity.common => 'Comune',
      CatRarity.uncommon => 'Non comune',
      CatRarity.rare => 'Rara',
      CatRarity.epic => 'Epica',
      CatRarity.legendary => 'Leggendaria',
      CatRarity.mythic => 'Leggendaria',
    };
  }
}

class _GenerateCardPlaceholder extends StatelessWidget {
  const _GenerateCardPlaceholder({
    required this.generating,
    required this.generatingLabel,
    required this.hasGenerationError,
    required this.debugRarityOverride,
    required this.onDebugRarityOverrideSelected,
    required this.generateLabel,
    required this.name,
    required this.onGenerate,
  });

  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final CatRarity? debugRarityOverride;
  final ValueChanged<CatRarity>? onDebugRarityOverrideSelected;
  final String? generateLabel;
  final String name;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        _LockedCardSurface(
          name: name,
          generating: generating,
          generatingLabel: generatingLabel,
          hasGenerationError: hasGenerationError,
          generateLabel: generateLabel,
          onGenerate: onGenerate,
        ),
        if (generating)
          _CardLoadingVeil(
            label: generatingLabel ?? '${l10n.generateCard}...',
          ),
        if (showRarityDebugControls && onDebugRarityOverrideSelected != null)
          Positioned(
            left: AppSpacing.sm,
            top: AppSpacing.sm,
            child: _DebugRarityMenu(
              selected: debugRarityOverride,
              onSelected: onDebugRarityOverrideSelected!,
            ),
          ),
      ],
    );
  }
}

class _LockedCardSurface extends StatelessWidget {
  const _LockedCardSurface({
    required this.name,
    required this.generating,
    required this.generatingLabel,
    required this.hasGenerationError,
    required this.generateLabel,
    required this.onGenerate,
  });

  final String name;
  final bool generating;
  final String? generatingLabel;
  final bool hasGenerationError;
  final String? generateLabel;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final title = hasGenerationError
        ? l10n.cardGenerationError
        : l10n.cardNotGenerated;
    final buttonLabel = hasGenerationError
        ? l10n.retryAction
        : generateLabel ?? l10n.generateCard;
    final accent = hasGenerationError ? AppColors.danger : AppColors.warning;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1F2937),
            Color(0xFF111827),
          ],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.34), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _LockedCardPatternPainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Icon(
                      hasGenerationError
                          ? Icons.error_outline_rounded
                          : Icons.lock_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
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
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: 8,
                    ),
                    backgroundColor: accent,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: generating ? null : onGenerate,
                  child: Text(
                    generating ? generatingLabel ?? 'Genero...' : buttonLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLoadingVeil extends StatelessWidget {
  const _CardLoadingVeil({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.ink.withValues(alpha: 0.58),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedCardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final fillPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.fill;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.58,
        height: size.height * 0.72,
      ),
      const Radius.circular(18),
    );
    canvas
      ..drawRRect(cardRect, fillPaint)
      ..drawRRect(cardRect, outlinePaint);

    final top = size.height * 0.18;
    final lockCenter = Offset(size.width / 2, size.height * 0.42);
    canvas
      ..drawCircle(lockCenter, size.width * 0.16, outlinePaint)
      ..drawLine(
        Offset(size.width * 0.22, top),
        Offset(size.width * 0.78, size.height * 0.82),
        outlinePaint,
      );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.white.withValues(alpha: 0.72),
          size: 34,
        ),
      ),
    );
  }
}
