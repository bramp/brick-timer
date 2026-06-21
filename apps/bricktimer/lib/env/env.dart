import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
/// Environment-backed configuration values.
abstract class Env {
  /// Rebrickable API key from generated `.env` content.
  @EnviedField(varName: 'REBRICKABLE_API_KEY', defaultValue: '')
  static final String rebrickableApiKey = _Env.rebrickableApiKey;
}
