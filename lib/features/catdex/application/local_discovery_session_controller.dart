import 'dart:async';

import 'package:catdex/features/cards/domain/generated_card_state.dart';
import 'package:catdex/features/catdex/application/active_catdex_session.dart';
import 'package:catdex/features/catdex/application/catdex_repository_providers.dart';
import 'package:catdex/features/catdex/data/repositories/merged_discovery_repository.dart';
import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/features/catdex/domain/repositories/discovery_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localDiscoverySessionProvider =
    NotifierProvider<LocalDiscoverySessionController, List<CatDiscovery>>(
      LocalDiscoverySessionController.new,
    );

class LocalDiscoverySessionController extends Notifier<List<CatDiscovery>> {
  int _restoreRevision = 0;
  Future<void>? _restoreInFlight;
  String? _restorePlayerId;

  @override
  List<CatDiscovery> build() {
    unawaited(Future<void>.microtask(_loadPersistedDiscoveries));

    return const [];
  }

  void addDiscovery(CatDiscovery discovery) {
    state = [
      discovery,
      ...state.where((item) => item.id != discovery.id),
    ];
  }

  void replaceDiscovery(CatDiscovery discovery) {
    var replaced = false;
    final next = <CatDiscovery>[];
    for (final item in state) {
      if (item.id == discovery.id) {
        replaced = true;
        next.add(discovery);
      } else {
        next.add(item);
      }
    }

    state = replaced ? next : [discovery, ...next];
  }

  Future<void> refreshFromRepository() => _loadPersistedDiscoveries();

  Future<CatDiscovery?> refreshDiscoveryById(String discoveryId) async {
    final discoveryRepository = ref.read(discoveryRepositoryProvider);
    final discovery = await discoveryRepository.getDiscoveryById(discoveryId);
    if (discovery != null) {
      final current = _findById(state, discoveryId);
      final merged = current == null
          ? discovery
          : mergeDiscoveryRecords(
              preferred: discovery,
              fallback: current,
            );
      replaceDiscovery(merged);
      return merged;
    }

    return null;
  }

  Future<void> _loadPersistedDiscoveries() {
    final activeSession = ref.read(activeCatDexSessionProvider);
    final current = _restoreInFlight;
    if (current != null && _restorePlayerId == activeSession.playerId) {
      return current;
    }

    final discoveryRepository = ref.read(discoveryRepositoryProvider);
    final revision = ++_restoreRevision;
    final operation = _performRestore(
      activeSession: activeSession,
      discoveryRepository: discoveryRepository,
      revision: revision,
    );
    _restoreInFlight = operation;
    _restorePlayerId = activeSession.playerId;
    return operation.whenComplete(() {
      if (identical(_restoreInFlight, operation)) {
        _restoreInFlight = null;
        _restorePlayerId = null;
      }
    });
  }

