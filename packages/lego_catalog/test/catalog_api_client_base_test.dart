import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:lego_catalog/src/errors/catalog_http_exception.dart';
import 'package:lego_catalog/src/http/catalog_api_client.dart';
import 'package:lego_catalog/src/http/catalog_http_config.dart';
import 'package:test/test.dart';

class _MockAdapter implements HttpClientAdapter {
  _MockAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

class _TestApiClient extends CatalogApiClient {
  _TestApiClient({required Dio dio})
    : super(
        dio: dio,
        httpConfig: const CatalogHttpConfig(retries: 0),
      );

  Future<Map<String, dynamic>> fetchJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return getJson(
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<List<Map<String, dynamic>>> fetchResults(String path) {
    return getJsonResults(
      path: path,
    );
  }
}

void main() {
  group('CatalogApiClient wrapper helpers', () {
    test('getJson returns parsed map for HTTP 200', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/ok');
        expect(request.queryParameters['q'], 'abc');
        return ResponseBody.fromString(
          jsonEncode({'hello': 'world'}),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = _TestApiClient(dio: dio);

      final result = await client.fetchJson(
        '/ok',
        queryParameters: {'q': 'abc'},
      );

      expect(result, {'hello': 'world'});
    });

    test('getJson throws CatalogHttpException on HTTP 404', () async {
      final adapter = _MockAdapter((_) async {
        return ResponseBody.fromString('Not found', 404);
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = _TestApiClient(dio: dio);

      await expectLater(
        () => client.fetchJson('/missing'),
        throwsA(
          isA<CatalogHttpException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });

    test('getJson throws CatalogHttpException for non-200 status', () async {
      final adapter = _MockAdapter((_) async {
        return ResponseBody.fromString('Boom', 500);
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = _TestApiClient(dio: dio);

      await expectLater(
        () => client.fetchJson('/boom'),
        throwsA(
          isA<CatalogHttpException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test(
      'getJson throws CatalogHttpException for invalid JSON payload',
      () async {
        final adapter = _MockAdapter((_) async {
          return ResponseBody.fromString(
            jsonEncode(['not', 'a', 'map']),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _TestApiClient(dio: dio);

        await expectLater(
          () => client.fetchJson('/bad-json'),
          throwsA(isA<CatalogHttpException>()),
        );
      },
    );

    test('getJsonResults returns only map entries from results', () async {
      final adapter = _MockAdapter((_) async {
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {'id': 1},
              'skip-me',
              {'id': 2},
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });
      final dio = Dio()..httpClientAdapter = adapter;
      final client = _TestApiClient(dio: dio);

      final results = await client.fetchResults('/results');

      expect(results, [
        {'id': 1},
        {'id': 2},
      ]);
    });

    test(
      'getJsonResults returns empty list when results is not a list',
      () async {
        final adapter = _MockAdapter((_) async {
          return ResponseBody.fromString(
            jsonEncode({'results': 'invalid'}),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });
        final dio = Dio()..httpClientAdapter = adapter;
        final client = _TestApiClient(dio: dio);

        final results = await client.fetchResults('/results');

        expect(results, isEmpty);
      },
    );
  });
}
