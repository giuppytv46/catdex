import 'package:catdex/features/capture/domain/entities/photo_source.dart';

class CapturedPhoto {
  const CapturedPhoto({
    required this.path,
    required this.source,
    required this.sizeBytes,
    required this.capturedAt,
    this.localPath,
    this.storagePath,
  }) : assert(sizeBytes >= 0, 'sizeBytes cannot be negative');

  final String path;
  final PhotoSource source;
  final int sizeBytes;
  final DateTime capturedAt;
  final String? localPath;
  final String? storagePath;

  String get bestLocalPath {
    final local = localPath?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    return path;
  }

  String get extension {
    final normalizedPath = bestLocalPath.toLowerCase();
    final dotIndex = normalizedPath.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == normalizedPath.length - 1) {
      return '';
    }

    return normalizedPath.substring(dotIndex + 1);
  }
}
