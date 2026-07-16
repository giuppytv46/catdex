import 'package:catdex/features/events/application/event_generation_coordinator.dart';
import 'package:catdex/features/events/data/shared_preferences_event_usage_repository.dart';
import 'package:catdex/features/events/domain/entities/catdex_event.dart';
import 'package:catdex/features/events/domain/repositories/event_usage_repository.dart';
import 'package:catdex/features/events/domain/services/halloween_event_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final eventUsageRepositoryProvider = Provider<EventUsageRepository>((ref) {
  return const SharedPreferencesEventUsageRepository();
});

final eventGenerationCoordinatorProvider = Provider<EventGenerationCoordinator>(
  (ref) => EventGenerationCoordinator(
    usageRepository: ref.watch(eventUsageRepositoryProvider),
  ),
);

final eventRuntimeConfigurationProvider = Provider<EventRuntimeConfiguration>(
  (ref) {
    final debugKey = EventRuntimeConfiguration.debugEventKey.isEmpty
        ? '-'
        : EventRuntimeConfiguration.debugEventKey;
    debugPrint(
      'CATDEX_EVENT_DEBUG_MODE '
      'active=${EventRuntimeConfiguration.debugEventActive} '
      'key=$debugKey '
      'premium=${EventRuntimeConfiguration.debugPremium}',
    );
    return const EventRuntimeConfiguration();
  },
);

CatDexEvent? activeCardGenerationEvent(Ref ref, {DateTime? now}) {
  return ref
      .read(eventRuntimeConfigurationProvider)
      .activeEvent(now ?? DateTime.now().toUtc());
}
