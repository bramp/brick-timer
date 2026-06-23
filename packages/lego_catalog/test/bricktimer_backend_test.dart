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
  group('BrickTimerBackend.searchSets', () {
    test(
      'uses default BrickTimer API base URL when baseUrl is omitted',
      () async {
        final adapter = _MockAdapter((request) async {
          expect(request.uri.host, 'api.bricktimer.bramp.net');
          expect(request.uri.path, '/v1/sets/search');
          expect(request.queryParameters['query'], 'Lamborghini');

          return ResponseBody.fromString(
            jsonEncode({
              'results': [
                {
                  'setNumber': '42115-1',
                  'name': 'Lamborghini Sian FKP 37',
                  'totalPieces': 3696,
                  'imageUrl': 'https://example.com/42115.jpg',
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
        final backend = BrickTimerBackend(dio: dio);

        final results = await backend.searchSets('Lamborghini');

        expect(results, hasLength(1));
        expect(results.first.setNumber, '42115-1');
      },
    );

    test('parses catalog search results and sends app check headers', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.uri.path, '/v1/sets/search');
        expect(request.queryParameters['query'], 'Lamborghini');
        expect(request.headers['X-Firebase-AppCheck'], 'APP_CHECK_TOKEN');

        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'setNumber': '42115-1',
                'name': 'Lamborghini Sian FKP 37',
                'totalPieces': 3696,
                'imageUrl': 'https://example.com/42115.jpg',
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
      final backend = BrickTimerBackend(
        baseUrl: 'https://bricktimer.example.com',
        dio: dio,
        additionalHeadersProvider: () async {
          return {'X-Firebase-AppCheck': 'APP_CHECK_TOKEN'};
        },
      );

      final results = await backend.searchSets('Lamborghini');

      expect(results, hasLength(1));
      expect(results.first.setNumber, '42115-1');
      expect(results.first.totalPieces, 3696);
    });

    test('returns empty results for blank queries', () async {
      final backend = BrickTimerBackend(
        baseUrl: 'https://bricktimer.example.com',
      );

      final results = await backend.searchSets('   ');

      expect(results, isEmpty);
    });

    test(
      'fromClient injects BrickTimer headers and uses backend baseUrl',
      () async {
        final adapter = _MockAdapter((request) async {
          expect(request.uri.host, 'bricktimer.example.com');
          expect(request.uri.path, '/v1/sets/search');
          expect(request.queryParameters['query'], 'Ferrari');
          expect(request.headers['Accept'], 'application/json');

          return ResponseBody.fromString(
            jsonEncode({
              'results': [
                {
                  'setNumber': '42143-1',
                  'name': 'Ferrari Daytona SP3',
                  'totalPieces': 3778,
                  'imageUrl': null,
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
        final client = CatalogApiClient(
          dio: dio,
        );
        final backend = BrickTimerBackend.fromClient(
          client,
          baseUrl: 'https://bricktimer.example.com',
        );

        final results = await backend.searchSets('Ferrari');

        expect(results, hasLength(1));
        expect(results.first.setNumber, '42143-1');
      },
    );
  });

  group('BrickTimerBackend.getSetDetails', () {
    test('parses catalog detail responses', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.uri.path, '/v1/sets/42096-1');

        return ResponseBody.fromString(
          jsonEncode({
            'setNumber': '42096-1',
            'name': 'Porsche 911 RSR',
            'totalPieces': 1580,
            'imageUrl': null,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = BrickTimerBackend(
        baseUrl: 'https://bricktimer.example.com',
        dio: dio,
      );

      final details = await backend.getSetDetails('42096-1');

      expect(details, isNotNull);
      expect(details!.setNumber, '42096-1');
      expect(details.totalPieces, 1580);
    });

    test('returns null for 404 responses', () async {
      final adapter = _MockAdapter((_) async {
        return ResponseBody.fromString('Not Found', 404);
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = BrickTimerBackend(
        baseUrl: 'https://bricktimer.example.com',
        dio: dio,
      );

      final details = await backend.getSetDetails('missing');

      expect(details, isNull);
    });
  });
}
