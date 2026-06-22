import 'dart:convert';

import 'package:firebase_functions/firebase_functions.dart';
import 'package:lego_catalog/lego_catalog.dart';
import 'package:shelf_router/shelf_router.dart';

/// Small Brick Timer HTTP API for app-facing catalog requests.
class BrickTimerCatalogService {
  /// Creates a service backed by the provided [backend].
  BrickTimerCatalogService({required LegoCatalogBackend backend})
    : _backend = backend;

  final LegoCatalogBackend _backend;

  /// Handles a single HTTP request.
  Future<Response> handle(Request request) async {
    final router = Router()
      ..get('/health', (request) => _jsonResponse(200, {'status': 'ok'}))
      ..get('/v1/sets/search', _handleSearch)
      ..get('/v1/sets/<setNumber>', _handleDetails);

    final response = await router.call(request);

    if (response.statusCode == 404) {
      return _jsonResponse(
        404,
        {
          'error': 'not_found',
          'message': 'Unknown endpoint.',
        },
      );
    }

    if (response.statusCode == 405) {
      return _jsonResponse(
        405,
        {
          'error': 'method_not_allowed',
          'message': 'Only GET requests are supported.',
        },
        headers: const {'Allow': 'GET, OPTIONS'},
      );
    }

    return response;
  }

  Future<Response> _handleSearch(Request request) async {
    final query = request.url.queryParameters['query']?.trim() ?? '';
    if (query.isEmpty) {
      return _jsonResponse(
        400,
        {
          'error': 'invalid_argument',
          'message': 'The query parameter is required.',
        },
      );
    }

    final pageSize = _readIntQueryParameter(request, 'pageSize', fallback: 20);
    final minParts = _readIntQueryParameter(request, 'minParts', fallback: 1);
    final excludedThemeRootIds = _readIntListQueryParameter(
      request,
      'excludedThemeRootIds',
      fallback: const {501},
    );
    final includeDescendantThemesInExclusion =
        _readBoolQueryParameter(
          request,
          'includeDescendantThemesInExclusion',
          fallback: true,
        ) ??
        true;

    final results = await _backend.searchSets(
      query,
      pageSize: pageSize,
      minParts: minParts,
      excludedThemeRootIds: excludedThemeRootIds,
      includeDescendantThemesInExclusion: includeDescendantThemesInExclusion,
    );

    return _jsonResponse(
      200,
      {
        'results': results.map(_serializeSummary).toList(),
      },
    );
  }

  Future<Response> _handleDetails(Request request, String setNumber) async {
    if (setNumber.trim().isEmpty) {
      return _jsonResponse(
        400,
        {
          'error': 'invalid_argument',
          'message': 'A set number is required.',
        },
      );
    }

    final decodedSetNumber = Uri.decodeComponent(setNumber);
    final details = await _backend.getSetDetails(decodedSetNumber);
    if (details == null) {
      return _jsonResponse(
        404,
        {
          'error': 'not_found',
          'message': 'Set not found.',
        },
      );
    }

    return _jsonResponse(200, _serializeDetails(details));
  }

  static Map<String, dynamic> _serializeSummary(LegoSetSummary summary) {
    return {
      'setNumber': summary.setNumber,
      'name': summary.name,
      'totalPieces': summary.totalPieces,
      'imageUrl': summary.imageUrl,
    };
  }

  static Map<String, dynamic> _serializeDetails(LegoSetDetails details) {
    return {
      'setNumber': details.setNumber,
      'name': details.name,
      'totalPieces': details.totalPieces,
      'imageUrl': details.imageUrl,
    };
  }

  static int _readIntQueryParameter(
    Request request,
    String key, {
    required int fallback,
  }) {
    final rawValue = request.url.queryParameters[key];
    if (rawValue == null || rawValue.trim().isEmpty) {
      return fallback;
    }

    return int.tryParse(rawValue) ?? fallback;
  }

  static bool? _readBoolQueryParameter(
    Request request,
    String key, {
    required bool fallback,
  }) {
    final rawValue = request.url.queryParameters[key];
    if (rawValue == null || rawValue.trim().isEmpty) {
      return fallback;
    }

    switch (rawValue.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
      default:
        return null;
    }
  }

  static Set<int> _readIntListQueryParameter(
    Request request,
    String key, {
    required Set<int> fallback,
  }) {
    final rawValue = request.url.queryParameters[key];
    if (rawValue == null || rawValue.trim().isEmpty) {
      return fallback;
    }

    final values = rawValue
        .split(',')
        .map((value) => int.tryParse(value.trim()))
        .whereType<int>()
        .toSet();

    return values.isEmpty ? fallback : values;
  }

  static Response _jsonResponse(
    int statusCode,
    Object body, {
    Map<String, String> headers = const {},
  }) {
    return Response(
      statusCode,
      body: jsonEncode(body),
      headers: <String, Object>{
        'Content-Type': 'application/json; charset=utf-8',
        'Cache-Control': 'no-store',
        ...headers,
      },
    );
  }
}
