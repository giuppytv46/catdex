import 'package:catdex/shared/state/build_safe_refresh_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final monetizationRefreshProvider =
    NotifierProvider<MonetizationRefreshController, int>(
      MonetizationRefreshController.new,
    );

final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return MonetizationService(
    ref.read(monetizationRefreshProvider.notifier).refresh,
  );
});

final monetizationStatusSummaryProvider =
    FutureProvider<MonetizationStatusSummary>((ref) async {
      ref.watch(monetizationRefreshProvider);
      return ref
          .watch(monetizationServiceProvider)
          .getMonetizationStatusSummary();
    });

final monetizationStatusProvider = FutureProvider<MonetizationStatus>((
  ref,
) async {
  ref.watch(monetizationRefreshProvider);
  return ref.watch(monetizationServiceProvider).getStatus();
});

class MonetizationRefreshController extends BuildSafeRefreshController {
  MonetizationRefreshController() : super('monetization_status');

  @override
  void refresh() {
    debugPrint('CATDEX_MONETIZATION_NOTIFY_LISTENERS');
    super.refresh();
  }
}

class MonetizationStatus {
  const MonetizationStatus({
    required this.isPremium,
    required this.dailyAnalysisCount,
    required this.dailyCardGenerationCount,
    required this.extraAnalysisCredits,
    required this.extraCardGenerationCredits,
    required this.lastLimitResetDate,
  });

  final bool isPremium;
  final int dailyAnalysisCount;
  final int dailyCardGenerationCount;
  final int extraAnalysisCredits;
  final int extraCardGenerationCredits;
  final String lastLimitResetDate;

  Map<String, Object?> toDebugJson() {
    return {
      'isPremium': isPremium,
      'dailyAnalysisCount': dailyAnalysisCount,
      'dailyCardGenerationCount': dailyCardGenerationCount,
      'extraAnalysisCredits': extraAnalysisCredits,
      'extraCardGenerationCredits': extraCardGenerationCredits,
      'lastLimitResetDate': lastLimitResetDate,
    };
  }

  int get maxDailyAnalyses => MonetizationService.freeDailyAnalysisLimit;
  int get maxDailyCardGenerations =>
      MonetizationService.freeDailyCardGenerationLimit;

  int get remainingDailyAnalyses {
    return (maxDailyAnalyses - dailyAnalysisCount).clamp(0, maxDailyAnalyses);
  }

  int get remainingDailyCardGenerations {
    return (maxDailyCardGenerations - dailyCardGenerationCount).clamp(
      0,
      maxDailyCardGenerations,
    );
  }
}

class MonetizationStatusSummary {
  const MonetizationStatusSummary({
    required this.status,
  });

  final MonetizationStatus status;

  bool get isPremium => status.isPremium;
  bool get premiumUnlimited => status.isPremium;
  int get remainingDailyAnalyses => status.remainingDailyAnalyses;
  int get remainingDailyCardGenerations => status.remainingDailyCardGenerations;
  int get maxDailyAnalyses => status.maxDailyAnalyses;
  int get maxDailyCardGenerations => status.maxDailyCardGenerations;
  int get extraAnalysisCredits => status.extraAnalysisCredits;
  int get extraCardGenerationCredits => status.extraCardGenerationCredits;

  String get analysisUsageLabel {
    if (isPremium) {
      return 'Premium attivo · Analisi illimitate';
    }

    final base =
        'Analisi rimaste oggi: $remainingDailyAnalyses/$maxDailyAnalyses';
    if (extraAnalysisCredits > 0) {
      return '$base · Crediti extra: $extraAnalysisCredits';
    }

    return base;
  }

  String get cardGenerationUsageLabel {
    if (isPremium) {
      return 'Premium attivo · Carte illimitate';
    }

    final base =
        'Generazioni carte rimaste oggi: '
        '$remainingDailyCardGenerations/$maxDailyCardGenerations';
    if (extraCardGenerationCredits > 0) {
      return '$base · Crediti extra: $extraCardGenerationCredits';
    }

    return base;
  }

