import 'dart:convert';

import 'package:brick_time/repositories/ledger_repository.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

/// Service to interact with the Rebrickable v3 API.
class RebrickableService {
  /// Creates a new [RebrickableService] with the given [apiKey].
  RebrickableService({required this.apiKey});

  /// The Rebrickable API key. In production, this should be securely managed.
  final String apiKey;

  static const String _baseUrl = 'https://rebrickable.com/api/v3/lego';

  /// Fetches LEGO set details by its set number.
  /// Note: Rebrickable usually requires a '-1' suffix for standard sets.
  Future<LegoSetsCompanion?> getSetDetails(String setNumber) async {
    final normalizedSetNum = setNumber.contains('-')
        ? setNumber
        : '$setNumber-1';
    final uri = Uri.parse('$_baseUrl/sets/$normalizedSetNum/');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'key $apiKey', 'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return LegoSetsCompanion.insert(
          setNumber: setNumber,
          name: data['name'] as String? ?? 'Unknown Set',
          totalPieces: data['num_parts'] as int? ?? 0,
          imageUrl: Value(data['set_img_url'] as String?),
        );
      }
    } on Exception catch (_) {
      // Handle network errors
    }
    return null;
  }
}
