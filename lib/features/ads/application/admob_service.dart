import 'dart:async';

import 'package:catdex/features/premium/application/local_monetization_service.dart';
import 'package:catdex/shared/celebrations/catdex_celebration_coordinator.dart';
import 'package:catdex/shared/state/build_safe_refresh_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keep ads opt-in for local development and production safety.
// ignore: avoid_redundant_argument_values
const bool showAds = bool.fromEnvironment('SHOW_ADS', defaultValue: false);

final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService(
    ref.read(monetizationServiceProvider),
    ref.read(rewardedAdStateRefreshProvider.notifier).refresh,
  );
});

final adVisibilityRefreshProvider =
    NotifierProvider<AdVisibilityRefreshController, int>(
      AdVisibilityRefreshController.new,
    );

final rewardedAdStateRefreshProvider =
    NotifierProvider<RewardedAdStateRefreshController, int>(
      RewardedAdStateRefreshController.new,
    );

class AdVisibilityRefreshController extends BuildSafeRefreshController {
  AdVisibilityRefreshController() : super('ad_visibility');
}

class RewardedAdStateRefreshController extends BuildSafeRefreshController {
  RewardedAdStateRefreshController() : super('rewarded_ad_state');
}

enum RewardedCreditType {
  analysis,
  cardGeneration,
}

enum RewardedAdLoadState {
  notLoaded,
  loading,
  loaded,
  failed,
}

enum InterstitialTrigger {
  analysis,
  card,
}

class AdMobService {
  AdMobService(this._monetizationService, this._notifyRewardedStateChanged);

  final MonetizationService _monetizationService;
  final VoidCallback _notifyRewardedStateChanged;

  static const _iosTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/2934735716';
  static const _androidTestBannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/4411468910';
  static const _androidTestInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';
  static const _iosTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/1712485313';
  static const _androidTestRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _interstitialLoading = false;
  RewardedAdLoadState _rewardedState = RewardedAdLoadState.notLoaded;
  String? _lastRewardedAdError;
  String? _lastVisibilityLogKey;
  DateTime? _lastVisibilityLogAt;

  static const _successfulAnalysesSinceLastInterstitialKey =
      'successfulAnalysesSinceLastInterstitial';
  static const _successfulCardGenerationsSinceLastInterstitialKey =
      'successfulCardGenerationsSinceLastInterstitial';
  static const _interstitialThreshold = 3;
  static Future<void>? _initializeFuture;

  bool get isRewardedAdLoaded => _rewardedAd != null;
  bool get isRewardedAdLoading => _rewardedState == RewardedAdLoadState.loading;
  bool get isInterstitialAdLoaded => _interstitialAd != null;
  String? get lastRewardedAdError => _lastRewardedAdError;

  static Future<void> initialize() async {
    final existing = _initializeFuture;
    if (existing != null) {
      return existing;
    }

    _initializeFuture = _initialize();
    return _initializeFuture!;
  }

  static Future<void> _initialize() async {
    debugPrint('CATDEX_SHOW_ADS_FLAG $showAds');
    if (!showAds) {
      debugPrint('CATDEX_ADMOB_DISABLED_SHOW_ADS_FALSE');
      debugPrint('CATDEX_ADMOB_DISABLED');
      return;
    }

    debugPrint('CATDEX_ADMOB_INIT');
    debugPrint('CATDEX_ADMOB_INIT_STARTED');
    try {
      await MobileAds.instance.initialize();
      debugPrint('CATDEX_ADMOB_INIT_SUCCESS');
    } on Object catch (error) {
      debugPrint('CATDEX_ADMOB_INIT_FAILED $error');
    }
  }

  BannerAd createBannerAd({
    required BannerAdListener listener,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: listener,
    );
  }

