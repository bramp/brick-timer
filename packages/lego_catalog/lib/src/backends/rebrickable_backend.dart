import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'package:lego_catalog/src/backends/lego_catalog_backend.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
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
  }) : _apiKey = apiKey,
       _dio = dio ?? Dio(),
       _ownsDio = dio == null {
    if (_apiKey.trim().isEmpty) {
      throw StateError('Missing Rebrickable API key.');
    }

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      headers: {
        'Authorization': 'key $_apiKey',
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

  static const String _defaultBaseUrl = 'https://rebrickable.com/api/v3/lego';

  final String _apiKey;
  final Dio _dio;
  final bool _ownsDio;

  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    late final Response<Object> response;
    try {
      response = await _dio.get<Object>(
        '/sets/',
        queryParameters: {
          'search': trimmedQuery,
          'page_size': pageSize.toString(),
        },
      );
    } on DioException catch (error) {
      throw _toCatalogHttpException(error, operation: 'search sets');
    }

    _throwOnUnexpectedStatus(response, operation: 'search sets');

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const CatalogHttpException(
        message: 'Rebrickable search returned an invalid response payload.',
      );
    }

    final results = data['results'];
    if (results is! List<dynamic>) {
      return const [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(LegoSetSummary.fromJson)
        .toList();
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
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

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const CatalogHttpException(
        message:
            'Rebrickable set details returned an invalid response payload.',
      );
    }

    return LegoSetDetails.fromJson(data);
  }

  /// Disposes owned HTTP resources when this backend created the Dio client.
  void dispose() {
    if (_ownsDio) {
      _dio.close(force: true);
    }
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
