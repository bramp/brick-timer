import 'package:brick_timer/main.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/catalog_service.dart';
import 'package:brick_timer/state/search_providers.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _FakeCatalogService implements CatalogService {
  _FakeCatalogService(this._resultsByQuery);

  final Map<String, List<LegoSetsCompanion>> _resultsByQuery;

  @override
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async => null;

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
    return _resultsByQuery[query] ?? const <LegoSetsCompanion>[];
  }
}

Future<void> _resetLedger() async {
  await ledgerRepository.delete(ledgerRepository.bagIntervals).go();
  await ledgerRepository.delete(ledgerRepository.buildSessions).go();
  await ledgerRepository.delete(ledgerRepository.legoSets).go();
}

ProviderScope _buildTestApp(CatalogService service) {
  return ProviderScope(
    overrides: [
      legoCatalogServiceProvider.overrideWithValue(service),
    ],
    child: const BrickTimerApp(),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await ledgerRepository.init();
  });

  setUp(() async {
    await _resetLedger();
  });

  testWidgets('start new build flow creates active build on dashboard', (
    tester,
  ) async {
    final service = _FakeCatalogService({
      'Lamborghini': [
        LegoSetsCompanion.insert(
          setNumber: '42115-1',
          name: 'Lamborghini Sian FKP 37',
          totalPieces: 3696,
          imageUrl: const Value('https://example.com/42115.png'),
        ),
      ],
    });

    await tester.pumpWidget(_buildTestApp(service));
    await tester.pumpAndSettle();

    expect(find.text('Start New Build'), findsOneWidget);

    await tester.tap(find.text('Start New Build'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Lamborghini');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.text('Lamborghini Sian FKP 37'), findsOneWidget);

    await tester.tap(find.text('Lamborghini Sian FKP 37'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Lamborghini Sian FKP 37'), findsOneWidget);
  });

  testWidgets('active build flow supports start, pause, resume and finish', (
    tester,
  ) async {
    final service = _FakeCatalogService({
      'technic': [
        LegoSetsCompanion.insert(
          setNumber: '42000-1',
          name: 'Technic Race Car',
          totalPieces: 250,
        ),
      ],
    });

    await tester.pumpWidget(_buildTestApp(service));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start New Build'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'technic');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Technic Race Car'));
    await tester.pumpAndSettle();

    expect(find.text('Start Bag 1'), findsOneWidget);

    await tester.tap(find.text('Start Bag 1'));
    await tester.pumpAndSettle();

    expect(find.text('Building Bag 1'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();

    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();

    expect(find.text('Building Bag 1'), findsOneWidget);

    await tester.tap(find.text('Finished Set!'));
    await tester.pumpAndSettle();

    expect(find.text('No active sessions yet.'), findsOneWidget);
    expect(find.text('Technic Race Car'), findsOneWidget);
  });
}