  bool shouldShowAds({
    required bool isPremium,
    required bool safeForAds,
  }) {
    final celebrationIdle = !CatDexCelebrationCoordinator.instance.isBusy;
    final result = showAds && !isPremium && safeForAds && celebrationIdle;
    final logKey = '$showAds|$isPremium|$safeForAds|$celebrationIdle|$result';
    final now = DateTime.now();
    final shouldLog =
        _lastVisibilityLogKey != logKey ||
        _lastVisibilityLogAt == null ||
        now.difference(_lastVisibilityLogAt!) > const Duration(seconds: 12);
    if (shouldLog) {
      _lastVisibilityLogKey = logKey;
      _lastVisibilityLogAt = now;
      debugPrint(
        'CATDEX_AD_VISIBILITY_CHECK showAds=$showAds premium=$isPremium '
        'result=$result',
      );

      if (!showAds) {
        debugPrint('CATDEX_ADS_HIDDEN_SHOW_ADS_FALSE');
      } else if (isPremium) {
        debugPrint('CATDEX_ADS_HIDDEN_PREMIUM_TRUE');
        debugPrint('CATDEX_AD_SKIPPED_PREMIUM_USER');
      } else if (!safeForAds || !celebrationIdle) {
        debugPrint('CATDEX_ADS_HIDDEN_UNSAFE_STATE');
      }
    }

    return result;
  }

  Future<InterstitialAd?> loadInterstitialAd() async {
    if (!showAds) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_SHOW_ADS_FALSE');
      return null;
    }

