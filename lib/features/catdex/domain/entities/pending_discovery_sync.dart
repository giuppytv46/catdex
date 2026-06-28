import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward.dart';

enum PendingDiscoverySyncReason {
  cloudSaveFailed,
}

class PendingDiscoverySync {
  const PendingDiscoverySync({
    required this.id,
    required this.discovery,
    required this.reward,
    required this.reason,
    required this.createdAt,
    required this.lastErrorMessage,
  });

  final String id;
  final CatDiscovery discovery;
  final DiscoveryReward reward;
  final PendingDiscoverySyncReason reason;
  final DateTime createdAt;
  final String lastErrorMessage;
}
