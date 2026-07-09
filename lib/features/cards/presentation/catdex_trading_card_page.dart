import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/ads/presentation/catdex_banner_ad_widget.dart';
import 'package:catdex/features/analysis/presentation/cat_display_data.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/cards/presentation/card_image_cache_buster.dart';
import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CardGenerationCallback = Future<String?> Function();

class CatDexTradingCardPage extends StatefulWidget {
  const CatDexTradingCardPage({
    required this.entry,
    this.cacheBustVersion,
    this.onGenerate,
    this.onRegenerate,
    super.key,
  });

  final CatDexCollectionEntry entry;
  final int? cacheBustVersion;
  final CardGenerationCallback? onGenerate;
  final CardGenerationCallback? onRegenerate;

  @override
  State<CatDexTradingCardPage> createState() => _CatDexTradingCardPageState();
}

class _CatDexTradingCardPageState extends State<CatDexTradingCardPage> {
  String? _latestImageSource;
  int? _localCacheBustVersion;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _localCacheBustVersion = widget.cacheBustVersion;
  }

  @override
  Widget build(BuildContext context) {
    final discovery = widget.entry.discovery;
    final display = discovery == null
        ? null
        : const CatDisplayFormatter().fromDiscovery(
            discovery,
            fallbackName: widget.entry.displayName,
          );
    final imageSource =
        _latestImageSource ??
        _cardImageSource(
          widget.entry,
          cacheBustVersion: _localCacheBustVersion,
        );

    debugPrint('CATDEX_CARD_OPENED_ID ${discovery?.id ?? '-'}');
    debugPrint('CATDEX_CARD_RENDER_MODE external_image');

    return Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF111827),
                      Color(0xFF0B1020),
                      Color(0xFF050816),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    76,
                    AppSpacing.lg,
                    40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CardHeroFrame(
                            imageSource: imageSource,
                            generating: _generating,
                            onGenerate: widget.onGenerate == null
                                ? null
                                : () => _runGeneration(
                                    callback: widget.onGenerate!,
                                    successMessage: 'Carta generata',
                                  ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardMetadataPanel(
                            display: display,
                            cardNumber: _cardNumber(widget.entry),
                            discoveredDate: _discoveredDate(widget.entry),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _CardActionsPanel(
                            hasImage: imageSource != null,
                            generating: _generating,
                            onRegenerate: widget.onRegenerate == null
                                ? null
                                : () => _runGeneration(
                                    callback: widget.onRegenerate!,
                                    successMessage: 'Carta aggiornata',
                                  ),
                            onShare: imageSource == null
                                ? null
                                : () => _copyImageReference(imageSource),
                            onSave: imageSource == null
                                ? null
                                : () => _showImageSaveFeedback(imageSource),
                          ),
                          CatDexBannerAdWidget(
                            placementLog:
                                'CATDEX_AD_BANNER_PLACEMENT_CARD_DETAIL',
                            safeForAds: !_generating,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.sm,
              top: AppSpacing.sm,
              child: Material(
                color: AppColors.ink.withValues(alpha: 0.54),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: CatDexLocalizations.of(context).backAction,
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runGeneration({
    required CardGenerationCallback callback,
    required String successMessage,
  }) async {
    if (_generating) {
      return;
    }

    setState(() {
      _generating = true;
    });

    String? result;
    try {
      result = await callback();
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (result == null || result.trim().isEmpty) {
      _showSnackBar('Errore generazione carta');
      return;
    }
    if (!isFinalGeneratedCardImageSource(result)) {
      debugPrint('CATDEX_CARD_IMAGE_REJECTED_ORIGINAL_PHOTO_PATH');
      debugPrint('CATDEX_CARD_GENERATION_FAILED_KEEP_EXISTING_IMAGE');
      _showSnackBar('Errore generazione carta');
      return;
    }

    setState(() {
      _localCacheBustVersion = DateTime.now().millisecondsSinceEpoch;
      _latestImageSource = cacheBustedCardImageUrl(
        source: result!.trim(),
        version: _localCacheBustVersion,
      );
    });
    _showSnackBar(successMessage);
  }

  Future<void> _copyImageReference(String source) async {
    await Clipboard.setData(ClipboardData(text: source));
    if (mounted) {
      _showSnackBar('Link carta copiato');
    }
  }

  void _showImageSaveFeedback(String source) {
    final isLocal =
        !(source.startsWith('http://') || source.startsWith('https://'));
    _showSnackBar(
      isLocal
          ? 'Immagine già salvata sul dispositivo'
          : 'Usa Condividi per copiare il link immagine',
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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

String _cardNumber(CatDexCollectionEntry entry) {
  return '#${entry.collectionNumber.toString().padLeft(4, '0')}';
}

String _discoveredDate(CatDexCollectionEntry entry) {
  final date = entry.discovery?.discoveredAt;
  if (date == null) {
    return '-';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _CardHeroFrame extends StatelessWidget {
  const _CardHeroFrame({
    required this.imageSource,
    required this.generating,
    required this.onGenerate,
  });

  final String? imageSource;
  final bool generating;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.16),
            AppColors.white.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.20),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AspectRatio(
          aspectRatio: 5 / 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: imageSource == null
                ? _MissingGeneratedCard(
                    generating: generating,
                    onGenerate: onGenerate,
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      _FinalCardImage(source: imageSource!),
                      if (generating)
                        ColoredBox(
                          color: AppColors.ink.withValues(alpha: 0.62),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FinalCardImage extends StatelessWidget {
  const _FinalCardImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _CardImageError(),
      );
    }

    return Image.file(
      File(source),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _CardImageError(),
    );
  }
}

class _MissingGeneratedCard extends StatelessWidget {
  const _MissingGeneratedCard({
    required this.generating,
    required this.onGenerate,
  });

  final bool generating;
  final VoidCallback? onGenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111827),
            Color(0xFF1F2937),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.14),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Icon(
                  Icons.style_rounded,
                  color: AppColors.white,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.cardNotGenerated,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.createFinalCardHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(
                generating ? '${l10n.generateCard}...' : l10n.generateCard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImageError extends StatelessWidget {
  const _CardImageError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.ink,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: AppColors.white,
          size: 46,
        ),
      ),
    );
  }
}

class _CardMetadataPanel extends StatelessWidget {
  const _CardMetadataPanel({
    required this.display,
    required this.cardNumber,
    required this.discoveredDate,
  });

  final CatDisplayData? display;
  final String cardNumber;
  final String discoveredDate;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              display?.displayName ?? 'Carta CatDex',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (display != null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.localizeDisplayValue(display!.displaySpecies),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MetadataChip(
                  icon: Icons.auto_awesome_rounded,
                  label: l10n.rarityLabel,
                  value: l10n.localizeDisplayValue(
                    display?.displayRarity ?? '-',
                  ),
                ),
                _MetadataChip(
                  icon: Icons.confirmation_number_rounded,
                  label: l10n.cardLabel,
                  value: cardNumber,
                ),
                _MetadataChip(
                  icon: Icons.calendar_month_rounded,
                  label: l10n.discoveryLabel,
                  value: discoveredDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.warning, size: 17),
            const SizedBox(width: 6),
            Text(
              '$label: ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardActionsPanel extends StatelessWidget {
  const _CardActionsPanel({
    required this.hasImage,
    required this.generating,
    required this.onRegenerate,
    required this.onShare,
    required this.onSave,
  });

  final bool hasImage;
  final bool generating;
  final VoidCallback? onRegenerate;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: generating ? null : onRegenerate,
          icon: generating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
          label: Text(
            generating ? '${l10n.regenerateCard}...' : l10n.regenerateCard,
          ),
        ),
        OutlinedButton.icon(
          onPressed: hasImage ? onShare : null,
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(l10n.shareAction),
        ),
        OutlinedButton.icon(
          onPressed: hasImage ? onSave : null,
          icon: const Icon(Icons.download_rounded),
          label: Text(l10n.saveImageAction),
        ),
      ],
    );
  }
}

class CollectibleCatCardPage extends CatDexTradingCardPage {
  const CollectibleCatCardPage({
    required super.entry,
    super.key,
  });
}
