import 'package:dio/dio.dart';

import 'package:lego_catalog/src/backends/lego_catalog_backend.dart';
import 'package:lego_catalog/src/backends/rebrickable/lego_theme.dart';
import 'package:lego_catalog/src/backends/rebrickable/search_filter_policy.dart';
import 'package:lego_catalog/src/backends/rebrickable/theme_exclusion_resolver.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
import 'package:lego_catalog/src/http/catalog_api_client.dart';
import 'package:lego_catalog/src/http/catalog_http_config.dart';
import 'package:lego_catalog/src/models/lego_set.dart';

/// Rebrickable-backed implementation of [LegoCatalogBackend].
class RebrickableBackend implements LegoCatalogBackend {
  /// Creates a backend with configurable retry, timeout, and base URL options.
  RebrickableBackend({
    required String apiKey,
    Dio? dio,
    String baseUrl = _defaultBaseUrl,
    CatalogHttpConfig httpConfig = const CatalogHttpConfig(),
  }) : _requestHeaders = _buildRequestHeaders(apiKey),
       _baseUrl = _normalizeBaseUrl(baseUrl),
       _ownsClient = true,
       _client = CatalogApiClient(
         dio: dio,
         httpConfig: httpConfig,
       );

  /// Creates a backend from a concrete API client.
  RebrickableBackend.fromClient(
    CatalogApiClient client, {
    required String apiKey,
    String baseUrl = _defaultBaseUrl,
  }) : _requestHeaders = _buildRequestHeaders(apiKey),
       _baseUrl = _normalizeBaseUrl(baseUrl),
       _ownsClient = false,
       _client = client;

  static const String _defaultBaseUrl = 'https://rebrickable.com';

  static Map<String, String> _buildRequestHeaders(String apiKey) {
    final normalizedApiKey = apiKey.trim();
    if (normalizedApiKey.isEmpty) {
      throw StateError('Missing Rebrickable API key.');
    }

    return <String, String>{
      'Authorization': 'key $normalizedApiKey',
      'Accept': 'application/json',
    };
  }

  final String _baseUrl;
  final bool _ownsClient;
  final CatalogApiClient _client;
  final Map<String, String> _requestHeaders;

  /// Searches for LEGO sets matching the given [query] string.
  ///
  /// Rebrickable contains many non-lego sets, so themes 501 (Gear) and
  /// 497 (Books) are excluded by default. If you want to include those,
  /// use [searchSetsAdvanced] instead.
  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
  }) {
    return searchSetsAdvanced(
      query,
      pageSize: pageSize,
      minParts: 1,
      excludedThemeRootIds: const {501, 497},
      includeDescendantThemesInExclusion: true,
    );
  }

  /// Advanced search with fine-grained control over filters and pagination.
  ///
  /// This is intended for internal use or advanced clients that need control
  /// over theme filtering and result sizing. Most callers should use
  /// [searchSets].
  ///
  Future<List<LegoSetSummary>> searchSetsAdvanced(
    String query, {
    int pageSize = 20,
    int minParts = 0,
    Set<int> excludedThemeRootIds = const {},
    bool includeDescendantThemesInExclusion = false,
  }) async {
    try {
      final trimmedQuery = query.trim();
      if (trimmedQuery.isEmpty) {
        return const <LegoSetSummary>[];
      }

      final filterPolicy = RebrickableSearchFilterPolicy(
        minParts: minParts,
        excludedThemeRootIds: excludedThemeRootIds,
        includeDescendantThemesInExclusion: includeDescendantThemesInExclusion,
      );

      final rawResults = await _client.getJsonResults(
        path: _resolvePath('/api/v3/lego/sets/'),
        queryParameters: filterPolicy.buildSearchQueryParameters(
          trimmedQuery,
          pageSize: pageSize,
        ),
        options: Options(headers: _requestHeaders),
      );
      final themeExclusionResolver = RebrickableThemeExclusionResolver(
        listThemes: _listThemes,
        rootThemeIds: filterPolicy.excludedThemeRootIds,
        includeDescendantThemes:
            filterPolicy.includeDescendantThemesInExclusion,
      );
      final excludedThemeIds = await themeExclusionResolver
          .getExcludedThemeIds();

      return rawResults
          .where((json) => filterPolicy.passes(json, excludedThemeIds))
          .map(LegoSetSummary.fromJson)
          .toList();
    } on CatalogHttpException catch (error) {
      throw CatalogHttpException(
        message: 'Rebrickable backend search sets failed: ${error.message}',
        statusCode: error.statusCode,
      );
    }
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    try {
      final normalizedSetNumber = setNumber.contains('-')
          ? setNumber
          : '$setNumber-1';

      final Map<String, dynamic> data;
      try {
        data = await _client.getJson(
          path: _resolvePath('/api/v3/lego/sets/$normalizedSetNumber/'),
          options: Options(headers: _requestHeaders),
        );
      } on CatalogHttpException catch (error) {
        if (error.statusCode == 404) {
          return null;
        }
        rethrow;
      }

      return LegoSetDetails.fromJson(data);
    } on CatalogHttpException catch (error) {
      throw CatalogHttpException(
        message: 'Rebrickable backend get set details failed: ${error.message}',
        statusCode: error.statusCode,
      );
    }
  }

  /// Lists Rebrickable themes for app-layer caching and expansion.
  Future<List<LegoTheme>> listThemes() async {
    try {
      return await _listThemes();
    } on CatalogHttpException catch (error) {
      throw CatalogHttpException(
        message: 'Rebrickable backend list themes failed: ${error.message}',
        statusCode: error.statusCode,
      );
    }
  }

  /// Disposes owned HTTP resources.
  void dispose() {
    if (_ownsClient) {
      _client.dispose();
    }
  }

  Future<List<LegoTheme>> _listThemes() async {
    final allThemes = <LegoTheme>[];
    var page = 1;

    while (true) {
      final data = await _client.getJson(
        path: _resolvePath('/api/v3/lego/themes/'),
        queryParameters: {
          'page': page.toString(),
          'page_size': '1000',
        },
        options: Options(headers: _requestHeaders),
      );

      final results = data['results'];
      if (results is! List<dynamic>) {
        return allThemes;
      }

      for (final item in results.whereType<Map<String, dynamic>>()) {
        allThemes.add(LegoTheme.fromJson(item));
      }

      final next = data['next'];
      if (next == null || (next is String && next.isEmpty)) {
        break;
      }
      page++;
    }

    return allThemes;
  }

  String _resolvePath(String path) {
    return Uri.parse(_baseUrl).resolve(path).toString();
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty) {
      throw StateError('Missing Rebrickable base URL.');
    }

    final uri = Uri.tryParse(normalizedBaseUrl);
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      throw StateError('Invalid Rebrickable base URL.');
    }

    final origin = uri.hasPort
        ? Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
            port: uri.port,
          )
        : Uri(
            scheme: uri.scheme,
            userInfo: uri.userInfo,
            host: uri.host,
          );
    return origin.toString();
  }
}
