import 'dart:convert';

import 'package:http/http.dart' as http;

/// Service to push completed bag data to a Google Apps Script Webhook.
class SpreadsheetService {
  /// Creates a new [SpreadsheetService] with the given [webhookUrl].
  SpreadsheetService({required this.webhookUrl});

  /// The target Google Apps Script Webhook URL.
  final String webhookUrl;

  /// Attempts to sync a payload to the spreadsheet.
  /// Returns true if successful.
  Future<bool> syncCompletedBag({
    required String setNumber,
    required String setName,
    required int bagNumber,
    required int totalDurationMinutes,
  }) async {
    try {
      final payload = {
        'date': DateTime.now().toIso8601String(),
        'setNumber': setNumber,
        'setName': setName,
        'bagNumber': bagNumber,
        'totalDurationMinutes': totalDurationMinutes,
      };

      final response = await http.post(
        Uri.parse(webhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      // Google Apps Script Webhooks often return 302 redirects which http
      // package follows, resulting in a 200 OK from the final destination.
      return response.statusCode == 200;
    } on Exception catch (_) {
      return false;
    }
  }
}
