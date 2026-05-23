import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
/// Environment-backed application configuration values.
abstract class Env {
  static const String _apiKeyFromDartDefine = String.fromEnvironment(
    'REBRICKABLE_API_KEY',
  );

  /// Rebrickable API key used by the catalog backend.
  @EnviedField(varName: 'REBRICKABLE_API_KEY')
  static final String rebrickableApiKey = _resolveRebrickableApiKey();

  static String _resolveRebrickableApiKey() {
    final candidate = _apiKeyFromDartDefine.trim().isNotEmpty
        ? _apiKeyFromDartDefine
        : _Env.rebrickableApiKey;
    return _normalizeApiKey(candidate);
  }

  static String _normalizeApiKey(String rawApiKey) {
    var normalized = rawApiKey.trim();

    if ((normalized.startsWith('"') && normalized.endsWith('"')) ||
        (normalized.startsWith("'") && normalized.endsWith("'"))) {
      normalized = normalized.substring(1, normalized.length - 1).trim();
    }

    final lowerNormalized = normalized.toLowerCase();
    if (lowerNormalized == 'key' || lowerNormalized.startsWith('key ')) {
      normalized = normalized.substring(3).trim();
    }

    if (normalized.isEmpty) {
      throw StateError('Missing Rebrickable API key.');
    }

    return normalized;
  }

  /// Normalizes a raw API key value for unit tests and diagnostics.
  static String normalizeApiKeyForTesting(String rawApiKey) {
    return _normalizeApiKey(rawApiKey);
  }
}
