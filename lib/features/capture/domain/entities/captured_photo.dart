import 'package:catdex/features/capture/domain/entities/photo_source.dart';

class CapturedPhoto {
  const CapturedPhoto({
    required this.path,
    required this.source,
    required this.sizeBytes,
    required this.capturedAt,
  }) : assert(sizeBytes >= 0, 'sizeBytes cannot be negative');

  final String path;
  final PhotoSource source;
  final int sizeBytes;
  final DateTime capturedAt;

  String get extension {
    final normalizedPath = path.toLowerCase();
    final dotIndex = normalizedPath.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == normalizedPath.length - 1) {
      return '';
    }

    return normalizedPath.substring(dotIndex + 1);
  }
}
