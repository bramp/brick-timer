import 'dart:async';

import 'package:brick_timer/env/env.dart';
import 'package:brick_timer/repositories/ledger_repository.dart';
import 'package:brick_timer/services/catalog_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the LEGO Catalog API service.
final legoCatalogServiceProvider = Provider<CatalogService>((ref) {
  // TODO(bramp): Later swap this to FirebaseProxyService
  return CatalogService.create(rebrickableApiKey: Env.rebrickableApiKey);
});

/// The current search query.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  /// Updates the active query while ignoring no-op normalized changes.
  void updateQuery(String newQuery) {
    if (newQuery.trim() == state.trim()) {
      return;
    }

    state = newQuery;
  }
}

/// Provider exposing the current user-entered search query string.
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

/// A provider that watches the search query, debounces it, and fetches results.
final searchResultsProvider = FutureProvider<List<LegoSetsCompanion>>((
  ref,
) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];

  // Flag to track if a new query was typed, which disposes this provider
  // instance.
  var isCancelled = false;
  ref.onDispose(() {
    isCancelled = true;
  });

  // Wait 500ms before making the request (debounce)
  await Future<void>.delayed(const Duration(milliseconds: 500));

  // If the user typed something else during the 500ms, abort the network call!
  if (isCancelled) {
    return [];
  }

  final service = ref.read(legoCatalogServiceProvider);
  return service.searchSets(query);
}, retry: (retryCount, error) => null);
