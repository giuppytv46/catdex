import 'dart:async';

import 'package:catdex/core/localization/catdex_localizations.dart';
import 'package:catdex/features/achievements/application/achievement_controller.dart';
import 'package:catdex/features/achievements/presentation/achievement_celebration_presenter.dart';
import 'package:catdex/features/cards/application/cat_card_repository_providers.dart';
import 'package:catdex/features/cards/domain/cat_card_record.dart';
import 'package:catdex/features/catdex/application/local_discovery_session_controller.dart';
import 'package:catdex/features/catdex/application/local_player_progress_session_controller.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/player_progress.dart';
import 'package:catdex/features/missions/application/daily_mission_controller.dart';
import 'package:catdex/features/missions/domain/entities/daily_mission_ledger.dart';
import 'package:catdex/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AchievementBootstrapScope extends ConsumerStatefulWidget {
  const AchievementBootstrapScope({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AchievementBootstrapScope> createState() =>
      _AchievementBootstrapScopeState();
}

class _AchievementBootstrapScopeState
    extends ConsumerState<AchievementBootstrapScope> {
  Timer? _debounce;
  Future<void> _presentationTail = Future<void>.value();

  @override
  void initState() {
    super.initState();
    ref
      ..listenManual<List<CatDiscovery>>(
        localDiscoverySessionProvider,
        (_, _) => _scheduleEvaluation('discovery_repository_changed'),
      )
      ..listenManual<List<CatCardRecord>>(
        catCardCollectionProvider,
        (_, _) => _scheduleEvaluation('card_repository_changed'),
      )
      ..listenManual<AsyncValue<DailyMissionLedger>>(
        dailyMissionControllerProvider,
        (_, _) => _scheduleEvaluation('mission_repository_changed'),
      )
      ..listenManual<PlayerProgress>(
        localPlayerProgressSessionProvider,
        (_, _) => _scheduleEvaluation('player_progress_changed'),
      )
      ..listenManual<AsyncValue<AchievementControllerState>>(
        achievementControllerProvider,
        _handleAchievementState,
      );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleEvaluation('startup_restore');
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleEvaluation(String source) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      unawaited(_evaluateSafely(source));
    });
  }

  Future<void> _evaluateSafely(String source) async {
    try {
      await ref
          .read(achievementControllerProvider.notifier)
          .evaluate(source: source);
    } on Object {
      // The controller logs the typed reason and keeps persisted state intact.
    }
  }

  void _handleAchievementState(
    AsyncValue<AchievementControllerState>? previous,
    AsyncValue<AchievementControllerState> next,
  ) {
    final previousRevision = previous?.value?.evaluationRevision ?? 0;
    final value = next.value;
    if (value == null || value.evaluationRevision <= previousRevision) return;
    if (value.lastUnlocks.isEmpty) return;
    _presentationTail = _presentationTail.then((_) async {
      if (!mounted) return;
      final l10n = CatDexLocalizations.of(context);
      if (value.lastEvaluationWasHistorical) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                l10n.achievementHistoricalSummary(value.lastUnlocks.length),
              ),
              action: SnackBarAction(
                label: l10n.achievementsProfileAction,
                onPressed: () {
                  if (mounted) {
                    unawaited(context.pushNamed(AppRoute.achievements.name));
                  }
                },
              ),
            ),
          );
        return;
      }
      for (final unlock in value.lastUnlocks) {
        if (!mounted) return;
        await AchievementCelebrationPresenter.present(context, unlock);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