  Future<void> _performRestore({
    required ActiveCatDexSession activeSession,
    required DiscoveryRepository discoveryRepository,
    required int revision,
  }) async {
    final beforeIds = state.map((item) => item.id).toSet();
    debugPrint('CATDEX_RESTORE_STARTED playerId=${activeSession.playerId}');
    debugPrint('CATDEX_DISCOVERY_REFRESH_BEFORE_IDS ${beforeIds.join(',')}');
    try {
      final discoveries = await discoveryRepository.getDiscoveriesForPlayer(
        activeSession.playerId,
      );
      if (!ref.mounted || revision != _restoreRevision) {
        return;
      }
      if (!activeSession.cloudSyncEnabled) {
        debugPrint('CATDEX_RESTORE_LOCAL_COUNT ${discoveries.length}');
        debugPrint('CATDEX_RESTORE_REMOTE_COUNT 0');
        debugPrint('CATDEX_DISCOVERY_LOAD_LOCAL_COUNT ${discoveries.length}');
        debugPrint('CATDEX_DISCOVERY_LOAD_REMOTE_COUNT 0');
      }
      final current = [...state];
      debugPrint('CATDEX_DISCOVERY_MERGE_BEFORE_COUNT ${current.length}');
      state = _mergeByDiscoveryId(current: current, refreshed: discoveries);
      final afterIds = state.map((item) => item.id).toSet();
      debugPrint('CATDEX_RESTORE_MERGED_COUNT ${state.length}');
      debugPrint('CATDEX_DISCOVERY_MERGE_AFTER_COUNT ${state.length}');
      debugPrint('CATDEX_DISCOVERY_MERGE_IDS ${afterIds.join(',')}');
      debugPrint('CATDEX_DISCOVERY_REFRESH_AFTER_IDS ${afterIds.join(',')}');
      for (final id in beforeIds.difference(afterIds)) {
        debugPrint('CATDEX_DISCOVERY_MISSING_AFTER_REFRESH id=$id');
      }
      for (final discovery in state) {
        final finalCardUrl = canonicalGeneratedCardUrl(discovery);
        debugPrint('CATDEX_RESTORE_DISCOVERY_ID ${discovery.id}');
        debugPrint(
          'CATDEX_RESTORE_PHOTO_SOURCE ${_restoredPhotoSource(discovery)}',
        );
        debugPrint(
          'CATDEX_RESTORE_CARD_FINAL_URL ${_safeUrlForLog(finalCardUrl)}',
        );
        debugPrint(
          'CATDEX_RESTORE_CARD_STATE '
          '${finalCardUrl == null ? 'retryable' : 'completed'}',
        );
      }
      debugPrint('CATDEX_CATDEX_REFRESH_COMPLETED count=${state.length}');
      debugPrint('CATDEX_RESTORE_COMPLETED count=${state.length}');
    } on Object catch (error) {
      if (!ref.mounted || revision != _restoreRevision) {
        return;
      }
      debugPrint('CATDEX_DISCOVERY_REFRESH_FAILED $error');
      debugPrint('CATDEX_DISCOVERY_REFRESH_AFTER_IDS ${beforeIds.join(',')}');
      debugPrint('CATDEX_RESTORE_FAILED ${error.runtimeType}');
    }
  }

  List<CatDiscovery> _dedupeByDiscoveryId(List<CatDiscovery> discoveries) {
    final seen = <String>{};
    final deduped = <CatDiscovery>[];
    for (final discovery in discoveries) {
      if (seen.add(discovery.id)) {
        deduped.add(discovery);
      }
    }

    return deduped;
  }

  List<CatDiscovery> _mergeByDiscoveryId({
    required List<CatDiscovery> current,
    required List<CatDiscovery> refreshed,
  }) {
    final byId = <String, CatDiscovery>{};
    for (final discovery in current) {
      byId[discovery.id] = discovery;
    }
    for (final discovery in _dedupeByDiscoveryId(refreshed)) {
      final currentDiscovery = byId[discovery.id];
      byId[discovery.id] = currentDiscovery == null
          ? discovery
          : mergeDiscoveryRecords(
              preferred: discovery,
              fallback: currentDiscovery,
            );
    }

    final merged = _dedupeByDiscoveryId(byId.values.toList(growable: false));
    return merged..sort((a, b) => b.discoveredAt.compareTo(a.discoveredAt));
  }

  CatDiscovery? _findById(
    List<CatDiscovery> discoveries,
    String discoveryId,
  ) {
    for (final discovery in discoveries) {
      if (discovery.id == discoveryId) {
        return discovery;
      }
    }
    return null;
  }

  String _restoredPhotoSource(CatDiscovery discovery) {
    final display = discovery.displayPhotoPath?.trim();
    final original = discovery.originalPhotoPath?.trim();
    final candidate = display?.isNotEmpty == true ? display : original;
    if (candidate?.startsWith('https://') == true ||
        candidate?.startsWith('http://') == true) {
      return 'network';
    }
    if (candidate?.startsWith('/') == true ||
        candidate?.startsWith('file://') == true) {
      return 'local_absolute';
    }
    if (candidate?.isNotEmpty == true) {
      return 'local_relative';
    }
    if (discovery.originalPhotoStoragePath?.trim().isNotEmpty == true) {
      return 'storage';
    }
    return 'none';
  }

  String _safeUrlForLog(String? value) {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || uri.host.isEmpty) {
      return '-';
    }
    return '${uri.host}${uri.path}';
  }
}
