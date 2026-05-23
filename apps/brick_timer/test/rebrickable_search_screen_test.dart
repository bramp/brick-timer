import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/Catalog_Service.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:brick_timer/ui/search/rebrickable_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCatalogService implements CatalogService {
  FakeCatalogService({
    this.shouldThrow = false,
    List<LegoSetsCompanion>? results,
  }) : _results = results ?? [];

  final bool shouldThrow;
  final List<LegoSetsCompanion> _results;
  final List<String> queries = [];

  @override
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async => null;

  @override
  Future<List<LegoSetsCompanion>> searchSets(String query) async {
    queries.add(query);
    if (shouldThrow) {
      throw StateError('API failure');
    }
    return _results;
  }
}

Widget _buildTestApp(CatalogService catalogService) {
  return ProviderScope(
    overrides: [
      legoCatalogServiceProvider.overrideWithValue(catalogService),
    ],
    child: const MaterialApp(home: RebrickableSearchScreen()),
  );
}

void main() {
  testWidgets('shows initial prompt before typing', (tester) async {
    await tester.pumpWidget(_buildTestApp(FakeCatalogService()));
    await tester.pumpAndSettle();

    expect(find.text('Type a set number or name to search.'), findsOneWidget);
  });

  testWidgets('shows search results after debounce', (tester) async {
    final service = FakeCatalogService(
      results: [
        LegoSetsCompanion.insert(
          setNumber: '42115-1',
          name: 'Lamborghini Sian FKP 37',
          totalPieces: 3696,
        ),
      ],
    );

    await tester.pumpWidget(_buildTestApp(service));

    await tester.enterText(find.byType(TextField), 'Lamborghini');
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Lamborghini Sian FKP 37'), findsOneWidget);
    expect(service.queries, ['Lamborghini']);
  });

  testWidgets('shows no sets found for empty result', (tester) async {
    await tester.pumpWidget(_buildTestApp(FakeCatalogService()));

    await tester.enterText(find.byType(TextField), 'unknown-set');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('No sets found.'), findsOneWidget);
  });

  testWidgets('shows error state when service throws', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(FakeCatalogService(shouldThrow: true)),
    );

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.textContaining('API failure'), findsOneWidget);
  });
}
