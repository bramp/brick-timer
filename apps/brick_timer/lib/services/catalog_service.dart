import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/rebrickable_theme_cache_service.dart';
import 'package:drift/drift.dart';
import 'package:lego_catalog/lego_catalog.dart';

/// Supported catalog backend implementations.
enum CatalogBackendType {
  /// Rebrickable API-backed catalog.
  rebrickable,
}

/// App adapter that maps generic catalog models to drift companions.
class CatalogService {
  /// Creates a catalog adapter from an external catalog backend.
  CatalogService({
    required LegoCatalogBackend backend,
    RebrickableThemeCacheService? themeCacheService,
  }) : _backend = backend,
       _themeCacheService = themeCacheService;

  /// Creates a catalog service using the selected backend type.
  factory CatalogService.create({
    required String rebrickableApiKey,
    CatalogBackendType backendType = CatalogBackendType.rebrickable,
  }) {
    switch (backendType) {
      case CatalogBackendType.rebrickable:
        return CatalogService.rebrickable(apiKey: rebrickableApiKey);
    }
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
  /// The default excluded theme root ID `501` is Rebrickable "Gear", which
  /// mostly returns non-buildable items (storage, accessories, books, etc.).
  Future<List<LegoSetsCompanion>> searchSets(
    String query, {
    int pageSize = 50,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  }) async {
    var effectiveExcludedThemeRootIds = excludedThemeRootIds;
    var effectiveIncludeDescendantThemes = includeDescendantThemesInExclusion;

    if (includeDescendantThemesInExclusion &&
        excludedThemeRootIds.isNotEmpty &&
        _themeCacheService != null) {
      effectiveExcludedThemeRootIds = await _themeCacheService
          .expandThemeRootIds(excludedThemeRootIds);
      effectiveIncludeDescendantThemes = false;
    }

    final results = await _backend.searchSets(
      query,
      pageSize: pageSize,
      minParts: minParts,
      excludedThemeRootIds: effectiveExcludedThemeRootIds,
      includeDescendantThemesInExclusion: effectiveIncludeDescendantThemes,
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
}
