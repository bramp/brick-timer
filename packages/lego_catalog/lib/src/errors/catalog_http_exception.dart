/// Represents an HTTP-layer failure from a catalog backend.
class CatalogHttpException implements Exception {
  /// Creates an exception with a human-readable [message] and status code.
  const CatalogHttpException({
    required this.message,
    this.statusCode,
  });

  /// Failure details suitable for logs and user-visible diagnostics.
  final String message;

  /// HTTP response status code, when one was available.
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'CatalogHttpException: $message';
    }
    return 'CatalogHttpException(statusCode: $statusCode, message: $message)';
  }
}