    debugPrint('CATDEX_INTERSTITIAL_LOAD_STARTED');
    InterstitialAd? loadedAd;
    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          loadedAd = ad;
          debugPrint('CATDEX_INTERSTITIAL_LOADED');
        },
        onAdFailedToLoad: (error) {
          debugPrint('CATDEX_INTERSTITIAL_FAILED $error');
        },
      ),
    );
    return loadedAd;
  }

  Future<InterstitialAd?> preloadInterstitialAd() async {
    if (!showAds) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_SHOW_ADS_FALSE');
      return null;
    }

    if (await _monetizationService.isPremiumUser()) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_PREMIUM_USER');
      return null;
    }

    if (_interstitialAd != null || _interstitialLoading) {
      return _interstitialAd;
    }

    debugPrint('CATDEX_INTERSTITIAL_PRELOAD_REQUESTED');
    _interstitialLoading = true;
    final ad = await loadInterstitialAd();
    _interstitialLoading = false;
    _interstitialAd = ad;
    if (ad == null) {
      Future<void>.delayed(const Duration(seconds: 8), () {
        unawaited(preloadInterstitialAd());
      });
    }
    return ad;
  }

  Future<void> recordSuccessfulAnalysisAndMaybeShow({
    required bool safeForAds,
  }) async {
    await _recordSuccessAndMaybeShow(
      trigger: InterstitialTrigger.analysis,
      safeForAds: safeForAds,
    );
  }

  Future<void> recordSuccessfulCardGenerationAndMaybeShow({
    required bool safeForAds,
  }) async {
    await _recordSuccessAndMaybeShow(
      trigger: InterstitialTrigger.card,
      safeForAds: safeForAds,
    );
  }

  Future<int> getAnalysisInterstitialCounter() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_successfulAnalysesSinceLastInterstitialKey) ?? 0;
  }

  Future<int> getCardGenerationInterstitialCounter() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(
          _successfulCardGenerationsSinceLastInterstitialKey,
        ) ??
        0;
  }

  Future<void> resetInterstitialCounters() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_successfulAnalysesSinceLastInterstitialKey, 0);
    await preferences.setInt(
      _successfulCardGenerationsSinceLastInterstitialKey,
      0,
    );
    debugPrint('CATDEX_INTERSTITIAL_COUNTER_RESET analysis');
    debugPrint('CATDEX_INTERSTITIAL_COUNTER_RESET card');
  }

  Future<bool> forceShowInterstitialForDebug({required bool safeForAds}) {
    return _showInterstitial(
      trigger: InterstitialTrigger.card,
      safeForAds: safeForAds,
    );
  }

  Future<bool> showRewardedAd({
    required Future<void> Function() onRewardGranted,
  }) async {
    if (!showAds) {
      debugPrint('CATDEX_REWARDED_AD_UNAVAILABLE show_ads_false');
      return false;
    }

    debugPrint('CATDEX_REWARDED_AD_SHOW_REQUESTED');
    final ad = _rewardedAd ?? await preloadRewardedAd();
    _rewardedAd = null;
    if (ad == null) {
      debugPrint('CATDEX_REWARDED_AD_NOT_READY');
      debugPrint('CATDEX_REWARDED_AD_UNAVAILABLE');
      return false;
    }

    var rewarded = false;
    Future<void>? rewardFuture;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        debugPrint('CATDEX_REWARDED_AD_RELOAD_AFTER_SHOW');
        _setRewardedState(RewardedAdLoadState.notLoaded);
        unawaited(preloadRewardedAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('CATDEX_REWARDED_AD_FAILED $error');
        unawaited(ad.dispose());
        debugPrint('CATDEX_REWARDED_AD_RELOAD_AFTER_SHOW');
        _lastRewardedAdError = error.toString();
        _setRewardedState(RewardedAdLoadState.notLoaded);
        unawaited(preloadRewardedAd());
      },
    );
    await ad.show(
      onUserEarnedReward: (_, _) {
        rewarded = true;
        debugPrint('CATDEX_REWARDED_AD_REWARD_GRANTED');
        rewardFuture = onRewardGranted();
      },
    );
    debugPrint('CATDEX_REWARDED_AD_SHOWN');
    await rewardFuture;
    return rewarded;
  }

  Future<bool> showRewardedForCredit({
    required RewardedCreditType creditType,
  }) async {
    if (!showAds) {
      debugPrint('CATDEX_REWARDED_SKIPPED_SHOW_ADS_FALSE');
      return false;
    }

    if (await _monetizationService.isPremiumUser()) {
      debugPrint('CATDEX_REWARDED_SKIPPED_PREMIUM_USER');
      return false;
    }

    return showRewardedAd(
      onRewardGranted: () async {
        switch (creditType) {
          case RewardedCreditType.analysis:
            debugPrint('CATDEX_REWARDED_CREDIT_TYPE analysis');
            await _monetizationService.addAnalysisCredits(1);
          case RewardedCreditType.cardGeneration:
            debugPrint('CATDEX_REWARDED_CREDIT_TYPE card');
            await _monetizationService.addCardGenerationCredits(1);
        }
        debugPrint('CATDEX_REWARDED_CREDIT_ADDED');
      },
    );
  }

  Future<RewardedAd?> preloadRewardedAd() async {
    if (!showAds) {
      debugPrint('CATDEX_REWARDED_SKIPPED_SHOW_ADS_FALSE');
      return null;
    }

    debugPrint('CATDEX_REWARDED_AD_PRELOAD_REQUESTED');

    if (await _monetizationService.isPremiumUser()) {
      debugPrint('CATDEX_REWARDED_SKIPPED_PREMIUM_USER');
      return null;
    }

    if (_rewardedAd != null) {
      _setRewardedState(RewardedAdLoadState.loaded);
      return _rewardedAd;
    }

    if (_rewardedState == RewardedAdLoadState.loading) {
      return null;
    }

    _lastRewardedAdError = null;
    _setRewardedState(RewardedAdLoadState.loading);
    debugPrint('CATDEX_REWARDED_AD_LOAD_STARTED');
    RewardedAd? loadedAd;
    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          loadedAd = ad;
          _lastRewardedAdError = null;
          _setRewardedState(RewardedAdLoadState.loaded);
          debugPrint('CATDEX_REWARDED_AD_LOADED');
        },
        onAdFailedToLoad: (error) {
          _lastRewardedAdError = error.toString();
          _setRewardedState(RewardedAdLoadState.failed);
          debugPrint('CATDEX_REWARDED_AD_FAILED $error');
          Future<void>.delayed(const Duration(seconds: 8), () {
            unawaited(preloadRewardedAd());
          });
        },
      ),
    );
    _rewardedAd = loadedAd;
    if (loadedAd == null && _rewardedState == RewardedAdLoadState.loading) {
      _setRewardedState(RewardedAdLoadState.failed);
    }
    return loadedAd;
  }

  Future<void> _recordSuccessAndMaybeShow({
    required InterstitialTrigger trigger,
    required bool safeForAds,
  }) async {
    if (!showAds) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_SHOW_ADS_FALSE');
      return;
    }

    if (await _monetizationService.isPremiumUser()) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_PREMIUM_USER');
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    final key = _counterKey(trigger);
    final nextCount = (preferences.getInt(key) ?? 0) + 1;
    await preferences.setInt(key, nextCount);
    _logCounter(trigger, nextCount);

    if (nextCount < _interstitialThreshold) {
      unawaited(preloadInterstitialAd());
      return;
    }

    final attempted = await _showInterstitial(
      trigger: trigger,
      safeForAds: safeForAds,
    );
    if (attempted) {
      await _resetCounter(trigger);
    }
  }

  Future<bool> _showInterstitial({
    required InterstitialTrigger trigger,
    required bool safeForAds,
  }) async {
    final label = _triggerLabel(trigger);
    debugPrint('CATDEX_INTERSTITIAL_SHOW_REQUESTED $label');
    if (!showAds) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_SHOW_ADS_FALSE');
      return false;
    }

    if (await _monetizationService.isPremiumUser()) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_PREMIUM_USER');
      return false;
    }

    if (!safeForAds) {
      debugPrint('CATDEX_INTERSTITIAL_SKIPPED_UNSAFE_STATE');
      return false;
    }

    // Give a success widget scheduled in the same frame time to acquire its
    // celebration lease before an interstitial is allowed on screen.
    await Future<void>.delayed(Duration.zero);
    final celebrations = CatDexCelebrationCoordinator.instance;
    if (celebrations.isBusy) {
      debugPrint('CATDEX_CELEBRATION_AD_DEFERRED');
      await celebrations.waitUntilIdle();
    }

    final ad = _interstitialAd;
    _interstitialAd = null;
    if (ad == null) {
      debugPrint('CATDEX_INTERSTITIAL_NOT_READY_CONTINUE');
      unawaited(preloadInterstitialAd());
      return true;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        unawaited(ad.dispose());
        unawaited(preloadInterstitialAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('CATDEX_INTERSTITIAL_FAILED $error');
        unawaited(ad.dispose());
        unawaited(preloadInterstitialAd());
      },
    );
    await ad.show();
    debugPrint('CATDEX_INTERSTITIAL_SHOWN $label');
    return true;
  }

  Future<void> _resetCounter(InterstitialTrigger trigger) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_counterKey(trigger), 0);
    debugPrint('CATDEX_INTERSTITIAL_COUNTER_RESET ${_triggerLabel(trigger)}');
  }

  void _logCounter(InterstitialTrigger trigger, int count) {
    switch (trigger) {
      case InterstitialTrigger.analysis:
        debugPrint('CATDEX_INTERSTITIAL_ANALYSIS_COUNTER $count');
      case InterstitialTrigger.card:
        debugPrint('CATDEX_INTERSTITIAL_CARD_COUNTER $count');
    }
  }

  String _counterKey(InterstitialTrigger trigger) {
    return switch (trigger) {
      InterstitialTrigger.analysis =>
        _successfulAnalysesSinceLastInterstitialKey,
      InterstitialTrigger.card =>
        _successfulCardGenerationsSinceLastInterstitialKey,
    };
  }

  String _triggerLabel(InterstitialTrigger trigger) {
    return switch (trigger) {
      InterstitialTrigger.analysis => 'analysis',
      InterstitialTrigger.card => 'card',
    };
  }

  void _setRewardedState(RewardedAdLoadState state) {
    if (_rewardedState == state) {
      debugPrint(
        'CATDEX_PROVIDER_UPDATE_DEDUPLICATED '
        'provider=rewarded_ad_state reason=unchanged',
      );
      return;
    }
    _rewardedState = state;
    _notifyRewardedStateChanged();
  }

  String get bannerAdUnitId {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestBannerAdUnitId
        : _androidTestBannerAdUnitId;
  }

  String get interstitialAdUnitId {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestInterstitialAdUnitId
        : _androidTestInterstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    return defaultTargetPlatform == TargetPlatform.iOS
        ? _iosTestRewardedAdUnitId
        : _androidTestRewardedAdUnitId;
  }
}
