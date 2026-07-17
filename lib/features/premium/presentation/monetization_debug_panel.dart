import 'dart:async';

import 'package:catdex/features/achievements/presentation/achievement_debug_controls.dart';
import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/missions/presentation/daily_mission_debug_controls.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/features/premium/presentation/monetization_debug_controls.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonetizationDebugPanel extends ConsumerStatefulWidget {
  const MonetizationDebugPanel({super.key});

  @override
  ConsumerState<MonetizationDebugPanel> createState() =>
      _MonetizationDebugPanelState();
}

class _MonetizationDebugPanelState
    extends ConsumerState<MonetizationDebugPanel> {
  MonetizationStatus? _status;
  int _analysisInterstitialCounter = 0;
  int _cardInterstitialCounter = 0;
  bool _loading = true;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    if (showMonetizationDebug) {
      debugPrint('CATDEX_MONETIZATION_DEBUG_PANEL_VISIBLE true');
      ref.listenManual<int>(monetizationRefreshProvider, (_, _) {
        _scheduleRefresh();
      });
      unawaited(_refresh());
    } else {
      _loading = false;
    }
  }

  Future<void> _refresh() async {
    final status = await ref.read(monetizationServiceProvider).getStatus();
    final adMobService = ref.read(adMobServiceProvider);
    final analysisInterstitialCounter = await adMobService
        .getAnalysisInterstitialCounter();
    final cardInterstitialCounter = await adMobService
        .getCardGenerationInterstitialCounter();
    if (!mounted) {
      return;
    }

    setState(() {
      _status = status;
      _analysisInterstitialCounter = analysisInterstitialCounter;
      _cardInterstitialCounter = cardInterstitialCounter;
      _loading = false;
    });
  }

  Future<void> _run(Future<void> Function(MonetizationService service) action) {
    return () async {
      setState(() {
        _loading = true;
      });
      final service = ref.read(monetizationServiceProvider);
      await action(service);
      ref.read(adVisibilityRefreshProvider.notifier).refresh();
    }();
  }

  Future<void> _runAdDebugAction(Future<void> Function() action) {
    return () async {
      setState(() {
        _loading = true;
      });
      await action();
      await _refresh();
    }();
  }

  @override
  Widget build(BuildContext context) {
    if (!showMonetizationDebug) {
      return const SizedBox.shrink();
    }
    final status = _status;
    final premium = status?.isPremium == true;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Debug Monetizzazione',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_loading && status == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              _DebugMetric(
                label: 'Premium',
                value: premium ? 'ON' : 'OFF',
              ),
              _DebugMetric(
                label: 'Analisi usate oggi',
                value: '${status?.dailyAnalysisCount ?? 0}',
              ),
              _DebugMetric(
                label: 'Analisi rimaste oggi',
                value: premium
                    ? 'illimitate'
                    : '${status?.remainingDailyAnalyses ?? 0}',
              ),
              _DebugMetric(
                label: 'Generazioni carte usate oggi',
                value: '${status?.dailyCardGenerationCount ?? 0}',
              ),
              _DebugMetric(
                label: 'Generazioni carte rimaste oggi',
                value: premium
                    ? 'illimitate'
                    : '${status?.remainingDailyCardGenerations ?? 0}',
              ),
              _DebugMetric(
                label: 'Crediti analisi extra',
                value: '${status?.extraAnalysisCredits ?? 0}',
              ),
              _DebugMetric(
                label: 'Crediti carte extra',
                value: '${status?.extraCardGenerationCredits ?? 0}',
              ),
              _DebugMetric(
                label: 'Data ultimo reset',
                value: status?.lastLimitResetDate.isEmpty == false
                    ? status!.lastLimitResetDate
                    : '-',
              ),
              _DebugMetric(
                label: 'Interstitial analisi',
                value: '$_analysisInterstitialCounter',
              ),
              _DebugMetric(
                label: 'Interstitial carte',
                value: '$_cardInterstitialCounter',
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FilledButton(
                    onPressed: _loading
                        ? null
                        : () {
                            final nextValue = !premium;
                            debugPrint(
                              'CATDEX_MONETIZATION_DEBUG_TOGGLE_PREMIUM '
                              '$nextValue',
                            );
                            unawaited(
                              _run(
                                (service) =>
                                    service.setPremiumForDebug(nextValue),
                              ),
                            );
                          },
                    child: Text(premium ? 'Premium OFF' : 'Premium ON'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            debugPrint(
                              'CATDEX_MONETIZATION_DEBUG_RESET_LIMITS',
                            );
                            unawaited(
                              _run(
                                (service) => service.resetDailyLimitsForDebug(),
                              ),
                            );
                          },
                    child: const Text('Reset daily limits'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            debugPrint(
                              'CATDEX_MONETIZATION_DEBUG_ADD_ANALYSIS_CREDITS '
                              '10',
                            );
                            unawaited(
                              _run(
                                (service) =>
                                    service.addAnalysisCreditsForDebug(10),
                              ),
                            );
                          },
                    child: const Text('+10 analysis credits'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            debugPrint(
                              'CATDEX_MONETIZATION_DEBUG_ADD_CARD_CREDITS 10',
                            );
                            unawaited(
                              _run(
                                (service) => service
                                    .addCardGenerationCreditsForDebug(10),
                              ),
                            );
                          },
                    child: const Text('+10 card credits'),
                  ),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            unawaited(
                              _run(
                                (service) =>
                                    service.clearExtraCreditsForDebug(),
                              ),
                            );
                          },
                    child: const Text('Clear extra credits'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            unawaited(
                              _runAdDebugAction(
                                () => ref
                                    .read(adMobServiceProvider)
                                    .resetInterstitialCounters(),
                              ),
                            );
                          },
                    child: const Text('Reset interstitial counters'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            unawaited(
                              _runAdDebugAction(
                                () async {
                                  await ref
                                      .read(adMobServiceProvider)
                                      .preloadInterstitialAd();
                                },
                              ),
                            );
                          },
                    child: const Text('Force load interstitial'),
                  ),
                  OutlinedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            final route = ModalRoute.of(context);
                            unawaited(
                              _runAdDebugAction(
                                () async {
                                  await ref
                                      .read(adMobServiceProvider)
                                      .forceShowInterstitialForDebug(
                                        safeForAds: route?.isCurrent == true,
                                      );
                                },
                              ),
                            );
                          },
                    child: const Text('Force show interstitial'),
                  ),
                ],
              ),
              const DailyMissionDebugControls(),
              const AchievementDebugControls(),
            ],
          ],
        ),
      ),
    );
  }

  void _scheduleRefresh() {
    if (_refreshScheduled) {
      debugPrint(
        'CATDEX_PROVIDER_UPDATE_DEDUPLICATED '
        'provider=monetization_debug_panel reason=already_scheduled',
      );
      return;
    }
    _refreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!mounted) return;
      unawaited(_refresh());
    });
  }
}

class _DebugMetric extends StatelessWidget {
  const _DebugMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.white.withValues(alpha: 0.74),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