  String get analysisLimitReachedDetail {
    return 'Hai usato $maxDailyAnalyses/$maxDailyAnalyses analisi gratuite oggi.';
  }

  String get cardGenerationLimitReachedDetail {
    return 'Hai usato $maxDailyCardGenerations/$maxDailyCardGenerations '
        'generazioni carte gratuite oggi.';
  }
}

enum CardGenerationCreditReservationResult {
  reserved,
  duplicate,
  unavailable,
}

class MonetizationService {
  MonetizationService(this._notifyListeners);

  final VoidCallback _notifyListeners;
  final Set<String> _cardGenerationCreditReservations = <String>{};

  static const freeDailyAnalysisLimit = 3;
  static const freeDailyCardGenerationLimit = 3;

  static const _isPremiumKey = 'catdex_monetization_is_premium';
  static const _dailyAnalysisCountKey =
      'catdex_monetization_daily_analysis_count';
  static const _dailyCardGenerationCountKey =
      'catdex_monetization_daily_card_generation_count';
  static const _extraAnalysisCreditsKey =
      'catdex_monetization_extra_analysis_credits';
  static const _extraCardGenerationCreditsKey =
      'catdex_monetization_extra_card_generation_credits';
  static const _lastLimitResetDateKey =
      'catdex_monetization_last_limit_reset_date';
  static String? _lastStatusLog;
  static DateTime? _lastStatusLogAt;
  String? _lastNotifiedStatusSignature;
  int _refreshTransactionSequence = 0;

  Future<bool> canAnalyzeCat() async {
    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    final used = preferences.getInt(_dailyAnalysisCountKey) ?? 0;
    final credits = preferences.getInt(_extraAnalysisCreditsKey) ?? 0;
    final allowed = premium || used < freeDailyAnalysisLimit || credits > 0;

    debugPrint(
      'CATDEX_ANALYSIS_LIMIT_CHECK premium=$premium used=$used '
      'limit=$freeDailyAnalysisLimit credits=$credits allowed=$allowed',
    );
    if (!premium && used < freeDailyAnalysisLimit) {
      debugPrint('CATDEX_ANALYSIS_ALLOWED_DAILY');
    } else if (!premium && credits > 0) {
      debugPrint('CATDEX_ANALYSIS_ALLOWED_EXTRA_CREDIT');
    }
    _logStatus(preferences);
    return allowed;
  }

  Future<bool> consumeAnalysis() async {
    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    if (premium) {
      debugPrint('CATDEX_PREMIUM_BYPASS_LIMIT analysis');
      _logStatus(preferences);
      return true;
    }

    final used = preferences.getInt(_dailyAnalysisCountKey) ?? 0;
    if (used < freeDailyAnalysisLimit) {
      await preferences.setInt(_dailyAnalysisCountKey, used + 1);
      debugPrint('CATDEX_ANALYSIS_USAGE_CONSUMED');
      _logStatus(preferences);
      _notifyUsageChanged(preferences);
      return true;
    }

    final credits = preferences.getInt(_extraAnalysisCreditsKey) ?? 0;
    if (credits > 0) {
      await preferences.setInt(_extraAnalysisCreditsKey, credits - 1);
      debugPrint('CATDEX_ANALYSIS_USAGE_CONSUMED');
      debugPrint('CATDEX_EXTRA_ANALYSIS_CREDIT_CONSUMED');
      debugPrint('CATDEX_EXTRA_CREDIT_CONSUMED analysis');
      _logStatus(preferences);
      _notifyUsageChanged(preferences);
      return true;
    }

    debugPrint('CATDEX_FREE_LIMIT_REACHED analysis');
    _logStatus(preferences);
    return false;
  }

