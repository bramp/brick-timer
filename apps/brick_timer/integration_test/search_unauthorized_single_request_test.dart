import 'dart:convert';
import 'dart:typed_data';

import 'package:brick_timer/services/catalog_service.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lego_catalog/lego_catalog.dart';

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

Widget _buildTestApp(CatalogService service) {
  return ProviderScope(
    overrides: [
      legoCatalogServiceProvider.overrideWithValue(service),
    ],
    child: const MaterialApp(home: LegoCatalogSearchScreen()),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'search sends one request on unauthorized backend response',
    (tester) async {
      final adapter = _MockAdapter((request) async {
        expect(request.path, '/sets/');
        expect(request.queryParameters['search'], 'technic');

        return ResponseBody.fromString(
          jsonEncode({'detail': 'Invalid key'}),
          401,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        );
      });

      final dio = Dio()..httpClientAdapter = adapter;

      final backend = RebrickableBackend(apiKey: 'TEST_KEY', dio: dio);
      final service = CatalogService(backend: backend);

      await tester.pumpWidget(_buildTestApp(service));

      await tester.enterText(find.byType(TextField), 'technic');
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 3000));
      await tester.pumpAndSettle();

      expect(adapter.requestCount, 1);
    },
  );
}
