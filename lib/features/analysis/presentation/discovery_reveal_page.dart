import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/application/discovery_reveal_sound_hooks.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/discovery_reveal_args.dart';
import 'package:catdex/features/analysis/presentation/cat_display_formatter.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_theme.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DiscoveryRevealPage extends ConsumerStatefulWidget {
  const DiscoveryRevealPage({required this.args, super.key});

  final DiscoveryRevealArgs args;

  @override
  ConsumerState<DiscoveryRevealPage> createState() =>
      _DiscoveryRevealPageState();
}

class _DiscoveryRevealPageState extends ConsumerState<DiscoveryRevealPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _collectionController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _saveFlowActive = false;
  bool _showCollectionSuccess = false;
  int _savedXp = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _collectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    unawaited(_controller.forward());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      ref.read(localDiscoverySaveControllerProvider.notifier).reset();
      _playRevealSound();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _collectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final displayData = const CatDisplayFormatter().fromAnalysis(
      widget.args.result,
    );
    final saveState = ref.watch(localDiscoverySaveControllerProvider);
    final currentSaveState = switch (saveState) {
      AsyncData(:final value) => value,
      _ => const LocalDiscoverySaveState.idle(),
    };
    final saving = currentSaveState.status == LocalDiscoverySaveStatus.saving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoveryRevealTitle)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                120,
              ),
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: _RevealCard(args: widget.args),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _ResultDetails(args: widget.args),
                const SizedBox(height: AppSpacing.lg),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: FilledButton.icon(
                    key: const Key('discovery_reveal_add_button'),
                    onPressed: saving || _saveFlowActive
                        ? null
                        : () => _saveDiscovery(context),
                    icon: saving || _saveFlowActive
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_circle_rounded),
                    label: Text(
                      currentSaveState.status ==
                              LocalDiscoverySaveStatus.failure
                          ? l10n.retrySaveAction
                          : l10n.addToCatDexAction,
                    ),
                  ),
                ),
                if (currentSaveState.status ==
                    LocalDiscoverySaveStatus.failure) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    currentSaveState.pendingSync == null
                        ? currentSaveState.message ?? l10n.globalErrorTitle
                        : l10n.saveToCatDexFailedLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
            if (_showCollectionSuccess)
              Positioned.fill(
                child: _CatDexAddSuccessOverlay(
                  animation: _collectionController,
                  photoPath: widget.args.photo.bestLocalPath,
                  species: l10n.localizeDisplayValue(
                    displayData.displaySpecies,
                  ),
                  rarity: l10n.localizeDisplayValue(
                    displayData.displayRarity,
                  ),
                  xp: _savedXp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _playCollectionSuccess(int xp) async {
    if (!mounted) return;
    debugPrint('CATDEX_CATDEX_ADD_ANIMATION_STARTED');
    final coordinator = CatDexCelebrationCoordinator.instance;
    final lease = coordinator.acquire(CatDexCelebrationType.addedToCatDex);
    final l10n = CatDexLocalizations.of(context);
    setState(() {
      _savedXp = xp;
      _showCollectionSuccess = true;
    });
    _collectionController.duration = _reduceMotion
        ? const Duration(milliseconds: 420)
        : const Duration(milliseconds: 2050);
    final celebration = coordinator.celebrate(
      context,
      CatDexCelebrationRequest(
        type: CatDexCelebrationType.addedToCatDex,
        theme: CatDexCelebrationTheme.forPalette(
          CatDexCelebrationPalette.catDex,
        ),
        title: l10n.catDexAddedSuccess,
        subtitle: xp > 0 ? '+$xp XP' : null,
        semanticLabel: l10n.catDexAddedSuccess,
        seed: _stableAddCelebrationSeed(widget.args.photo.bestLocalPath),
        reduceMotion: _reduceMotion,
      ),
    );
    debugPrint('CATDEX_CELEBRATION_NAVIGATION_DEFERRED');
    try {
      await Future.wait<void>([
        _collectionController.forward(from: 0),
        celebration,
      ]);
      if (!mounted) return;
      debugPrint('CATDEX_CATDEX_ADD_ANIMATION_COMPLETED');
    } on Object {
      // A disposed route can cancel the local ticker; persistence is already
      // complete and must not be changed by presentation cleanup.
    } finally {
      lease.release();
    }
  }

  bool get _reduceMotion {
    final media = MediaQuery.maybeOf(context);
    return (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
  }

  Future<void> _saveDiscovery(BuildContext context) async {
    if (_saveFlowActive) {
      return;
    }
    setState(() => _saveFlowActive = true);
    final suggestedName = widget.args.suggestedName.trim();
    final catName = await showDialog<String>(
      context: context,
      builder: (_) {
        return _NameCatDialog(
          initialName: suggestedName,
        );
      },
    );
    if (catName == null || !context.mounted) {
      if (mounted) {
        setState(() => _saveFlowActive = false);
      }
      return;
    }

    final notifier = ref.read(localDiscoverySaveControllerProvider.notifier);
    final displayData = const CatDisplayFormatter().fromAnalysis(
      widget.args.result,
    );
    debugPrint(
      'CATDEX_SAVE_USES_EDITED_DETAILS ${widget.args.usesEditedDetails}',
    );
    debugPrint('CATDEX_SAVE_FINAL_SPECIES ${displayData.displaySpecies}');
    debugPrint('CATDEX_SAVE_FINAL_COAT_COLOR ${displayData.displayCoatColor}');
    debugPrint('CATDEX_SAVE_FINAL_PATTERN ${displayData.displayCoatPattern}');
    debugPrint('CATDEX_SAVE_FINAL_EYE_COLOR ${displayData.displayEyeColor}');
    debugPrint(
      'CATDEX_SAVE_FINAL_HAIR_LENGTH ${displayData.displayHairLength}',
    );
    debugPrint(
      'CATDEX_SAVE_FINAL_PERSONALITY ${displayData.displayPersonality}',
    );
    debugPrint('CATDEX_SAVE_FINAL_RARITY ${displayData.displayRarity}');
    await notifier.save(
      widget.args.result,
      photoPath: widget.args.photo.bestLocalPath,
      cloudStoragePath: widget.args.photo.storagePath,
      customName: catName,
      suggestedName: displayData.displaySpecies,
      usesEditedDetails: widget.args.usesEditedDetails,
    );

    final state = ref.read(localDiscoverySaveControllerProvider).value;
    if (!context.mounted || state?.status != LocalDiscoverySaveStatus.saved) {
      if (mounted) {
        setState(() => _saveFlowActive = false);
      }
      return;
    }

    final savedXp = state?.reward?.xp ?? 0;
    await _playCollectionSuccess(savedXp);
    if (!context.mounted) return;
    ref.read(discoveryRevealSoundHooksProvider).playLevelUp();
    context.goNamed(AppRoute.catDex.name);
  }

  void _playRevealSound() {
    final hooks = ref.read(discoveryRevealSoundHooksProvider);
    final result = widget.args.result;

    if (_isShinyVariant(result.variant.id)) {
      hooks.playShinyReveal();
      return;
    }

    if (_isRareRarity(result.rarity)) {
      hooks.playRareReveal();
      return;
    }

    hooks.playCommonReveal();
  }
}

int _stableAddCelebrationSeed(String value) {
  var result = 29;
  for (final codeUnit in value.codeUnits) {
    result = ((result * 37) + codeUnit) & 0x7FFFFFFF;
  }
  return result;
}

class _CatDexAddSuccessOverlay extends StatelessWidget {
  const _CatDexAddSuccessOverlay({
    required this.animation,
    required this.photoPath,
    required this.species,
    required this.rarity,
    required this.xp,
  });

  final Animation<double> animation;
  final String photoPath;
  final String species;
  final String rarity;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final reduceMotion =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    return Semantics(
      liveRegion: true,
      label: l10n.catDexAddedSuccess,
      child: Material(
        color: AppColors.ink.withValues(alpha: 0.88),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final progress = Curves.easeOutCubic.transform(animation.value);
            final moveProgress = const Interval(
              0.08,
              0.62,
              curve: Curves.easeInOutCubic,
            ).transform(progress);
            final pulse = reduceMotion
                ? 1.0
                : 0.92 +
                      (0.08 *
                          Curves.easeOutBack.transform(
                            const Interval(0.46, 0.82).transform(progress),
                          ));
            final successProgress = const Interval(
              0.56,
              1,
              curve: Curves.easeOutBack,
            ).transform(progress);
            final curveX = reduceMotion
                ? 0.0
                : math.sin(math.pi * moveProgress) * 68;
            final curveY = reduceMotion ? 68.0 : -72 + (178 * moveProgress);
            final cardScale = reduceMotion ? 0.56 : 1 - (0.44 * moveProgress);
            final cardTilt = reduceMotion ? 0.0 : -0.08 + (0.12 * moveProgress);
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: SizedBox(
                      height: 500,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: const Alignment(0, 0.30),
                            child: Transform.scale(
                              scale: pulse,
                              child: _CatDexCollectionSlot(
                                completed: successProgress > 0.56,
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, -0.36),
                            child: Transform.translate(
                              offset: Offset(curveX, curveY),
                              child: Transform.rotate(
                                angle: cardTilt,
                                child: Transform.scale(
                                  scale: cardScale,
                                  child: _DiscoveryCollectionCard(
                                    cardKey: const Key(
                                      'catdex_add_rectangular_discovery_card',
                                    ),
                                    photoPath: photoPath,
                                    species: species,
                                    rarity: rarity,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, 0.92),
                            child: Opacity(
                              opacity: successProgress.clamp(0, 1),
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - successProgress)),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.catDexAddedSuccess.toUpperCase(),
                                      key: const Key(
                                        'catdex_add_success_label',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    if (xp > 0) ...[
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '+$xp XP',
                                        key: const Key(
                                          'catdex_add_success_xp',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: AppColors.primaryGreen,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DiscoveryCollectionCard extends StatelessWidget {
  const _DiscoveryCollectionCard({
    required this.cardKey,
    required this.photoPath,
    required this.species,
    required this.rarity,
  });

  final Key cardKey;
  final String photoPath;
  final String species;
  final String rarity;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    return Container(
      key: cardKey,
      width: 250,
      height: 230,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFB7A7FF), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : const ColoredBox(
                      color: Color(0xFFE5E7EB),
                      child: Icon(Icons.pets_rounded, color: Color(0xFF6B7280)),
                    ),
            ),
          ),
          if (species.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              species,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
          if (rarity.isNotEmpty)
            Text(
              rarity,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

class _CatDexCollectionSlot extends StatelessWidget {
  const _CatDexCollectionSlot({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('catdex_collection_target'),
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.primaryPurple,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFF8FAFC), width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0x667C3AED), blurRadius: 28, spreadRadius: 3),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.collections_bookmark_rounded,
            color: Colors.white,
            size: 48,
          ),
          if (completed)
            const Positioned(
              right: 8,
              bottom: 8,
              child: Icon(
                Icons.check_circle_rounded,
                key: Key('catdex_add_success_check'),
                color: AppColors.primaryGreen,
                size: 28,
              ),
            ),
        ],
      ),
    );
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.args});

  final DiscoveryRevealArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final result = args.result;
    final displayData = const CatDisplayFormatter().fromAnalysis(result);
    final rarityColor = _rarityColor(result.rarity);
    final shimmer =
        _isShinyVariant(result.variant.id) || _isRareRarity(result.rarity);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: _ConfettiPlaceholder(color: rarityColor)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white,
                rarityColor.withValues(alpha: 0.22),
                AppColors.primaryPurple.withValues(alpha: 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.42),
                blurRadius: 34,
                spreadRadius: 4,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(
              color: rarityColor.withValues(alpha: 0.82),
              width: 3,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(38),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      Text(
                        l10n.discoveryUnlockedLabel,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.localizeDisplayValue(displayData.displaySpecies),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Hero(
                        tag: 'catdex-photo-${args.photo.bestLocalPath}',
                        child: _DiscoveryCollectionCard(
                          cardKey: const Key('discovery_reveal_photo_card'),
                          photoPath: args.photo.bestLocalPath,
                          species: '',
                          rarity: '',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _RevealBadge(
                            label: l10n.localizeDisplayValue(
                              displayData.displayRarity,
                            ),
                          ),
                          _RevealBadge(
                            label: l10n.localizeDisplayValue(
                              displayData.displayVariant,
                            ),
                          ),
                          _RevealBadge(
                            label: l10n.localizeDisplayValue(
                              displayData.displayPersonality,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (shimmer) _ShimmerOverlay(color: rarityColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NameCatDialog extends StatefulWidget {
  const _NameCatDialog({required this.initialName});

  final String initialName;

  @override
  State<_NameCatDialog> createState() => _NameCatDialogState();
}

class _NameCatDialogState extends State<_NameCatDialog> {
  late final TextEditingController _controller;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white,
              AppColors.primaryGreen.withValues(alpha: 0.18),
              AppColors.primaryPurple.withValues(alpha: 0.14),
            ],
          ),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '🐈 ${l10n.nameDiscoveryTitle}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1C2340),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.nameDiscoverySubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3E4A66),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                cursorColor: const Color(0xFF6D3BFF),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1E243B),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF9AA3B2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(
                      color: Color(0xFF6D3BFF),
                      width: 2,
                    ),
                  ),
                ),
                onSubmitted: (_) => _save(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitted
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF66D9B5),
                        side: const BorderSide(color: Color(0xFF8F95A3)),
                      ),
                      child: Text(l10n.cancelAction),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('name_discovery_save_button'),
                      onPressed: _submitted ? null : () => _save(context),
                      style: FilledButton.styleFrom(
                        foregroundColor: const Color(0xFF2A2352),
                      ),
                      icon: const Icon(
                        Icons.pets_rounded,
                        color: Color(0xFF2A2352),
                      ),
                      label: Text(
                        l10n.saveToCatDexAction,
                        style: const TextStyle(color: Color(0xFF2A2352)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (_submitted) {
      return;
    }
    setState(() => _submitted = true);
    final trimmed = _controller.text.trim();
    Navigator.of(context).pop(trimmed.isEmpty ? widget.initialName : trimmed);
  }
}

class _ConfettiPlaceholder extends StatelessWidget {
  const _ConfettiPlaceholder({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    const offsets = [
      Alignment(-0.92, -1.05),
      Alignment(-0.62, -0.9),
      Alignment(0.68, -0.98),
      Alignment(0.94, -0.62),
      Alignment(-0.88, 0.74),
      Alignment(0.82, 0.92),
    ];

    return IgnorePointer(
      child: Stack(
        children: offsets
            .map((alignment) {
              return Align(
                alignment: alignment,
                child: Container(
                  width: 10,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ShimmerOverlay extends StatelessWidget {
  const _ShimmerOverlay({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.transparent,
                AppColors.white.withValues(alpha: 0.34),
                color.withValues(alpha: 0.16),
                Colors.transparent,
              ],
              stops: const [0, 0.42, 0.52, 1],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isRareRarity(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common || CatRarity.uncommon => false,
    CatRarity.rare ||
    CatRarity.epic ||
    CatRarity.legendary ||
    CatRarity.mythic => true,
  };
}

bool _isShinyVariant(String variantId) {
  return switch (variantId) {
    'shiny' || 'golden' || 'event_edition' => true,
    _ => false,
  };
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({required this.args});

  final DiscoveryRevealArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final result = args.result;
    final displayData = const CatDisplayFormatter().fromAnalysis(result);
    final traits =
        '${l10n.localizeDisplayValue(displayData.displayCoatColor)}, '
        '${l10n.localizeDisplayValue(displayData.displayCoatPattern)}, '
        '${l10n.localizeDisplayValue(displayData.displayEyeColor)}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailLine(
              label: l10n.confidenceLabel,
              value:
                  '${result.confidence.percentage}% ${result.confidence.label}',
            ),
            _DetailLine(
              label: l10n.traitsLabel,
              value: traits,
            ),
            _DetailLine(
              label: l10n.storyLabel,
              value: displayData.displayStory,
            ),
          ],
        ),
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
          Text(value),
        ],
      ),
    );
  }
}

class _RevealBadge extends StatelessWidget {
  const _RevealBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primaryPurple,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Color _rarityColor(CatRarity rarity) {
  return switch (rarity) {
    CatRarity.common => AppColors.primaryGreen,
    CatRarity.uncommon => AppColors.skyBlue,
    CatRarity.rare => AppColors.primaryPurple,
    CatRarity.epic => const Color(0xFFEC4899),
    CatRarity.legendary => AppColors.warning,
    CatRarity.mythic => const Color(0xFFEF4444),
  };
}
