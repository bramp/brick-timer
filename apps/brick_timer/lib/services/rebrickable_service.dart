import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/lego_catalog_service.dart';
import 'package:drift/drift.dart';
import 'package:lego_catalog/lego_catalog.dart';

/// App adapter that maps generic catalog models to drift companions.
class RebrickableService implements LegoCatalogService {
  /// Creates a catalog adapter using the provided backend or Rebrickable.
  RebrickableService({
    required String apiKey,
    LegoCatalogBackend? backend,
  }) : _backend = backend ?? RebrickableBackend(apiKey: apiKey);

  final LegoCatalogBackend _backend;

  /// Fetches LEGO set details by its set number.
  /// Note: Rebrickable usually requires a '-1' suffix for standard sets.
  @override
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async {
    final details = await _backend.getSetDetails(setNumber);
    if (details == null) {
      return null;
    }

    return LegoSetsCompanion.insert(
      setNumber: details.setNumber,
      name: details.name,
      totalPieces: details.totalPieces,
      imageUrl: Value(details.imageUrl),
    );
  }

  /// Searches for LEGO sets by text query.
  @override
  Future<List<LegoSetsCompanion>> searchSets(String query) async {
    final results = await _backend.searchSets(query);
    return results.map((set) {
      return LegoSetsCompanion.insert(
        setNumber: set.setNumber,
        name: set.name,
        totalPieces: set.totalPieces,
        imageUrl: Value(set.imageUrl),
      );
    }).toList();
  }
}
