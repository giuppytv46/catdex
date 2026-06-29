import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';

abstract class CatCutoutService {
  const CatCutoutService();

  bool get isAvailable;

  /// Future background removal will create a transparent cat cutout and store
  /// its path in `cutoutImagePath`. Cards use that path first, then fall back
  /// to the saved discovery photo.
  Future<String?> generateCutoutForDiscovery(CatDiscovery discovery);
}

class LocalPlaceholderCatCutoutService implements CatCutoutService {
  const LocalPlaceholderCatCutoutService();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> generateCutoutForDiscovery(CatDiscovery discovery) async {
    return null;
  }
}
