import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lego_catalog/lego_catalog.dart';
import 'package:test/test.dart';

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions) _handler;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('RebrickableBackend.searchSets', () {
    test('parses successful API response', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/sets/');
        expect(request.queryParameters['search'], 'Lamborghini');
        expect(request.headers['Authorization'], 'key TEST_KEY');

        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'set_num': '42115-1',
                'name': 'Lamborghini Sian FKP 37',
                'num_parts': 3696,
                'set_img_url': 'https://example.com/42115.jpg',
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      final results = await backend.searchSets('Lamborghini');

      expect(results, hasLength(1));
      expect(results.first.setNumber, '42115-1');
      expect(results.first.name, 'Lamborghini Sian FKP 37');
      expect(results.first.totalPieces, 3696);
    });

    test('throws when API key is missing', () {
      expect(
        () => RebrickableBackend(apiKey: '  '),
        throwsA(isA<StateError>()),
      );
    });

    test('retries transient failures and eventually succeeds', () async {
      var requestCount = 0;
      final adapter = _MockAdapter((request) async {
        requestCount++;
        if (requestCount == 1) {
          return ResponseBody.fromString('Service Unavailable', 503);
        }

        expect(request.queryParameters['search'], 'technic');
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'set_num': '42000-1',
                'name': 'Technic Race Car',
                'num_parts': 250,
                'set_img_url': null,
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = RebrickableBackend(
        apiKey: 'TEST_KEY',
        dio: dio,
        initialRetryDelay: Duration.zero,
      );

      final results = await backend.searchSets('technic');

      expect(requestCount, 2);
      expect(results, hasLength(1));
      expect(results.first.setNumber, '42000-1');
    });

    test('does not retry unauthorized responses', () async {
      final adapter = _MockAdapter((_) async {
        return ResponseBody.fromString('Unauthorized', 401);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      await expectLater(
        () => backend.searchSets('technic'),
        throwsA(isA<CatalogHttpException>()),
      );

      expect(adapter.requestCount, 1);
    });
  });
}