  Future<bool> canGenerateCard() async {
    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    final used = preferences.getInt(_dailyCardGenerationCountKey) ?? 0;
    final credits = preferences.getInt(_extraCardGenerationCreditsKey) ?? 0;
    final allowed =
        premium || used < freeDailyCardGenerationLimit || credits > 0;

    debugPrint(
      'CATDEX_CARD_GENERATION_LIMIT_CHECK premium=$premium used=$used '
      'limit=$freeDailyCardGenerationLimit credits=$credits allowed=$allowed',
    );
    if (!premium && used < freeDailyCardGenerationLimit) {
      debugPrint('CATDEX_CARD_GENERATION_ALLOWED_DAILY');
    } else if (!premium && credits > 0) {
      debugPrint('CATDEX_CARD_GENERATION_ALLOWED_EXTRA_CREDIT');
    }
    _logStatus(preferences);
    return allowed;
  }

  Future<CardGenerationCreditReservationResult> reserveCardGenerationCredit(
    String discoveryId,
  ) async {
    final normalizedId = discoveryId.trim();
    if (_cardGenerationCreditReservations.contains(normalizedId)) {
      debugPrint('CATDEX_CARD_GENERATION_DUPLICATE_BLOCKED $normalizedId');
      return CardGenerationCreditReservationResult.duplicate;
    }

    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    final used = preferences.getInt(_dailyCardGenerationCountKey) ?? 0;
    final credits = preferences.getInt(_extraCardGenerationCreditsKey) ?? 0;
    final remainingDaily = (freeDailyCardGenerationLimit - used).clamp(
      0,
      freeDailyCardGenerationLimit,
    );
    final availableUnits = remainingDaily + credits;
    if (!premium &&
        _cardGenerationCreditReservations.length >= availableUnits) {
      debugPrint('CATDEX_FREE_LIMIT_REACHED card_generation');
      return CardGenerationCreditReservationResult.unavailable;
    }

    _cardGenerationCreditReservations.add(normalizedId);
    debugPrint('CATDEX_CARD_CREDIT_RESERVED $normalizedId');
    return CardGenerationCreditReservationResult.reserved;
  }

  Future<bool> commitCardGenerationCredit(String discoveryId) async {
    final normalizedId = discoveryId.trim();
    if (!_cardGenerationCreditReservations.remove(normalizedId)) {
      return false;
    }

    final committed = await consumeCardGeneration();
    if (committed) {
      debugPrint('CATDEX_CARD_CREDIT_COMMITTED $normalizedId');
      return true;
    }

    debugPrint('CATDEX_CARD_CREDIT_RELEASED $normalizedId commit_failed');
    return false;
  }

  void releaseCardGenerationCredit(String discoveryId) {
    final normalizedId = discoveryId.trim();
    if (_cardGenerationCreditReservations.remove(normalizedId)) {
      debugPrint('CATDEX_CARD_CREDIT_RELEASED $normalizedId');
    }
  }

  Future<bool> consumeCardGeneration() async {
    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    if (premium) {
      debugPrint('CATDEX_PREMIUM_BYPASS_LIMIT card_generation');
      _logStatus(preferences);
      return true;
    }

    final used = preferences.getInt(_dailyCardGenerationCountKey) ?? 0;
    if (used < freeDailyCardGenerationLimit) {
      await preferences.setInt(_dailyCardGenerationCountKey, used + 1);
      debugPrint('CATDEX_CARD_GENERATION_USAGE_CONSUMED');
      _logStatus(preferences);
      _notifyUsageChanged(preferences);
      return true;
    }

    final credits = preferences.getInt(_extraCardGenerationCreditsKey) ?? 0;
    if (credits > 0) {
      await preferences.setInt(_extraCardGenerationCreditsKey, credits - 1);
      debugPrint('CATDEX_CARD_GENERATION_USAGE_CONSUMED');
      debugPrint('CATDEX_EXTRA_CARD_CREDIT_CONSUMED');
      debugPrint('CATDEX_EXTRA_CREDIT_CONSUMED card_generation');
      _logStatus(preferences);
      _notifyUsageChanged(preferences);
      return true;
    }

    debugPrint('CATDEX_FREE_LIMIT_REACHED card_generation');
    _logStatus(preferences);
    return false;
  }

  Future<bool> isPremiumUser() async {
    final preferences = await _preparedPreferences();
    final premium = preferences.getBool(_isPremiumKey) ?? false;
    _logStatus(preferences);
    return premium;
  }

