import 'package:bricktimer_service/src/bricktimer_catalog_service.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:lego_catalog/lego_catalog.dart';
import 'package:test/test.dart';

class _FakeBackend implements LegoCatalogBackend {
  List<LegoSetSummary> searchResults = const [];
  LegoSetDetails? details;
  String? lastSearchQuery;
  String? lastSetNumber;
  int? lastPageSize;
  int? lastMinParts;
  Set<int>? lastExcludedThemeRootIds;
  bool? lastIncludeDescendantThemesInExclusion;

  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  }) async {
    lastSearchQuery = query;
    lastPageSize = pageSize;
    lastMinParts = minParts;
    lastExcludedThemeRootIds = excludedThemeRootIds;
    lastIncludeDescendantThemesInExclusion = includeDescendantThemesInExclusion;
    return searchResults;
  }

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    lastSetNumber = setNumber;
    return details;
  }
}

void main() {
  group('BrickTimerCatalogService', () {
    test('serves health checks', () async {
      final service = BrickTimerCatalogService(backend: _FakeBackend());
      final response = await service.handle(
        Request('GET', Uri.parse('https://example.com/health')),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), contains('"status":"ok"'));
    });

    test('searches sets and returns app-specific JSON', () async {
      final backend = _FakeBackend()
        ..searchResults = [
          const LegoSetSummary(
            setNumber: '42115-1',
            name: 'Lamborghini Sian FKP 37',
            totalPieces: 3696,
            imageUrl: 'https://example.com/42115.jpg',
          ),
        ];
      final service = BrickTimerCatalogService(backend: backend);
      final response = await service.handle(
        Request(
          'GET',
          Uri.parse(
            'https://example.com/v1/sets/search?query=Lamborghini&pageSize=12&minParts=5&excludedThemeRootIds=501,497&includeDescendantThemesInExclusion=false',
          ),
        ),
      );

      expect(response.statusCode, 200);
      expect(backend.lastSearchQuery, 'Lamborghini');
      expect(backend.lastPageSize, 12);
      expect(backend.lastMinParts, 5);
      expect(backend.lastExcludedThemeRootIds, {501, 497});
      expect(backend.lastIncludeDescendantThemesInExclusion, false);
      expect(
        await response.readAsString(),
        contains('"setNumber":"42115-1"'),
      );
    });

    test('returns details when a set exists', () async {
      final backend = _FakeBackend()
        ..details = const LegoSetDetails(
          setNumber: '42096-1',
          name: 'Porsche 911 RSR',
          totalPieces: 1580,
        );
      final service = BrickTimerCatalogService(backend: backend);
      final response = await service.handle(
        Request('GET', Uri.parse('https://example.com/v1/sets/42096-1')),
      );

      expect(response.statusCode, 200);
      expect(backend.lastSetNumber, '42096-1');
      expect(await response.readAsString(), contains('"totalPieces":1580'));
    });

    test('returns not found when the set is missing', () async {
      final service = BrickTimerCatalogService(backend: _FakeBackend());
      final response = await service.handle(
        Request('GET', Uri.parse('https://example.com/v1/sets/missing')),
      );

      expect(response.statusCode, 404);
    });

    test('rejects blank search queries', () async {
      final service = BrickTimerCatalogService(backend: _FakeBackend());
      final response = await service.handle(
        Request('GET', Uri.parse('https://example.com/v1/sets/search')),
      );

      expect(response.statusCode, 400);
      expect(await response.readAsString(), contains('query parameter'));
    });
  });
}
