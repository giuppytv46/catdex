import 'dart:async';
import 'dart:io';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/analysis/application/discovery_reveal_sound_hooks.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_controller.dart';
import 'package:catdex/features/analysis/application/local_discovery_save_state.dart';
import 'package:catdex/features/analysis/domain/entities/discovery_reveal_args.dart';
import 'package:catdex/features/catdex/domain/entities/cat_personality.dart';
import 'package:catdex/features/catdex/domain/entities/cat_rarity.dart';
import 'package:catdex/routing/app_routes.dart';
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    ref.read(localDiscoverySaveControllerProvider.notifier).reset();
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
    unawaited(_controller.forward());
    unawaited(
      Future<void>.microtask(() {
        ref.read(discoveryRevealSoundHooksProvider).playReveal();
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final result = widget.args.result;
    final saveState = ref.watch(localDiscoverySaveControllerProvider);
    final currentSaveState = switch (saveState) {
      AsyncData(:final value) => value,
      _ => const LocalDiscoverySaveState.idle(),
    };
    final previewReward = ref
        .read(localDiscoverySaveControllerProvider.notifier)
        .previewReward(result);
    final reward = currentSaveState.reward ?? previewReward;
    final saving = currentSaveState.status == LocalDiscoverySaveStatus.saving;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.discoveryRevealTitle)),
      body: SafeArea(
        child: ListView(
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _RewardPanel(
                key: ValueKey('${reward.xp}-${reward.coins}'),
                xp: reward.xp,
                coins: reward.coins,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResultDetails(args: widget.args),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: saving ? null : () => _saveDiscovery(context),
              icon: saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_rounded),
              label: Text(
                currentSaveState.status == LocalDiscoverySaveStatus.failure
                    ? l10n.retrySaveAction
                    : l10n.addToCatDexAction,
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
      ),
    );
  }

  Future<void> _saveDiscovery(BuildContext context) async {
    final notifier = ref.read(localDiscoverySaveControllerProvider.notifier);

    await notifier.save(widget.args.result);
    ref.read(discoveryRevealSoundHooksProvider).playRewards();

    final state = ref.read(localDiscoverySaveControllerProvider).value;
    if (!context.mounted || state?.status != LocalDiscoverySaveStatus.saved) {
      return;
    }

    context.goNamed(AppRoute.home.name);
  }
}

class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.args});

  final DiscoveryRevealArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final result = args.result;
    final rarityColor = _rarityColor(result.rarity);

    return DecoratedBox(
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
      child: Padding(
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
            const SizedBox(height: AppSpacing.md),
            Hero(
              tag: 'catdex-photo-${args.photo.path}',
              child: _PhotoMedallion(path: args.photo.path),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              result.primaryBreed.species.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _RevealBadge(label: l10n.rarityName(result.rarity.name)),
                _RevealBadge(label: result.variant.name),
                _RevealBadge(label: _personalityName(result.personality)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoMedallion extends StatelessWidget {
  const _PhotoMedallion({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);

    return Container(
      width: 168,
      height: 168,
      decoration: const BoxDecoration(
        color: AppColors.primaryGreen,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: file.existsSync()
          ? Image.file(file, fit: BoxFit.cover)
          : const Icon(Icons.pets_rounded, color: AppColors.white, size: 92),
    );
  }
}

class _RewardPanel extends StatelessWidget {
  const _RewardPanel({
    required this.xp,
    required this.coins,
    super.key,
  });

  final int xp;
  final int coins;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _RewardTile(
            label: l10n.xpEarnedLabel,
            value: '+$xp XP',
            icon: Icons.bolt_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _RewardTile(
            label: l10n.coinsEarnedLabel,
            value: '+$coins',
            icon: Icons.stars_rounded,
            color: AppColors.primaryGreen,
          ),
        ),
      ],
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultDetails extends StatelessWidget {
  const _ResultDetails({required this.args});

  final DiscoveryRevealArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = CatDexLocalizations.of(context);
    final result = args.result;
    final traits = result.visualTraits.notableTraits
        .map((trait) => '${trait.name}: ${trait.value}')
        .join(', ');

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
              value:
                  '${result.visualTraits.coatColor}, '
                  '${result.visualTraits.coatPattern}, '
                  '${result.visualTraits.eyeColor} eyes, '
                  '${result.visualTraits.hairLength} hair'
                  '${traits.isEmpty ? '' : ', $traits'}',
            ),
            _DetailLine(label: l10n.storyLabel, value: result.story),
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

String _personalityName(CatPersonality personality) {
  return switch (personality) {
    CatPersonality.sleepy => 'Sleepy',
    CatPersonality.curious => 'Curious',
    CatPersonality.boss => 'Boss',
    CatPersonality.friendly => 'Friendly',
    CatPersonality.royal => 'Royal',
    CatPersonality.mischievous => 'Mischievous',
    CatPersonality.silly => 'Silly',
    CatPersonality.mysterious => 'Mysterious',
    CatPersonality.brave => 'Brave',
    CatPersonality.lazy => 'Lazy',
    CatPersonality.relaxed => 'Relaxed',
    CatPersonality.playful => 'Playful',
  };
}
