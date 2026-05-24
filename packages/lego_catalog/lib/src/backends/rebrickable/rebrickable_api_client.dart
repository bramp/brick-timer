import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:lego_catalog/src/backends/rebrickable/lego_theme.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';

/// Thin API client for Rebrickable HTTP interactions.
class RebrickableApiClient {
  /// Creates a Rebrickable HTTP client with retry and timeout configuration.
  RebrickableApiClient({
    required String apiKey,
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 10),
    Duration sendTimeout = const Duration(seconds: 10),
    int retries = 3,
    Duration initialRetryDelay = const Duration(milliseconds: 250),
  }) : _dio = dio ?? Dio(),
       _ownsDio = dio == null {
    if (apiKey.trim().isEmpty) {
      throw StateError('Missing Rebrickable API key.');
    }

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Authorization': 'key $apiKey',
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

  /// Default Rebrickable API base URL.
  static const String defaultBaseUrl = 'https://rebrickable.com/api/v3/lego';

  final Dio _dio;
  final bool _ownsDio;

  /// Searches sets and returns raw result objects from the API payload.
  Future<List<Map<String, dynamic>>> searchSetsRaw({
    required Map<String, String> queryParameters,
  }) async {
    late final Response<Object> response;
    try {
      response = await _dio.get<Object>(
        '/sets/',
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      throw _toCatalogHttpException(error, operation: 'search sets');
    }

    _throwOnUnexpectedStatus(response, operation: 'search sets');
    final data = _asJsonMap(
      response.data,
      invalidPayloadMessage:
          'Rebrickable search returned an invalid response payload.',
    );

    final results = data['results'];
    if (results is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    return results.whereType<Map<String, dynamic>>().toList();
  }

  /// Fetches one set by set number and returns the raw set JSON.
  ///
  /// Returns null when the set is not found.
  Future<Map<String, dynamic>?> getSetDetailsRaw(String setNumber) async {
    final normalizedSetNumber = setNumber.contains('-')
        ? setNumber
        : '$setNumber-1';

    late final Response<Object> response;
    try {
      response = await _dio.get<Object>('/sets/$normalizedSetNumber/');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      throw _toCatalogHttpException(error, operation: 'get set details');
    }

    _throwOnUnexpectedStatus(response, operation: 'get set details');
    return _asJsonMap(
      response.data,
      invalidPayloadMessage:
          'Rebrickable set details returned an invalid response payload.',
    );
  }

  /// Lists all themes by paging through the API.
  Future<List<LegoTheme>> listThemes() async {
    final allThemes = <LegoTheme>[];
    var page = 1;

    while (true) {
      late final Response<Object> response;
      try {
        response = await _dio.get<Object>(
          '/themes/',
          queryParameters: {
            'page': page.toString(),
            'page_size': '1000',
          },
        );
      } on DioException catch (error) {
        throw _toCatalogHttpException(error, operation: 'list themes');
      }

      _throwOnUnexpectedStatus(response, operation: 'list themes');
      final data = _asJsonMap(
        response.data,
        invalidPayloadMessage:
            'Rebrickable themes returned an invalid response payload.',
      );

      final results = data['results'];
      if (results is! List<dynamic>) {
        return allThemes;
      }

      for (final item in results.whereType<Map<String, dynamic>>()) {
        allThemes.add(
          LegoTheme.fromJson(item.cast<String, Object?>()),
        );
      }

      final next = data['next'];
      if (next == null || (next is String && next.isEmpty)) {
        break;
      }
      page++;
    }

    return allThemes;
  }

  /// Disposes owned HTTP resources.
  void dispose() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
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
      message: 'Rebrickable $operation failed with status $statusCode.',
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
        message: 'Rebrickable $operation failed with status $statusCode.',
        statusCode: statusCode,
      );
    }

    return CatalogHttpException(
      message: 'Rebrickable $operation request failed: ${error.message}',
    );
  }
}
