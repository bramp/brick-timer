/// Lightweight set information returned from search endpoints.
class LegoSetSummary {
  /// Creates a set summary.
  const LegoSetSummary({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses a set summary from a backend JSON payload.
  factory LegoSetSummary.fromJson(Map<String, dynamic> json) {
    return LegoSetSummary(
      setNumber: json['set_num'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unknown Set',
      totalPieces: _intValue(json, 'num_parts'),
      imageUrl: _stringOrNull(json, 'set_img_url'),
    );
  }

  /// Rebrickable set number, for example 42115-1.
  final String setNumber;

  /// Human-readable set name.
  final String name;

  /// Number of pieces in the set.
  final int totalPieces;

  /// Optional image URL for display.
  final String? imageUrl;

  /// Serializes this summary to JSON.
  Map<String, dynamic> toJson() {
    return {
      'set_num': setNumber,
      'name': name,
      'num_parts': totalPieces,
      'set_img_url': imageUrl,
    };
  }
}

/// Detailed set information returned from set detail endpoints.
class LegoSetDetails {
  /// Creates set details.
  const LegoSetDetails({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  /// Parses set details from a backend JSON payload.
  factory LegoSetDetails.fromJson(Map<String, dynamic> json) {
    return LegoSetDetails(
      setNumber: json['set_num'] as String,
      name: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : 'Unknown Set',
      totalPieces: _intValue(json, 'num_parts'),
      imageUrl: _stringOrNull(json, 'set_img_url'),
    );
  }

  /// Rebrickable set number, for example 42115-1.
  final String setNumber;

  /// Human-readable set name.
  final String name;

  /// Number of pieces in the set.
  final int totalPieces;

  /// Optional image URL for display.
  final String? imageUrl;

  /// Serializes these details to JSON.
  Map<String, dynamic> toJson() {
    return {
      'set_num': setNumber,
      'name': name,
      'num_parts': totalPieces,
      'set_img_url': imageUrl,
    };
  }
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
