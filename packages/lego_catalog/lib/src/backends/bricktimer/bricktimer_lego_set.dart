import 'package:lego_catalog/src/models/lego_set.dart';

/// Wire model for the Brick Timer catalog search response.
class BrickTimerLegoSetSummary {
  /// Creates a Brick Timer set summary DTO.
  const BrickTimerLegoSetSummary({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses a set summary from the Brick Timer backend payload.
  factory BrickTimerLegoSetSummary.fromJson(Map<String, dynamic> json) {
    return BrickTimerLegoSetSummary(
      setNumber: _stringValue(json, 'setNumber'),
      name: _stringValue(json, 'name', fallback: 'Unknown Set'),
      totalPieces: _intValue(json, 'totalPieces'),
      imageUrl: _stringOrNull(json, 'imageUrl'),
    );
  }

  /// Canonical set identifier (for example, `10316-1`).
  final String setNumber;

  /// Human-readable set name.
  final String name;

  /// Total number of pieces in the set.
  final int totalPieces;

  /// Optional image URL for the set.
  final String? imageUrl;

  /// Converts the Brick Timer DTO into the shared catalog model.
  LegoSetSummary toDomain() {
    return LegoSetSummary(
      setNumber: setNumber,
      name: name,
      totalPieces: totalPieces,
      imageUrl: imageUrl,
    );
  }
}

/// Wire model for the Brick Timer catalog details response.
class BrickTimerLegoSetDetails {
  /// Creates a Brick Timer set details DTO.
  const BrickTimerLegoSetDetails({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses set details from the Brick Timer backend payload.
  factory BrickTimerLegoSetDetails.fromJson(Map<String, dynamic> json) {
    return BrickTimerLegoSetDetails(
      setNumber: _stringValue(json, 'setNumber'),
      name: _stringValue(json, 'name', fallback: 'Unknown Set'),
      totalPieces: _intValue(json, 'totalPieces'),
      imageUrl: _stringOrNull(json, 'imageUrl'),
    );
  }

  /// Canonical set identifier (for example, `10316-1`).
  final String setNumber;

  /// Human-readable set name.
  final String name;

  /// Total number of pieces in the set.
  final int totalPieces;

  /// Optional image URL for the set.
  final String? imageUrl;

  /// Converts the Brick Timer DTO into the shared catalog model.
  LegoSetDetails toDomain() {
    return LegoSetDetails(
      setNumber: setNumber,
      name: name,
      totalPieces: totalPieces,
      imageUrl: imageUrl,
    );
  }
}

String _stringValue(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return fallback;
}

String? _stringOrNull(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return null;
}

int _intValue(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}
