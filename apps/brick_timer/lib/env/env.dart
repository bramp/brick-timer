import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
/// Environment-backed application configuration values.
abstract class Env {
  /// Rebrickable API key used by the catalog backend.
  @EnviedField(varName: 'REBRICKABLE_API_KEY')
  static final String rebrickableApiKey = _Env.rebrickableApiKey;
}
