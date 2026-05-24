import 'package:lego_catalog/src/models/lego_set.dart';

/// Defines a pluggable LEGO catalog backend implementation.
abstract class LegoCatalogBackend {
  /// Searches for sets matching [query].
  ///
  /// By default, theme root `501` (Rebrickable "Gear") is excluded because it
  /// primarily contains non-buildable merchandise (for example storage, video
  /// game accessories, stationery, and similar items).
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
    int minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    bool includeDescendantThemesInExclusion = true,
  });

  /// Fetches details for a single set number, or null when not found.
  Future<LegoSetDetails?> getSetDetails(String setNumber);
}
