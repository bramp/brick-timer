class CatalogHttpException implements Exception {
  const CatalogHttpException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return 'CatalogHttpException: $message';
    }
    return 'CatalogHttpException(statusCode: $statusCode, message: $message)';
  }
}
