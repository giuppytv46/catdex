import 'dart:convert';
import 'dart:io';

import 'package:catdex/features/catdex/domain/entities/cat_discovery.dart';
import 'package:catdex/shared/images/catdex_image_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final backgroundRemovalServiceProvider = Provider<BackgroundRemovalService>((
  _,
) {
  return const BackgroundRemovalService();
});

class BackgroundRemovalService {
  const BackgroundRemovalService();

  static const _apiKey = String.fromEnvironment('REMOVE_BG_API_KEY');
  static final Uri _endpoint = Uri.parse(
    'https://api.remove.bg/v1.0/removebg',
  );

  Future<String?> removeBackgroundForDiscovery(
    CatDiscovery discovery,
  ) async {
    debugPrint('CATDEX_BG_REMOVE_DISCOVERY_ID ${discovery.id}');
    final sourcePath = CatDexImageResolver.resolveBestPhotoPath(discovery);
    debugPrint('CATDEX_BG_REMOVE_SOURCE_PATH ${sourcePath ?? '-'}');

    if (sourcePath == null) {
      debugPrint('CATDEX_BG_REMOVE_ERROR missing source photo');
      return null;
    }

    if (_apiKey.trim().isEmpty) {
      debugPrint('CATDEX_BG_REMOVE_ERROR missing REMOVE_BG_API_KEY');
      return null;
    }

    try {
      debugPrint('CATDEX_BG_REMOVE_STARTED');
      final imageBytes = await _loadSourceBytes(sourcePath);
      final boundary = 'catdex-${DateTime.now().microsecondsSinceEpoch}';
      final body = _multipartBody(
        boundary: boundary,
        imageBytes: imageBytes,
      );

      final client = HttpClient();
      try {
        final request = await client.postUrl(_endpoint);
        request.headers
          ..set('X-Api-Key', _apiKey)
          ..set(
            HttpHeaders.contentTypeHeader,
            'multipart/form-data; boundary=$boundary',
          )
          ..set(HttpHeaders.contentLengthHeader, body.length);
        request.add(body);

        final response = await request.close();
        final responseBytes = await consolidateHttpClientResponseBytes(
          response,
        );
        if (response.statusCode != HttpStatus.ok) {
          debugPrint(
            'CATDEX_BG_REMOVE_ERROR status=${response.statusCode} '
            'body=${utf8.decode(responseBytes, allowMalformed: true)}',
          );
          return null;
        }

        final outputDirectory = await _cutoutDirectory();
        if (!outputDirectory.existsSync()) {
          outputDirectory.createSync(recursive: true);
        }
        final output = File(
          '${outputDirectory.path}/cutout_${discovery.id}.png',
        );
        await output.writeAsBytes(responseBytes, flush: true);
        debugPrint('CATDEX_BG_REMOVE_SUCCESS');
        debugPrint('CATDEX_BG_REMOVE_OUTPUT_PATH ${output.path}');
        return output.path;
      } finally {
        client.close(force: true);
      }
    } on Object catch (error) {
      debugPrint('CATDEX_BG_REMOVE_ERROR $error');
      return null;
    }
  }

  Uint8List _multipartBody({
    required String boundary,
    required Uint8List imageBytes,
  }) {
    final header = utf8.encode(
      '--$boundary\r\n'
      'Content-Disposition: form-data; name="image_file"; '
      'filename="catdex_photo.jpg"\r\n'
      'Content-Type: application/octet-stream\r\n\r\n',
    );
    final middle = utf8.encode(
      '\r\n--$boundary\r\n'
      'Content-Disposition: form-data; name="size"\r\n\r\n'
      'auto\r\n',
    );
    final footer = utf8.encode('--$boundary--\r\n');
    final bytes = Uint8List(
      header.length + imageBytes.length + middle.length + footer.length,
    );
    var offset = 0;
    bytes.setRange(offset, offset + header.length, header);
    offset += header.length;
    bytes.setRange(offset, offset + imageBytes.length, imageBytes);
    offset += imageBytes.length;
    bytes.setRange(offset, offset + middle.length, middle);
    offset += middle.length;
    bytes.setRange(offset, offset + footer.length, footer);

    return bytes;
  }

  Future<Uint8List> _loadSourceBytes(String sourcePath) async {
    final normalized = sourcePath.replaceFirst('asset:', '');
    if (normalized.startsWith('assets/')) {
      final data = await rootBundle.load(normalized);
      return data.buffer.asUint8List();
    }

    final uri = Uri.tryParse(normalized);
    if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
      throw StateError(
        'Remote photo URLs are not supported for Remove.bg yet.',
      );
    }

    final file = File(normalized);
    if (!file.existsSync()) {
      throw StateError('Missing source image file: $normalized');
    }

    return file.readAsBytes();
  }

  Future<Directory> _cutoutDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    return Directory('${documents.path}/catdex/cutouts');
  }
}
