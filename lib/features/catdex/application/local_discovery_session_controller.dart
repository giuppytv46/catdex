import 'dart:async';

import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localDiscoverySessionProvider =
    NotifierProvider<LocalDiscoverySessionController, List<CatDiscovery>>(
      LocalDiscoverySessionController.new,
    );

class LocalDiscoverySessionController extends Notifier<List<CatDiscovery>> {
  @override
  List<CatDiscovery> build() {
    unawaited(Future<void>.microtask(_loadPersistedDiscoveries));

    return const [];
  }

  void addDiscovery(CatDiscovery discovery) {
    state = [discovery, ...state];
  }

  Future<void> _loadPersistedDiscoveries() async {
    final activeSession = ref.read(activeCatDexSessionProvider);
    final discoveryRepository = ref.read(discoveryRepositoryProvider);
    final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
      activeSession.playerId,
    );
    if (discoveries.isEmpty) {
      return;
    }

    state = discoveries;
  }
}
