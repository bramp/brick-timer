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
        expect(request.queryParameters['ordering'], '-year');
        expect(request.queryParameters['min_parts'], '1');
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

      final results = await backend.searchSets(
        'technic',
        excludedThemeRootIds: const {},
      );

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

    test('filters excluded theme descendants from results', () async {
      final adapter = _MockAdapter((request) async {
        if (request.path == '/themes/') {
          return ResponseBody.fromString(
            jsonEncode({
              'next': null,
              'results': [
                {'id': 501, 'parent_id': null, 'name': 'Gear'},
                {'id': 740, 'parent_id': 501, 'name': 'Storage'},
                {'id': 158, 'parent_id': null, 'name': 'Star Wars'},
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        }

        expect(request.path, '/sets/');
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'set_num': '0878119001641-1',
                'name': 'Star Wars ZipBin Storage Toy Case Battle Bridge',
                'num_parts': 4,
                'theme_id': 740,
                'set_img_url': null,
              },
              {
                'set_num': '3340-1',
                'name': 'Star Wars #1 - Sith Minifig Pack',
                'num_parts': 30,
                'theme_id': 158,
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
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      final results = await backend.searchSets('star wars');

      expect(results, hasLength(1));
      expect(results.first.setNumber, '3340-1');
    });

    test('supports disabling theme exclusions', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/sets/');
        return ResponseBody.fromString(
          jsonEncode({
            'results': [
              {
                'set_num': '0878119001641-1',
                'name': 'Star Wars ZipBin Storage Toy Case Battle Bridge',
                'num_parts': 4,
                'theme_id': 740,
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
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      final results = await backend.searchSets(
        'star wars',
        excludedThemeRootIds: const {},
      );

      expect(results, hasLength(1));
      expect(results.first.setNumber, '0878119001641-1');
      expect(adapter.requestCount, 1);
    });
  });

  group('RebrickableBackend.getSetDetails', () {
    test('normalizes set number by appending default version suffix', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/sets/42096-1/');
        return ResponseBody.fromString(
          jsonEncode({
            'set_num': '42096-1',
            'name': 'Porsche 911 RSR',
            'num_parts': 1580,
            'set_img_url': 'https://example.com/42096.jpg',
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      final details = await backend.getSetDetails('42096');

      expect(details, isNotNull);
      expect(details!.setNumber, '42096-1');
      expect(adapter.requestCount, 1);
    });

    test('keeps explicit set version when suffix is already present', () async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/sets/42096-3/');
        return ResponseBody.fromString(
          jsonEncode({
            'set_num': '42096-3',
            'name': 'Porsche 911 RSR',
            'num_parts': 1580,
            'set_img_url': null,
          }),
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;
      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);

      final details = await backend.getSetDetails('42096-3');

      expect(details, isNotNull);
      expect(details!.setNumber, '42096-3');
      expect(adapter.requestCount, 1);
    });
  });
}
