import '../models/lego_set.dart';

abstract class LegoCatalogBackend {
  Future<List<LegoSetSummary>> searchSets(
    String query, {
    int pageSize = 20,
  });

  Future<LegoSetDetails?> getSetDetails(String setNumber);
}
