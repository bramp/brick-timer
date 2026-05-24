/// Configurable local and server-side filter policy for set searches.
class RebrickableSearchFilterPolicy {
  /// Creates a policy used to build search params and post-filter results.
  RebrickableSearchFilterPolicy({
    this.minParts = 1,
    Set<int> excludedThemeRootIds = const {501},
    this.includeDescendantThemesInExclusion = true,
  }) : excludedThemeRootIds = Set<int>.unmodifiable(excludedThemeRootIds) {
    if (minParts < 0) {
      throw ArgumentError.value(minParts, 'minParts', 'must be >= 0');
    }
  }

  /// Minimum number of parts required for a set to be included.
  final int minParts;

  /// Root theme IDs to exclude from results.
  ///
  /// Theme root `501` is Rebrickable "Gear" and is excluded by default to
  /// reduce non-buildable merchandise results.
  final Set<int> excludedThemeRootIds;

  /// Whether descendant themes of [excludedThemeRootIds] should also be
  /// excluded.
  final bool includeDescendantThemesInExclusion;

  /// Builds query parameters for the remote set-search request.
  Map<String, String> buildSearchQueryParameters(
    String query, {
    required int pageSize,
  }) {
    return {
      'search': query,
      'page_size': pageSize.toString(),
      if (minParts > 0) 'min_parts': minParts.toString(),
    };
  }

  /// Applies local filtering to a raw set payload.
  bool passes(Map<String, dynamic> setJson, Set<int> excludedThemeIds) {
    final numParts = (setJson['num_parts'] as num?)?.toInt() ?? 0;
    if (numParts < minParts) {
      return false;
    }

    final themeId = (setJson['theme_id'] as num?)?.toInt();
    if (themeId != null && excludedThemeIds.contains(themeId)) {
      return false;
    }

    return true;
  }
}
