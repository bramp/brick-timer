import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:lego_catalog/src/backends/bricktimer/bricktimer_lego_set.dart';
import 'package:lego_catalog/src/backends/lego_catalog_backend.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
import 'package:lego_catalog/src/models/lego_set.dart';

/// App-specific backend for the Brick Timer catalog API.
///
/// This backend is intended for use by the Flutter app, while the server-side
/// proxy can keep the Rebrickable API key hidden and optionally swap in other
/// upstream catalog providers later.
class BrickTimerBackend implements LegoCatalogBackend {
  /// Creates a Brick Timer backend for the given [baseUrl].
  BrickTimerBackend({
    required String baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    Duration sendTimeout = const Duration(seconds: 10),
    int retries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 250),
    Future<Map<String, String>> Function()? additionalHeadersProvider,
  }) : _dio = dio ?? Dio(),
       _ownsDio = dio == null,
       _additionalHeadersProvider = additionalHeadersProvider {
    final normalizedBaseUrl = baseUrl.trim();
    if (normalizedBaseUrl.isEmpty) {
      throw StateError('Missing Brick Timer base URL.');
    }

    _dio.options = BaseOptions(
      baseUrl: normalizedBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: const {
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: retries,
        retryDelays: _buildRetryDelays(retries, initialRetryDelay),
        retryEvaluator: _isRetryable,
      ),
    );
  }

  final Dio _dio;
  final bool _ownsDio;
  final Future<Map<String, String>> Function()? _additionalHeadersProvider;

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

    late final Response<Object> response;
    try {
      response = await _dio.get<Object>(
        '/v1/sets/search',
        queryParameters: {
          'query': trimmedQuery,
          'pageSize': pageSize.toString(),
          'minParts': minParts.toString(),
          'excludedThemeRootIds': excludedThemeRootIds.join(','),
          'includeDescendantThemesInExclusion':
              includeDescendantThemesInExclusion.toString(),
        },
        options: Options(
          headers: await _buildHeaders(),
        ),
      );
    } on DioException catch (error) {
      throw _toCatalogHttpException(error, operation: 'search sets');
    }

    _throwOnUnexpectedStatus(response, operation: 'search sets');
    final data = _asJsonMap(
      response.data,
      invalidPayloadMessage:
          'Brick Timer catalog search returned an invalid response payload.',
    );

    final results = data['results'];
    if (results is! List<dynamic>) {
      return const <LegoSetSummary>[];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(BrickTimerLegoSetSummary.fromJson)
        .map((set) => set.toDomain())
        .toList();
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    final normalizedSetNumber = setNumber.trim();
    if (normalizedSetNumber.isEmpty) {
      return null;
    }

    late final Response<Object> response;
    try {
      response = await _dio.get<Object>(
        '/v1/sets/${Uri.encodeComponent(normalizedSetNumber)}',
        options: Options(
          headers: await _buildHeaders(),
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw _toCatalogHttpException(error, operation: 'get set details');
    }

    _throwOnUnexpectedStatus(response, operation: 'get set details');
    final data = _asJsonMap(
      response.data,
      invalidPayloadMessage:
          'Brick Timer catalog set details returned '
          'an invalid response payload.',
    );
    return BrickTimerLegoSetDetails.fromJson(data).toDomain();
  }

  /// Disposes owned HTTP resources.
  void dispose() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
  }

  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{};
    final additionalHeadersProvider = _additionalHeadersProvider;
    if (additionalHeadersProvider != null) {
      headers.addAll(await additionalHeadersProvider());
    }

    return headers;
  }

  static Map<String, dynamic> _asJsonMap(
    Object? data, {
    required String invalidPayloadMessage,
  }) {
    if (data is! Map<String, dynamic>) {
      throw CatalogHttpException(message: invalidPayloadMessage);
    }
    return data;
  }

  static List<Duration> _buildRetryDelays(
    int retries,
    Duration initialRetryDelay,
  ) {
    return List<Duration>.generate(retries, (index) {
      final multiplier = 1 << index;
      return Duration(
        milliseconds: initialRetryDelay.inMilliseconds * multiplier,
      );
    });
  }

  static bool _isRetryable(DioException error, int attempt) {
    final type = error.type;
    if (type == DioExceptionType.connectionError ||
        type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.unknown) {
      return true;
    }

    final statusCode = error.response?.statusCode;
    return statusCode == 408 ||
        statusCode == 429 ||
        (statusCode != null && statusCode >= 500);
  }

  static void _throwOnUnexpectedStatus(
    Response<Object> response, {
    required String operation,
  }) {
    final statusCode = response.statusCode;
    if (statusCode == 200) {
      return;
    }

    throw CatalogHttpException(
      message: 'Brick Timer catalog $operation failed with status $statusCode.',
      statusCode: statusCode,
    );
  }

  static CatalogHttpException _toCatalogHttpException(
    DioException error, {
    required String operation,
  }) {
    final statusCode = error.response?.statusCode;
    if (statusCode != null) {
      return CatalogHttpException(
        message:
            'Brick Timer catalog $operation failed with status $statusCode.',
        statusCode: statusCode,
      );
    }

    return CatalogHttpException(
      message:
          'Brick Timer catalog $operation request failed: ${error.message}',
    );
  }
}
