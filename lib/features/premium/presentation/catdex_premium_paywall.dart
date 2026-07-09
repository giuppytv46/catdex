import 'dart:async';

import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_controls.dart';
import 'package:catdex/features/premium/presentation/monetization_limit_kind.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CatDexPremiumPaywall extends ConsumerStatefulWidget {
  const CatDexPremiumPaywall({
    required this.reason,
    super.key,
  });

  final MonetizationLimitKind reason;

  @override
  ConsumerState<CatDexPremiumPaywall> createState() =>
      _CatDexPremiumPaywallState();
}

class _CatDexPremiumPaywallState extends ConsumerState<CatDexPremiumPaywall> {
  MonetizationStatus? _status;
  bool _rewardLoading = false;
  bool _rewardUnavailable = false;

  @override
  void initState() {
    super.initState();
    debugPrint('CATDEX_PAYWALL_SHOWN ${widget.reason.logValue}');
    debugPrint('CATDEX_REWARDED_PAYWALL_OPENED');
    unawaited(_loadStatus());
    unawaited(_prepareRewardedAd());
  }

  Future<void> _loadStatus() async {
    final status = await ref.read(monetizationServiceProvider).getStatus();
    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(rewardedAdStateRefreshProvider);
    final liveStatus = ref
        .watch(monetizationStatusProvider)
        .maybeWhen(
          data: (status) => status,
          orElse: () => null,
        );
    final status = liveStatus ?? _status;
    final adMobService = ref.read(adMobServiceProvider);
    final adLoaded = adMobService.isRewardedAdLoaded;
    final adLoading = adMobService.isRewardedAdLoading || _rewardLoading;
    final isPremium = status?.isPremium == true;
    final showDebugFallback =
        showMonetizationDebug &&
        !isPremium &&
        !adLoading &&
        (!adLoaded || _rewardUnavailable);
    debugPrint(
      'CATDEX_REWARDED_STATE loaded=$adLoaded loading=$adLoading',
    );
    if (showDebugFallback) {
      debugPrint('CATDEX_DEBUG_REWARDED_FALLBACK_VISIBLE true');
    }
    final rewardedButtonLabel = _rewardedButtonLabel(
      loaded: adLoaded,
      loading: adLoading,
      unavailable: _rewardUnavailable,
    );
    debugPrint(
      adLoading
          ? 'CATDEX_REWARDED_BUTTON_LOADING'
          : adLoaded
          ? 'CATDEX_REWARDED_BUTTON_READY'
          : _rewardUnavailable
          ? 'CATDEX_REWARDED_BUTTON_RETRY'
          : 'CATDEX_REWARDED_BUTTON_LOADING',
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple,
                    AppColors.skyBlue,
                    AppColors.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
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
                      size: 42,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Sblocca CatDex Premium',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Continua a scoprire gatti, generare carte e completare '
                      'il tuo album senza limiti.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _UsageCard(reason: widget.reason, status: status),
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.12),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    _BenefitRow(
                      icon: Icons.auto_awesome_rounded,
                      label: 'Analisi gatto extra',
                    ),
                    _BenefitRow(
                      icon: Icons.style_rounded,
                      label: 'Generazioni carte extra',
                    ),
                    _BenefitRow(
                      icon: Icons.block_rounded,
                      label: 'Nessuna pubblicità',
                    ),
                    _BenefitRow(
                      icon: Icons.collections_bookmark_rounded,
                      label: 'Album carte completo',
                    ),
                    _BenefitRow(
                      icon: Icons.ios_share_rounded,
                      label: 'Salva e condividi le carte',
                    ),
                    _BenefitRow(
                      icon: Icons.celebration_rounded,
                      label: 'Template speciali evento in futuro',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () {
                debugPrint('CATDEX_PAYWALL_PREMIUM_TAPPED');
                _showPlaceholder(
                  context,
                  'Acquisti in-app in arrivo',
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Passa a CatDex Premium'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: adLoading
                  ? null
                  : () {
                      unawaited(_handleCreditsTap(context));
                    },
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: Text(rewardedButtonLabel),
            ),
            if (showDebugFallback) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () {
                  unawaited(_addDebugFallbackCredit(context));
                },
                icon: const Icon(Icons.bug_report_rounded),
                label: const Text('Debug: aggiungi credito'),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () {
                debugPrint('CATDEX_PAYWALL_DISMISSED');
                Navigator.of(context).pop();
              },
              child: const Text('Continua gratis'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleCreditsTap(BuildContext context) async {
    debugPrint('CATDEX_PAYWALL_CREDITS_TAPPED');
    if (!showAds) {
      _showPlaceholder(
        context,
        'Crediti extra tramite annunci in arrivo',
      );
      return;
    }

    final monetization = ref.read(monetizationServiceProvider);
    if (await monetization.isPremiumUser()) {
      if (!context.mounted) {
        return;
      }

      debugPrint('CATDEX_AD_SKIPPED_PREMIUM_USER');
      debugPrint('CATDEX_REWARDED_SKIPPED_PREMIUM_USER');
      _showPlaceholder(
        context,
        'Hai già Premium attivo.',
      );
      return;
    }

    final adMobService = ref.read(adMobServiceProvider);
    if (!adMobService.isRewardedAdLoaded) {
      debugPrint('CATDEX_REWARDED_AD_WAITING_FOR_LOAD');
      setState(() {
        _rewardLoading = true;
        _rewardUnavailable = false;
      });
      final ad = await adMobService.preloadRewardedAd();
      if (!context.mounted) {
        return;
      }

      setState(() {
        _rewardLoading = false;
        _rewardUnavailable = ad == null;
      });
      if (ad == null) {
        debugPrint('CATDEX_REWARDED_AD_FAILED_SHOW_RETRY');
        _showPlaceholder(
          context,
          'Annuncio non disponibile al momento. Riprova tra poco.',
        );
        return;
      }

      debugPrint('CATDEX_REWARDED_AD_LOADED_PAYWALL_REFRESH');
      debugPrint('CATDEX_REWARDED_AD_SHOW_AFTER_READY');
      return;
    }

    setState(() {
      _rewardLoading = true;
      _rewardUnavailable = false;
    });
    final rewarded = await adMobService.showRewardedForCredit(
      creditType: _rewardedCreditType,
    );

    if (!context.mounted) {
      return;
    }
    setState(() {
      _rewardLoading = false;
    });

    if (!rewarded) {
      debugPrint('CATDEX_REWARDED_AD_UNAVAILABLE');
      setState(() {
        _rewardUnavailable = true;
      });
      debugPrint('CATDEX_REWARDED_AD_FAILED_SHOW_RETRY');
      _showPlaceholder(
        context,
        'Annuncio non disponibile al momento. Riprova tra poco.',
      );
      return;
    }

    await _loadStatus();
    if (!context.mounted) {
      return;
    }

    _showPlaceholder(context, 'Credito extra aggiunto!');
    Navigator.of(context).pop();
  }

  Future<void> _prepareRewardedAd() async {
    if (!showAds) {
      return;
    }

    final monetization = ref.read(monetizationServiceProvider);
    if (await monetization.isPremiumUser()) {
      debugPrint('CATDEX_REWARDED_SKIPPED_PREMIUM_USER');
      return;
    }

    await ref.read(adMobServiceProvider).preloadRewardedAd();
    if (!mounted) {
      return;
    }

    debugPrint('CATDEX_REWARDED_AD_LOADED_PAYWALL_REFRESH');
    setState(() {});
  }

  String _rewardedButtonLabel({
    required bool loaded,
    required bool loading,
    required bool unavailable,
  }) {
    if (loading) {
      return 'Caricamento annuncio...';
    }

    if (loaded) {
      return 'Guarda annuncio e ottieni credito';
    }

    if (unavailable) {
      return 'Riprova';
    }

    return 'Caricamento annuncio...';
  }

  RewardedCreditType get _rewardedCreditType {
    return switch (widget.reason) {
      MonetizationLimitKind.analysis => RewardedCreditType.analysis,
      MonetizationLimitKind.cardGeneration => RewardedCreditType.cardGeneration,
    };
  }

  Future<void> _addDebugFallbackCredit(BuildContext context) async {
    debugPrint('CATDEX_DEBUG_REWARDED_FALLBACK_TAPPED');
    final monetization = ref.read(monetizationServiceProvider);
    switch (widget.reason) {
      case MonetizationLimitKind.analysis:
        await monetization.addAnalysisCredits(1);
        debugPrint('CATDEX_DEBUG_REWARDED_FALLBACK_CREDIT_ADDED analysis');
      case MonetizationLimitKind.cardGeneration:
        await monetization.addCardGenerationCredits(1);
        debugPrint('CATDEX_DEBUG_REWARDED_FALLBACK_CREDIT_ADDED card');
    }

    await _loadStatus();
    if (!context.mounted) {
      return;
    }

    _showPlaceholder(context, 'Credito extra aggiunto!');
    Navigator.of(context).pop();
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.reason,
    required this.status,
  });

  final MonetizationLimitKind reason;
  final MonetizationStatus? status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = switch (reason) {
      MonetizationLimitKind.analysis =>
        status == null
            ? 'Hai usato 3/3 analisi gratuite oggi.'
            : 'Hai usato ${status!.dailyAnalysisCount}/'
                  '${status!.maxDailyAnalyses} analisi gratuite oggi.',
      MonetizationLimitKind.cardGeneration =>
        status == null
            ? 'Hai usato 3/3 generazioni carte gratuite oggi.'
            : 'Hai usato ${status!.dailyCardGenerationCount}/'
                  '${status!.maxDailyCardGenerations} generazioni carte '
                  'gratuite '
                  'oggi.',
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_bottom_rounded,
              color: AppColors.warning,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                detail,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryPurple, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
