import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/onboarding/application/onboarding_controller.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = CatDexLocalizations.of(context);
    final completing = ref.watch(onboardingControllerProvider).isLoading;
    final steps = _steps(l10n);
    final permissions = _permissions(l10n);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.onboardingTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            120,
          ),
          children: [
            _MascotPlaceholder(l10n: l10n),
            const SizedBox(height: AppSpacing.lg),
            for (final (index, step) in steps.indexed) ...[
              _OnboardingStepCard(step: step, index: index + 1),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            _PermissionEducationSection(
              items: permissions,
              title: l10n.permissionEducationTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: completing
                  ? null
                  : () => _completeAndNavigate(
                      context: context,
                      ref: ref,
                      route: AppRoute.home,
                    ),
              icon: const Icon(Icons.pets_rounded),
              label: Text(l10n.continueAsGuestAction),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: completing
                  ? null
                  : () => _completeAndNavigate(
                      context: context,
                      ref: ref,
                      route: AppRoute.login,
                    ),
              icon: const Icon(Icons.login_rounded),
              label: Text(l10n.onboardingSignInAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeAndNavigate({
    required BuildContext context,
    required WidgetRef ref,
    required AppRoute route,
  }) async {
    await ref.read(onboardingControllerProvider.notifier).completeOnboarding();
    if (!context.mounted) {
      return;
    }

    context.goNamed(route.name);
  }
}

class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder({required this.l10n});

  final CatDexLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen,
            AppColors.skyBlue,
            AppColors.primaryPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cruelty_free_rounded,
                color: AppColors.white,
                size: 64,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.mascotPlaceholderTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.mascotPlaceholderMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({required this.step, required this.index});

  final _OnboardingStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: step.colors),
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 64,
                child: Icon(step.icon, color: AppColors.white, size: 32),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$index. ${step.title}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(step.message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionEducationSection extends StatelessWidget {
  const _PermissionEducationSection({
    required this.items,
    required this.title,
  });

  final List<_PermissionEducationItem> items;
  final String title;

  @override
  Widget build(BuildContext context) {
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
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in items) ...[
              _PermissionEducationTile(item: item),
              if (item != items.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _PermissionEducationTile extends StatelessWidget {
  const _PermissionEducationTile({required this.item});

  final _PermissionEducationItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(item.icon, color: AppColors.primaryPurple),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(item.message),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingStep {
  const _OnboardingStep({
    required this.title,
    required this.message,
    required this.icon,
    required this.colors,
  });

  final String title;
  final String message;
  final IconData icon;
  final List<Color> colors;
}

class _PermissionEducationItem {
  const _PermissionEducationItem({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;
}

List<_OnboardingStep> _steps(CatDexLocalizations l10n) {
  return [
    _OnboardingStep(
      title: l10n.onboardingDiscoverTitle,
      message: l10n.onboardingDiscoverMessage,
      icon: Icons.camera_alt_rounded,
      colors: const [AppColors.primaryGreen, AppColors.skyBlue],
    ),
    _OnboardingStep(
      title: l10n.onboardingCardsTitle,
      message: l10n.onboardingCardsMessage,
      icon: Icons.auto_awesome_rounded,
      colors: const [AppColors.skyBlue, AppColors.primaryPurple],
    ),
    _OnboardingStep(
      title: l10n.onboardingLevelTitle,
      message: l10n.onboardingLevelMessage,
      icon: Icons.emoji_events_rounded,
      colors: const [AppColors.warning, AppColors.primaryPurple],
    ),
  ];
}

List<_PermissionEducationItem> _permissions(CatDexLocalizations l10n) {
  return [
    _PermissionEducationItem(
      title: l10n.cameraEducationTitle,
      message: l10n.cameraEducationMessage,
      icon: Icons.photo_camera_rounded,
    ),
    _PermissionEducationItem(
      title: l10n.photosEducationTitle,
      message: l10n.photosEducationMessage,
      icon: Icons.photo_library_rounded,
    ),
    _PermissionEducationItem(
      title: l10n.locationEducationTitle,
      message: l10n.locationEducationMessage,
      icon: Icons.location_on_rounded,
    ),
  ];
}
