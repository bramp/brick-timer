import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:lego_catalog/lego_catalog.dart';
import 'package:logger/logger.dart';

/// Persists Rebrickable themes and expands excluded theme roots.
class RebrickableThemeCacheService {
  /// Creates a persisted theme cache service with an expiration [ttl].
  RebrickableThemeCacheService({
    required Future<List<LegoTheme>> Function() fetchThemes,
    BaseCacheManager? cacheManager,
    Duration ttl = const Duration(days: 7),
    Clock? clock,
  }) : _fetchThemes = fetchThemes,
       _cacheManager = cacheManager ?? _RebrickableThemeCacheManager.instance,
       _ttl = ttl,
       _clock = clock ?? const Clock();

  static const String _themesCacheObjectKey = 'rebrickable_theme_cache_v1';
  static final Logger _logger = Logger(level: Level.warning);

  final Future<List<LegoTheme>> Function() _fetchThemes;
  final BaseCacheManager _cacheManager;
  final Duration _ttl;
  final Clock _clock;

  Future<List<LegoTheme>>? _themesFuture;

  /// Refreshes cached themes only when the current snapshot is older than TTL.
  Future<void> refreshIfExpired() async {
    final cached = await _readCache();
    if (cached != null && !_isExpired(cached.fetchedAt)) {
      return;
    }

    _themesFuture = null;
    await _getThemes();
  }

  /// Expands [rootThemeIds] with descendant themes from cached/fetched themes.
  Future<Set<int>> expandThemeRootIds(Set<int> rootThemeIds) async {
    if (rootThemeIds.isEmpty) {
      return const <int>{};
    }

    final themes = await _getThemes();
    if (themes.isEmpty) {
      return Set<int>.from(rootThemeIds);
    }

    final childThemeIdsByParent = <int?, List<int>>{};
    for (final theme in themes) {
      childThemeIdsByParent
          .putIfAbsent(theme.parentId, () => <int>[])
          .add(theme.id);
    }

    final excluded = Set<int>.from(rootThemeIds);
    final toVisit = List<int>.from(rootThemeIds);
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

  Future<List<LegoTheme>> _getThemes() {
    return _themesFuture ??= _loadThemes();
  }

  Future<List<LegoTheme>> _loadThemes() async {
    final cached = await _readCache();
    if (cached != null && !_isExpired(cached.fetchedAt)) {
      return cached.themes;
    }

    try {
      final fetchedThemes = await _fetchThemes();
      final payload = _ThemeCachePayload(
        fetchedAt: _clock.now().toUtc(),
        themes: fetchedThemes,
      );

      try {
        await _writeCache(payload);
      } on Exception catch (error, stackTrace) {
        _logger.e(
          'Failed to serialize/write Rebrickable theme cache.',
          error: error,
          stackTrace: stackTrace,
        );
      }

      return fetchedThemes;
    } on Exception catch (error, stackTrace) {
      _logger.e(
        'Failed to fetch Rebrickable themes. Falling back to cached themes '
        'when available.',
        error: error,
        stackTrace: stackTrace,
      );
      if (cached != null) {
        return cached.themes;
      }
      return const <LegoTheme>[];
    }
  }

  bool _isExpired(DateTime fetchedAt) {
    final age = _clock.now().toUtc().difference(fetchedAt.toUtc());
    return age >= _ttl;
  }

  Future<_ThemeCachePayload?> _readCache() async {
    final fileInfo = await _cacheManager.getFileFromCache(
      _themesCacheObjectKey,
    );
    if (fileInfo == null) {
      return null;
    }

    try {
      final text = await fileInfo.file.readAsString();
      final dynamic decoded = jsonDecode(text);
      if (decoded is! Map<String, Object?>) {
        _logger.w(
          'Theme cache payload is not a JSON object. Ignoring cache entry.',
        );
        return null;
      }

      final fetchedAtRaw = decoded['fetched_at'];
      final themesRaw = decoded['themes'];
      if (fetchedAtRaw is! String || themesRaw is! List<Object?>) {
        _logger.w(
          'Theme cache payload is missing required fields. Ignoring cache '
          'entry.',
        );
        return null;
      }

      final fetchedAt = DateTime.parse(fetchedAtRaw).toUtc();
      final themes = <LegoTheme>[];
      for (final themeRaw in themesRaw) {
        if (themeRaw is! Map<String, Object?>) {
          _logger.w(
            'Theme cache contains a non-object entry. Ignoring cache entry.',
          );
          return null;
        }

        try {
          themes.add(LegoTheme.fromJson(themeRaw));
        } on FormatException catch (error, stackTrace) {
          _logger.w(
            'Theme cache contains an invalid theme entry. Ignoring cache '
            'entry.',
            error: error,
            stackTrace: stackTrace,
          );
          return null;
        }
      }

      // TODO(bramp): Be smarter by comparing highest theme IDs first (reverse
      // order). If no new theme ID appears, skip refresh and extend validity.
      return _ThemeCachePayload(fetchedAt: fetchedAt, themes: themes);
    } on Exception catch (error, stackTrace) {
      _logger.e(
        'Failed to deserialize Rebrickable theme cache. Ignoring cache entry.',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _writeCache(_ThemeCachePayload payload) async {
    final bytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'fetched_at': payload.fetchedAt.toUtc().toIso8601String(),
          'themes': payload.themes
              .map<Map<String, Object?>>((theme) => theme.toJson())
              .toList(),
        }),
      ),
    );

    await _cacheManager.putFile(
      _themesCacheObjectKey,
      bytes,
      fileExtension: 'json',
      maxAge: const Duration(days: 3650),
    );
  }
}

class _ThemeCachePayload {
  const _ThemeCachePayload({required this.fetchedAt, required this.themes});

  final DateTime fetchedAt;
  final List<LegoTheme> themes;
}

class _RebrickableThemeCacheManager extends CacheManager {
  _RebrickableThemeCacheManager._()
    : super(
        Config(
          _cacheKey,
          stalePeriod: const Duration(days: 3650),
          maxNrOfCacheObjects: 4,
        ),
      );

  static const String _cacheKey = 'rebrickable_theme_cache';

  static final _RebrickableThemeCacheManager instance =
      _RebrickableThemeCacheManager._();
}
