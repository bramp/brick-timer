import 'package:brick_timer/repositories/ledger_repository.dart';

/// An abstract interface for fetching LEGO catalog data.
///
/// This allows us to cleanly swap out the underlying data source
/// (e.g., direct Rebrickable API vs Firebase Serverless Proxy) without
/// affecting the UI or state providers.
// TODO We can remove this now, since this abstraction moved into packages/lego_catalog
abstract class LegoCatalogService {
  /// Searches for LEGO sets by text query.
  Future<List<LegoSetsCompanion>> searchSets(String query);

  /// Fetches LEGO set details by its set number.
  Future<LegoSetsCompanion?> getSetDetails(String setNumber);
}
