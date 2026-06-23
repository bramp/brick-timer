import 'package:dio/dio.dart';

import 'package:lego_catalog/src/backends/bricktimer/bricktimer_models.dart';
import 'package:lego_catalog/src/backends/lego_catalog_backend.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
import 'package:lego_catalog/src/http/catalog_api_client.dart';
import 'package:lego_catalog/src/http/catalog_http_config.dart';
import 'package:lego_catalog/src/models/lego_set.dart';

/// App-specific backend for the Brick Timer catalog API.
///
/// This backend is intended for use by the Flutter app, while the server-side
/// proxy can keep the Rebrickable API key hidden and optionally swap in other
/// upstream catalog providers later.
class BrickTimerBackend implements LegoCatalogBackend {
  static const String _defaultBaseUrl = 'https://api.bricktimer.bramp.net';

  /// Creates a Brick Timer backend for the given [baseUrl].
  BrickTimerBackend({
    String baseUrl = _defaultBaseUrl,
    Dio? dio,
    CatalogHttpConfig httpConfig = const CatalogHttpConfig(),
    Future<Map<String, String>> Function()? additionalHeadersProvider,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _ownsClient = true,
       _client = CatalogApiClient(
         dio: dio,
         httpConfig: httpConfig,
         additionalHeadersProvider: additionalHeadersProvider,
       );

  /// Creates a Brick Timer backend from a concrete API client.
  BrickTimerBackend.fromClient(
    CatalogApiClient client, {
    String baseUrl = _defaultBaseUrl,
  }) : _baseUrl = _normalizeBaseUrl(baseUrl),
       _ownsClient = false,
       _client = client;

  final String _baseUrl;
  final bool _ownsClient;
  final CatalogApiClient _client;

  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    late final List<Map<String, dynamic>> rawResults;
    try {
      rawResults = await _client.getJsonResults(
        path: _resolvePath('/v1/sets/search'),
        queryParameters: {
          'query': trimmedQuery,
          'pageSize': pageSize.toString(),
        },
        options: await _buildBrickTimerRequestOptions(),
      );
    } on CatalogHttpException catch (error) {
      throw CatalogHttpException(
        message: 'Brick Timer backend search sets failed: ${error.message}',
        statusCode: error.statusCode,
      );
    }

    return rawResults
        .map(BrickTimerLegoSetSummary.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    final normalizedSetNumber = setNumber.trim();
    if (normalizedSetNumber.isEmpty) {
      return null;
    }

    final Map<String, dynamic> data;
    try {
      data = await _client.getJson(
        path: _resolvePath(
          '/v1/sets/${Uri.encodeComponent(normalizedSetNumber)}',
        ),
        options: await _buildBrickTimerRequestOptions(),
      );
    } on CatalogHttpException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }
      throw CatalogHttpException(
        message: 'Brick Timer backend get set details failed: ${error.message}',
        statusCode: error.statusCode,
      );
    }

    return BrickTimerLegoSetDetails.fromJson(data).toDomain();
  }

  /// Disposes owned HTTP resources.
  void dispose() {
    if (_ownsClient) {
      _client.dispose();
    }
  }

  Future<Options> _buildBrickTimerRequestOptions() async {
    final options = await _client.buildRequestOptions();
    options.headers = <String, dynamic>{
      ...?options.headers,
      'Accept': 'application/json',
    };
    return options;
  }

  String _resolvePath(String path) {
    return Uri.parse(_baseUrl).resolve(path).toString();
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty) {
      throw StateError('Missing Brick Timer catalog base URL.');
    }

    return normalizedBaseUrl.endsWith('/')
        ? normalizedBaseUrl
        : '$normalizedBaseUrl/';
  }
}
