import 'package:dio/dio.dart';

import 'package:lego_catalog/src/backends/lego_catalog_backend.dart';
import 'package:lego_catalog/src/backends/rebrickable/lego_theme.dart';
import 'package:lego_catalog/src/backends/rebrickable/rebrickable_api_client.dart';
import 'package:lego_catalog/src/backends/rebrickable/search_filter_policy.dart';
import 'package:lego_catalog/src/backends/rebrickable/theme_exclusion_resolver.dart';
import 'package:lego_catalog/src/models/lego_set.dart';

/// Rebrickable-backed implementation of [LegoCatalogBackend].
class RebrickableBackend implements LegoCatalogBackend {
  /// Creates a backend with configurable retry, timeout, and base URL options.
  RebrickableBackend({
    required String apiKey,
    Dio? dio,
    String baseUrl = _defaultBaseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    Duration sendTimeout = const Duration(seconds: 10),
    int retries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 250),
  }) : _apiClient = RebrickableApiClient(
         apiKey: apiKey,
         dio: dio,
         baseUrl: baseUrl,
         connectTimeout: connectTimeout,
         receiveTimeout: receiveTimeout,
         sendTimeout: sendTimeout,
         retries: retries,
         initialRetryDelay: initialRetryDelay,
       );

  static const String _defaultBaseUrl = RebrickableApiClient.defaultBaseUrl;

  final RebrickableApiClient _apiClient;

  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    final filterPolicy = RebrickableSearchFilterPolicy(
      minParts: minParts,
      excludedThemeRootIds: excludedThemeRootIds,
      includeDescendantThemesInExclusion: includeDescendantThemesInExclusion,
    );

    final rawResults = await _apiClient.searchSetsRaw(
      queryParameters: filterPolicy.buildSearchQueryParameters(
        trimmedQuery,
        pageSize: pageSize,
      ),
    );
    final themeExclusionResolver = RebrickableThemeExclusionResolver(
      apiClient: _apiClient,
      rootThemeIds: filterPolicy.excludedThemeRootIds,
      includeDescendantThemes: filterPolicy.includeDescendantThemesInExclusion,
    );
    final excludedThemeIds = await themeExclusionResolver.getExcludedThemeIds();

    return rawResults
        .where((json) => filterPolicy.passes(json, excludedThemeIds))
        .map(LegoSetSummary.fromJson)
        .toList();
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    final data = await _apiClient.getSetDetailsRaw(setNumber);
    if (data == null) {
      return null;
    }
    return LegoSetDetails.fromJson(data);
  }

  /// Lists Rebrickable themes for app-layer caching and expansion.
  Future<List<LegoTheme>> listThemes() {
    return _apiClient.listThemes();
  }

  /// Disposes owned HTTP resources when this backend created the Dio client.
  void dispose() {
    _apiClient.dispose();
  }
}
