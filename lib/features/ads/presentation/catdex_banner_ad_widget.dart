import 'dart:async';

import 'package:catdex/features/ads/application/admob_service.dart';
import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/theme/app_colors.dart';
import 'package:catdex/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class CatDexBannerAdWidget extends ConsumerStatefulWidget {
  const CatDexBannerAdWidget({
    required this.placementLog,
    this.safeForAds = true,
    super.key,
  });

  final String placementLog;
  final bool safeForAds;

  @override
  ConsumerState<CatDexBannerAdWidget> createState() =>
      _CatDexBannerAdWidgetState();
}

class _CatDexBannerAdWidgetState extends ConsumerState<CatDexBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _loading = false;
  bool _loaded = false;
  bool _failed = false;
  bool _loadScheduled = false;
  bool _disposeScheduled = false;

  @override
  void initState() {
    super.initState();
    if (showAds) {
      debugPrint(widget.placementLog);
      debugPrint('CATDEX_AD_BANNER_WIDGET_MOUNTED');
    }
  }

  @override
  void dispose() {
    final bannerAd = _bannerAd;
    if (bannerAd != null) {
      unawaited(bannerAd.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final refreshVersion = ref.watch(adVisibilityRefreshProvider);
    return ValueListenableBuilder<int>(
      valueListenable: CatDexCelebrationCoordinator.instance.activityListenable,
      builder: (context, celebrationVersion, _) {
        return FutureBuilder<bool>(
          key: ValueKey('$refreshVersion:$celebrationVersion'),
          future: ref.read(monetizationServiceProvider).isPremiumUser(),
          builder: (context, snapshot) {
            final isPremium = snapshot.data == true;
            final visible = ref
                .read(adMobServiceProvider)
                .shouldShowAds(
                  isPremium: isPremium,
                  safeForAds: widget.safeForAds,
                );

            if (!visible) {
              _scheduleBannerDisposal();
              return const SizedBox.shrink();
            }

            if (snapshot.connectionState == ConnectionState.done &&
                !_loading &&
                !_loaded &&
                !_failed &&
                !_loadScheduled) {
              _loadScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadScheduled = false;
                if (!mounted) return;
                _loadBanner();
              });
            }

            return _BannerFrame(
              child: _loaded && _bannerAd != null
                  ? AdWidget(ad: _bannerAd!)
                  : Text(
                      _failed ? 'Banner Ad failed' : 'Banner Ad loading...',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            );
          },
        );
      },
    );
  }

  void _loadBanner() {
    setState(() {
      _loading = true;
    });
    debugPrint('CATDEX_AD_BANNER_LOAD_STARTED');

    final ad = ref
        .read(adMobServiceProvider)
        .createBannerAd(
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              if (!mounted) {
                unawaited(ad.dispose());
                return;
              }

              setState(() {
                _bannerAd = ad as BannerAd;
                _loading = false;
                _loaded = true;
                _failed = false;
              });
              debugPrint('CATDEX_AD_BANNER_LOADED');
            },
            onAdFailedToLoad: (ad, error) {
              unawaited(ad.dispose());
              if (!mounted) {
                return;
              }

              setState(() {
                _loading = false;
                _loaded = false;
                _failed = true;
              });
              debugPrint('CATDEX_AD_BANNER_FAILED $error');
            },
          ),
        );

    unawaited(ad.load());
  }

  void _disposeBanner() {
    final bannerAd = _bannerAd;
    if (bannerAd != null) {
      unawaited(bannerAd.dispose());
    }
    _bannerAd = null;
    _loading = false;
    _loaded = false;
    _failed = false;
  }

  void _scheduleBannerDisposal() {
    if (_disposeScheduled || _bannerAd == null) return;
    _disposeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _disposeScheduled = false;
      if (!mounted) return;
      _disposeBanner();
    });
  }
}

class _BannerFrame extends StatelessWidget {
  const _BannerFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 68,
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppSpacing.md),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.primaryPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryPurple.withValues(alpha: 0.42),
            width: 2,
          ),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: AdSize.banner.width.toDouble(),
          height: AdSize.banner.height.toDouble(),
          child: Center(child: child),
        ),
      ),
    );
  }
}