  Future<int> getRemainingDailyAnalyses() async {
    final status = await getStatus();
    _logUsage(status);
    return status.remainingDailyAnalyses;
  }

  Future<int> getRemainingDailyCardGenerations() async {
    final status = await getStatus();
    _logUsage(status);
    return status.remainingDailyCardGenerations;
  }

  int getMaxDailyAnalyses() {
    return freeDailyAnalysisLimit;
  }

  int getMaxDailyCardGenerations() {
    return freeDailyCardGenerationLimit;
  }

  Future<int> getExtraAnalysisCredits() async {
    final status = await getStatus();
    _logUsage(status);
    return status.extraAnalysisCredits;
  }

  Future<int> getExtraCardGenerationCredits() async {
    final status = await getStatus();
    _logUsage(status);
    return status.extraCardGenerationCredits;
  }

  Future<MonetizationStatusSummary> getMonetizationStatusSummary() async {
    final status = await getStatus();
    _logUsage(status);
    return MonetizationStatusSummary(status: status);
  }

  // Keep the debug helper signature aligned with the sprint contract.
  // ignore: avoid_positional_boolean_parameters
  Future<void> setPremiumForDebug(bool value) async {
    final preferences = await _preparedPreferences();
    await preferences.setBool(_isPremiumKey, value);
    _logStatus(preferences);
    _notifyUsageChanged(preferences);
  }

  Future<void> resetDailyLimitsForDebug() async {
    final preferences = await _preparedPreferences();
    await _resetDailyCounts(preferences, _todayKey());
    _logStatus(preferences);
    _notifyUsageChanged(preferences);
  }

  Future<void> addAnalysisCreditsForDebug(int amount) async {
    await addAnalysisCredits(amount);
  }

  Future<void> addAnalysisCredits(int amount) async {
    final preferences = await _preparedPreferences();
    final current = preferences.getInt(_extraAnalysisCreditsKey) ?? 0;
    await preferences.setInt(_extraAnalysisCreditsKey, current + amount);
    _logStatus(preferences);
    _notifyUsageChanged(preferences);
  }

  Future<void> addCardGenerationCreditsForDebug(int amount) async {
    await addCardGenerationCredits(amount);
  }

  Future<void> addCardGenerationCredits(int amount) async {
    final preferences = await _preparedPreferences();
    final current = preferences.getInt(_extraCardGenerationCreditsKey) ?? 0;
    await preferences.setInt(_extraCardGenerationCreditsKey, current + amount);
    _logStatus(preferences);
    _notifyUsageChanged(preferences);
  }

  Future<void> clearExtraCreditsForDebug() async {
    final preferences = await _preparedPreferences();
    await preferences.setInt(_extraAnalysisCreditsKey, 0);
    await preferences.setInt(_extraCardGenerationCreditsKey, 0);
    _logStatus(preferences);
    _notifyUsageChanged(preferences);
  }

  Future<MonetizationStatus> getStatus() async {
    final preferences = await _preparedPreferences();
    _logStatus(preferences);
    return MonetizationStatus(
      isPremium: preferences.getBool(_isPremiumKey) ?? false,
      dailyAnalysisCount: preferences.getInt(_dailyAnalysisCountKey) ?? 0,
      dailyCardGenerationCount:
          preferences.getInt(_dailyCardGenerationCountKey) ?? 0,
      extraAnalysisCredits: preferences.getInt(_extraAnalysisCreditsKey) ?? 0,
      extraCardGenerationCredits:
          preferences.getInt(_extraCardGenerationCreditsKey) ?? 0,
      lastLimitResetDate: preferences.getString(_lastLimitResetDateKey) ?? '',
    );
  }

  Future<SharedPreferences> _preparedPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final today = _todayKey();
    final lastReset = preferences.getString(_lastLimitResetDateKey);
    if (lastReset != today) {
      await _resetDailyCounts(preferences, today);
      _notifyUsageChanged(preferences);
    }

