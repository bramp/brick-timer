import 'package:brick_timer/services/catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_catalog/lego_catalog.dart';

class _FakeBackend implements LegoCatalogBackend {
  _FakeBackend({
    this.searchResult = const [],
    this.detailsResult,
    this.searchError,
  });

  final List<LegoSetSummary> searchResult;
  final LegoSetDetails? detailsResult;
  final Exception? searchError;

  @override
  Future<LegoSetDetails?> getSetDetails(String setNumber) async {
    return detailsResult;
  }

  @override
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  }) async {
    if (searchError != null) {
      throw searchError!;
    }
    return searchResult;
  }
}

void main() {
  group('CatalogService.searchSets', () {
    test('maps backend search results to drift companions', () async {
      final service = CatalogService(
        backend: _FakeBackend(
          searchResult: const [
            LegoSetSummary(
              setNumber: '42115-1',
              name: 'Lamborghini Sian FKP 37',
              totalPieces: 3696,
              imageUrl: 'https://example.com/42115.jpg',
            ),
          ],
        ),
      );

      final results = await service.searchSets('Lamborghini');

      expect(results, hasLength(1));
      expect(results.first.setNumber.value, '42115-1');
      expect(results.first.name.value, 'Lamborghini Sian FKP 37');
      expect(results.first.totalPieces.value, 3696);
    });

    test('rebrickable factory throws when API key is missing', () async {
      await expectLater(
        () async => CatalogService.rebrickable(
          apiKey: '   ',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates backend errors', () async {
      final service = CatalogService(
        backend: _FakeBackend(
          searchError: const CatalogHttpException(
            message: 'Unauthorized',
            statusCode: 401,
          ),
        ),
      );

      await expectLater(
        () => service.searchSets('technic'),
        throwsA(isA<CatalogHttpException>()),
      );
    });
  });

  group('CatalogService.getSetDetails', () {
    test('maps backend details to drift companion', () async {
      final service = CatalogService(
        backend: _FakeBackend(
          detailsResult: const LegoSetDetails(
            setNumber: '42096-1',
            name: 'Porsche 911 RSR',
            totalPieces: 1580,
            imageUrl: 'https://example.com/42096.jpg',
          ),
        ),
      );

      final result = await service.getSetDetails('42096');
      expect(result, isNotNull);
      expect(result!.setNumber.value, '42096-1');
      expect(result.name.value, 'Porsche 911 RSR');
      expect(result.totalPieces.value, 1580);
    });

    test('returns null when set does not exist', () async {
      final service = CatalogService(backend: _FakeBackend());

      expect(await service.getSetDetails('missing-set'), isNull);
    });
  });
}
