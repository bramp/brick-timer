import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk-backed cache manager for LEGO set thumbnail images.
class LegoSetImageCacheManager extends CacheManager {
  LegoSetImageCacheManager._({
    required String cacheKey,
    required Duration stalePeriod,
    required int maxNrOfCacheObjects,
    FileService? fileService,
  }) : super(
         Config(
           cacheKey,
           stalePeriod: stalePeriod,
           maxNrOfCacheObjects: maxNrOfCacheObjects,
           fileService: fileService ?? HttpFileService(),
         ),
       );

  /// Creates a test cache manager using a provided file service.
  @visibleForTesting
  factory LegoSetImageCacheManager.test({
    required String cacheKey,
    required FileService fileService,
    Duration stalePeriod = const Duration(days: 30),
    int maxNrOfCacheObjects = 400,
  }) {
    return LegoSetImageCacheManager._(
      cacheKey: cacheKey,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maxNrOfCacheObjects,
      fileService: fileService,
    );
  }

  static const String _defaultCacheKey = 'lego_set_thumbnails';

  /// Shared cache manager instance for all LEGO set thumbnails.
  static final LegoSetImageCacheManager instance = LegoSetImageCacheManager._(
    cacheKey: _defaultCacheKey,
    stalePeriod: const Duration(days: 30),
    maxNrOfCacheObjects: 400,
  );
}
