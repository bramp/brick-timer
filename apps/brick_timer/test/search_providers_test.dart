import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/catalog_service.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// A simple mock to track how many times the API was actually hit.
class MockCatalogService implements CatalogService {
  int searchSetsCallCount = 0;
  final queriedStrings = <String>[];

  @override
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async {
    return null;
  }

  @override
  Future<void> refreshThemeCacheIfExpired() async {}

  @override
  Future<void> warmUp() async {}

  @override
  Future<List<LegoSetsCompanion>> searchSets(
    String query, {
    int pageSize = 20,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  }) async {
    searchSetsCallCount++;
    queriedStrings.add(query);
    return [];
  }
}

void main() {
  test(
    'searchResultsProvider debounces queries and cancels old requests',
    () async {
      final mockService = MockCatalogService();
      final container = ProviderContainer(
        overrides: [
          legoCatalogServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      // Listen to the provider so it stays alive and evaluates
      container.listen(searchResultsProvider, (previous, next) {});

      // 1. User types 'L'
      container.read(searchQueryProvider.notifier).updateQuery('L');

      // Wait 200ms (less than the 500ms debounce)
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // 2. User types 'Le' before the first one finishes
      container.read(searchQueryProvider.notifier).updateQuery('Le');

      // Wait 200ms
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // 3. User types 'Lego'
      container.read(searchQueryProvider.notifier).updateQuery('Lego');

      // Now we wait long enough for the 500ms debounce to finally complete
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Verify: The API should have only been hit exactly once, with the final
      // string.
      expect(mockService.searchSetsCallCount, 1);
      expect(mockService.queriedStrings, ['Lego']);
    },
  );

  test('searchResultsProvider ignores repeated normalized queries', () async {
    final mockService = MockCatalogService();
    final container = ProviderContainer(
      overrides: [
        legoCatalogServiceProvider.overrideWithValue(mockService),
      ],
    );
    addTearDown(container.dispose);

    container.listen(searchResultsProvider, (previous, next) {});

    container.read(searchQueryProvider.notifier).updateQuery('Technic');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    container.read(searchQueryProvider.notifier).updateQuery('Technic');
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(mockService.searchSetsCallCount, 1);
    expect(mockService.queriedStrings, ['Technic']);
  });

  test('searchResultsProvider refetches when invalidated', () async {
    final mockService = MockCatalogService();
    final container = ProviderContainer(
      overrides: [
        legoCatalogServiceProvider.overrideWithValue(mockService),
      ],
    );
    addTearDown(container.dispose);

    container.listen(searchResultsProvider, (previous, next) {});

    container.read(searchQueryProvider.notifier).updateQuery('Technic');
    await container.read(searchResultsProvider.future);

    container.invalidate(searchResultsProvider);
    await container.read(searchResultsProvider.future);

    expect(mockService.searchSetsCallCount, 2);
    expect(mockService.queriedStrings, ['Technic', 'Technic']);
  });
}
