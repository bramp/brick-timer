import 'package:brick_timer/env/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Env.normalizeApiKeyForTesting', () {
    test('keeps a plain key as-is', () {
      expect(Env.normalizeApiKeyForTesting('abc123'), 'abc123');
    });

    test('trims leading and trailing whitespace', () {
      expect(Env.normalizeApiKeyForTesting('  abc123  '), 'abc123');
    });

    test('strips single or double quotes', () {
      expect(Env.normalizeApiKeyForTesting('"abc123"'), 'abc123');
      expect(Env.normalizeApiKeyForTesting("'abc123'"), 'abc123');
    });

    test('strips accidental key prefix', () {
      expect(Env.normalizeApiKeyForTesting('key abc123'), 'abc123');
      expect(Env.normalizeApiKeyForTesting('KEY abc123'), 'abc123');
    });

    test('throws when normalized key becomes empty', () {
      expect(
        () => Env.normalizeApiKeyForTesting('  ""  '),
        throwsA(isA<StateError>()),
      );
      expect(
        () => Env.normalizeApiKeyForTesting('key   '),
        throwsA(isA<StateError>()),
      );
    });
  });
}
