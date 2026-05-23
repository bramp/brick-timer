import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:drift/drift.dart';
import 'package:lego_catalog/lego_catalog.dart';

/// App adapter that maps generic catalog models to drift companions.
class CatalogService {
  /// Creates a catalog adapter from an external catalog backend.
  CatalogService({required LegoCatalogBackend backend}) : _backend = backend;

  /// Creates a catalog adapter backed by Rebrickable.
  factory CatalogService.rebrickable({required String apiKey}) {
    return CatalogService(backend: RebrickableBackend(apiKey: apiKey));
  }

  final LegoCatalogBackend _backend;

  /// Fetches LEGO set details by its set number.
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
