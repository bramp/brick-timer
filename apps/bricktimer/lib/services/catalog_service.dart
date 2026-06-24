import 'package:bricktimer/repositories/ledger_repository.dart';
import 'package:bricktimer/services/rebrickable_theme_cache_service.dart';
import 'package:drift/drift.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:lego_catalog/lego_catalog.dart';

/// App adapter that maps generic catalog models to drift companions.
class CatalogService {
  /// Creates a catalog adapter from an external catalog backend.
  CatalogService({
    required LegoCatalogBackend backend,
    RebrickableThemeCacheService? themeCacheService,
  }) : _backend = backend,
       _themeCacheService = themeCacheService;

  /// Creates a catalog adapter backed by the Brick Timer backend service.
  factory CatalogService.brickTimer({String? baseUrl}) {
    final backend = BrickTimerBackend(
      baseUrl:
          baseUrl ??
          const String.fromEnvironment(
            _catalogBaseUrlDefine,
            defaultValue: _defaultCatalogBaseUrl,
          ),
      additionalHeadersProvider: _firebaseAppCheckHeaders,
    );
    return CatalogService(backend: backend);
  }

  /// Creates a catalog adapter backed by Rebrickable.
  factory CatalogService.rebrickable({required String apiKey}) {
    final backend = RebrickableBackend(apiKey: apiKey);
    return CatalogService(
      backend: backend,
      themeCacheService: RebrickableThemeCacheService(
        fetchThemes: backend.listThemes,
      ),
    );
  }

  static const String _catalogBaseUrlDefine = 'BRICKTIMER_CATALOG_BASE_URL';
  // TODO(bramp): Change to remote config, so this can easily be changed
  static const String _defaultCatalogBaseUrl =
      'https://us-central1-bricktimer-bramp-net.cloudfunctions.net/bricktimerCatalog';

  final LegoCatalogBackend _backend;
  final RebrickableThemeCacheService? _themeCacheService;

  /// Performs backend-specific startup tasks (for example TTL cache refresh).
  Future<void> warmUp() async {
    await _themeCacheService?.refreshIfExpired();
  }

  /// Refreshes the persisted Rebrickable theme cache when its TTL has expired.
  ///
  /// Prefer [warmUp] for generic startup lifecycle usage.
  Future<void> refreshThemeCacheIfExpired() async {
    await warmUp();
  }

  /// Fetches LEGO set details by its set number.
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async {
    final details = await _backend.getSetDetails(setNumber);
    if (details == null) {
      return null;
    }

    return LegoSetsCompanion.insert(
      setNumber: details.setNumber,
      name: details.name,
      totalPieces: details.totalPieces,
      imageUrl: Value(details.imageUrl),
    );
  }

  /// Searches for LEGO sets by text query.
  ///
  Future<List<LegoSetsCompanion>> searchSets(
    String query, {
    int pageSize = 50,
  }) async {
    final results = await _backend.searchSets(
      query,
      pageSize: pageSize,
    );
    return results.map((set) {
      return LegoSetsCompanion.insert(
        setNumber: set.setNumber,
        name: set.name,
        totalPieces: set.totalPieces,
        imageUrl: Value(set.imageUrl),
      );
    }).toList();
  }

  static Future<Map<String, String>> _firebaseAppCheckHeaders() async {
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      if (token != null && token.trim().isNotEmpty) {
        return {'X-Firebase-AppCheck': token.trim()};
      }
    } on Object catch (error, stackTrace) {
      debugPrint('Skipping App Check header: $error\n$stackTrace');
    }

    return const <String, String>{};
  }
}
