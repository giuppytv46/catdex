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
        children: [
          _PhotoPreview(photo: widget.photo),
          const SizedBox(height: AppSpacing.lg),
          _AnalysisStatusCard(state: state),
          if (state.result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _AnalysisResultCard(photo: widget.photo, result: state.result!),
          ],
        ],
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
    final l10n = CatDexLocalizations.of(context);
    const formatter = CatAnalysisDisplayFormatter();
    final traitDisplay = formatter.traits(result.visualTraits.notableTraits);

    debugPrint(
      'CATDEX_AI_UI_FIELDS '
      '${_safeJson(_analysisUiDebugJson(result, traitDisplay))}',
    );
    debugPrint(
      'CATDEX_UI_MODEL '
      '${_safeJson(_analysisUiDebugJson(result, traitDisplay))}',
    );

    return DecoratedBox(
      decoration: _analysisDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            AppColors.primaryGreen.withValues(alpha: 0.22),
            AppColors.primaryPurple.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ResultRow(
              label: l10n.catNameLabel,
              value: l10n.catNamePlaceholder,
            ),
            _ResultRow(
              label: l10n.breedLabel,
              value: formatter.value(result.displayBreed),
            ),
            _ResultRow(
              label: l10n.confidenceLabel,
              value:
                  '${result.confidence.percentage}% ${result.confidence.label}',
            ),
            _ResultRow(
              label: l10n.coatColorLabel,
              value: formatter.value(result.visualTraits.coatColor),
            ),
            _ResultRow(
              label: l10n.coatPatternLabel,
              value: formatter.value(result.visualTraits.coatPattern),
            ),
            _ResultRow(
              label: l10n.eyeColorLabel,
              value: formatter.value(result.visualTraits.eyeColor),
            ),
            _ResultRow(
              label: l10n.hairLengthLabel,
              value: formatter.value(result.visualTraits.hairLength),
            ),
            _ResultRow(
              label: l10n.estimatedAgeLabel,
              value: formatter.nullableValue(result.estimatedAge),
            ),
            _ResultRow(
              label: l10n.traitsLabel,
              value: traitDisplay,
            ),
            _ResultRow(
              label: l10n.rarityFiltersTitle,
              value: formatter.value(result.displayRarity),
            ),
            _ResultRow(
              label: l10n.variantLabel,
              value: formatter.value(result.displayVariant),
            ),
            _ResultRow(
              label: l10n.moodLabel,
              value: formatter.value(result.displayPersonality),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.storyLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(result.story),
            if (result.funFact != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.funFactLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(result.funFact!),
            ],
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
              label: Text(l10n.revealDiscoveryAction),
            ),
          ],
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.primaryPurple,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
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
