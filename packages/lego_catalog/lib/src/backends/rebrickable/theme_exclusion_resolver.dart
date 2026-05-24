import 'package:lego_catalog/src/backends/rebrickable/rebrickable_api_client.dart';

/// Resolves excluded theme IDs, optionally including descendants.
class RebrickableThemeExclusionResolver {
  /// Creates a resolver for excluded theme IDs.
  RebrickableThemeExclusionResolver({
    required RebrickableApiClient apiClient,
    required Set<int> rootThemeIds,
    required bool includeDescendantThemes,
  }) : _apiClient = apiClient,
       _rootThemeIds = Set<int>.unmodifiable(rootThemeIds),
       _includeDescendantThemes = includeDescendantThemes;

  final RebrickableApiClient _apiClient;
  final Set<int> _rootThemeIds;
  final bool _includeDescendantThemes;

  Future<Set<int>>? _excludedThemeIdsFuture;

  /// Returns the excluded theme IDs, using a cached value after first lookup.
  Future<Set<int>> getExcludedThemeIds() {
    if (_rootThemeIds.isEmpty) {
      return Future<Set<int>>.value(const <int>{});
    }

    return _excludedThemeIdsFuture ??= _fetchExcludedThemeIds();
  }

  Future<Set<int>> _fetchExcludedThemeIds() async {
    if (!_includeDescendantThemes) {
      return Set<int>.from(_rootThemeIds);
    }

    final allThemes = await _safeListThemes();
    if (allThemes.isEmpty) {
      return Set<int>.from(_rootThemeIds);
    }

    final childThemeIdsByParent = <int?, List<int>>{};
    for (final theme in allThemes) {
      final id = (theme['id'] as num?)?.toInt();
      if (id == null) {
        continue;
      }

      final parentId = (theme['parent_id'] as num?)?.toInt();
      childThemeIdsByParent.putIfAbsent(parentId, () => <int>[]).add(id);
    }

    final excluded = Set<int>.from(_rootThemeIds);
    final toVisit = List<int>.from(_rootThemeIds);
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeLast();
      final children = childThemeIdsByParent[current];
      if (children == null) {
        continue;
      }

      for (final child in children) {
        if (excluded.add(child)) {
          toVisit.add(child);
        }
      }
    }

    return excluded;
  }

  Future<List<Map<String, dynamic>>> _safeListThemes() async {
    try {
      return await _apiClient.listThemesRaw();
    } on Exception {
      // If theme lookup fails, continue with configured roots only.
      return const <Map<String, dynamic>>[];
    }
  }
}
