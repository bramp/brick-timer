import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/Catalog_Service.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:brick_timer/ui/search/lego_catalog_search_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCatalogService implements CatalogService {
  FakeCatalogService({
    this.shouldThrow = false,
    this.throwsBeforeSuccess = 0,
    List<LegoSetsCompanion>? results,
  }) : _results = results ?? [];

  final bool shouldThrow;
  int throwsBeforeSuccess;
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
    if (throwsBeforeSuccess > 0) {
      throwsBeforeSuccess--;
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
    child: const MaterialApp(
      home: LegoCatalogSearchScreen(),
    ),
  );
}

void main() {
  testWidgets('shows initial prompt before typing', (tester) async {
    await tester.pumpWidget(_buildTestApp(FakeCatalogService()));
    await tester.pumpAndSettle();

    expect(find.text('Find your next build'), findsOneWidget);
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

  testWidgets('renders cached network image for result with image url', (
    tester,
  ) async {
    final service = FakeCatalogService(
      results: [
        LegoSetsCompanion.insert(
          setNumber: '42115-1',
          name: 'Lamborghini Sian FKP 37',
          totalPieces: 3696,
          imageUrl: const Value('https://example.com/42115.png'),
        ),
      ],
    );
    await tester.pumpWidget(_buildTestApp(service));

    await tester.enterText(find.byType(TextField), 'Lamborghini');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Lamborghini Sian FKP 37'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsOneWidget);

    final image = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(image.imageUrl, 'https://example.com/42115.png');
  });

  testWidgets('shows no sets found for empty result', (tester) async {
    await tester.pumpWidget(_buildTestApp(FakeCatalogService()));

    await tester.enterText(find.byType(TextField), 'unknown-set');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('No sets found'), findsOneWidget);
  });

  testWidgets('shows error state when service throws', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(FakeCatalogService(shouldThrow: true)),
    );

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Could not load search results'), findsOneWidget);
    expect(
      find.text('We could not load search results. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.textContaining('API failure'), findsNothing);

    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.textContaining('API failure'), findsOneWidget);

    await tester.tap(find.text('Hide details'));
    await tester.pumpAndSettle();
    expect(find.text('Technical details'), findsNothing);
  });

  testWidgets('pull-to-refresh retries search after an error', (tester) async {
    final service = FakeCatalogService(
      throwsBeforeSuccess: 1,
      results: [
        LegoSetsCompanion.insert(
          setNumber: '42000-1',
          name: 'Technic Race Car',
          totalPieces: 250,
        ),
      ],
    );

    await tester.pumpWidget(_buildTestApp(service));

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Could not load search results'), findsOneWidget);
    expect(service.queries, ['technic']);

    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Technic Race Car'), findsOneWidget);
    expect(service.queries, ['technic', 'technic']);
  });

  testWidgets('retry button retries search after an error', (tester) async {
    final service = FakeCatalogService(
      throwsBeforeSuccess: 1,
      results: [
        LegoSetsCompanion.insert(
          setNumber: '42000-1',
          name: 'Technic Race Car',
          totalPieces: 250,
        ),
      ],
    );

    await tester.pumpWidget(_buildTestApp(service));

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Could not load search results'), findsOneWidget);
    expect(service.queries, ['technic']);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Technic Race Car'), findsOneWidget);
    expect(service.queries, ['technic', 'technic']);
  });

  testWidgets('app bar refresh retries search after an error', (tester) async {
    final service = FakeCatalogService(
      throwsBeforeSuccess: 1,
      results: [
        LegoSetsCompanion.insert(
          setNumber: '42000-1',
          name: 'Technic Race Car',
          totalPieces: 250,
        ),
      ],
    );

    await tester.pumpWidget(_buildTestApp(service));

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(find.text('Could not load search results'), findsOneWidget);
    expect(service.queries, ['technic']);

    await tester.tap(find.byTooltip('Refresh search results'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(find.text('Technic Race Car'), findsOneWidget);
    expect(service.queries, ['technic', 'technic']);
  });
}