    return preferences;
  }

  Future<void> _resetDailyCounts(
    SharedPreferences preferences,
    String today,
  ) async {
    await preferences.setInt(_dailyAnalysisCountKey, 0);
    await preferences.setInt(_dailyCardGenerationCountKey, 0);
    await preferences.setString(_lastLimitResetDateKey, today);
    debugPrint('CATDEX_DAILY_LIMITS_RESET $today');
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  void _logStatus(SharedPreferences preferences) {
    final message =
        'CATDEX_MONETIZATION_STATUS '
        'premium=${preferences.getBool(_isPremiumKey) ?? false} '
        'analysis=${preferences.getInt(_dailyAnalysisCountKey) ?? 0} '
        'cards=${preferences.getInt(_dailyCardGenerationCountKey) ?? 0} '
        'analysisCredits='
        '${preferences.getInt(_extraAnalysisCreditsKey) ?? 0} '
        'cardCredits='
        '${preferences.getInt(_extraCardGenerationCreditsKey) ?? 0}';
    final now = DateTime.now();
    if (_lastStatusLog == message &&
        _lastStatusLogAt != null &&
        now.difference(_lastStatusLogAt!) <= const Duration(seconds: 12)) {
      return;
    }

    _lastStatusLog = message;
    _lastStatusLogAt = now;
    debugPrint(message);
  }

  void _logUsage(MonetizationStatus status) {
    debugPrint(
      'CATDEX_USAGE_REMAINING_ANALYSES ${status.remainingDailyAnalyses}',
    );
    debugPrint(
      'CATDEX_USAGE_REMAINING_CARD_GENERATIONS '
      '${status.remainingDailyCardGenerations}',
    );
    debugPrint(
      'CATDEX_USAGE_EXTRA_ANALYSIS_CREDITS '
      '${status.extraAnalysisCredits}',
    );
    debugPrint(
      'CATDEX_USAGE_EXTRA_CARD_CREDITS '
      '${status.extraCardGenerationCredits}',
    );
    debugPrint('CATDEX_USAGE_PREMIUM_UNLIMITED ${status.isPremium}');
  }

  void _notifyUsageChanged(SharedPreferences preferences) {
    final status = MonetizationStatus(
      isPremium: preferences.getBool(_isPremiumKey) ?? false,
      dailyAnalysisCount: preferences.getInt(_dailyAnalysisCountKey) ?? 0,
      dailyCardGenerationCount:
          preferences.getInt(_dailyCardGenerationCountKey) ?? 0,
      extraAnalysisCredits: preferences.getInt(_extraAnalysisCreditsKey) ?? 0,
      extraCardGenerationCredits:
          preferences.getInt(_extraCardGenerationCreditsKey) ?? 0,
      lastLimitResetDate: preferences.getString(_lastLimitResetDateKey) ?? '',
    );
    debugPrint(
      'CATDEX_USAGE_UI_ANALYSES_UPDATED '
      'remaining=${status.remainingDailyAnalyses} '
      'max=${status.maxDailyAnalyses} '
      'credits=${status.extraAnalysisCredits}',
    );
    debugPrint(
      'CATDEX_USAGE_UI_CARD_GENERATIONS_UPDATED '
      'remaining=${status.remainingDailyCardGenerations} '
      'max=${status.maxDailyCardGenerations} '
      'credits=${status.extraCardGenerationCredits}',
    );
    final signature = [
      status.isPremium,
      status.dailyAnalysisCount,
      status.dailyCardGenerationCount,
      status.extraAnalysisCredits,
      status.extraCardGenerationCredits,
      status.lastLimitResetDate,
    ].join(':');
    if (_lastNotifiedStatusSignature == signature) {
      debugPrint('CATDEX_MONETIZATION_REFRESH_SKIPPED_DUPLICATE');
      return;
    }

    _lastNotifiedStatusSignature = signature;
    final transaction = 'monetization-${++_refreshTransactionSequence}';
    debugPrint(
      'CATDEX_MONETIZATION_REFRESH_COMMITTED transaction=$transaction',
    );
    debugPrint('CATDEX_USAGE_UI_REFRESH_REQUESTED transaction=$transaction');
    _notifyListeners();
  }
}
