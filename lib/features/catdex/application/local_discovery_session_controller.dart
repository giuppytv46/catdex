import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localDiscoverySessionProvider =
    NotifierProvider<LocalDiscoverySessionController, List<CatDiscovery>>(
      LocalDiscoverySessionController.new,
    );

class LocalDiscoverySessionController extends Notifier<List<CatDiscovery>> {
  @override
  List<CatDiscovery> build() {
    return const [];
  }

  void addDiscovery(CatDiscovery discovery) {
    state = [discovery, ...state];
  }
}
