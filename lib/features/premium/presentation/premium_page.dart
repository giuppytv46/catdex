import 'dart:async';

import 'package:catdex/features/premium/application/premium_controller.dart';
import 'package:catdex/features/premium/application/premium_state.dart';
import 'package:catdex/features/premium/domain/entities/premium_plan.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PremiumPage extends ConsumerWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(premiumControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('CatDex Premium')),
      body: SafeArea(
        child: state.when(
          data: (value) => _PremiumContent(state: value),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const _PremiumError(),
        ),
      ),
    );
  }
}

class _PremiumContent extends ConsumerWidget {
  const _PremiumContent({required this.state});

  final PremiumState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanLimit = state.scanLimit;
    final remaining = scanLimit.scansRemaining;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        120,
      ),
      children: [
        DecoratedBox(
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
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.white,
                  size: 44,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Ethical Premium Foundation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  scanLimit.unlimited
                      ? 'Premium scans: unlimited placeholder'
                      : 'Free scans today: $remaining remaining',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final plan in state.plans) ...[
          _PlanCard(plan: plan),
          const SizedBox(height: AppSpacing.md),
        ],
        const _BenefitsCard(
          benefits: [
            'More daily cat scans',
            'Premium badge placeholder',
            'Cosmetic reward placeholders',
            'No real payments enabled',
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {
            unawaited(
              ref.read(premiumControllerProvider.notifier).restorePurchases(),
            );
          },
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Restore Purchases'),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final PremiumPlan plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.featured ? AppColors.primaryPurple : AppColors.skyBlue;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              plan.priceLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final benefit in plan.benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: color, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.benefits});

  final List<String> benefits;

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
              'Benefits',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text('- $benefit'),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumError extends StatelessWidget {
  const _PremiumError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Premium options are unavailable right now.'),
    );
  }
}
