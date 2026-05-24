import 'package:lego_catalog/src/backends/rebrickable/lego_theme.dart';
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

  /// Returns the excluded theme IDs.
  Future<Set<int>> getExcludedThemeIds() {
    if (_rootThemeIds.isEmpty) {
      return Future<Set<int>>.value(const <int>{});
    }

    return _fetchExcludedThemeIds();
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
      childThemeIdsByParent.putIfAbsent(theme.parentId, () => <int>[]).add(
        theme.id,
      );
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

  Future<List<LegoTheme>> _safeListThemes() async {
    try {
      return await _apiClient.listThemes();
    } on Exception {
      // If theme lookup fails, continue with configured roots only.
      return const <LegoTheme>[];
    }
  }
}
