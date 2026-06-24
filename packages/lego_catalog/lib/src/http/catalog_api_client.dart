import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
import 'package:lego_catalog/src/http/catalog_http_config.dart';
import 'package:logging/logging.dart';

/// Concrete reusable API client for catalog backends.
///
/// Backends compose this client for transport concerns while keeping domain
/// mapping and filtering in backend-specific code.
class CatalogApiClient {
  /// Creates a concrete catalog API client.
  CatalogApiClient({
    Dio? dio,
    CatalogHttpConfig httpConfig = const CatalogHttpConfig(),
    Map<String, String> defaultHeaders = const <String, String>{},
    Future<Map<String, String>> Function()? additionalHeadersProvider,
  }) : _dio = dio ?? Dio(),
       _ownsDio = dio == null,
       _additionalHeadersProvider = additionalHeadersProvider {
    _dio.options = BaseOptions(
      connectTimeout: httpConfig.connectTimeout,
      receiveTimeout: httpConfig.receiveTimeout,
      sendTimeout: httpConfig.sendTimeout,
      headers: defaultHeaders,
    );

    _dio.interceptors.add(
      RetryInterceptor(
        dio: _dio,
        retries: httpConfig.retries,
        retryDelays: _buildRetryDelays(
          httpConfig.retries,
          httpConfig.initialRetryDelay,
        ),
        retryEvaluator: _isRetryable,
      ),
    );
  }

  static final Logger _logger = Logger('lego_catalog.http.catalog_api_client');

  final Dio _dio;
  final bool _ownsDio;
  final Future<Map<String, String>> Function()? _additionalHeadersProvider;

  /// Underlying Dio client for endpoint-specific requests.
  Dio get dio => _dio;

  /// Builds request options with any per-request additional headers.
  Future<Options> buildRequestOptions() async {
    final additionalHeadersProvider = _additionalHeadersProvider;
    if (additionalHeadersProvider == null) {
      return Options();
    }

    return Options(headers: await additionalHeadersProvider());
  }

  /// Performs a GET request and returns a validated JSON map response.
  Future<Map<String, dynamic>> getJson({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final requestOptions = (options ?? await buildRequestOptions())
      ..responseType = ResponseType.json;
    _logger.finest(
      'HTTP GET $path query=$queryParameters headers='
      '${_redactedHeaders(requestOptions.headers)}',
    );

    late final Response<Object> response;
    try {
      response = await dio.get<Object>(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
      );
    } on DioException catch (error) {
      _logger.finest(
        'HTTP ERROR GET $path status=${error.response?.statusCode} '
        'type=${error.type} message=${error.message} '
        'api_error=${_extractApiErrorMessage(error.response?.data)}',
      );
      throw toCatalogHttpException(error);
    }

    _logger.finest('HTTP ${response.statusCode} GET $path');
    throwOnUnexpectedStatus(response);
    return asJsonMap(response.data);
  }

  /// Performs a GET request and returns the `results` list as JSON maps.
  Future<List<Map<String, dynamic>>> getJsonResults({
    required String path,
    String resultsField = 'results',
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final data = await getJson(
      path: path,
      queryParameters: queryParameters,
      options: options,
    );

    final results = data[resultsField];
    if (results is! List<dynamic>) {
      return const <Map<String, dynamic>>[];
    }

    return results.whereType<Map<String, dynamic>>().toList();
  }

  /// Validates that [data] is a JSON object and returns it as a map.
  Map<String, dynamic> asJsonMap(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const CatalogHttpException(
        message: 'Request returned an invalid response payload.',
      );
    }
    return data;
  }

  /// Throws a [CatalogHttpException] for unexpected non-200 responses.
  void throwOnUnexpectedStatus(Response<Object> response) {
    final statusCode = response.statusCode;
    if (statusCode == 200) {
      return;
    }

    final apiError = _extractApiErrorMessage(response.data);
    final detail = apiError == null ? '' : ': $apiError';

    throw CatalogHttpException(
      message: 'Request failed with status $statusCode$detail.',
      statusCode: statusCode,
    );
  }

  /// Converts a Dio error to a source-scoped [CatalogHttpException].
  CatalogHttpException toCatalogHttpException(DioException error) {
    final method = error.requestOptions.method;
    final uri = error.requestOptions.uri;
    final statusCode = error.response?.statusCode;
    final apiError = _extractApiErrorMessage(error.response?.data);
    if (statusCode != null) {
      final detail = apiError == null ? '' : ': $apiError';
      return CatalogHttpException(
        message: '$method $uri failed with status $statusCode$detail.',
        statusCode: statusCode,
      );
    }

    final detail = apiError ?? error.message ?? 'Unknown network error.';
    return CatalogHttpException(
      message: '$method $uri request failed: $detail',
    );
  }

  /// Disposes owned HTTP resources.
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

  static Map<String, dynamic> _redactedHeaders(Map<String, dynamic>? headers) {
    final source = headers ?? const <String, dynamic>{};
    final redacted = <String, dynamic>{};
    for (final entry in source.entries) {
      final key = entry.key.toLowerCase();
      final isSensitive =
          key == 'authorization' ||
          key == 'x-api-key' ||
          key == 'proxy-authorization';
      redacted[entry.key] = isSensitive ? '<redacted>' : entry.value;
    }
    return redacted;
  }

  static String? _extractApiErrorMessage(Object? data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      final text = data.trim();
      return text.isEmpty ? null : text;
    }
    if (data is List<dynamic>) {
      final parts = data
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    }
    if (data is Map<String, dynamic>) {
      for (final key in <String>[
        'detail',
        'error',
        'message',
        'title',
      ]) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }

      final nonFieldErrors = data['non_field_errors'];
      if (nonFieldErrors is List<dynamic>) {
        final text = nonFieldErrors
            .map((item) => item?.toString().trim() ?? '')
            .where((item) => item.isNotEmpty)
            .join(', ');
        if (text.isNotEmpty) {
          return text;
        }
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final entry in errors.entries) {
          final value = entry.value;
          if (value is String && value.trim().isNotEmpty) {
            return '${entry.key}: ${value.trim()}';
          }
          if (value is List<dynamic>) {
            final text = value
                .map((item) => item?.toString().trim() ?? '')
                .where((item) => item.isNotEmpty)
                .join(', ');
            if (text.isNotEmpty) {
              return '${entry.key}: $text';
            }
          }
        }
      }
    }

    return null;
  }
}
