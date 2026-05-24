import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:brick_timer/services/lego_set_image_cache_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _FakeFileService implements FileService {
  int requestCount = 0;
  @override
  int concurrentFetches = 10;

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    requestCount++;
    return _FakeFileServiceResponse(_oneByOneTransparentPng);
  }
}

class _FakeFileServiceResponse implements FileServiceResponse {
  _FakeFileServiceResponse(this._bytes);

  final Uint8List _bytes;

  @override
  Stream<List<int>> get content => Stream<List<int>>.value(_bytes);

  @override
  int get statusCode => 200;

  @override
  DateTime get validTill => DateTime.now().add(const Duration(days: 30));

  @override
  String get fileExtension => 'png';

  @override
  int? get contentLength => _bytes.length;

  @override
  String? get eTag => null;
}

final Uint8List _oneByOneTransparentPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGNgYAAAAAMA'
  'ASsJTYQAAAAASUVORK5CYII=',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final supportDir = Directory('/tmp/brick_timer_test_support')
      ..createSync(recursive: true);
    final tempDir = Directory('/tmp/brick_timer_test_temp')
      ..createSync(recursive: true);
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      supportPath: supportDir.path,
      temporaryPath: tempDir.path,
    );
  });

  test('uses disk cache to avoid repeated fetches for the same URL', () async {
    final fileService = _FakeFileService();
    final cacheKey =
        'lego_set_cache_test_${DateTime.now().microsecondsSinceEpoch}';
    final cacheManager = LegoSetImageCacheManager.test(
      cacheKey: cacheKey,
      fileService: fileService,
    );

    const imageUrl = 'https://example.com/42115.png';

    await cacheManager.getSingleFile(imageUrl);
    await cacheManager.getSingleFile(imageUrl);

    expect(fileService.requestCount, 1);
  });
}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required this.supportPath,
    required this.temporaryPath,
  });

  final String supportPath;
  final String temporaryPath;

  @override
  Future<String?> getApplicationSupportPath() async => supportPath;

  @override
  Future<String?> getTemporaryPath() async => temporaryPath;
}
