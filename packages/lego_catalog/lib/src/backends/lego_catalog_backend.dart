import 'package:lego_catalog/src/models/lego_set.dart';

/// Defines a pluggable LEGO catalog backend implementation.
abstract class LegoCatalogBackend {
  /// Searches for sets matching [query].
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
  });

  /// Fetches details for a single set number, or null when not found.
  Future<LegoSetDetails?> getSetDetails(String setNumber);
}
