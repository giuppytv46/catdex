import 'dart:async';
import 'dart:io';

import 'package:catdex/features/analysis/data/backend_cat_analysis_client.dart';
import 'package:catdex/features/analysis/data/backend_cat_analysis_repository.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_exception.dart';
import 'package:catdex/features/analysis/domain/entities/cat_analysis_failure.dart';
import 'package:catdex/features/capture/domain/entities/captured_photo.dart';
import 'package:catdex/features/capture/domain/entities/photo_source.dart';
import 'package:test/test.dart';

void main() {
  test('calls backend function client and parses response', () async {
    final client = _FakeBackendClient(response: _json());
    final repository = BackendCatAnalysisRepository(client: client);

    final result = await repository.analyzePhoto(_photo());

    expect(result.primaryBreed.species.id, 'domestic_tabby_cat');
    expect(client.lastBody?['photoReference'], 'cat.jpg');
    expect(client.lastBody?['locale'], 'it');
    expect(client.lastBody?['metadata'], isA<Map<String, Object?>>());
  });

  test('sends base64 image data when photo path is a local file', () async {
    final tempDir = await Directory.systemTemp.createTemp('catdex_ai_test_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final imageFile = File('${tempDir.path}/cat.jpg')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final client = _FakeBackendClient(response: _json());
    final repository = BackendCatAnalysisRepository(client: client);

    await repository.analyzePhoto(_photo(path: imageFile.path));

    expect(
      client.lastBody?['base64_image'],
      'data:image/jpeg;base64,AQIDBA==',
    );
    expect(client.lastBody?.containsKey('photoReference'), isFalse);
  });

  test('sends image_url when photo path is remote', () async {
    final client = _FakeBackendClient(response: _json());
    final repository = BackendCatAnalysisRepository(client: client);

    await repository.analyzePhoto(_photo(path: 'https://example.com/cat.jpg'));

    expect(client.lastBody?['image_url'], 'https://example.com/cat.jpg');
    expect(client.lastBody?.containsKey('photoReference'), isFalse);
  });

  test('maps backend client failures into CatAnalysisException', () async {
    const repository = BackendCatAnalysisRepository(
      client: _FailingBackendClient(SocketException('offline')),
    );

    await expectLater(
      repository.analyzePhoto(_photo()),
      throwsA(
        isA<CatAnalysisException>().having(
          (error) => error.failure.code,
          'code',
          CatAnalysisFailureCode.noInternet,
        ),
      ),
    );
  });

  test('maps backend timeout into CatAnalysisException', () async {
    final repository = BackendCatAnalysisRepository(
      client: _HangingBackendClient(),
      timeout: Duration.zero,
    );

    await expectLater(
      repository.analyzePhoto(_photo()),
      throwsA(
        isA<CatAnalysisException>().having(
          (error) => error.failure.code,
          'code',
          CatAnalysisFailureCode.timeout,
        ),
      ),
    );
  });
}

CapturedPhoto _photo({String path = 'cat.jpg'}) {
  return CapturedPhoto(
    path: path,
    source: PhotoSource.gallery,
    sizeBytes: 1024,
    capturedAt: DateTime.utc(2026),
  );
}

Map<String, Object?> _json() {
  return {
    'primaryBreed': {
      'speciesId': 'domestic_tabby_cat',
      'confidence': 0.82,
    },
    'breedCandidates': [
      {
        'speciesId': 'domestic_tabby_cat',
        'confidence': 0.82,
      },
    ],
    'visualTraits': {
      'coatColor': 'Brown',
      'coatPattern': 'Tabby',
      'eyeColor': 'Green',
      'hairLength': 'Short',
      'notableTraits': <Map<String, Object?>>[],
    },
    'confidence': 0.82,
    'rarity': 'common',
    'variantId': 'normal',
    'personality': 'curious',
    'story': 'A curious local cat joins CatDex.',
    'analyzedAt': '2026-06-28T12:00:00.000Z',
  };
}

class _FakeBackendClient implements CatAnalysisBackendClient {
  _FakeBackendClient({required this.response});

  final Object? response;
  Map<String, Object?>? lastBody;

  @override
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body) async {
    lastBody = body;
    return response;
  }
}

class _FailingBackendClient implements CatAnalysisBackendClient {
  const _FailingBackendClient(this.error);

  final Exception error;

  @override
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body) {
    throw error;
  }
}

class _HangingBackendClient implements CatAnalysisBackendClient {
  @override
  Future<Object?> analyzeCatPhoto(Map<String, Object?> body) {
    return Completer<Object?>().future;
  }
}
