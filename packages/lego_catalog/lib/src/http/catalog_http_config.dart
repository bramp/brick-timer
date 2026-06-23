/// HTTP client configuration for catalog API clients.
///
/// Groups timeout, retry, and other HTTP-level settings into a single,
/// reusable configuration object.
class CatalogHttpConfig {
  /// Creates HTTP configuration with sensible defaults for API clients.
  const CatalogHttpConfig({
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.sendTimeout = const Duration(seconds: 10),
    this.retries = 3,
    this.initialRetryDelay = const Duration(milliseconds: 250),
  });

  /// Maximum duration to wait for establishing a connection.
  final Duration connectTimeout;

  /// Maximum duration to wait for receiving a complete response.
  final Duration receiveTimeout;

  /// Maximum duration to wait for sending a complete request.
  final Duration sendTimeout;

  /// Number of times to retry transient failures (timeouts, 429, 5xx).
  final int retries;

  /// Initial delay before the first retry; subsequent retries use exponential backoff.
  final Duration initialRetryDelay;
}
