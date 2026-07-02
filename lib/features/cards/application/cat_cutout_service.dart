import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

final catCutoutServiceProvider = Provider<CatCutoutService>((_) {
  return const CatCutoutService();
});

class CatCutoutService {
  const CatCutoutService();

  Future<String?> generateCutoutForDiscovery(CatDiscovery discovery) async {
    debugPrint('CATDEX_CUTOUT_DISCOVERY_ID ${discovery.id}');
    try {
      final sourcePath = _bestSourcePhotoPath(discovery);
      debugPrint('CATDEX_CUTOUT_SOURCE_PHOTO ${sourcePath ?? '-'}');
      if (sourcePath == null) {
        debugPrint('CATDEX_CUTOUT_SUCCESS false');
        debugPrint('CATDEX_CUTOUT_ERROR missing source photo');
        return null;
      }

      final sourceBytes = await _loadBytes(sourcePath);
      final sourceImage = img.decodeImage(sourceBytes);
      if (sourceImage == null) {
        debugPrint('CATDEX_CUTOUT_SUCCESS false');
        debugPrint('CATDEX_CUTOUT_ERROR could not decode source photo');
        return null;
      }

      final cutout = _removeBorderBackground(sourceImage);
      final outputDirectory = await _cutoutDirectory();
      if (!outputDirectory.existsSync()) {
        outputDirectory.createSync(recursive: true);
      }

      final output = File(
        '${outputDirectory.path}/cutout_${discovery.id}.png',
      );
      await output.writeAsBytes(img.encodePng(cutout), flush: true);
      debugPrint('CATDEX_CUTOUT_OUTPUT_PATH ${output.path}');
      debugPrint('CATDEX_CUTOUT_SUCCESS true');

      return output.path;
    } on Object catch (error) {
      debugPrint('CATDEX_CUTOUT_SUCCESS false');
      debugPrint('CATDEX_CUTOUT_ERROR $error');
      return null;
    }
  }

  img.Image _removeBorderBackground(img.Image source) {
    final output = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 4,
    );

    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        final pixel = source.getPixel(x, y);
        output.setPixelRgba(
          x,
          y,
          pixel.r.toInt(),
          pixel.g.toInt(),
          pixel.b.toInt(),
          pixel.a.toInt(),
        );
      }
    }

    final visited = List<bool>.filled(source.width * source.height, false);
    final queue = Queue<Point<int>>();

    void addIfBackground(int x, int y) {
      if (x < 0 || y < 0 || x >= source.width || y >= source.height) {
        return;
      }
      final index = y * source.width + x;
      if (visited[index]) {
        return;
      }
      final pixel = source.getPixel(x, y);
      if (!_isLikelyBackground(pixel)) {
        return;
      }
      visited[index] = true;
      queue.add(Point<int>(x, y));
    }

    for (var x = 0; x < source.width; x++) {
      addIfBackground(x, 0);
      addIfBackground(x, source.height - 1);
    }
    for (var y = 0; y < source.height; y++) {
      addIfBackground(0, y);
      addIfBackground(source.width - 1, y);
    }

    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      output.setPixelRgba(point.x, point.y, 0, 0, 0, 0);
      addIfBackground(point.x + 1, point.y);
      addIfBackground(point.x - 1, point.y);
      addIfBackground(point.x, point.y + 1);
      addIfBackground(point.x, point.y - 1);
    }

    return output;
  }

  bool _isLikelyBackground(img.Pixel pixel) {
    final red = pixel.r.toInt();
    final green = pixel.g.toInt();
    final blue = pixel.b.toInt();
    final alpha = pixel.a.toInt();
    if (alpha < 16) {
      return true;
    }

    final brightness = (red + green + blue) / 3;
    final maxChannel = max(red, max(green, blue));
    final minChannel = min(red, min(green, blue));
    final saturation = maxChannel - minChannel;

    return brightness > 210 && saturation < 44;
  }

  Future<Uint8List> _loadBytes(String path) async {
    final normalized = path.replaceFirst('asset:', '');
    if (normalized.startsWith('assets/')) {
      final data = await rootBundle.load(normalized);
      return data.buffer.asUint8List();
    }

    final file = File(normalized);
    if (!file.existsSync()) {
      throw StateError('Missing source image file: $normalized');
    }

    return file.readAsBytes();
  }

  String? _bestSourcePhotoPath(CatDiscovery discovery) {
    final candidates = [
      discovery.displayPhotoPath,
      discovery.originalPhotoPath,
      discovery.photoPath,
      discovery.card?.originalPhotoPath,
    ];

    for (final path in candidates) {
      final normalized = path?.trim();
      if (normalized == null || normalized.isEmpty) {
        continue;
      }
      if (_isRemote(normalized)) {
        continue;
      }
      if (normalized.startsWith('assets/') ||
          normalized.startsWith('asset:') ||
          File(normalized).existsSync()) {
        return normalized;
      }
    }

    return null;
  }

  bool _isRemote(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  Future<Directory> _cutoutDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/catdex/cutouts');
  }
}
