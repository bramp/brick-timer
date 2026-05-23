class LegoSetSummary {
  const LegoSetSummary({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  factory LegoSetSummary.fromJson(Map<String, dynamic> json) {
    return LegoSetSummary(
      setNumber: json['set_num'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Set',
      totalPieces: json['num_parts'] as int? ?? 0,
      imageUrl: json['set_img_url'] as String?,
    );
  }

  final String setNumber;
  final String name;
  final int totalPieces;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'set_num': setNumber,
      'name': name,
      'num_parts': totalPieces,
      'set_img_url': imageUrl,
    };
  }
}

class LegoSetDetails {
  const LegoSetDetails({
    required this.setNumber,
    required this.name,
    required this.totalPieces,
    this.imageUrl,
  });

  factory LegoSetDetails.fromJson(Map<String, dynamic> json) {
    return LegoSetDetails(
      setNumber: json['set_num'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Set',
      totalPieces: json['num_parts'] as int? ?? 0,
      imageUrl: json['set_img_url'] as String?,
    );
  }

  final String setNumber;
  final String name;
  final int totalPieces;
  final String? imageUrl;

  Map<String, dynamic> toJson() {
    return {
      'set_num': setNumber,
      'name': name,
      'num_parts': totalPieces,
      'set_img_url': imageUrl,
    };
  }
}
