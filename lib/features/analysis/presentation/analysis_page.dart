import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/application/cat_analysis_controller.dart';
import 'package:catdex/features/analysis/application/cat_analysis_state.dart';
import 'package:catdex/features/analysis/domain/entities/analysis_status.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_result.dart';
import 'package:catdex/features/analysis/domain/entities/discovery_reveal_args.dart';
import 'package:catdex/features/analysis/presentation/cat_analysis_display_formatter.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalysisPage extends ConsumerStatefulWidget {
  const AnalysisPage({required this.photo, super.key});

  final CapturedPhoto photo;

  @override
  ConsumerState<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends ConsumerState<AnalysisPage> {
  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() {
        return ref
            .read(catAnalysisControllerProvider.notifier)
            .analyze(widget.photo);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final state = ref.watch(catAnalysisControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.analysisTitle)),
      body: ListView(
        key: const Key('analysis_page'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          120,
        ),
        children: state.result == null
            ? [
                _PhotoPreview(photo: widget.photo),
                const SizedBox(height: AppSpacing.lg),
                _AnalysisStatusCard(state: state),
              ]
            : [_AnalysisResultCard(photo: widget.photo, result: state.result!)],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final CapturedPhoto photo;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final file = File(photo.path);

    return Hero(
      tag: 'catdex-photo-${photo.path}',
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: _analysisDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.skyBlue, AppColors.primaryPurple],
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_rounded,
                        color: AppColors.white,
                        size: 72,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.photoPreviewLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
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

class _AnalysisStatusCard extends StatelessWidget {
  const _AnalysisStatusCard({required this.state});

  final CatAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final failure = state.failure;

    return DecoratedBox(
      decoration: _analysisDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.skyBlue],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: switch (state.status) {
          AnalysisStatus.idle || AnalysisStatus.analyzing => Column(
            children: [
              const SizedBox.square(
                dimension: 48,
                child: CircularProgressIndicator(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.analysisPreparingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.analysisPreparingMessage,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.white),
              ),
            ],
          ),
          AnalysisStatus.success => Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.white,
                size: 36,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l10n.analysisResultTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          AnalysisStatus.failure => Text(
            failure?.message ?? l10n.globalErrorTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        },
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({
    required this.photo,
    required this.result,
  });

  final CapturedPhoto photo;
  final CatAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    const formatter = CatAnalysisDisplayFormatter();
    final traitDisplay = formatter.traits(result.visualTraits.notableTraits);
    final breed = formatter.value(result.displayBreed);
    final rarity = formatter.value(result.displayRarity);
    final variant = formatter.value(result.displayVariant);
    final personality = formatter.value(result.displayPersonality);
    final coatColor = formatter.value(result.visualTraits.coatColor);
    final coatPattern = formatter.value(result.visualTraits.coatPattern);
    final eyeColor = formatter.value(result.visualTraits.eyeColor);
    final hairLength = formatter.value(result.visualTraits.hairLength);
    final estimatedAge = formatter.nullableValue(result.estimatedAge);
    final confidence =
        '${result.confidence.percentage}% ${result.confidence.label}';

    debugPrint(
      'CATDEX_AI_UI_FIELDS '
      '${_safeJson(_analysisUiDebugJson(result, traitDisplay))}',
    );
    debugPrint(
      'CATDEX_UI_MODEL '
      '${_safeJson(_analysisUiDebugJson(result, traitDisplay))}',
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - value)),
            child: Transform.scale(
              scale: 0.94 + (0.06 * value),
              child: child,
            ),
          ),
        );
      },
      child: DecoratedBox(
        decoration: _analysisDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              _rarityColor(result.rarity).withValues(alpha: 0.14),
              AppColors.skyBlue.withValues(alpha: 0.16),
              AppColors.primaryPurple.withValues(alpha: 0.16),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CollectiblePhoto(
                photo: photo,
                rarityColor: _rarityColor(result.rarity),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '✨ New Discovery!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                breed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryPurple,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: _RarityBadge(
                  label: rarity,
                  color: _rarityColor(result.rarity),
                  icon: _rarityIcon(result.rarity),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  Expanded(
                    child: _RewardCard(
                      label: 'XP',
                      amount: 80,
                      icon: Icons.bolt_rounded,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _RewardCard(
                      label: 'Monete',
                      amount: 15,
                      icon: Icons.paid_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _PersonalityChip(
                    icon: Icons.psychology_alt_rounded,
                    label: personality,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoTile(
                icon: Icons.pets_rounded,
                title: 'Species',
                value: breed,
                color: AppColors.primaryPurple,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoTile(
                icon: Icons.palette_rounded,
                title: 'Coat',
                value: coatColor,
                color: AppColors.skyBlue,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoTile(
                icon: Icons.visibility_rounded,
                title: 'Eyes',
                value: eyeColor,
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoTile(
                icon: Icons.favorite_rounded,
                title: 'Personality',
                value: personality,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: AppSpacing.lg),
              _StoryCard(story: result.story, funFact: result.funFact),
              const SizedBox(height: AppSpacing.md),
              _MoreDetailsSection(
                confidence: confidence,
                coatPattern: coatPattern,
                hairLength: hairLength,
                estimatedAge: estimatedAge,
                traits: traitDisplay,
                variant: variant,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  unawaited(
                    context.pushNamed(
                      AppRoute.discoveryReveal.name,
                      extra: DiscoveryRevealArgs(photo: photo, result: result),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Rivela Scoperta'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Object?> _analysisUiDebugJson(
    CatAnalysisResult result,
    String traitDisplay,
  ) {
    return {
      'breed': result.displayBreed,
      'coatColor': result.visualTraits.coatColor,
      'coatPattern': result.visualTraits.coatPattern,
      'eyeColor': result.visualTraits.eyeColor,
      'hairLength': result.visualTraits.hairLength,
      'estimatedAge': result.estimatedAge,
      'traits': result.visualTraits.notableTraits
          .map(
            (trait) => {
              'name': trait.name,
              'value': trait.value,
              'rarityWeight': trait.rarityWeight,
            },
          )
          .toList(growable: false),
      'personality': result.displayPersonality,
      'rarity': result.displayRarity,
      'variant': result.displayVariant,
      'story': result.story,
      'funFact': result.funFact,
      'traitDisplay': traitDisplay,
    };
  }

  String _safeJson(Object? value) {
    try {
      return jsonEncode(value);
    } on Object {
      return value.toString();
    }
  }
}

class _CollectiblePhoto extends StatelessWidget {
  const _CollectiblePhoto({
    required this.photo,
    required this.rarityColor,
  });

  final CapturedPhoto photo;
  final Color rarityColor;

  @override
  Widget build(BuildContext context) {
    final file = File(photo.path);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _StarField(color: rarityColor)),
        Hero(
          tag: 'catdex-photo-${photo.path}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withValues(alpha: 0.45),
                  blurRadius: 36,
                  spreadRadius: 3,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.skyBlue, AppColors.primaryPurple],
                    ),
                    border: Border.all(
                      color: AppColors.white.withValues(
                        alpha: 0.85,
                      ),
                      width: 3,
                    ),
                  ),
                  child: file.existsSync()
                      ? Image.file(file, fit: BoxFit.cover)
                      : const Icon(
                          Icons.pets_rounded,
                          color: AppColors.white,
                          size: 96,
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarField extends StatelessWidget {
  const _StarField({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const stars = [
      (Alignment(-0.92, -0.92), 18.0),
      (Alignment(0.86, -0.86), 24.0),
      (Alignment(-0.82, 0.78), 20.0),
      (Alignment(0.9, 0.72), 16.0),
      (Alignment(0.02, -1.06), 14.0),
    ];

    return IgnorePointer(
      child: Stack(
        children: stars
            .map((star) {
              return Align(
                alignment: star.$1,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value.clamp(0, 1),
                      child: Transform.scale(scale: value, child: child),
                    );
                  },
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: color,
                    size: star.$2,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.55), width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: AppSpacing.xs),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: amount.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Text(
                  '+${value.round()}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalityChip extends StatelessWidget {
  const _PersonalityChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryPurple.withValues(alpha: 0.22),
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
            Icon(icon, color: AppColors.primaryPurple, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(icon, color: color, size: 26),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.funFact});

  final String story;
  final String? funFact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withValues(alpha: 0.92),
            AppColors.skyBlue.withValues(alpha: 0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📖 Story',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              story,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                height: 1.38,
              ),
            ),
            if (funFact != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                funFact!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreDetailsSection extends StatelessWidget {
  const _MoreDetailsSection({
    required this.confidence,
    required this.coatPattern,
    required this.hairLength,
    required this.estimatedAge,
    required this.traits,
    required this.variant,
  });

  final String confidence;
  final String coatPattern;
  final String hairLength;
  final String estimatedAge;
  final String traits;
  final String variant;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(
          'More details',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        children: [
          _DetailLine(label: 'Confidence', value: confidence),
          _DetailLine(label: 'Coat pattern', value: coatPattern),
          _DetailLine(label: 'Hair length', value: hairLength),
          _DetailLine(label: 'Estimated age', value: estimatedAge),
          _DetailLine(label: 'Variant', value: variant),
          _DetailLine(label: 'Traits', value: traits),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primaryPurple,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _rarityColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => AppColors.primaryGreen,
    CatRarity.uncommon || CatRarity.rare => AppColors.skyBlue,
    CatRarity.epic || CatRarity.mythic => AppColors.primaryPurple,
    CatRarity.legendary => AppColors.warning,
  };
}

IconData _rarityIcon(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => Icons.circle_rounded,
    CatRarity.uncommon || CatRarity.rare => Icons.diamond_rounded,
    CatRarity.epic || CatRarity.mythic => Icons.auto_awesome_rounded,
    CatRarity.legendary => Icons.workspace_premium_rounded,
  };
}

BoxDecoration _analysisDecoration({required Gradient gradient}) {
  return BoxDecoration(
    gradient: gradient,
    borderRadius: BorderRadius.circular(40),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
}
