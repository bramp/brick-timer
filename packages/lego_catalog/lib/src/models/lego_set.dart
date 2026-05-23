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
      setNumber: json['set_num'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Set',
      totalPieces: json['num_parts'] as int? ?? 0,
      imageUrl: json['set_img_url'] as String?,
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
      setNumber: json['set_num'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Set',
      totalPieces: json['num_parts'] as int? ?? 0,
      imageUrl: json['set_img_url'] as String?,
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
