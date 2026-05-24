import 'dart:convert';
import 'dart:typed_data';

import 'package:brick_timer/services/rebrickable_theme_cache_service.dart';
import 'package:clock/clock.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCacheManager implements BaseCacheManager {
  _FakeCacheManager({required this.cachedPayload})
    : fileSystem = MemoryFileSystem();

  final MemoryFileSystem fileSystem;
  final String cachedPayload;

  int getFileFromCacheCalls = 0;
  int putFileCalls = 0;

  @override
  Future<File> getSingleFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FileInfo> downloadFile(
    String url, {
    String? key,
    Map<String, String>? authHeaders,
    bool force = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> emptyCache() {
    throw UnimplementedError();
  }

  @override
  Stream<FileInfo> getFile(
    String url, {
    String? key,
    Map<String, String>? headers,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FileInfo?> getFileFromCache(
    String key, {
    bool ignoreMemCache = false,
  }) async {
    getFileFromCacheCalls++;
    final file = fileSystem.file('/cache/$key.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(cachedPayload);
    return FileInfo(
      file,
      FileSource.Cache,
      DateTime.now().toUtc().add(const Duration(days: 365)),
      key,
    );
  }

  @override
  Future<FileInfo?> getFileFromMemory(String key) {
    throw UnimplementedError();
  }

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<File> putFile(
    String url,
    Uint8List fileBytes, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) async {
    putFileCalls++;
    final file = fileSystem.file('/cache/${key ?? url}.$fileExtension')
      ..createSync(recursive: true)
      ..writeAsBytesSync(fileBytes);
    return file;
  }

  @override
  Future<File> putFileStream(
    String url,
    Stream<List<int>> source, {
    String? key,
    String? eTag,
    Duration maxAge = const Duration(days: 30),
    String fileExtension = 'file',
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeFile(String key) {
    throw UnimplementedError();
  }

  @override
  Future<void> dispose() {
    throw UnimplementedError();
  }
}

void main() {
  test('falls back to expired cached themes when refresh fails', () async {
    final now = DateTime.utc(2026, 5, 24);
    final cachedPayload = jsonEncode({
      'fetched_at': now.subtract(const Duration(days: 14)).toIso8601String(),
      'themes': const [
        {'id': 1, 'parent_id': null, 'name': 'Root'},
        {'id': 2, 'parent_id': 1, 'name': 'Child'},
      ],
    });
    final cacheManager = _FakeCacheManager(cachedPayload: cachedPayload);
    var fetchAttempts = 0;
    final service = RebrickableThemeCacheService(
      fetchThemes: () async {
        fetchAttempts++;
        throw Exception('network down');
      },
      cacheManager: cacheManager,
      clock: Clock.fixed(now),
    );

    final expanded = await service.expandThemeRootIds({1});

    expect(fetchAttempts, 1);
    expect(cacheManager.getFileFromCacheCalls, greaterThanOrEqualTo(1));
    expect(expanded, unorderedEquals([1, 2]));
    expect(cacheManager.putFileCalls, 0);
  });
}
