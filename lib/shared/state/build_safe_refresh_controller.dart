import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BuildSafeRefreshController extends Notifier<int> {
  BuildSafeRefreshController(this.providerName);

  final String providerName;
  bool _refreshScheduled = false;

  @override
  int build() {
    debugPrint(
      'CATDEX_RIVERPOD_BUILD_PHASE_FIX_SOURCE source=$providerName',
    );
    return 0;
  }

  void refresh() {
    if (!ref.mounted) {
      debugPrint(
        'CATDEX_PROVIDER_UPDATE_DEDUPLICATED '
        'provider=$providerName reason=disposed',
      );
      return;
    }

    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      state += 1;
      return;
    }

    if (_refreshScheduled) {
      debugPrint(
        'CATDEX_PROVIDER_UPDATE_DEDUPLICATED '
        'provider=$providerName reason=already_scheduled',
      );
      return;
    }

    _refreshScheduled = true;
    debugPrint('CATDEX_BUILD_PHASE_ASSERTION_GUARD_TRIGGERED');
    debugPrint('CATDEX_PROVIDER_UPDATE_DEFERRED provider=$providerName');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshScheduled = false;
      if (!ref.mounted) {
        debugPrint(
          'CATDEX_PROVIDER_UPDATE_DEDUPLICATED '
          'provider=$providerName reason=disposed',
        );
        return;
      }
      state += 1;
    });
  }
}
