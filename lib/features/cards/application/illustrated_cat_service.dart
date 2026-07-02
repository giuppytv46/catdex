import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final illustratedCatServiceProvider = Provider<IllustratedCatService>((_) {
  return const IllustratedCatService();
});

const bool forceTestIllustratedCatAsset = true;
const String testIllustratedCatAssetPath =
    'assets/cards/test_illustrated_cat.png';

class IllustratedCatService {
  const IllustratedCatService();

  Future<String?> generateIllustratedCat({
    required CatDiscovery discovery,
  }) async {
    debugPrint('CATDEX_ILLUSTRATION_DISCOVERY_ID ${discovery.id}');
    final sourcePhoto = CatDexImageResolver.resolveBestPhotoPath(discovery);
    debugPrint('CATDEX_ILLUSTRATION_SOURCE_PHOTO ${sourcePhoto ?? '-'}');
    debugPrint('CATDEX_ILLUSTRATION_STARTED');
    debugPrint(
      'CATDEX_ILLUSTRATION_USING_TEST_ASSET $forceTestIllustratedCatAsset',
    );

    if (forceTestIllustratedCatAsset) {
      debugPrint('CATDEX_ILLUSTRATION_SUCCESS');
      debugPrint(
        'CATDEX_ILLUSTRATION_OUTPUT_PATH $testIllustratedCatAssetPath',
      );
      return testIllustratedCatAssetPath;
    }

    if (sourcePhoto == null) {
      debugPrint('CATDEX_ILLUSTRATION_ERROR missing source photo');
      return null;
    }

    // TODO(CatDex): call AI image service and write transparent PNG to output.
    final directory = await _illustrationsDirectory();
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }
    final output = File('${directory.path}/illustrated_${discovery.id}.png');
    debugPrint('CATDEX_ILLUSTRATION_ERROR no AI image service configured');
    debugPrint('CATDEX_ILLUSTRATION_OUTPUT_PATH ${output.path}');

    return null;
  }

  Future<Directory> _illustrationsDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/catdex/illustrations');
  }
}
