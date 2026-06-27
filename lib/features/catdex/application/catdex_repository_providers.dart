import 'package:catdex/features/catdex/data/repositories/in_memory_discovery_repository.dart';
import 'package:catdex/features/catdex/data/repositories/in_memory_player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:catdex/features/catdex/domain/repositories/player_progress_repository.dart';
import 'package:catdex/features/catdex/domain/services/discovery_reward_calculator.dart';
import 'package:catdex/features/catdex/domain/services/level_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((_) {
  return InMemoryDiscoveryRepository();
});

final playerProgressRepositoryProvider = Provider<PlayerProgressRepository>((
  _,
) {
  return InMemoryPlayerProgressRepository();
});

final discoveryRewardCalculatorProvider = Provider<DiscoveryRewardCalculator>((
  _,
) {
  return const DiscoveryRewardCalculator();
});

final levelCalculatorProvider = Provider<LevelCalculator>((_) {
  return const LevelCalculator();
});
