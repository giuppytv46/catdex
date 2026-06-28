import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/entities/pending_discovery_sync.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';

enum LocalDiscoverySaveStatus {
  idle,
  saving,
  saved,
  failure,
}

class LocalDiscoverySaveState {
  const LocalDiscoverySaveState({
    required this.status,
    this.discovery,
    this.reward,
    this.message,
    this.pendingSync,
  });

  const LocalDiscoverySaveState.idle()
    : this(status: LocalDiscoverySaveStatus.idle);

  final LocalDiscoverySaveStatus status;
  final CatDiscovery? discovery;
  final DiscoveryReward? reward;
  final String? message;
  final PendingDiscoverySync? pendingSync;
}
