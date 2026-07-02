import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/catdex_collection.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';

class CatDexTradingCardPage extends StatelessWidget {
  const CatDexTradingCardPage({required this.entry, super.key});

  final CatDexCollectionEntry entry;

  @override
  Widget build(BuildContext context) {
    final discovery = entry.discovery;
    final imageSource = _cardImageSource(entry);

    debugPrint('CATDEX_CARD_OPENED_ID ${discovery?.id ?? '-'}');
    debugPrint('CATDEX_CARD_RENDER_MODE external_image');

    return Scaffold(
      backgroundColor: const Color(0xFF101827),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: imageSource == null
                    ? const _MissingGeneratedCard()
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 5 / 7,
                            child: _FinalCardImage(source: imageSource),
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
                  tooltip: 'Indietro',
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

class _FinalCardImage extends StatelessWidget {
  const _FinalCardImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('http://') || source.startsWith('https://')) {
      return Image.network(source, fit: BoxFit.cover);
    }

    return Image.file(File(source), fit: BoxFit.cover);
  }
}

class _MissingGeneratedCard extends StatelessWidget {
  const _MissingGeneratedCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Genera questa carta dalla pagina Carte.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class CollectibleCatCardPage extends CatDexTradingCardPage {
  const CollectibleCatCardPage({
    required super.entry,
    super.key,
  });
}
